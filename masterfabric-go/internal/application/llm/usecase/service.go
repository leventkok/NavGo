package usecase

import (
	"context"
	"encoding/json"
	"fmt"
	"strings"

	"github.com/leventkok/NavGo/internal/application/llm/dto"
	"github.com/leventkok/NavGo/internal/domain/llm"
	domainErr "github.com/leventkok/NavGo/internal/shared/errors"
)

// Service implements LLM planning helpers (intent + stop pick).
type Service struct {
	chat  llm.ChatClient
	model string
}

// NewService wires an OpenAI-compatible chat client.
func NewService(chat llm.ChatClient, model string) *Service {
	return &Service{chat: chat, model: model}
}

// ParseIntent extracts Places search fields from a free-form prompt.
func (s *Service) ParseIntent(ctx context.Context, req dto.ParseIntentRequest) (*dto.ParseIntentResponse, error) {
	if s.chat == nil {
		return nil, domainErr.New(domainErr.ErrUnavailable, "LLM is not configured", nil)
	}
	prompt := strings.TrimSpace(req.Prompt)
	if prompt == "" {
		return nil, domainErr.New(domainErr.ErrValidation, "prompt is required", nil)
	}

	var prefs strings.Builder
	if a := strings.TrimSpace(req.DefaultArea); a != "" {
		fmt.Fprintf(&prefs, "default_area=%s\n", a)
	}
	if t := strings.TrimSpace(req.Tempo); t != "" {
		fmt.Fprintf(&prefs, "tempo=%s\n", t)
	}
	if len(req.Interests) > 0 {
		fmt.Fprintf(&prefs, "interests=%s\n", strings.Join(req.Interests, ","))
	}
	if g := strings.TrimSpace(req.GroupType); g != "" {
		fmt.Fprintf(&prefs, "group_type=%s\n", g)
	}
	if m := strings.TrimSpace(req.TransportMode); m != "" {
		fmt.Fprintf(&prefs, "transport_mode=%s\n", m)
	}

	userContent := prompt
	if prefs.Len() > 0 {
		userContent = "Preferences:\n" + prefs.String() + "\nPrompt:\n" + prompt
	}

	content, err := s.chat.Chat(ctx, llm.ChatRequest{
		Temperature: 0.2,
		MaxTokens:   256,
		Messages: []llm.Message{
			{
				Role: "system",
				Content: "You are the NavGo travel assistant. The user may write in any language; follow their language for area/query/duration_label text. " +
					"Return ONLY valid JSON, no other text. Schema: {\"area\":\"string\",\"query\":\"string\",\"duration_label\":\"string\",\"max_stops\":number}. " +
					"Do NOT invent place_id, lat, or lng. area is a district/city (e.g. Kadıköy Istanbul). query is a search phrase in the user's language. max_stops is 3-6.",
			},
			{Role: "user", Content: userContent},
		},
	})
	if err != nil {
		return nil, err
	}

	raw, err := extractJSONObject(content)
	if err != nil {
		return nil, domainErr.New(domainErr.ErrInternal, "LLM did not return JSON", err)
	}

	var parsed struct {
		Area          string `json:"area"`
		Query         string `json:"query"`
		DurationLabel string `json:"duration_label"`
		MaxStops      int    `json:"max_stops"`
	}
	if err := json.Unmarshal(raw, &parsed); err != nil {
		return nil, domainErr.New(domainErr.ErrInternal, "failed to parse intent JSON", err)
	}

	area := strings.TrimSpace(parsed.Area)
	if area == "" {
		area = strings.TrimSpace(req.DefaultArea)
	}
	if area == "" {
		area = "İstanbul"
	}
	query := strings.TrimSpace(parsed.Query)
	if query == "" {
		query = area
	}
	duration := strings.TrimSpace(parsed.DurationLabel)
	if duration == "" {
		duration = "1 day"
	}
	maxStops := parsed.MaxStops
	if maxStops < 3 {
		maxStops = 3
	}
	if maxStops > 6 {
		maxStops = 6
	}

	return &dto.ParseIntentResponse{
		Area:          area,
		Query:         query,
		DurationLabel: duration,
		MaxStops:      maxStops,
		Model:         s.model,
	}, nil
}

// PickStops selects indices from a grounded place catalog.
func (s *Service) PickStops(ctx context.Context, req dto.PickStopsRequest) (*dto.PickStopsResponse, error) {
	if s.chat == nil {
		return nil, domainErr.New(domainErr.ErrUnavailable, "LLM is not configured", nil)
	}
	prompt := strings.TrimSpace(req.Prompt)
	if prompt == "" {
		return nil, domainErr.New(domainErr.ErrValidation, "prompt is required", nil)
	}
	if len(req.Places) < 2 {
		return nil, domainErr.New(domainErr.ErrValidation, "at least 2 places required", nil)
	}

	maxStops := req.MaxStops
	if maxStops < 2 {
		maxStops = 2
	}
	if maxStops > len(req.Places) {
		maxStops = len(req.Places)
	}
	if maxStops > 6 {
		maxStops = 6
	}

	var catalog strings.Builder
	for i, p := range req.Places {
		name := strings.TrimSpace(p.DisplayName)
		addr := strings.TrimSpace(p.FormattedAddress)
		fmt.Fprintf(&catalog, "%d. %s — %s\n", i, name, addr)
	}

	content, err := s.chat.Chat(ctx, llm.ChatRequest{
		Temperature: 0.2,
		MaxTokens:   128,
		Messages: []llm.Message{
			{
				Role: "system",
				Content: "From the numbered place list, pick stop indices for a day plan. The user prompt may be in any language; use it only to choose relevant places. " +
					"Return ONLY JSON: {\"indices\":[number,...]}. Do not use numbers absent from the list. Do not invent place_id.",
			},
			{
				Role: "user",
				Content: fmt.Sprintf(
					"Prompt: %s\nMax: %d\nPlaces:\n%s",
					prompt,
					maxStops,
					catalog.String(),
				),
			},
		},
	})
	if err != nil {
		return nil, err
	}

	indices := fallbackIndices(len(req.Places), maxStops)
	raw, err := extractJSONObject(content)
	if err == nil {
		var parsed struct {
			Indices []int `json:"indices"`
		}
		if json.Unmarshal(raw, &parsed) == nil {
			seen := map[int]struct{}{}
			out := make([]int, 0, maxStops)
			for _, n := range parsed.Indices {
				if n < 0 || n >= len(req.Places) {
					continue
				}
				if _, ok := seen[n]; ok {
					continue
				}
				seen[n] = struct{}{}
				out = append(out, n)
				if len(out) >= maxStops {
					break
				}
			}
			if len(out) >= 2 {
				indices = out
			}
		}
	}

	return &dto.PickStopsResponse{Indices: indices, Model: s.model}, nil
}

var allowedDayCardIcons = map[string]struct{}{
	"historic":   {},
	"waterfront": {},
	"coffee":     {},
	"museum":     {},
	"parks":      {},
	"bazaar":     {},
	"viewpoints": {},
	"modern":     {},
}

// SuggestDayCards returns location-realistic day-plan theme cards via LLM.
func (s *Service) SuggestDayCards(ctx context.Context, req dto.SuggestDayCardsRequest) (*dto.SuggestDayCardsResponse, error) {
	if s.chat == nil {
		return nil, domainErr.New(domainErr.ErrUnavailable, "LLM is not configured", nil)
	}
	area := strings.TrimSpace(req.Area)
	if area == "" {
		return nil, domainErr.New(domainErr.ErrValidation, "area is required", nil)
	}

	locale := strings.TrimSpace(req.Locale)
	if locale == "" {
		locale = "tr"
	}

	var prefs strings.Builder
	fmt.Fprintf(&prefs, "area=%s\nlocale=%s\n", area, locale)
	if t := strings.TrimSpace(req.Tempo); t != "" {
		fmt.Fprintf(&prefs, "tempo=%s\n", t)
	}
	if len(req.Interests) > 0 {
		fmt.Fprintf(&prefs, "interests=%s\n", strings.Join(req.Interests, ","))
	}
	if g := strings.TrimSpace(req.GroupType); g != "" {
		fmt.Fprintf(&prefs, "group_type=%s\n", g)
	}
	if m := strings.TrimSpace(req.TransportMode); m != "" {
		fmt.Fprintf(&prefs, "transport_mode=%s\n", m)
	}

	content, err := s.chat.Chat(ctx, llm.ChatRequest{
		Temperature: 0.4,
		MaxTokens:   512,
		Messages: []llm.Message{
			{
				Role: "system",
				Content: "You are the NavGo travel assistant. Return ONLY valid JSON, no other text. " +
					"Schema: {\"cards\":[{\"title\":\"string\",\"subtitle\":\"string\",\"query\":\"string\",\"icon\":\"string\"}]}. " +
					"Exactly 4 cards. title and subtitle must be in the locale language (tr/en/ru). " +
					"query is a short Places search phrase for that theme in the locale language. " +
					"icon must be one of: historic, waterfront, coffee, museum, parks, bazaar, viewpoints, modern. " +
					"Cards MUST be realistic for the given location. " +
					"NEVER suggest waterfront/harbor/coast/beach/marina themes for inland cities (e.g. Ankara, Konya, Nevşehir). " +
					"Only use icon=waterfront when the place actually has a meaningful coastline, harbor, lake shore promenade, or waterfront district. " +
					"Prefer variety: history, culture, food/coffee, parks/nature, viewpoints, modern streets when fitting.",
			},
			{
				Role: "user",
				Content: fmt.Sprintf(
					"Konum: %s\nPreferences:\n%s\nBu konumda bir günlük gezi için 4 öneri kartı öner. "+
						"Sahil/liman bu konumda yoksa waterfront kullanma ve liman/sahil kartı yazma.",
					area,
					prefs.String(),
				),
			},
		},
	})
	if err != nil {
		return nil, err
	}

	raw, err := extractJSONObject(content)
	if err != nil {
		return nil, domainErr.New(domainErr.ErrInternal, "LLM did not return JSON", err)
	}

	var parsed struct {
		Cards []struct {
			Title    string `json:"title"`
			Subtitle string `json:"subtitle"`
			Query    string `json:"query"`
			Icon     string `json:"icon"`
		} `json:"cards"`
	}
	if err := json.Unmarshal(raw, &parsed); err != nil {
		return nil, domainErr.New(domainErr.ErrInternal, "failed to parse day cards JSON", err)
	}

	cards := make([]dto.DayCardSuggestion, 0, 4)
	for _, c := range parsed.Cards {
		title := strings.TrimSpace(c.Title)
		subtitle := strings.TrimSpace(c.Subtitle)
		query := strings.TrimSpace(c.Query)
		icon := strings.ToLower(strings.TrimSpace(c.Icon))
		if title == "" || query == "" {
			continue
		}
		if _, ok := allowedDayCardIcons[icon]; !ok {
			icon = "modern"
		}
		if subtitle == "" {
			subtitle = query
		}
		cards = append(cards, dto.DayCardSuggestion{
			Title:    title,
			Subtitle: subtitle,
			Query:    query,
			Icon:     icon,
		})
		if len(cards) >= 4 {
			break
		}
	}
	if len(cards) < 2 {
		return nil, domainErr.New(domainErr.ErrInternal, "LLM returned too few day cards", nil)
	}

	return &dto.SuggestDayCardsResponse{Cards: cards, Model: s.model}, nil
}

func fallbackIndices(n, maxStops int) []int {
	if maxStops > n {
		maxStops = n
	}
	out := make([]int, 0, maxStops)
	for i := 0; i < maxStops; i++ {
		out = append(out, i)
	}
	return out
}

func extractJSONObject(text string) ([]byte, error) {
	trimmed := strings.TrimSpace(text)
	if strings.HasPrefix(trimmed, "```") {
		trimmed = strings.TrimPrefix(trimmed, "```json")
		trimmed = strings.TrimPrefix(trimmed, "```JSON")
		trimmed = strings.TrimPrefix(trimmed, "```")
		if idx := strings.LastIndex(trimmed, "```"); idx >= 0 {
			trimmed = trimmed[:idx]
		}
		trimmed = strings.TrimSpace(trimmed)
	}
	start := strings.Index(trimmed, "{")
	end := strings.LastIndex(trimmed, "}")
	if start < 0 || end < 0 || end <= start {
		return nil, fmt.Errorf("no JSON object in LLM output")
	}
	return []byte(trimmed[start : end+1]), nil
}
