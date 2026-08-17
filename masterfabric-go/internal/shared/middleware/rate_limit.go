package middleware

import (
	"context"
	"fmt"
	"net/http"
	"sync"
	"time"

	"github.com/leventkok/NavGo/internal/shared/response"
	"github.com/redis/go-redis/v9"
)

// RateLimiter is the shared interface for auth/LLM limiting.
type RateLimiter interface {
	Allow(key string) bool
}

type rateBucket struct {
	count   int
	resetAt time.Time
}

// MemoryRateLimiter is a simple in-process fixed window limiter.
type MemoryRateLimiter struct {
	mu      sync.Mutex
	buckets map[string]*rateBucket
	limit   int
	window  time.Duration
}

// NewMemoryRateLimiter constructs a limiter.
func NewMemoryRateLimiter(limit int, window time.Duration) *MemoryRateLimiter {
	return &MemoryRateLimiter{
		buckets: make(map[string]*rateBucket),
		limit:   limit,
		window:  window,
	}
}

func (l *MemoryRateLimiter) Allow(key string) bool {
	l.mu.Lock()
	defer l.mu.Unlock()
	now := time.Now()
	b, ok := l.buckets[key]
	if !ok || now.After(b.resetAt) {
		l.buckets[key] = &rateBucket{count: 1, resetAt: now.Add(l.window)}
		return true
	}
	if b.count >= l.limit {
		return false
	}
	b.count++
	return true
}

// RedisRateLimiter uses INCR + EXPIRE windows in Redis.
type RedisRateLimiter struct {
	rdb    *redis.Client
	limit  int
	window time.Duration
	prefix string
}

// NewRedisRateLimiter constructs a Redis-backed limiter. Falls back behavior is caller responsibility when rdb is nil.
func NewRedisRateLimiter(rdb *redis.Client, prefix string, limit int, window time.Duration) *RedisRateLimiter {
	return &RedisRateLimiter{rdb: rdb, prefix: prefix, limit: limit, window: window}
}

func (l *RedisRateLimiter) Allow(key string) bool {
	if l == nil || l.rdb == nil {
		return true
	}
	ctx, cancel := context.WithTimeout(context.Background(), 200*time.Millisecond)
	defer cancel()
	full := fmt.Sprintf("rl:%s:%s", l.prefix, key)
	n, err := l.rdb.Incr(ctx, full).Result()
	if err != nil {
		return true // fail open on Redis blip
	}
	if n == 1 {
		_ = l.rdb.Expire(ctx, full, l.window).Err()
	}
	return n <= int64(l.limit)
}

// RateLimit returns middleware that limits by client IP + route group.
func RateLimit(limiter RateLimiter, group string) func(http.Handler) http.Handler {
	return func(next http.Handler) http.Handler {
		return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
			if limiter != nil {
				key := group + ":" + r.RemoteAddr
				if !limiter.Allow(key) {
					response.JSON(w, http.StatusTooManyRequests, map[string]string{"error": "rate limit exceeded"})
					return
				}
			}
			next.ServeHTTP(w, r)
		})
	}
}

// PreferRedisOrMemory returns Redis limiter when client is usable, else memory.
func PreferRedisOrMemory(rdb *redis.Client, prefix string, limit int, window time.Duration) RateLimiter {
	if rdb != nil {
		ctx, cancel := context.WithTimeout(context.Background(), 300*time.Millisecond)
		defer cancel()
		if err := rdb.Ping(ctx).Err(); err == nil {
			return NewRedisRateLimiter(rdb, prefix, limit, window)
		}
	}
	return NewMemoryRateLimiter(limit, window)
}
