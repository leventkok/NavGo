package llm

import (
	"encoding/json"
	"net/http"

	"github.com/google/uuid"
	"github.com/leventkok/NavGo/internal/application/llm/dto"
	"github.com/leventkok/NavGo/internal/application/llm/usecase"
	"github.com/leventkok/NavGo/internal/shared/middleware"
	"github.com/leventkok/NavGo/internal/shared/response"
	sharedsec "github.com/leventkok/NavGo/internal/shared/security"
	"github.com/leventkok/NavGo/internal/shared/validator"
)

// Handler exposes LLM planning HTTP endpoints.
type Handler struct {
	svc   *usecase.Service
	audit *sharedsec.AuditWriter
}

// NewHandler constructs an LLM HTTP handler.
func NewHandler(svc *usecase.Service, audit *sharedsec.AuditWriter) *Handler {
	return &Handler{svc: svc, audit: audit}
}

func (h *Handler) auditLLM(r *http.Request, action string) {
	if h.audit == nil {
		return
	}
	orgID, _ := middleware.OrgIDFromContext(r.Context())
	if orgID == uuid.Nil {
		return
	}
	var uid *uuid.UUID
	if userID, ok := middleware.UserIDFromContext(r.Context()); ok && userID != uuid.Nil {
		uid = &userID
	}
	meta, _ := json.Marshal(map[string]string{"path": r.URL.Path})
	h.audit.Write(r.Context(), action, "llm", r.URL.Path, orgID, uid, meta)
}

// ParseIntent handles POST /api/v1/llm/parse-intent.
func (h *Handler) ParseIntent(w http.ResponseWriter, r *http.Request) {
	var req dto.ParseIntentRequest
	if err := validator.DecodeAndValidate(r, &req); err != nil {
		response.JSON(w, http.StatusBadRequest, map[string]string{"error": err.Error()})
		return
	}
	resp, err := h.svc.ParseIntent(r.Context(), req)
	if err != nil {
		response.Error(w, err)
		return
	}
	h.auditLLM(r, "llm.parse_intent")
	response.JSON(w, http.StatusOK, resp)
}

// PickStops handles POST /api/v1/llm/pick-stops.
func (h *Handler) PickStops(w http.ResponseWriter, r *http.Request) {
	var req dto.PickStopsRequest
	if err := validator.DecodeAndValidate(r, &req); err != nil {
		response.JSON(w, http.StatusBadRequest, map[string]string{"error": err.Error()})
		return
	}
	resp, err := h.svc.PickStops(r.Context(), req)
	if err != nil {
		response.Error(w, err)
		return
	}
	h.auditLLM(r, "llm.pick_stops")
	response.JSON(w, http.StatusOK, resp)
}

// SuggestDayCards handles POST /api/v1/llm/suggest-day-cards.
func (h *Handler) SuggestDayCards(w http.ResponseWriter, r *http.Request) {
	var req dto.SuggestDayCardsRequest
	if err := validator.DecodeAndValidate(r, &req); err != nil {
		response.JSON(w, http.StatusBadRequest, map[string]string{"error": err.Error()})
		return
	}
	resp, err := h.svc.SuggestDayCards(r.Context(), req)
	if err != nil {
		response.Error(w, err)
		return
	}
	h.auditLLM(r, "llm.suggest_day_cards")
	response.JSON(w, http.StatusOK, resp)
}
