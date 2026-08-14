package llminfra

import (
	"bytes"
	"context"
	"encoding/json"
	"fmt"
	"io"
	"net/http"
	"strings"
	"time"

	"github.com/leventkok/NavGo/internal/domain/llm"
	domainErr "github.com/leventkok/NavGo/internal/shared/errors"
)

// OpenAIClient calls OpenAI-compatible /chat/completions (Ollama, Groq, etc.).
type OpenAIClient struct {
	baseURL    string
	model      string
	apiKey     string
	httpClient *http.Client
}

// NewOpenAIClient builds a chat client. baseURL should include /v1 (no trailing slash).
func NewOpenAIClient(baseURL, model, apiKey string) *OpenAIClient {
	return &OpenAIClient{
		baseURL: strings.TrimRight(strings.TrimSpace(baseURL), "/"),
		model:   model,
		apiKey:  apiKey,
		httpClient: &http.Client{
			// Colab/tunnel cold generate can exceed 90s; warm calls are fast.
			Timeout: 300 * time.Second,
		},
	}
}

type chatCompletionRequest struct {
	Model       string        `json:"model"`
	Messages    []chatMessage `json:"messages"`
	Temperature float64       `json:"temperature,omitempty"`
	MaxTokens   int           `json:"max_tokens,omitempty"`
}

type chatMessage struct {
	Role    string `json:"role"`
	Content string `json:"content"`
}

type chatCompletionResponse struct {
	Choices []struct {
		Message struct {
			Content string `json:"content"`
		} `json:"message"`
	} `json:"choices"`
	Error *struct {
		Message string `json:"message"`
	} `json:"error,omitempty"`
}

// Chat implements [llm.ChatClient].
func (c *OpenAIClient) Chat(ctx context.Context, req llm.ChatRequest) (string, error) {
	if c.baseURL == "" {
		return "", domainErr.New(domainErr.ErrUnavailable, "LLM is not configured", nil)
	}
	if c.model == "" {
		return "", domainErr.New(domainErr.ErrValidation, "LLM model is not configured", nil)
	}

	msgs := make([]chatMessage, 0, len(req.Messages))
	for _, m := range req.Messages {
		msgs = append(msgs, chatMessage{Role: m.Role, Content: m.Content})
	}

	body := chatCompletionRequest{
		Model:       c.model,
		Messages:    msgs,
		Temperature: req.Temperature,
		MaxTokens:   req.MaxTokens,
	}
	payload, err := json.Marshal(body)
	if err != nil {
		return "", domainErr.New(domainErr.ErrInternal, "failed to encode LLM request", err)
	}

	httpReq, err := http.NewRequestWithContext(
		ctx,
		http.MethodPost,
		c.baseURL+"/chat/completions",
		bytes.NewReader(payload),
	)
	if err != nil {
		return "", domainErr.New(domainErr.ErrInternal, "failed to build LLM request", err)
	}
	httpReq.Header.Set("Content-Type", "application/json")
	if c.apiKey != "" {
		httpReq.Header.Set("Authorization", "Bearer "+c.apiKey)
	}

	resp, err := c.httpClient.Do(httpReq)
	if err != nil {
		return "", domainErr.New(domainErr.ErrUnavailable, "LLM request failed", err)
	}
	defer resp.Body.Close()

	raw, err := io.ReadAll(io.LimitReader(resp.Body, 1<<20))
	if err != nil {
		return "", domainErr.New(domainErr.ErrInternal, "failed to read LLM response", err)
	}

	var parsed chatCompletionResponse
	if err := json.Unmarshal(raw, &parsed); err != nil {
		return "", domainErr.New(domainErr.ErrInternal, "invalid LLM response JSON", err)
	}
	if parsed.Error != nil && parsed.Error.Message != "" {
		return "", domainErr.New(domainErr.ErrUnavailable, parsed.Error.Message, nil)
	}
	if resp.StatusCode < 200 || resp.StatusCode >= 300 {
		return "", domainErr.New(
			domainErr.ErrUnavailable,
			fmt.Sprintf("LLM upstream status %d: %s", resp.StatusCode, strings.TrimSpace(string(raw))),
			nil,
		)
	}
	if len(parsed.Choices) == 0 || strings.TrimSpace(parsed.Choices[0].Message.Content) == "" {
		return "", domainErr.New(domainErr.ErrInternal, "LLM returned empty content", nil)
	}
	return parsed.Choices[0].Message.Content, nil
}
