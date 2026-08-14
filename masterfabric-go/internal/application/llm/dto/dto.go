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
