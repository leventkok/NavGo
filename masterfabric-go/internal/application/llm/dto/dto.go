package dto

// ParseIntentRequest asks the LLM to extract a Places search intent.
type ParseIntentRequest struct {
	Prompt        string   `json:"prompt" validate:"required"`
	DefaultArea   string   `json:"default_area"`
	Tempo         string   `json:"tempo"`
	Interests     []string `json:"interests"`
	GroupType     string   `json:"group_type"`
	TransportMode string   `json:"transport_mode"`
}

// ParseIntentResponse is grounded-search intent (no place_id / lat / lng).
type ParseIntentResponse struct {
	Area          string `json:"area"`
	Query         string `json:"query"`
	DurationLabel string `json:"duration_label"`
	MaxStops      int    `json:"max_stops"`
	Model         string `json:"model,omitempty"`
}

// PlaceCatalogItem is a grounded place summary for stop picking (no IDs to invent).
type PlaceCatalogItem struct {
	DisplayName      string `json:"display_name"`
	FormattedAddress string `json:"formatted_address"`
}

// PickStopsRequest asks the LLM to choose indices from a grounded catalog.
type PickStopsRequest struct {
	Prompt   string             `json:"prompt" validate:"required"`
	Places   []PlaceCatalogItem `json:"places" validate:"required"`
	MaxStops int                `json:"max_stops"`
}

// PickStopsResponse contains zero-based indices into the request places list.
type PickStopsResponse struct {
	Indices []int  `json:"indices"`
	Model   string `json:"model,omitempty"`
}

// SuggestDayCardsRequest asks the LLM for location-aware day-plan theme cards.
type SuggestDayCardsRequest struct {
	Area          string   `json:"area" validate:"required"`
	Locale        string   `json:"locale"`
	Tempo         string   `json:"tempo"`
	Interests     []string `json:"interests"`
	GroupType     string   `json:"group_type"`
	TransportMode string   `json:"transport_mode"`
}

// DayCardSuggestion is one quick-start routelist card for the plan home screen.
type DayCardSuggestion struct {
	Title    string `json:"title"`
	Subtitle string `json:"subtitle"`
	Query    string `json:"query"`
	Icon     string `json:"icon"`
	Intent   string `json:"intent"`
	Area     string `json:"area,omitempty"`
}

// RouteCardTurn is one compact chat turn sent with a route-card request.
type RouteCardTurn struct {
	Role   string `json:"role"`
	Text   string `json:"text,omitempty"`
	Area   string `json:"area,omitempty"`
	Title  string `json:"title,omitempty"`
	Query  string `json:"query,omitempty"`
	Intent string `json:"intent,omitempty"`
}

// SuggestRouteCardRequest asks the LLM for a single routelist card from a chat prompt.
type SuggestRouteCardRequest struct {
	Prompt      string             `json:"prompt" validate:"required"`
	Locale      string             `json:"locale"`
	DefaultArea string             `json:"default_area"`
	Previous    *DayCardSuggestion `json:"previous"`
	Messages    []RouteCardTurn    `json:"messages"`
}

// SuggestRouteCardResponse is exactly one routelist card (no assistant prose).
type SuggestRouteCardResponse struct {
	Card  DayCardSuggestion `json:"card"`
	Area  string            `json:"area"`
	Model string            `json:"model,omitempty"`
}

// SuggestDayCardsResponse is a short list of location-realistic theme cards.
type SuggestDayCardsResponse struct {
	Cards []DayCardSuggestion `json:"cards"`
	Model string              `json:"model,omitempty"`
}
