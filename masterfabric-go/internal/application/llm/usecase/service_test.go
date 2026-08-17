package usecase_test

import (
	"context"
	"errors"
	"strings"
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

type captureChat struct {
	content string
	err     error
	last    llm.ChatRequest
}

func (s *captureChat) Chat(ctx context.Context, req llm.ChatRequest) (string, error) {
	s.last = req
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
			{"title":"Şehre yeni misin?","subtitle":"İkonik duraklarla hızlı tur","query":"tarihi yer meydan","icon":"modern","intent":"first_day"},
			{"title":"Hikâyeyi dinle","subtitle":"Müze ve anıt rotası","query":"müze anıt","icon":"museum","intent":"culture"},
			{"title":"Ağırdan al","subtitle":"Kahve ve kısa yürüyüş","query":"kahve cafe park","icon":"coffee","intent":"slow"},
			{"title":"Yerel tat","subtitle":"Esnaf ve sokak lezzeti","query":"lokal yemek pazar","icon":"bazaar","intent":"food"}
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
	if got.Cards[0].Intent != "first_day" || got.Cards[0].Title == "" {
		t.Fatalf("unexpected first card: %+v", got.Cards[0])
	}
}

func TestSuggestRouteCard_JSON(t *testing.T) {
	svc := usecase.NewService(stubChat{
		content: `{"title":"Yerel tat","subtitle":"Esnaf ve sokak lezzeti","query":"lokal yemek pazar","icon":"bazaar","intent":"food","area":"Sivas"}`,
	}, "navgo-gemma")

	got, err := svc.SuggestRouteCard(context.Background(), dto.SuggestRouteCardRequest{
		Prompt:      "Sivas'ta sokak yemeği",
		Locale:      "tr",
		DefaultArea: "Sivas",
	})
	if err != nil {
		t.Fatalf("SuggestRouteCard: %v", err)
	}
	if got.Card.Intent != "food" || got.Card.Title == "" || got.Area != "Sivas" {
		t.Fatalf("unexpected card: %+v area=%s", got.Card, got.Area)
	}
}

func TestSuggestRouteCard_EditKeepsCard(t *testing.T) {
	svc := usecase.NewService(stubChat{
		content: `{"title":"Ağırdan al","subtitle":"Kahve ve kısa yürüyüş","query":"kahve cafe park","icon":"coffee","intent":"slow","area":"Sivas"}`,
	}, "navgo-gemma")

	got, err := svc.SuggestRouteCard(context.Background(), dto.SuggestRouteCardRequest{
		Prompt: "daha yavaş olsun",
		Locale: "tr",
		Previous: &dto.DayCardSuggestion{
			Title:    "Yerel tat",
			Subtitle: "Esnaf",
			Query:    "yemek",
			Intent:   "food",
			Icon:     "bazaar",
			Area:     "Sivas",
		},
	})
	if err != nil {
		t.Fatalf("SuggestRouteCard edit: %v", err)
	}
	if got.Card.Intent != "slow" || got.Area != "Sivas" {
		t.Fatalf("unexpected edited card: %+v", got)
	}
}

func TestSuggestRouteCard_FallbackOnLLMError(t *testing.T) {
	svc := usecase.NewService(stubChat{err: errors.New("down")}, "navgo-gemma")
	got, err := svc.SuggestRouteCard(context.Background(), dto.SuggestRouteCardRequest{
		Prompt:      "Sivas'ta kahve ve park",
		Locale:      "tr",
		DefaultArea: "Sivas",
	})
	if err != nil {
		t.Fatalf("SuggestRouteCard fallback: %v", err)
	}
	if got.Card.Title == "" || got.Area != "Sivas" || got.Card.Intent != "slow" {
		t.Fatalf("unexpected fallback card: %+v", got)
	}
}

func TestSuggestRouteCard_ThreadKeepsCityOverGPS(t *testing.T) {
	chat := &captureChat{
		content: `{"title":"Ağırdan al","subtitle":"Kahve","query":"kahve cafe","icon":"coffee","intent":"slow","area":"Sivas"}`,
	}
	svc := usecase.NewService(chat, "navgo-gemma")
	got, err := svc.SuggestRouteCard(context.Background(), dto.SuggestRouteCardRequest{
		Prompt:      "daha yavaş olsun",
		Locale:      "tr",
		DefaultArea: "Sivas",
		Previous: &dto.DayCardSuggestion{
			Title:    "Sahil günü",
			Subtitle: "Kaleiçi ve deniz",
			Query:    "antalya sahil kaleici",
			Intent:   "slow",
			Icon:     "waterfront",
			Area:     "Antalya",
		},
		Messages: []dto.RouteCardTurn{
			{Role: "user", Text: "Antalya'da sahil günü"},
			{Role: "assistant", Area: "Antalya", Title: "Sahil günü", Query: "antalya sahil kaleici", Intent: "slow"},
			{Role: "user", Text: "daha yavaş olsun"},
		},
	})
	if err != nil {
		t.Fatalf("SuggestRouteCard thread: %v", err)
	}
	if got.Area != "Antalya" {
		t.Fatalf("want Antalya, got %q card=%+v", got.Area, got.Card)
	}
	blob := chatMessagesBlob(chat.last.Messages)
	if !strings.Contains(blob, "Antalya") {
		t.Fatalf("expected thread to mention Antalya, got %q", blob)
	}
	if strings.Contains(blob, "default_area=Sivas") {
		t.Fatalf("GPS default_area should not be sent when session_area is set: %q", blob)
	}
}

func TestSuggestRouteCard_FallbackKeepsPreviousCity(t *testing.T) {
	svc := usecase.NewService(stubChat{err: errors.New("down")}, "navgo-gemma")
	got, err := svc.SuggestRouteCard(context.Background(), dto.SuggestRouteCardRequest{
		Prompt:      "daha yavaş olsun",
		Locale:      "tr",
		DefaultArea: "Sivas",
		Previous: &dto.DayCardSuggestion{
			Title:  "Sahil günü",
			Query:  "antalya sahil",
			Intent: "slow",
			Area:   "Antalya",
		},
	})
	if err != nil {
		t.Fatalf("fallback city: %v", err)
	}
	if got.Area != "Antalya" {
		t.Fatalf("want Antalya fallback, got %q", got.Area)
	}
}

func TestSuggestRouteCard_ThreadAreaWithoutPrevious(t *testing.T) {
	svc := usecase.NewService(stubChat{
		content: `{"title":"Ağırdan al","subtitle":"Kahve","query":"kahve","icon":"coffee","intent":"slow","area":"Sivas"}`,
	}, "navgo-gemma")
	got, err := svc.SuggestRouteCard(context.Background(), dto.SuggestRouteCardRequest{
		Prompt:      "müze de ekle",
		Locale:      "tr",
		DefaultArea: "Sivas",
		Messages: []dto.RouteCardTurn{
			{Role: "user", Text: "Antalya sahil"},
			{Role: "assistant", Area: "Antalya", Title: "Sahil günü", Query: "sahil", Intent: "slow"},
		},
	})
	if err != nil {
		t.Fatalf("thread without previous: %v", err)
	}
	if got.Area != "Antalya" {
		t.Fatalf("want Antalya from thread, got %q", got.Area)
	}
}

func TestSuggestRouteCard_PromptCityOverridesSession(t *testing.T) {
	chat := &captureChat{
		content: `{"title":"Antalya sahilinde sakin bir gün","subtitle":"İstanbulda tarihi yerler önerir misin","query":"kahve","icon":"coffee","intent":"slow","area":"Antalya"}`,
	}
	svc := usecase.NewService(chat, "navgo-gemma")
	got, err := svc.SuggestRouteCard(context.Background(), dto.SuggestRouteCardRequest{
		Prompt:      "İstanbulda tarihi yerler önerir misin",
		Locale:      "tr",
		DefaultArea: "Sivas",
		Previous: &dto.DayCardSuggestion{
			Title:  "Antalya sahilinde sakin bir gün",
			Query:  "antalya sahil",
			Intent: "slow",
			Area:   "Antalya",
		},
	})
	if err != nil {
		t.Fatalf("city switch: %v", err)
	}
	if got.Area != "İstanbul" {
		t.Fatalf("want İstanbul, got %q", got.Area)
	}
	last := chat.last.Messages[len(chat.last.Messages)-1].Content
	if !strings.Contains(last, "user_changed_city=true") || !strings.Contains(last, "prompt=") {
		t.Fatalf("expected new-city prompt, got %q", last)
	}
	if strings.Contains(last, "previous_title=") || strings.Contains(last, "\nedit=") {
		t.Fatalf("city change should not be sent as an edit: %q", last)
	}
}

func TestSuggestRouteCard_FallbackSwitchesCity(t *testing.T) {
	svc := usecase.NewService(stubChat{err: errors.New("down")}, "navgo-gemma")
	got, err := svc.SuggestRouteCard(context.Background(), dto.SuggestRouteCardRequest{
		Prompt:      "Istanbulda tarihi yerler önerir misin",
		Locale:      "tr",
		DefaultArea: "Sivas",
		Previous: &dto.DayCardSuggestion{
			Title:  "Antalya sahilinde sakin bir gün",
			Query:  "antalya sahil",
			Intent: "slow",
			Icon:   "coffee",
			Area:   "Antalya",
		},
	})
	if err != nil {
		t.Fatalf("fallback city switch: %v", err)
	}
	if got.Area != "İstanbul" {
		t.Fatalf("want İstanbul fallback, got %q", got.Area)
	}
	if got.Card.Title == "Antalya sahilinde sakin bir gün" {
		t.Fatalf("city change must not keep previous title: %+v", got.Card)
	}
	if got.Card.Intent != "culture" {
		t.Fatalf("want culture intent for tarihi, got %q", got.Card.Intent)
	}
}

func chatMessagesBlob(messages []llm.Message) string {
	var b strings.Builder
	for _, m := range messages {
		b.WriteString(m.Role)
		b.WriteByte(':')
		b.WriteString(m.Content)
		b.WriteByte('\n')
	}
	return b.String()
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
