package main

import (
	"context"
	"encoding/json"
	"fmt"
	"log/slog"
	"os"
	"strings"
	"time"

	"github.com/google/uuid"
	"github.com/mark3labs/mcp-go/mcp"
	"github.com/mark3labs/mcp-go/server"

	"github.com/leventkok/NavGo/internal/application/trip/dto"
	tripUC "github.com/leventkok/NavGo/internal/application/trip/usecase"
	placesinfra "github.com/leventkok/NavGo/internal/infrastructure/places"
	placespg "github.com/leventkok/NavGo/internal/infrastructure/postgres/places"
	trippg "github.com/leventkok/NavGo/internal/infrastructure/postgres/trip"
	"github.com/leventkok/NavGo/internal/shared/config"
	"github.com/leventkok/NavGo/internal/shared/database"
	"github.com/leventkok/NavGo/internal/shared/logger"
)

func main() {
	if err := run(); err != nil {
		fmt.Fprintf(os.Stderr, "navgo-mcp error: %v\n", err)
		os.Exit(1)
	}
}

func run() error {
	cfg := config.Load()
	log := logger.New(cfg.Log.Level, cfg.Log.Format)
	slog.SetDefault(log)

	boundUser, err := resolveMCPIdentity()
	if err != nil {
		return err
	}

	ctx, cancel := context.WithTimeout(context.Background(), 10*time.Second)
	defer cancel()

	db, err := database.NewPostgresPool(ctx, cfg.Database)
	if err != nil {
		return fmt.Errorf("postgres: %w", err)
	}
	defer db.Close()

	placeCache := placespg.NewCacheRepo(db)
	placesClient, directionsClient := placesinfra.NewClients(cfg.GoogleMaps.APIKey, placeCache)
	itineraryRepo := trippg.NewItineraryRepo(db)
	svc := tripUC.NewService(placesClient, directionsClient, placeCache, itineraryRepo)

	s := server.NewMCPServer(
		"navgo",
		"0.1.0",
		server.WithToolCapabilities(true),
	)

	s.AddTool(mcp.NewTool("search_places",
		mcp.WithDescription("Search grounded places (Google-shaped). Never invent place_id."),
		mcp.WithString("query", mcp.Required(), mcp.Description("Free-text search query")),
		mcp.WithString("area", mcp.Description("Area hint, e.g. Kaleiçi Antalya")),
		mcp.WithString("language", mcp.Description("BCP-47 language, default tr")),
		mcp.WithNumber("max_results", mcp.Description("Max places to return")),
	), func(ctx context.Context, req mcp.CallToolRequest) (*mcp.CallToolResult, error) {
		args := req.GetArguments()
		max := intArg(args, "max_results", 8)
		resp, err := svc.SearchPlaces(ctx, dto.SearchPlacesRequest{
			Query:      strArg(args, "query"),
			Area:       strArg(args, "area"),
			Language:   strArg(args, "language"),
			MaxResults: max,
		})
		return jsonResult(resp, err)
	})

	s.AddTool(mcp.NewTool("build_day_route",
		mcp.WithDescription("Build a day route from grounded place_ids."),
		mcp.WithArray("place_ids", mcp.Required(), mcp.Description("Grounded Google place_id list"), mcp.Items(map[string]any{"type": "string"})),
		mcp.WithString("travel_mode", mcp.Description("WALK|DRIVE|BICYCLE|TRANSIT")),
		mcp.WithBoolean("optimize_waypoint_order", mcp.Description("Nearest-neighbor optimize")),
	), func(ctx context.Context, req mcp.CallToolRequest) (*mcp.CallToolResult, error) {
		args := req.GetArguments()
		ids := stringSliceArg(args, "place_ids")
		resp, err := svc.BuildRoute(ctx, dto.BuildRouteRequest{
			PlaceIDs:              ids,
			TravelMode:            strArg(args, "travel_mode"),
			OptimizeWaypointOrder: boolArg(args, "optimize_waypoint_order", true),
		})
		return jsonResult(resp, err)
	})

	s.AddTool(mcp.NewTool("save_itinerary",
		mcp.WithDescription("Persist a grounded itinerary decision for the bound MCP principal."),
		mcp.WithString("prompt", mcp.Required(), mcp.Description("Original user prompt")),
		mcp.WithString("area", mcp.Description("Area label")),
		mcp.WithString("locale", mcp.Description("Locale")),
		mcp.WithString("model", mcp.Description("Client model id")),
		mcp.WithArray("stops", mcp.Required(), mcp.Description("Grounded stops with place_id"), mcp.Items(map[string]any{"type": "object"})),
		mcp.WithString("google_maps_url", mcp.Description("Maps URL")),
		mcp.WithString("overview_polyline", mcp.Description("Encoded/overview polyline")),
	), func(ctx context.Context, req mcp.CallToolRequest) (*mcp.CallToolResult, error) {
		args := req.GetArguments()
		rawStops, _ := json.Marshal(args["stops"])
		var stops []dto.StopInput
		if err := json.Unmarshal(rawStops, &stops); err != nil {
			return mcp.NewToolResultError("invalid stops"), nil
		}
		it, err := svc.SaveItinerary(ctx, boundUser, dto.SaveItineraryRequest{
			Prompt:           strArg(args, "prompt"),
			Area:             strArg(args, "area"),
			Locale:           strArg(args, "locale"),
			Model:            strArg(args, "model"),
			Stops:            stops,
			GoogleMapsURL:    strArg(args, "google_maps_url"),
			OverviewPolyline: strArg(args, "overview_polyline"),
		})
		return jsonResult(it, err)
	})

	s.AddTool(mcp.NewTool("get_itinerary",
		mcp.WithDescription("Fetch itinerary by id (owner must match MCP_USER_ID)"),
		mcp.WithString("id", mcp.Required(), mcp.Description("Itinerary UUID")),
	), func(ctx context.Context, req mcp.CallToolRequest) (*mcp.CallToolResult, error) {
		id, err := uuid.Parse(strArg(req.GetArguments(), "id"))
		if err != nil {
			return mcp.NewToolResultError("invalid id"), nil
		}
		it, err := svc.GetItinerary(ctx, id)
		if err != nil {
			return jsonResult(it, err)
		}
		if it.UserID != boundUser {
			return mcp.NewToolResultError("itinerary access denied"), nil
		}
		return jsonResult(it, nil)
	})

	s.AddTool(mcp.NewTool("list_itineraries",
		mcp.WithDescription("List itineraries for the bound MCP principal"),
		mcp.WithNumber("limit", mcp.Description("Page size")),
		mcp.WithNumber("offset", mcp.Description("Offset")),
	), func(ctx context.Context, req mcp.CallToolRequest) (*mcp.CallToolResult, error) {
		args := req.GetArguments()
		list, err := svc.ListItineraries(ctx, boundUser, intArg(args, "limit", 20), intArg(args, "offset", 0))
		return jsonResult(list, err)
	})

	s.AddTool(mcp.NewTool("plan_day",
		mcp.WithDescription("Orchestrate search + route (+ optional save) for a day plan."),
		mcp.WithString("prompt", mcp.Required(), mcp.Description("User free-text prompt")),
		mcp.WithString("area", mcp.Required(), mcp.Description("Area e.g. Kaleiçi, Antalya")),
		mcp.WithString("locale", mcp.Description("Locale")),
		mcp.WithString("travel_mode", mcp.Description("WALK|DRIVE")),
		mcp.WithBoolean("optimize_waypoint_order", mcp.Description("Optimize order")),
		mcp.WithBoolean("save", mcp.Description("Persist itinerary when true")),
		mcp.WithNumber("max_stops", mcp.Description("Max grounded stops")),
		mcp.WithString("model", mcp.Description("Client model id")),
	), func(ctx context.Context, req mcp.CallToolRequest) (*mcp.CallToolResult, error) {
		args := req.GetArguments()
		resp, err := svc.PlanDay(ctx, dto.PlanDayRequest{
			Prompt:                strArg(args, "prompt"),
			Area:                  strArg(args, "area"),
			Locale:                strArg(args, "locale"),
			TravelMode:            strArg(args, "travel_mode"),
			OptimizeWaypointOrder: boolArg(args, "optimize_waypoint_order", true),
			Save:                  boolArg(args, "save", false),
			UserID:                boundUser,
			MaxStops:              intArg(args, "max_stops", 5),
			Model:                 strArg(args, "model"),
		})
		return jsonResult(resp, err)
	})

	log.Info("navgo MCP server starting on stdio", "bound_user", boundUser.String())
	return server.ServeStdio(s)
}

// resolveMCPIdentity enforces AuthZ outside the prompt: identity comes from env, not tool args.
func resolveMCPIdentity() (uuid.UUID, error) {
	token := strings.TrimSpace(os.Getenv("MCP_SERVICE_TOKEN"))
	require := strings.EqualFold(os.Getenv("MCP_REQUIRE_TOKEN"), "true") || os.Getenv("MCP_REQUIRE_TOKEN") == "1"
	expected := strings.TrimSpace(os.Getenv("MCP_EXPECTED_TOKEN"))
	if require {
		if token == "" {
			return uuid.Nil, fmt.Errorf("MCP_SERVICE_TOKEN required when MCP_REQUIRE_TOKEN=true")
		}
		if expected != "" && token != expected {
			return uuid.Nil, fmt.Errorf("MCP_SERVICE_TOKEN mismatch")
		}
	} else if expected != "" && token != "" && token != expected {
		return uuid.Nil, fmt.Errorf("MCP_SERVICE_TOKEN mismatch")
	}

	raw := strings.TrimSpace(os.Getenv("MCP_USER_ID"))
	if raw == "" {
		return uuid.Nil, fmt.Errorf("MCP_USER_ID is required (do not pass user_id via tool args)")
	}
	id, err := uuid.Parse(raw)
	if err != nil {
		return uuid.Nil, fmt.Errorf("invalid MCP_USER_ID: %w", err)
	}
	return id, nil
}

func jsonResult(v any, err error) (*mcp.CallToolResult, error) {
	if err != nil {
		return mcp.NewToolResultError(err.Error()), nil
	}
	b, mErr := json.MarshalIndent(v, "", "  ")
	if mErr != nil {
		return mcp.NewToolResultError(mErr.Error()), nil
	}
	return mcp.NewToolResultText(string(b)), nil
}

func strArg(args map[string]any, key string) string {
	if v, ok := args[key]; ok {
		if s, ok := v.(string); ok {
			return s
		}
	}
	return ""
}

func intArg(args map[string]any, key string, def int) int {
	if v, ok := args[key]; ok {
		switch n := v.(type) {
		case float64:
			return int(n)
		case int:
			return n
		}
	}
	return def
}

func boolArg(args map[string]any, key string, def bool) bool {
	if v, ok := args[key]; ok {
		if b, ok := v.(bool); ok {
			return b
		}
	}
	return def
}

func stringSliceArg(args map[string]any, key string) []string {
	v, ok := args[key]
	if !ok {
		return nil
	}
	arr, ok := v.([]any)
	if !ok {
		return nil
	}
	out := make([]string, 0, len(arr))
	for _, item := range arr {
		if s, ok := item.(string); ok {
			out = append(out, s)
		}
	}
	return out
}
