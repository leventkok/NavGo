package middleware

import (
	"context"
	"net/http"
	"time"

	"github.com/leventkok/NavGo/internal/shared/response"
	sharedsec "github.com/leventkok/NavGo/internal/shared/security"
	"github.com/redis/go-redis/v9"
)

const redisLLMKillKey = "navgo:llm_kill_switch"

// LLMKillSwitch blocks LLM routes when env or Redis flag is on.
func LLMKillSwitch(rdb *redis.Client) func(http.Handler) http.Handler {
	return func(next http.Handler) http.Handler {
		return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
			if sharedsec.LLMKillSwitchEnv() || redisKillEnabled(rdb) {
				response.JSON(w, http.StatusServiceUnavailable, map[string]string{
					"error": "llm disabled by kill switch",
					"code":  "LLM_KILL_SWITCH",
				})
				return
			}
			next.ServeHTTP(w, r)
		})
	}
}

func redisKillEnabled(rdb *redis.Client) bool {
	if rdb == nil {
		return false
	}
	ctx, cancel := context.WithTimeout(context.Background(), 200*time.Millisecond)
	defer cancel()
	v, err := rdb.Get(ctx, redisLLMKillKey).Result()
	if err != nil {
		return false
	}
	return v == "1" || v == "true" || v == "on"
}

// SetLLMKillSwitchRedis is a helper for ops (optional admin use).
func SetLLMKillSwitchRedis(ctx context.Context, rdb *redis.Client, on bool) error {
	if rdb == nil {
		return nil
	}
	if on {
		return rdb.Set(ctx, redisLLMKillKey, "1", 0).Err()
	}
	return rdb.Del(ctx, redisLLMKillKey).Err()
}
