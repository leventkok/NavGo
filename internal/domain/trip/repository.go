package trip

import (
	"context"

	"github.com/google/uuid"
)

// Repository persists itineraries.
type Repository interface {
	Create(ctx context.Context, itinerary *Itinerary) error
	GetByID(ctx context.Context, id uuid.UUID) (*Itinerary, error)
	ListByUser(ctx context.Context, userID uuid.UUID, limit, offset int) ([]Itinerary, error)
}
