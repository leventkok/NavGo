package llm

import (
	"net/http"

	"github.com/leventkok/NavGo/internal/application/llm/dto"
	"github.com/leventkok/NavGo/internal/application/llm/usecase"
	"github.com/leventkok/NavGo/internal/shared/response"
	"github.com/leventkok/NavGo/internal/shared/validator"
)

// Handler exposes LLM planning HTTP endpoints.
type Handler struct {
	svc *usecase.Service
}

// NewHandler constructs an LLM HTTP handler.
func NewHandler(svc *usecase.Service) *Handler {
	return &Handler{svc: svc}
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
	response.JSON(w, http.StatusOK, resp)
}
