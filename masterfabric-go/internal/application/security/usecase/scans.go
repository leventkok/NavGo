package usecase

import (
	"context"
	"encoding/json"
	"time"

	"github.com/google/uuid"
	"github.com/leventkok/NavGo/internal/application/security/dto"
	"github.com/leventkok/NavGo/internal/domain/security/model"
	"github.com/leventkok/NavGo/internal/domain/security/repository"
	domainErr "github.com/leventkok/NavGo/internal/shared/errors"
)

// IngestScanUseCase stores MCP/CLI security reports.
type IngestScanUseCase struct {
	repo repository.ScanRepository
}

// NewIngestScanUseCase constructs IngestScanUseCase.
func NewIngestScanUseCase(repo repository.ScanRepository) *IngestScanUseCase {
	return &IngestScanUseCase{repo: repo}
}

// Execute persists a scan report.
func (uc *IngestScanUseCase) Execute(ctx context.Context, userID uuid.UUID, orgID *uuid.UUID, req dto.IngestScanRequest) (*dto.ScanInfo, error) {
	if len(req.Report) == 0 || !json.Valid(req.Report) {
		return nil, domainErr.New(domainErr.ErrBadRequest, "report must be valid JSON", nil)
	}
	source := req.Source
	if source == "" {
		source = "mcp"
	}
	s := &model.SecurityScan{
		ID:             uuid.New(),
		OrganizationID: orgID,
		UserID:         &userID,
		Source:         source,
		ScoreGrade:     req.ScoreGrade,
		ScoreValue:     req.ScoreValue,
		Report:         req.Report,
		CreatedAt:      time.Now().UTC(),
	}
	if err := uc.repo.Create(ctx, s); err != nil {
		return nil, err
	}
	return &dto.ScanInfo{
		ID:             s.ID,
		OrganizationID: s.OrganizationID,
		UserID:         s.UserID,
		Source:         s.Source,
		ScoreGrade:     s.ScoreGrade,
		ScoreValue:     s.ScoreValue,
		Report:         s.Report,
		CreatedAt:      s.CreatedAt,
	}, nil
}

// ListScansUseCase lists stored security scans.
type ListScansUseCase struct {
	repo repository.ScanRepository
}

// NewListScansUseCase constructs ListScansUseCase.
func NewListScansUseCase(repo repository.ScanRepository) *ListScansUseCase {
	return &ListScansUseCase{repo: repo}
}

// Execute lists scans.
func (uc *ListScansUseCase) Execute(ctx context.Context, limit, offset int) ([]dto.ScanInfo, error) {
	rows, err := uc.repo.List(ctx, limit, offset)
	if err != nil {
		return nil, err
	}
	out := make([]dto.ScanInfo, 0, len(rows))
	for _, s := range rows {
		out = append(out, dto.ScanInfo{
			ID:             s.ID,
			OrganizationID: s.OrganizationID,
			UserID:         s.UserID,
			Source:         s.Source,
			ScoreGrade:     s.ScoreGrade,
			ScoreValue:     s.ScoreValue,
			Report:         s.Report,
			CreatedAt:      s.CreatedAt,
		})
	}
	return out, nil
}
