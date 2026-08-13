package llm

import "context"

// ChatClient talks to an OpenAI-compatible chat completions API.
type ChatClient interface {
	Chat(ctx context.Context, req ChatRequest) (string, error)
}

// ChatRequest is a minimal chat completion payload.
type ChatRequest struct {
	Messages    []Message
	Temperature float64
	MaxTokens   int
}

// Message is a single chat turn.
type Message struct {
	Role    string // system | user | assistant
	Content string
}
