package usecase

import (
	"context"
	"encoding/json"
	"fmt"
	"strings"
	"time"

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

var allowedDayCardIntents = map[string]struct{}{
	"first_day": {},
	"slow":      {},
	"culture":   {},
	"food":      {},
	"shop":      {},
	"photo":     {},
	"family":    {},
	"evening":   {},
}

func iconForIntent(intent string) string {
	switch intent {
	case "first_day":
		return "modern"
	case "slow":
		return "coffee"
	case "culture":
		return "museum"
	case "food", "shop":
		return "bazaar"
	case "photo":
		return "viewpoints"
	case "family":
		return "parks"
	case "evening":
		return "modern"
	default:
		return "modern"
	}
}

func intentForIcon(icon string) string {
	switch icon {
	case "historic", "museum":
		return "culture"
	case "coffee":
		return "slow"
	case "parks":
		return "family"
	case "bazaar":
		return "food"
	case "viewpoints":
		return "photo"
	case "waterfront":
		return "slow"
	default:
		return "first_day"
	}
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
		Temperature: 0.5,
		MaxTokens:   640,
		Messages: []llm.Message{
			{
				Role: "system",
				Content: "You are the NavGo travel assistant. Return ONLY valid JSON, no other text. " +
					"Schema: {\"cards\":[{\"title\":\"string\",\"subtitle\":\"string\",\"query\":\"string\",\"icon\":\"string\",\"intent\":\"string\"}]}. " +
					"Exactly 4 cards. Write like Spotify playlist recommendations: mood-first title (question or hook) plus a short promise as subtitle. " +
					"title and subtitle must be in the locale language (tr/en/ru). Do not use generic category labels like Historic center / Waterfront / Museum. " +
					"intent must be one of: first_day, slow, culture, food, shop, photo, family, evening. Use four different intents. " +
					"query is a short Places search phrase for that mood in the locale language (no invented place_id). " +
					"icon must be one of: historic, waterfront, coffee, museum, parks, bazaar, viewpoints, modern. " +
					"Cards MUST be realistic for the given location. " +
					"NEVER suggest waterfront/harbor/coast/beach/marina themes for inland cities (e.g. Ankara, Konya, Nevşehir, Sivas). " +
					"Only use icon=waterfront when the place actually has a meaningful coastline, harbor, lake shore promenade, or waterfront district. " +
					"Prefer a mix: first-day highlights, slow/coffee, culture, food/shop, photo, family, or evening when they fit.",
			},
			{
				Role: "user",
				Content: fmt.Sprintf(
					"Konum: %s\nPreferences:\n%s\nBu konumda bir günlük gezi için 4 routelist kartı öner. "+
						"Her kart bir niyet/playlist olsun (ör. şehre yeni misin, yerel tat, ağırdan al). "+
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
			Intent   string `json:"intent"`
		} `json:"cards"`
	}
	if err := json.Unmarshal(raw, &parsed); err != nil {
		return nil, domainErr.New(domainErr.ErrInternal, "failed to parse day cards JSON", err)
	}

	cards := make([]dto.DayCardSuggestion, 0, 4)
	seenIntent := map[string]struct{}{}
	for _, c := range parsed.Cards {
		title := strings.TrimSpace(c.Title)
		subtitle := strings.TrimSpace(c.Subtitle)
		query := strings.TrimSpace(c.Query)
		icon := strings.ToLower(strings.TrimSpace(c.Icon))
		intent := strings.ToLower(strings.TrimSpace(c.Intent))
		if title == "" || query == "" {
			continue
		}
		if _, ok := allowedDayCardIntents[intent]; !ok {
			if _, ok := allowedDayCardIcons[icon]; ok {
				intent = intentForIcon(icon)
			} else {
				intent = "first_day"
			}
		}
		if _, dup := seenIntent[intent]; dup {
			continue
		}
		if _, ok := allowedDayCardIcons[icon]; !ok {
			icon = iconForIntent(intent)
		}
		if subtitle == "" {
			subtitle = query
		}
		seenIntent[intent] = struct{}{}
		cards = append(cards, dto.DayCardSuggestion{
			Title:    title,
			Subtitle: subtitle,
			Query:    query,
			Icon:     icon,
			Intent:   intent,
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

// SuggestRouteCard returns exactly one routelist card for a chat prompt (or an edit of a previous card).
func (s *Service) SuggestRouteCard(ctx context.Context, req dto.SuggestRouteCardRequest) (*dto.SuggestRouteCardResponse, error) {
	if s.chat == nil {
		return nil, domainErr.New(domainErr.ErrUnavailable, "LLM is not configured", nil)
	}
	prompt := strings.TrimSpace(req.Prompt)
	if prompt == "" {
		return nil, domainErr.New(domainErr.ErrValidation, "prompt is required", nil)
	}

	locale := strings.TrimSpace(req.Locale)
	if locale == "" {
		locale = "tr"
	}
	session := conversationArea(req)
	named := cityFromPrompt(prompt)
	cityChanged := named != "" && session != "" && !sameCity(named, session)
	if named != "" {
		session = named
	}

	var user strings.Builder
	fmt.Fprintf(&user, "locale=%s\n", locale)
	if session != "" {
		fmt.Fprintf(&user, "session_area=%s\n", session)
	} else if a := strings.TrimSpace(req.DefaultArea); a != "" {
		fmt.Fprintf(&user, "default_area=%s\n", a)
	}
	if cityChanged {
		fmt.Fprintf(&user, "user_changed_city=true\n")
	}
	if req.Previous != nil && !cityChanged {
		fmt.Fprintf(&user, "previous_title=%s\n", strings.TrimSpace(req.Previous.Title))
		fmt.Fprintf(&user, "previous_subtitle=%s\n", strings.TrimSpace(req.Previous.Subtitle))
		fmt.Fprintf(&user, "previous_query=%s\n", strings.TrimSpace(req.Previous.Query))
		fmt.Fprintf(&user, "previous_intent=%s\n", strings.TrimSpace(req.Previous.Intent))
		fmt.Fprintf(&user, "previous_icon=%s\n", strings.TrimSpace(req.Previous.Icon))
		if a := strings.TrimSpace(req.Previous.Area); a != "" {
			fmt.Fprintf(&user, "previous_area=%s\n", a)
		}
		fmt.Fprintf(&user, "edit=%s\n", prompt)
	} else {
		fmt.Fprintf(&user, "prompt=%s\n", prompt)
	}

	messages := []llm.Message{{
		Role: "system",
		Content: "You are the NavGo travel assistant. Return ONLY one JSON object, no other text, no markdown. " +
			"Schema: {\"title\":\"string\",\"subtitle\":\"string\",\"query\":\"string\",\"icon\":\"string\",\"intent\":\"string\",\"area\":\"string\"}. " +
			"This is a single routelist card (Spotify-playlist mood): title is a hook, subtitle is a short promise, query is a Places search phrase. " +
			"title and subtitle in the locale language. Do not write assistant chatter, stop lists, or extra keys. " +
			"intent must be one of: first_day, slow, culture, food, shop, photo, family, evening. " +
			"icon must be one of: historic, waterfront, coffee, museum, parks, bazaar, viewpoints, modern. " +
			"session_area is the city locked for this chat. If session_area is set, ignore GPS/default_area and keep that city unless the user names a different city in this turn. " +
			"If user_changed_city=true, ignore previous_* and emit a NEW card for session_area (new title, new query). " +
			"area must match session_area when it is set and the user did not change city. " +
			"NEVER suggest waterfront/harbor/coast/beach/marina for inland cities. " +
			"If previous_* fields are present, revise that card using edit=; keep the same city unless the user changes it. " +
			"Earlier user/assistant turns are the conversation — stay consistent with them.",
	}}
	for _, turn := range historyTurns(req.Messages, prompt) {
		role, content := formatRouteCardTurn(turn)
		if content == "" {
			continue
		}
		messages = append(messages, llm.Message{Role: role, Content: content})
	}
	messages = append(messages, llm.Message{Role: "user", Content: user.String()})

	llmCtx, cancel := context.WithTimeout(context.WithoutCancel(ctx), 35*time.Second)
	defer cancel()
	content, err := s.chat.Chat(llmCtx, llm.ChatRequest{
		Temperature: 0.4,
		MaxTokens:   320,
		Messages:    messages,
	})
	if err != nil {
		fb := fallbackRouteCard(req)
		return &fb, nil
	}

	raw, err := extractJSONObject(content)
	if err != nil {
		fb := fallbackRouteCard(req)
		return &fb, nil
	}

	var parsed struct {
		Title    string `json:"title"`
		Subtitle string `json:"subtitle"`
		Query    string `json:"query"`
		Icon     string `json:"icon"`
		Intent   string `json:"intent"`
		Area     string `json:"area"`
		Card     *struct {
			Title    string `json:"title"`
			Subtitle string `json:"subtitle"`
			Query    string `json:"query"`
			Icon     string `json:"icon"`
			Intent   string `json:"intent"`
			Area     string `json:"area"`
		} `json:"card"`
	}
	if err := json.Unmarshal(raw, &parsed); err != nil {
		fb := fallbackRouteCard(req)
		return &fb, nil
	}
	title, subtitle, query, icon, intent, area := parsed.Title, parsed.Subtitle, parsed.Query, parsed.Icon, parsed.Intent, parsed.Area
	if parsed.Card != nil {
		title, subtitle, query, icon, intent, area = parsed.Card.Title, parsed.Card.Subtitle, parsed.Card.Query, parsed.Card.Icon, parsed.Card.Intent, parsed.Card.Area
	}

	card, ok := normalizeDayCard(title, subtitle, query, icon, intent)
	if !ok {
		fb := fallbackRouteCard(req)
		return &fb, nil
	}

	area = lockArea(session, strings.TrimSpace(area), prompt)
	if named != "" {
		area = named
	}
	if area == "" {
		area = strings.TrimSpace(req.DefaultArea)
	}
	card.Area = area

	return &dto.SuggestRouteCardResponse{Card: card, Area: area, Model: s.model}, nil
}

func conversationArea(req dto.SuggestRouteCardRequest) string {
	if req.Previous != nil {
		if a := strings.TrimSpace(req.Previous.Area); a != "" {
			return a
		}
	}
	for i := len(req.Messages) - 1; i >= 0; i-- {
		if a := strings.TrimSpace(req.Messages[i].Area); a != "" {
			return a
		}
	}
	return ""
}

func lockArea(session, llmArea, prompt string) string {
	if named := cityFromPrompt(prompt); named != "" {
		return named
	}
	session = strings.TrimSpace(session)
	llmArea = strings.TrimSpace(llmArea)
	if session == "" {
		return llmArea
	}
	if llmArea == "" || sameCity(llmArea, session) {
		return session
	}
	if containsFold(prompt, llmArea) {
		return llmArea
	}
	return session
}

func foldTR(s string) string {
	s = strings.ToLower(strings.TrimSpace(s))
	s = strings.ReplaceAll(s, "\u0307", "")
	replacer := strings.NewReplacer("ı", "i", "ş", "s", "ğ", "g", "ü", "u", "ö", "o", "ç", "c")
	return replacer.Replace(s)
}

func sameCity(a, b string) bool {
	a, b = foldTR(a), foldTR(b)
	return a != "" && a == b
}

func containsFold(haystack, needle string) bool {
	h := foldTR(haystack)
	n := foldTR(needle)
	if n == "" {
		return false
	}
	return strings.Contains(h, n)
}

type cityName struct {
	canonical string
	aliases   []string
}

var knownCities = []cityName{
	{canonical: "İstanbul", aliases: []string{"istanbul"}},
	{canonical: "Ankara", aliases: []string{"ankara"}},
	{canonical: "İzmir", aliases: []string{"izmir"}},
	{canonical: "Antalya", aliases: []string{"antalya"}},
	{canonical: "Bursa", aliases: []string{"bursa"}},
	{canonical: "Sivas", aliases: []string{"sivas"}},
	{canonical: "Muğla", aliases: []string{"mugla"}},
	{canonical: "Bodrum", aliases: []string{"bodrum"}},
	{canonical: "Fethiye", aliases: []string{"fethiye"}},
	{canonical: "Marmaris", aliases: []string{"marmaris"}},
	{canonical: "Alanya", aliases: []string{"alanya"}},
	{canonical: "Kaş", aliases: []string{"kas"}},
	{canonical: "Kapadokya", aliases: []string{"kapadokya", "cappadocia"}},
	{canonical: "Nevşehir", aliases: []string{"nevsehir"}},
	{canonical: "Trabzon", aliases: []string{"trabzon"}},
	{canonical: "Gaziantep", aliases: []string{"gaziantep", "antep"}},
	{canonical: "Konya", aliases: []string{"konya"}},
	{canonical: "Adana", aliases: []string{"adana"}},
	{canonical: "Mersin", aliases: []string{"mersin"}},
	{canonical: "Eskişehir", aliases: []string{"eskisehir"}},
	{canonical: "Çanakkale", aliases: []string{"canakkale"}},
	{canonical: "Kadıköy", aliases: []string{"kadikoy"}},
	{canonical: "Çeşme", aliases: []string{"cesme"}},
}

func cityFromPrompt(prompt string) string {
	folded := foldTR(prompt)
	if folded == "" {
		return ""
	}
	bestIdx := -1
	bestLen := 0
	best := ""
	for _, city := range knownCities {
		for _, alias := range city.aliases {
			idx := indexAlias(folded, alias)
			if idx < 0 {
				continue
			}
			if bestIdx < 0 || idx < bestIdx || (idx == bestIdx && len(alias) > bestLen) {
				bestIdx = idx
				bestLen = len(alias)
				best = city.canonical
			}
		}
	}
	return best
}

func indexAlias(folded, alias string) int {
	if alias == "" {
		return -1
	}
	start := 0
	for start <= len(folded)-len(alias) {
		idx := strings.Index(folded[start:], alias)
		if idx < 0 {
			return -1
		}
		idx += start
		if idx > 0 {
			r := rune(folded[idx-1])
			if r >= 'a' && r <= 'z' {
				start = idx + 1
				continue
			}
		}
		return idx
	}
	return -1
}

const maxRouteCardTurns = 16

func compactTurns(turns []dto.RouteCardTurn) []dto.RouteCardTurn {
	if len(turns) <= maxRouteCardTurns {
		return turns
	}
	firstUser := -1
	for i, turn := range turns {
		if strings.EqualFold(strings.TrimSpace(turn.Role), "user") && strings.TrimSpace(turn.Text) != "" {
			firstUser = i
			break
		}
	}
	tailStart := len(turns) - (maxRouteCardTurns - 1)
	if firstUser >= 0 && firstUser < tailStart {
		out := make([]dto.RouteCardTurn, 0, maxRouteCardTurns)
		out = append(out, turns[firstUser])
		out = append(out, turns[tailStart:]...)
		return out
	}
	return turns[len(turns)-maxRouteCardTurns:]
}

func historyTurns(turns []dto.RouteCardTurn, prompt string) []dto.RouteCardTurn {
	turns = compactTurns(turns)
	if n := len(turns); n > 0 {
		last := turns[n-1]
		if strings.EqualFold(strings.TrimSpace(last.Role), "user") && strings.TrimSpace(last.Text) == prompt {
			return turns[:n-1]
		}
	}
	return turns
}

func formatRouteCardTurn(turn dto.RouteCardTurn) (role, content string) {
	role = strings.ToLower(strings.TrimSpace(turn.Role))
	if role != "assistant" {
		return "user", strings.TrimSpace(turn.Text)
	}
	var b strings.Builder
	if a := strings.TrimSpace(turn.Area); a != "" {
		fmt.Fprintf(&b, "area=%s", a)
	}
	if t := strings.TrimSpace(turn.Title); t != "" {
		if b.Len() > 0 {
			b.WriteString(" | ")
		}
		fmt.Fprintf(&b, "title=%s", t)
	}
	if i := strings.TrimSpace(turn.Intent); i != "" {
		if b.Len() > 0 {
			b.WriteString(" | ")
		}
		fmt.Fprintf(&b, "intent=%s", i)
	}
	if q := strings.TrimSpace(turn.Query); q != "" {
		if b.Len() > 0 {
			b.WriteString(" | ")
		}
		fmt.Fprintf(&b, "query=%s", q)
	}
	if b.Len() == 0 {
		return "assistant", strings.TrimSpace(turn.Text)
	}
	return "assistant", b.String()
}

func fallbackRouteCard(req dto.SuggestRouteCardRequest) dto.SuggestRouteCardResponse {
	prompt := strings.TrimSpace(req.Prompt)
	named := cityFromPrompt(prompt)
	area := named
	if area == "" {
		area = conversationArea(req)
	}
	if area == "" {
		area = strings.TrimSpace(req.DefaultArea)
	}
	cityChanged := named != "" && req.Previous != nil && !sameCity(named, req.Previous.Area)
	query := prompt
	intent := "first_day"
	previous := req.Previous
	if cityChanged {
		previous = nil
	}
	if previous != nil {
		if q := strings.TrimSpace(previous.Query); q != "" {
			query = strings.TrimSpace(q + " " + prompt)
		}
		if i := strings.TrimSpace(previous.Intent); i != "" {
			intent = i
		}
	}
	lower := foldTR(prompt + " " + query)
	switch {
	case strings.Contains(lower, "kahve"), strings.Contains(lower, "coffee"), strings.Contains(lower, "yavas"), strings.Contains(lower, "slow"):
		intent = "slow"
	case strings.Contains(lower, "muze"), strings.Contains(lower, "museum"), strings.Contains(lower, "kultur"), strings.Contains(lower, "tarih"):
		intent = "culture"
	case strings.Contains(lower, "yemek"), strings.Contains(lower, "food"), strings.Contains(lower, "lezzet"), strings.Contains(lower, "pazar"):
		intent = "food"
	case strings.Contains(lower, "aile"), strings.Contains(lower, "family"):
		intent = "family"
	case strings.Contains(lower, "aksam"), strings.Contains(lower, "evening"):
		intent = "evening"
	}
	if query == "" {
		query = area
	}
	if query == "" {
		query = "gezilecek yerler"
	}
	runes := []rune(query)
	if len(runes) > 80 {
		query = string(runes[:80])
	}
	title, subtitle := fallbackCardCopy(req.Locale, prompt, previous)
	card, _ := normalizeDayCard(title, subtitle, query, iconForIntent(intent), intent)
	card.Area = area
	return dto.SuggestRouteCardResponse{Card: card, Area: area, Model: "fallback"}
}

func fallbackCardCopy(locale, prompt string, previous *dto.DayCardSuggestion) (title, subtitle string) {
	prompt = strings.TrimSpace(prompt)
	runes := []rune(prompt)
	if len(runes) > 72 {
		prompt = string(runes[:72])
	}
	if previous != nil && strings.TrimSpace(previous.Title) != "" {
		title = strings.TrimSpace(previous.Title)
		if prompt != "" {
			return title, prompt
		}
		return title, strings.TrimSpace(previous.Subtitle)
	}
	switch strings.ToLower(strings.TrimSpace(locale)) {
	case "en":
		return "Your kind of day", prompt
	case "ru":
		return "Твой день", prompt
	default:
		return "Anlattığın gün", prompt
	}
}

func normalizeDayCard(title, subtitle, query, icon, intent string) (dto.DayCardSuggestion, bool) {
	title = strings.TrimSpace(title)
	subtitle = strings.TrimSpace(subtitle)
	query = strings.TrimSpace(query)
	icon = strings.ToLower(strings.TrimSpace(icon))
	intent = strings.ToLower(strings.TrimSpace(intent))
	if title == "" || query == "" {
		return dto.DayCardSuggestion{}, false
	}
	if _, ok := allowedDayCardIntents[intent]; !ok {
		if _, ok := allowedDayCardIcons[icon]; ok {
			intent = intentForIcon(icon)
		} else {
			intent = "first_day"
		}
	}
	if _, ok := allowedDayCardIcons[icon]; !ok {
		icon = iconForIntent(intent)
	}
	if subtitle == "" {
		subtitle = query
	}
	return dto.DayCardSuggestion{
		Title:    title,
		Subtitle: subtitle,
		Query:    query,
		Icon:     icon,
		Intent:   intent,
	}, true
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
