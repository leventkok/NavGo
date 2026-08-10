package placesinfra

import (
	"context"
	"crypto/tls"
	"io"
	"net"
	"net/http"
	"strings"
	"time"
)

// newGoogleHTTPClient returns a client tuned for Google Maps REST APIs on Windows.
//
// Local middleboxes sometimes break Go's default TLS 1.3 + ML-KEM ClientHello
// ("tls: server did not echo the legacy session ID"). Stick to classic curves,
// disable HTTP/2, and retry transient transport failures.
func newGoogleHTTPClient() *http.Client {
	transport := &http.Transport{
		Proxy: http.ProxyFromEnvironment,
		DialContext: (&net.Dialer{
			Timeout:   10 * time.Second,
			KeepAlive: 30 * time.Second,
		}).DialContext,
		ForceAttemptHTTP2: false,
		TLSNextProto:      map[string]func(authority string, c *tls.Conn) http.RoundTripper{},
		TLSClientConfig: &tls.Config{
			MinVersion: tls.VersionTLS12,
			// Avoid post-quantum hybrids (X25519MLKEM768 / SecP*MLKEM*) that
			// inflate ClientHello and confuse some Windows TLS inspectors.
			CurvePreferences: []tls.CurveID{
				tls.X25519,
				tls.CurveP256,
				tls.CurveP384,
			},
		},
		MaxIdleConns:          10,
		IdleConnTimeout:       30 * time.Second,
		TLSHandshakeTimeout:   20 * time.Second,
		ExpectContinueTimeout: 1 * time.Second,
		ResponseHeaderTimeout: 30 * time.Second,
	}
	return &http.Client{
		Timeout:   45 * time.Second,
		Transport: transport,
		CheckRedirect: func(req *http.Request, via []*http.Request) error {
			return http.ErrUseLastResponse
		},
	}
}

func isTransientGoogleTransportErr(err error) bool {
	if err == nil {
		return false
	}
	msg := err.Error()
	return strings.Contains(msg, "legacy session ID") ||
		strings.Contains(msg, "TLS handshake timeout") ||
		strings.Contains(msg, "connection reset") ||
		strings.Contains(msg, "EOF") ||
		strings.Contains(msg, "i/o timeout")
}

// doGoogleRequest runs an HTTP request with a couple of retries for flaky Windows TLS.
func doGoogleRequest(ctx context.Context, client *http.Client, req *http.Request) (*http.Response, []byte, error) {
	var lastErr error
	for attempt := 0; attempt < 4; attempt++ {
		if attempt > 0 {
			select {
			case <-ctx.Done():
				return nil, nil, ctx.Err()
			case <-time.After(time.Duration(attempt) * 400 * time.Millisecond):
			}
		}
		cloned := req.Clone(ctx)
		if req.GetBody != nil {
			body, err := req.GetBody()
			if err != nil {
				return nil, nil, err
			}
			cloned.Body = body
		}
		resp, err := client.Do(cloned)
		if err != nil {
			lastErr = err
			if isTransientGoogleTransportErr(err) {
				continue
			}
			return nil, nil, err
		}
		raw, readErr := io.ReadAll(io.LimitReader(resp.Body, 1<<20))
		resp.Body.Close()
		if readErr != nil {
			lastErr = readErr
			if isTransientGoogleTransportErr(readErr) {
				continue
			}
			return nil, nil, readErr
		}
		return resp, raw, nil
	}
	return nil, nil, lastErr
}
