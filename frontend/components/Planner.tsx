"use client";

import { useEffect, useRef, useState } from "react";
import {
  buildRoute,
  ensureDemoAuth,
  type Place,
  type RouteResponse,
  saveItinerary,
  searchPlaces,
} from "@/lib/api";
import {
  createGemmaEngine,
  GEMMA_MODEL_ID,
  parseIntent,
  pickStops,
  type ChatEngine,
} from "@/lib/gemma";

type Step =
  | "idle"
  | "auth"
  | "loading_model"
  | "ready"
  | "intent"
  | "search"
  | "pick"
  | "route"
  | "save"
  | "done"
  | "error";

export default function Planner() {
  const [prompt, setPrompt] = useState(
    "Antalya'ya yeni geldim, Kaleiçi'ni gezmek istiyorum, tüm gün buradayım.",
  );
  const [step, setStep] = useState<Step>("idle");
  const [log, setLog] = useState("Model henüz yüklenmedi.");
  const [error, setError] = useState<string | null>(null);
  const [places, setPlaces] = useState<Place[]>([]);
  const [selected, setSelected] = useState<Place[]>([]);
  const [route, setRoute] = useState<RouteResponse | null>(null);
  const [token, setToken] = useState<string | null>(null);
  const [modelLoaded, setModelLoaded] = useState(false);
  const engineRef = useRef<ChatEngine | null>(null);

  useEffect(() => {
    return () => {
      void engineRef.current?.unload();
    };
  }, []);

  async function loadModel() {
    setError(null);
    setStep("auth");
    setLog("Demo kullanıcı ile API auth...");
    try {
      const t = await ensureDemoAuth();
      setToken(t);
      setStep("loading_model");
      setLog(`Gemma indiriliyor / yükleniyor: ${GEMMA_MODEL_ID}\n(WebGPU gerekir, ~1GB+)`);
      const engine = await createGemmaEngine((text) => setLog(text));
      engineRef.current = engine;
      setModelLoaded(true);
      setStep("ready");
      setLog("Gemma hazır. Prompt yazıp planla.");
    } catch (e) {
      setStep("error");
      setError(e instanceof Error ? e.message : String(e));
    }
  }

  async function planDay() {
    if (!engineRef.current || !token) return;
    setError(null);
    setPlaces([]);
    setSelected([]);
    setRoute(null);
    try {
      setStep("intent");
      setLog("Gemma intent çıkarıyor...");
      const intent = await parseIntent(engineRef.current, prompt);
      setLog(`Intent: ${JSON.stringify(intent, null, 2)}`);

      setStep("search");
      setLog("Grounded Places aranıyor (API)...");
      const search = await searchPlaces(token, intent);
      setPlaces(search.places);
      setLog(
        `Places: ${search.places.length} sonuç · provider=${search.provider} · cache_hit=${search.cache_hit}`,
      );
      if (search.places.length < 2) {
        throw new Error("Yeterli grounded mekan yok");
      }

      setStep("pick");
      setLog("Gemma listeden durak seçiyor...");
      const indices = await pickStops(
        engineRef.current,
        prompt,
        search.places,
        intent.max_stops,
      );
      const chosen = indices.map((i) => search.places[i]);
      setSelected(chosen);

      setStep("route");
      setLog("Rota oluşturuluyor...");
      const built = await buildRoute(
        token,
        chosen.map((p) => p.place_id),
      );
      setRoute(built);

      setStep("save");
      setLog("Itinerary kaydediliyor...");
      await saveItinerary(token, {
        prompt,
        area: intent.area,
        duration_label: intent.duration_label,
        stops: chosen.map((p, order) => ({
          place_id: p.place_id,
          displayName: p.displayName,
          formattedAddress: p.formattedAddress,
          location: p.location,
          order: order + 1,
          types: p.types,
          googleMapsUri: p.googleMapsUri,
        })),
        overview_polyline: built.overviewPolyline,
        google_maps_url: built.googleMapsUrl,
        distance_meters: built.distanceMeters,
        duration_seconds: built.durationSeconds,
      });

      setStep("done");
      setLog("Plan hazır.");
    } catch (e) {
      setStep("error");
      setError(e instanceof Error ? e.message : String(e));
    }
  }

  const modelReady = step === "ready" || step === "done" || step === "error";
  const busy = ["auth", "loading_model", "intent", "search", "pick", "route", "save"].includes(
    step,
  );

  return (
    <>
      <section className="panel">
        <label htmlFor="prompt">Prompt</label>
        <textarea
          id="prompt"
          value={prompt}
          onChange={(e) => setPrompt(e.target.value)}
          disabled={busy}
        />
        <div className="row">
          <button type="button" onClick={loadModel} disabled={busy || modelLoaded}>
            {modelLoaded ? "Gemma yüklü" : "Gemma 2B yükle"}
          </button>
          <button
            type="button"
            className="secondary"
            onClick={planDay}
            disabled={!modelReady || busy || !prompt.trim()}
          >
            Günü planla
          </button>
        </div>
      </section>

      <section className="panel">
        <div className="status">
          Adım: <strong>{step}</strong>
          {"\n"}
          {log}
        </div>
        {error ? <p className="error">{error}</p> : null}
      </section>

      {places.length > 0 ? (
        <section className="panel">
          <h2>
            Grounded mekanlar
            <span className="badge">API</span>
          </h2>
          <ul className="list">
            {places.map((p) => (
              <li key={p.place_id}>
                <strong>{p.displayName}</strong>
                <div className="status">{p.formattedAddress}</div>
                <div className="status">{p.place_id}</div>
              </li>
            ))}
          </ul>
        </section>
      ) : null}

      {selected.length > 0 ? (
        <section className="panel">
          <h2>
            Seçilen duraklar
            <span className="badge">Gemma</span>
          </h2>
          <ul className="list">
            {selected.map((p, i) => (
              <li key={p.place_id}>
                {i + 1}. {p.displayName}
              </li>
            ))}
          </ul>
        </section>
      ) : null}

      {route ? (
        <section className="panel">
          <h2>
            Rota
            <span className="badge">{route.provider}</span>
          </h2>
          <p className="status">
            {(route.distanceMeters / 1000).toFixed(1)} km · ~
            {Math.round(route.durationSeconds / 60)} dk yürüyüş
          </p>
          <a href={route.googleMapsUrl} target="_blank" rel="noreferrer">
            Google Maps’te aç
          </a>
        </section>
      ) : null}
    </>
  );
}
