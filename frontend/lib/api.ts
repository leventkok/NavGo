const API_URL = process.env.NEXT_PUBLIC_NAVGO_API_URL ?? "http://localhost:8080";

export type Place = {
  place_id: string;
  displayName: string;
  formattedAddress: string;
  location: { latitude: number; longitude: number };
  types?: string[];
  rating?: number;
  googleMapsUri?: string;
};

export type SearchResponse = {
  places: Place[];
  cache_hit: boolean;
  provider: string;
};

export type RouteResponse = {
  overviewPolyline: string;
  googleMapsUrl: string;
  distanceMeters: number;
  durationSeconds: number;
  waypointOrder: number[];
  status: string;
  provider: string;
};

export type Intent = {
  area: string;
  query: string;
  duration_label: string;
  max_stops: number;
};

async function request<T>(path: string, init: RequestInit = {}, token?: string): Promise<T> {
  const headers = new Headers(init.headers);
  headers.set("Content-Type", "application/json");
  if (token) headers.set("Authorization", `Bearer ${token}`);

  const url = `${API_URL}${path}`;
  let res: Response;
  try {
    res = await fetch(url, { ...init, headers });
  } catch (err) {
    const detail = err instanceof Error ? err.message : String(err);
    throw new Error(`API erişilemedi (${url}): ${detail}`);
  }

  const text = await res.text();
  let data: { message?: string; error?: string } | null = null;
  if (text) {
    try {
      data = JSON.parse(text);
    } catch {
      throw new Error(`API JSON değil (${res.status}): ${text.slice(0, 160)}`);
    }
  }
  if (!res.ok) {
    const msg = data?.message || data?.error || res.statusText;
    throw new Error(msg);
  }
  return data as T;
}

export async function ensureDemoAuth(): Promise<string> {
  const email = "demo@navgo.local";
  const password = "NavGoDemo1!";
  try {
    const login = await request<{ token: string }>("/api/v1/auth/login", {
      method: "POST",
      body: JSON.stringify({ email, password }),
    });
    return login.token;
  } catch {
    await request("/api/v1/auth/register", {
      method: "POST",
      body: JSON.stringify({
        email,
        password,
        first_name: "NavGo",
        last_name: "Demo",
      }),
    });
    const login = await request<{ token: string }>("/api/v1/auth/login", {
      method: "POST",
      body: JSON.stringify({ email, password }),
    });
    return login.token;
  }
}

export function searchPlaces(token: string, intent: Intent) {
  return request<SearchResponse>(
    "/api/v1/places/search",
    {
      method: "POST",
      body: JSON.stringify({
        query: intent.query || intent.area,
        area: intent.area,
        language: "tr",
        max_results: intent.max_stops || 5,
      }),
    },
    token,
  );
}

export function buildRoute(token: string, placeIds: string[]) {
  return request<RouteResponse>(
    "/api/v1/routes/build",
    {
      method: "POST",
      body: JSON.stringify({
        place_ids: placeIds,
        travel_mode: "WALK",
        optimize_waypoint_order: true,
        language: "tr",
      }),
    },
    token,
  );
}

export function saveItinerary(
  token: string,
  payload: {
    prompt: string;
    area: string;
    duration_label: string;
    stops: Array<{
      place_id: string;
      displayName: string;
      formattedAddress: string;
      location: Place["location"];
      order: number;
      types?: string[];
      googleMapsUri?: string;
    }>;
    overview_polyline: string;
    google_maps_url: string;
    distance_meters: number;
    duration_seconds: number;
    model?: string;
  },
) {
  return request(
    "/api/v1/itineraries",
    {
      method: "POST",
      body: JSON.stringify({
        ...payload,
        locale: "tr",
        model: payload.model ?? "gemma-2-2b-it-q4f16_1-MLC",
        client_meta: { client: "navgo-web" },
      }),
    },
    token,
  );
}
