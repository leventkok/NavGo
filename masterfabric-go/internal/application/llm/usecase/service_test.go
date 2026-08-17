package usecase_test

import (
	"context"
	"testing"

	"github.com/leventkok/NavGo/internal/application/llm/dto"
	"github.com/leventkok/NavGo/internal/application/llm/usecase"
	"github.com/leventkok/NavGo/internal/domain/llm"
)

type stubChat struct {
	content string
	err     error
}

func (s stubChat) Chat(ctx context.Context, req llm.ChatRequest) (string, error) {
	return s.content, s.err
}

func TestParseIntent_JSON(t *testing.T) {
	svc := usecase.NewService(stubChat{
		content: "```json\n{\"area\":\"Kadıköy\",\"query\":\"cafe müze\",\"duration_label\":\"yarım gün\",\"max_stops\":4}\n```",
	}, "gemma2:2b")

	got, err := svc.ParseIntent(context.Background(), dto.ParseIntentRequest{
		Prompt:      "Kadıköy'de gezmek istiyorum",
		DefaultArea: "İstanbul",
	})
	if err != nil {
		t.Fatalf("ParseIntent: %v", err)
	}
	if got.Area != "Kadıköy" || got.Query != "cafe müze" || got.MaxStops != 4 {
		t.Fatalf("unexpected intent: %+v", got)
	}
}

func TestSuggestDayCards_JSON(t *testing.T) {
	svc := usecase.NewService(stubChat{
		content: `{"cards":[
			{"title":"Müze rotası","subtitle":"Anıtkabir · müzeler","query":"müze anıt","icon":"museum"},
			{"title":"Kahve","subtitle":"Kızılay kafeler","query":"kahve cafe","icon":"coffee"},
			{"title":"Park","subtitle":"Yeşil alan","query":"park göl","icon":"parks"},
			{"title":"Tarihi merkez","subtitle":"Ulus","query":"tarihi yer","icon":"historic"}
		]}`,
	}, "navgo-gemma")

	got, err := svc.SuggestDayCards(context.Background(), dto.SuggestDayCardsRequest{
		Area:   "Ankara",
		Locale: "tr",
	})
	if err != nil {
		t.Fatalf("SuggestDayCards: %v", err)
	}
	if len(got.Cards) != 4 {
		t.Fatalf("want 4 cards, got %d", len(got.Cards))
	}
	if got.Cards[0].Icon != "museum" || got.Cards[0].Title == "" {
		t.Fatalf("unexpected first card: %+v", got.Cards[0])
	}
}

func TestPickStops_FiltersInvalid(t *testing.T) {
	svc := usecase.NewService(stubChat{
		content: `{"indices":[0, 99, 1, 0]}`,
	}, "gemma2:2b")

	got, err := svc.PickStops(context.Background(), dto.PickStopsRequest{
		Prompt: "gez",
		Places: []dto.PlaceCatalogItem{
			{DisplayName: "A", FormattedAddress: "x"},
			{DisplayName: "B", FormattedAddress: "y"},
			{DisplayName: "C", FormattedAddress: "z"},
		},
		MaxStops: 3,
	})
	if err != nil {
		t.Fatalf("PickStops: %v", err)
	}
	if len(got.Indices) != 2 || got.Indices[0] != 0 || got.Indices[1] != 1 {
		t.Fatalf("unexpected indices: %+v", got.Indices)
	}
}
