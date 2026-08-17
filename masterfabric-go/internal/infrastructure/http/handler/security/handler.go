package security

import (
	"encoding/json"
	"net/http"
	"strconv"

	"github.com/google/uuid"
	"github.com/leventkok/NavGo/internal/application/security/dto"
	"github.com/leventkok/NavGo/internal/application/security/usecase"
	"github.com/leventkok/NavGo/internal/shared/middleware"
	"github.com/leventkok/NavGo/internal/shared/response"
	sharedsec "github.com/leventkok/NavGo/internal/shared/security"
	"github.com/leventkok/NavGo/internal/shared/validator"
)

// Handler exposes handshake, bind, channel, magic-link, and scan endpoints.
type Handler struct {
	handshakeUC   *usecase.HandshakeUseCase
	bindUC        *usecase.BindUseCase
	ingestUC      *usecase.IngestScanUseCase
	listUC        *usecase.ListScansUseCase
	magicReqUC    *usecase.RequestMagicLinkUseCase
	magicVerifyUC *usecase.VerifyMagicLinkUseCase
	audit         *sharedsec.AuditWriter
}

// NewHandler constructs the security handler.
func NewHandler(
	handshakeUC *usecase.HandshakeUseCase,
	bindUC *usecase.BindUseCase,
	ingestUC *usecase.IngestScanUseCase,
	listUC *usecase.ListScansUseCase,
	magicReqUC *usecase.RequestMagicLinkUseCase,
	magicVerifyUC *usecase.VerifyMagicLinkUseCase,
	audit *sharedsec.AuditWriter,
) *Handler {
	return &Handler{
		handshakeUC:   handshakeUC,
		bindUC:        bindUC,
		ingestUC:      ingestUC,
		listUC:        listUC,
		magicReqUC:    magicReqUC,
		magicVerifyUC: magicVerifyUC,
		audit:         audit,
	}
}

func (h *Handler) Handshake(w http.ResponseWriter, r *http.Request) {
	var req dto.HandshakeRequest
	_ = validator.DecodeAndValidate(r, &req)
	resp, err := h.handshakeUC.Execute(r.Context(), req)
	if err != nil {
		response.Error(w, err)
		return
	}
	meta, _ := json.Marshal(map[string]string{"handshake_id": resp.HandshakeID, "channel_id": resp.ChannelID})
	if h.audit != nil {
		// org unknown at handshake — skip typed org audit; HTTP middleware may also skip
		_ = meta
	}
	response.JSON(w, http.StatusOK, resp)
}

func (h *Handler) Bind(w http.ResponseWriter, r *http.Request) {
	userID, ok := middleware.UserIDFromContext(r.Context())
	if !ok {
		response.JSON(w, http.StatusUnauthorized, map[string]string{"error": "not authenticated"})
		return
	}
	var req dto.BindRequest
	if err := validator.DecodeAndValidate(r, &req); err != nil {
		response.JSON(w, http.StatusBadRequest, map[string]string{"error": err.Error()})
		return
	}
	email, _ := r.Context().Value(middleware.ContextKeyEmail).(string)
	orgID, _ := middleware.OrgIDFromContext(r.Context())
	resp, err := h.bindUC.Execute(r.Context(), userID, email, orgID, req)
	if err != nil {
		response.Error(w, err)
		return
	}
	if h.audit != nil && orgID != uuid.Nil {
		uid := userID
		meta, _ := json.Marshal(map[string]string{"channel_id": resp.ChannelID, "handshake_id": req.HandshakeID})
		h.audit.Write(r.Context(), "auth.bind", "session", resp.ChannelID, orgID, &uid, meta)
	}
	response.JSON(w, http.StatusOK, resp)
}

func (h *Handler) RequestMagicLink(w http.ResponseWriter, r *http.Request) {
	if h.magicReqUC == nil {
		response.JSON(w, http.StatusNotFound, map[string]string{"error": "magic link unavailable"})
		return
	}
	var req usecase.MagicLinkRequest
	if err := validator.DecodeAndValidate(r, &req); err != nil {
		response.JSON(w, http.StatusBadRequest, map[string]string{"error": err.Error()})
		return
	}
	resp, err := h.magicReqUC.Execute(r.Context(), req)
	if err != nil {
		response.Error(w, err)
		return
	}
	response.JSON(w, http.StatusOK, resp)
}

func (h *Handler) VerifyMagicLink(w http.ResponseWriter, r *http.Request) {
	if h.magicVerifyUC == nil {
		response.JSON(w, http.StatusNotFound, map[string]string{"error": "magic link unavailable"})
		return
	}
	var req usecase.MagicLinkVerifyRequest
	if err := validator.DecodeAndValidate(r, &req); err != nil {
		response.JSON(w, http.StatusBadRequest, map[string]string{"error": err.Error()})
		return
	}
	login, handshakeID, err := h.magicVerifyUC.Execute(r.Context(), req)
	if err != nil {
		response.Error(w, err)
		return
	}
	response.JSON(w, http.StatusOK, map[string]any{
		"token":        login.Token,
		"user":         login.User,
		"handshake_id": handshakeID,
		"next":         "POST /api/v1/auth/bind with handshake_id + barrier",
	})
}

func (h *Handler) ChannelMe(w http.ResponseWriter, r *http.Request) {
	userID, ok := middleware.UserIDFromContext(r.Context())
	if !ok {
		response.JSON(w, http.StatusUnauthorized, map[string]string{"error": "not authenticated"})
		return
	}
	channelID, _ := middleware.ChannelIDFromContext(r.Context())
	response.JSON(w, http.StatusOK, map[string]any{
		"user_id":    userID.String(),
		"channel_id": channelID.String(),
		"token_kind": "blended",
	})
}

func (h *Handler) ChannelPreflight(w http.ResponseWriter, r *http.Request) {
	channelID, _ := middleware.ChannelIDFromContext(r.Context())
	response.JSON(w, http.StatusOK, map[string]any{
		"ok":         true,
		"channel_id": channelID.String(),
		"stage":      "preflight",
	})
}

func (h *Handler) IngestScan(w http.ResponseWriter, r *http.Request) {
	userID, ok := middleware.UserIDFromContext(r.Context())
	if !ok {
		response.JSON(w, http.StatusUnauthorized, map[string]string{"error": "not authenticated"})
		return
	}
	var req dto.IngestScanRequest
	if err := validator.DecodeAndValidate(r, &req); err != nil {
		response.JSON(w, http.StatusBadRequest, map[string]string{"error": err.Error()})
		return
	}
	var orgPtr *uuid.UUID
	if orgID, ok := middleware.OrgIDFromContext(r.Context()); ok && orgID != uuid.Nil {
		orgPtr = &orgID
	}
	info, err := h.ingestUC.Execute(r.Context(), userID, orgPtr, req)
	if err != nil {
		response.Error(w, err)
		return
	}
	response.Created(w, info)
}

func (h *Handler) ListScans(w http.ResponseWriter, r *http.Request) {
	limit, _ := strconv.Atoi(r.URL.Query().Get("limit"))
	offset, _ := strconv.Atoi(r.URL.Query().Get("offset"))
	items, err := h.listUC.Execute(r.Context(), limit, offset)
	if err != nil {
		response.Error(w, err)
		return
	}
	response.JSON(w, http.StatusOK, map[string]any{"items": items})
}
