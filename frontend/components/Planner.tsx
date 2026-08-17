"use client";

import { useEffect, useRef, useState } from "react";
import {
  buildRoute,
  ensureSession,
  type Place,
  type RouteResponse,
  saveItinerary,
  searchPlaces,
} from "@/lib/api";
import {
  clearGemmaCache,
  createGemmaEngine,
  GEMMA_MODEL_ID,
  parseIntent,
  pickStops,
  type ChatEngine,
} from "@/lib/gemma";
import { WorldMapDefs } from "@/components/WorldMap";
import PlanStepper from "./planner/PlanStepper";
import PromptChips from "./planner/PromptChips";
import ModelStatus from "./planner/ModelStatus";
import RoutePanel from "./planner/RoutePanel";
import {
  DEFAULT_PROMPT,
  EXAMPLE_PROMPTS,
  type ChatMessage,
  type PlannerStep,
} from "./planner/types";

export default function Planner() {
  const [messages, setMessages] = useState<ChatMessage[]>([]);
  const [input, setInput] = useState("");
  const [step, setStep] = useState<PlannerStep>("idle");
  const [error, setError] = useState<string | null>(null);
  const [selected, setSelected] = useState<Place[]>([]);
  const [route, setRoute] = useState<RouteResponse | null>(null);
  const [routeTitle, setRouteTitle] = useState("");
  const [durationLabel, setDurationLabel] = useState("");
  const [token, setToken] = useState<string | null>(null);
  const [modelLoaded, setModelLoaded] = useState(false);
  const [loadedModelId, setLoadedModelId] = useState<string | null>(null);
  const [modelProgress, setModelProgress] = useState<string | null>(null);
  const [highlightedStopId, setHighlightedStopId] = useState<string | null>(null);
  const [mobileRouteExpanded, setMobileRouteExpanded] = useState(true);
  const engineRef = useRef<ChatEngine | null>(null);
  const chatHistoryRef = useRef<HTMLDivElement>(null);
  const textareaRef = useRef<HTMLTextAreaElement>(null);

  const modelLoading = step === "loading_model" || step === "auth";
  const busy = modelLoading || ["intent", "search", "pick", "route", "save"].includes(step);
  const routeVisible = selected.length > 0 && route !== null;
  const modelReady = modelLoaded && !!token;

  useEffect(() => {
    return () => {
      void engineRef.current?.unload();
    };
  }, []);

  useEffect(() => {
    if (chatHistoryRef.current) {
      chatHistoryRef.current.scrollTop = chatHistoryRef.current.scrollHeight;
    }
  }, [messages, busy]);

  useEffect(() => {
    if (routeVisible) setMobileRouteExpanded(true);
  }, [routeVisible]);

  function pushMessage(role: ChatMessage["role"], text: string) {
    setMessages((prev) => [...prev, { id: Date.now() + Math.random(), role, text }]);
  }

  async function loadModel(clearCacheFirst = false): Promise<string | null> {
    setError(null);
    setStep("auth");
    try {
      const t = await ensureSession();
      setToken(t);
      if (clearCacheFirst) await clearGemmaCache();
      setStep("loading_model");
      setModelProgress("Model indiriliyor…");
      const { engine, modelId } = await createGemmaEngine((text) => setModelProgress(text));
      setModelProgress(null);
      engineRef.current = engine;
      setLoadedModelId(modelId);
      setModelLoaded(true);
      setStep("ready");
      pushMessage(
        "assistant",
        modelId === GEMMA_MODEL_ID
          ? "Gemma hazır. Nereye gitmek istediğini yaz veya örneklerden birini seç."
          : `${modelId} yüklendi. Planlamaya başlayabilirsin.`,
      );
      return t;
    } catch (e) {
      setStep("error");
      const msg = e instanceof Error ? e.message : String(e);
      setError(msg);
      pushMessage("assistant", msg);
      return null;
    }
  }

  async function planDay(promptText: string, authToken: string) {
    if (!engineRef.current) return;
    setError(null);
    setSelected([]);
    setRoute(null);
    setHighlightedStopId(null);
    try {
      setStep("intent");
      const intent = await parseIntent(engineRef.current, promptText);
      setRouteTitle(intent.area || "Gün planı");
      setDurationLabel(intent.duration_label || "1 gün");

      setStep("search");
      const search = await searchPlaces(authToken, intent);
      if (search.places.length < 2) throw new Error("Yeterli grounded mekan yok");

      setStep("pick");
      const indices = await pickStops(
        engineRef.current,
        promptText,
        search.places,
        intent.max_stops,
      );
      const chosen = indices.map((i) => search.places[i]);
      setSelected(chosen);

      setStep("route");
      const built = await buildRoute(
        authToken,
        chosen.map((p) => p.place_id),
      );
      setRoute(built);

      setStep("save");
      await saveItinerary(authToken, {
        prompt: promptText,
        area: intent.area,
        duration_label: intent.duration_label,
        model: loadedModelId ?? GEMMA_MODEL_ID,
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
      pushMessage(
        "assistant",
        `${chosen.length} duraklı rota hazır. Haritada rotayı görebilir, duraklara tıklayarak vurgulayabilirsin.`,
      );
    } catch (e) {
      setStep("error");
      const msg = e instanceof Error ? e.message : String(e);
      setError(msg);
      pushMessage("assistant", msg);
    }
  }

  async function handleSubmit(e: React.FormEvent) {
    e.preventDefault();
    const text = input.trim() || DEFAULT_PROMPT;
    if (busy) return;

    setInput("");
    if (textareaRef.current) textareaRef.current.style.height = "auto";
    pushMessage("user", text);

    let authToken = token;
    if (!modelReady) authToken = await loadModel();
    if (!authToken || !engineRef.current) return;

    await planDay(text, authToken);
  }

  function handleKeyDown(e: React.KeyboardEvent<HTMLTextAreaElement>) {
    if (e.key === "Enter" && !e.shiftKey) {
      e.preventDefault();
      if (!busy) void handleSubmit(e as unknown as React.FormEvent);
    }
  }

  function handleInputChange(e: React.ChangeEvent<HTMLTextAreaElement>) {
    setInput(e.target.value);
    e.target.style.height = "auto";
    e.target.style.height = `${e.target.scrollHeight}px`;
  }

  return (
    <div className="flex h-full w-full flex-col overflow-hidden md:flex-row">
      <WorldMapDefs />

      <header className="z-10 flex h-16 shrink-0 items-center justify-between border-b border-outline-variant bg-surface px-margin-mobile md:hidden">
        <div className="flex items-center gap-2 font-headline-md text-headline-md font-bold text-primary">
          <span className="material-symbols-outlined filled-icon">navigation</span>
          NavGo
        </div>
        <ModelStatus loaded={modelLoaded} loading={modelLoading} modelId={loadedModelId} />
      </header>

      <nav className="z-10 hidden h-full w-[68px] shrink-0 flex-col items-center border-r border-outline-variant bg-surface-container-lowest py-5 md:flex">
        <div className="mb-4 flex h-9 w-9 items-center justify-center rounded-lg bg-secondary-container">
          <span className="font-headline-md text-[15px] font-bold text-primary">N</span>
        </div>
        <a
          href="#"
          title="Planner"
          className="mb-1 flex h-10 w-10 items-center justify-center rounded-lg border-l-2 border-primary bg-secondary-container"
        >
          <span className="material-symbols-outlined filled-icon text-[20px] text-primary">map</span>
        </a>
        <div className="flex-1" />
        <div className="flex flex-col items-center gap-2 pb-1">
          <button
            type="button"
            className="relative flex h-10 w-10 items-center justify-center rounded-lg bg-primary text-on-primary transition-opacity hover:opacity-90 disabled:opacity-50"
            title={modelLoaded ? "Gemma yüklü" : "Gemma 2B yükle"}
            onClick={() => void loadModel()}
            disabled={busy || modelLoaded}
          >
            <span className="material-symbols-outlined filled-icon text-[20px]">
              {modelLoaded ? "check" : "add"}
            </span>
            {modelLoading ? (
              <span className="absolute -right-0.5 -top-0.5 h-2.5 w-2.5 animate-pulse rounded-full border-2 border-surface-container-lowest bg-tertiary" />
            ) : modelLoaded ? (
              <span className="absolute -right-0.5 -top-0.5 h-2.5 w-2.5 rounded-full border-2 border-surface-container-lowest bg-primary" />
            ) : null}
          </button>
          {step === "error" && !modelLoaded ? (
            <button
              type="button"
              className="flex h-10 w-10 items-center justify-center rounded-lg text-on-surface-variant hover:bg-surface-container-high"
              title="Önbelleği temizle"
              onClick={() => void loadModel(true)}
              disabled={busy}
            >
              <span className="material-symbols-outlined text-[20px]">refresh</span>
            </button>
          ) : null}
        </div>
      </nav>

      <main className="relative flex min-h-0 flex-1 flex-col md:flex-row">
        <section className="relative z-10 flex min-h-0 flex-1 flex-col bg-surface md:h-full md:w-2/5 md:shrink-0 md:border-r md:border-outline-variant md:shadow-[4px_0_24px_rgba(0,0,0,0.02)]">
          <div className="flex shrink-0 items-center justify-between border-b border-surface-container-highest bg-surface-container-lowest px-panel-padding py-4">
            <div>
              <h2 className="font-headline-md text-headline-md text-on-surface">NavGo</h2>
              <div className="hidden md:block">
                <ModelStatus loaded={modelLoaded} loading={modelLoading} modelId={loadedModelId} />
              </div>
            </div>
          </div>

          <PlanStepper step={step} modelLoading={modelLoading} modelProgress={modelProgress} />

          {!modelLoaded && !modelLoading ? (
            <div className="border-b border-tertiary/20 bg-tertiary-container/5 px-panel-padding py-2 font-body-sm text-body-sm text-on-surface-variant">
              Gemma yüklemek için sol alttaki <strong>+</strong> butonuna bas (~1GB, Chrome
              önerilir).
            </div>
          ) : null}

          <div
            ref={chatHistoryRef}
            className="chat-scroll flex min-h-0 flex-1 flex-col gap-6 overflow-y-auto bg-surface-bright p-panel-padding"
          >
            <div className="flex gap-4">
              <div className="mt-1 flex h-8 w-8 shrink-0 items-center justify-center rounded-full bg-primary text-[13px] font-bold text-on-primary">
                N
              </div>
              <div className="flex max-w-[85%] flex-col gap-1">
                <span className="font-label-caps text-label-caps text-on-surface-variant">
                  NavGo
                </span>
                <div className="border-l-2 border-primary py-0.5 pl-3 font-body-md text-body-md text-on-surface">
                  Neredesin ve ne görmek istersin? Aşağıdaki örneklerden birini seçebilir veya
                  kendi cümleni yazabilirsin.
                </div>
              </div>
            </div>

            {messages.map((msg) =>
              msg.role === "user" ? (
                <div key={msg.id} className="flex flex-row-reverse gap-4">
                  <div className="mt-1 flex h-8 w-8 shrink-0 items-center justify-center rounded-full bg-surface-container-high text-on-surface-variant">
                    <span className="material-symbols-outlined text-sm">person</span>
                  </div>
                  <div className="flex max-w-[85%] flex-col items-end gap-1">
                    <span className="font-label-caps text-label-caps text-on-surface-variant">
                      Sen
                    </span>
                    <div className="border-r-2 border-tertiary py-0.5 pr-3 text-right font-body-md text-body-md text-on-surface">
                      {msg.text}
                    </div>
                  </div>
                </div>
              ) : (
                <div key={msg.id} className="flex gap-4">
                  <div className="mt-1 flex h-8 w-8 shrink-0 items-center justify-center rounded-full bg-primary text-[13px] font-bold text-on-primary">
                    N
                  </div>
                  <div className="flex max-w-[85%] flex-col gap-1">
                    <span className="font-label-caps text-label-caps text-on-surface-variant">
                      NavGo
                    </span>
                    <div className="border-l-2 border-primary py-0.5 pl-3 font-body-md text-body-md text-on-surface">
                      {msg.text}
                    </div>
                  </div>
                </div>
              ),
            )}

            {busy ? (
              <div className="flex gap-4">
                <div className="mt-1 flex h-8 w-8 shrink-0 items-center justify-center rounded-full bg-primary text-[13px] font-bold text-on-primary">
                  N
                </div>
                <div className="flex items-center border-l-2 border-primary py-2 pl-3">
                  <div className="dot-flashing" />
                </div>
              </div>
            ) : null}

            {error ? (
              <p className="rounded-lg border border-error/20 bg-error-container/30 p-3 font-body-sm text-body-sm text-error">
                {error}
              </p>
            ) : null}
          </div>

          <div className="shrink-0 border-t border-outline-variant bg-surface-container-lowest p-4">
            <PromptChips
              prompts={EXAMPLE_PROMPTS}
              disabled={busy}
              onSelect={(p) => setInput(p)}
            />
            <form
              onSubmit={(e) => void handleSubmit(e)}
              className="flex items-end gap-2 rounded-xl border border-outline-variant bg-surface-container-low p-2 transition-all focus-within:border-primary focus-within:ring-1 focus-within:ring-primary"
            >
              <textarea
                ref={textareaRef}
                value={input}
                onChange={handleInputChange}
                onKeyDown={handleKeyDown}
                placeholder={modelReady ? "Nereye gitmek istersin?" : "Önce + ile Gemma yükle…"}
                rows={1}
                disabled={busy}
                style={{ minHeight: "48px", maxHeight: "120px" }}
                className="w-full resize-none border-none bg-transparent py-3 font-body-md text-body-md placeholder:text-on-surface-variant focus:ring-0"
              />
              <button
                type="submit"
                disabled={busy}
                className="mb-1 flex h-10 w-10 shrink-0 items-center justify-center rounded-full bg-primary text-on-primary hover:opacity-90 disabled:opacity-50"
              >
                <span className="material-symbols-outlined filled-icon">send</span>
              </button>
            </form>
          </div>
        </section>

        <RoutePanel
          routeVisible={routeVisible}
          route={route}
          selected={selected}
          routeTitle={routeTitle}
          durationLabel={durationLabel}
          highlightedStopId={highlightedStopId}
          mobileExpanded={mobileRouteExpanded}
          onToggleMobile={() => setMobileRouteExpanded((v) => !v)}
          onStopSelect={setHighlightedStopId}
        />
      </main>
    </div>
  );
}
