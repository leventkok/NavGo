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

type Session = {
  token: string;
  barrier: string;
  handshakeId: string;
  channelPath: string;
};

const SESSION_KEY = "navgo_session_v1";

function loadSession(): Session | null {
  if (typeof window === "undefined") return null;
  try {
    const raw = sessionStorage.getItem(SESSION_KEY);
    return raw ? (JSON.parse(raw) as Session) : null;
  } catch {
    return null;
  }
}

function saveSession(s: Session) {
  if (typeof window === "undefined") return;
  sessionStorage.setItem(SESSION_KEY, JSON.stringify(s));
}

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

/** Handshake → login/register → bind. Demo only when NEXT_PUBLIC_ALLOW_DEMO_AUTH=true. */
export async function ensureSession(): Promise<string> {
  const cached = loadSession();
  if (cached?.token) return cached.token;

  const allowDemo = process.env.NEXT_PUBLIC_ALLOW_DEMO_AUTH === "true";
  const email = process.env.NEXT_PUBLIC_NAVGO_USER_EMAIL || (allowDemo ? "demo@navgo.local" : "");
  const password = process.env.NEXT_PUBLIC_NAVGO_USER_PASSWORD || (allowDemo ? "NavGoDemo1!" : "");
  if (!email || !password) {
    throw new Error("Set NEXT_PUBLIC_NAVGO_USER_EMAIL/PASSWORD or NEXT_PUBLIC_ALLOW_DEMO_AUTH=true");
  }

  const hs = await request<{
    handshake_id: string;
    barrier: string;
    channel_path: string;
  }>("/api/v1/auth/handshake", { method: "POST", body: "{}" });

  const loginBody = JSON.stringify({
    email,
    password,
    handshake_id: hs.handshake_id,
  });

  let login: { token: string };
  try {
    login = await request<{ token: string }>("/api/v1/auth/login", {
      method: "POST",
      body: loginBody,
    });
  } catch {
    await request("/api/v1/auth/register", {
      method: "POST",
      body: JSON.stringify({
        email,
        password,
        first_name: "NavGo",
        last_name: allowDemo ? "Demo" : "User",
        handshake_id: hs.handshake_id,
      }),
    });
    login = await request<{ token: string }>("/api/v1/auth/login", {
      method: "POST",
      body: loginBody,
    });
  }

  const bind = await request<{ token: string; channel_path: string }>(
    "/api/v1/auth/bind",
    {
      method: "POST",
      body: JSON.stringify({
        handshake_id: hs.handshake_id,
        barrier: hs.barrier,
      }),
    },
    login.token,
  );

  saveSession({
    token: bind.token,
    barrier: hs.barrier,
    handshakeId: hs.handshake_id,
    channelPath: bind.channel_path || hs.channel_path,
  });
  return bind.token;
}

/** @deprecated use ensureSession */
export async function ensureDemoAuth(): Promise<string> {
  return ensureSession();
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
