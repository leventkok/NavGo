import type { AppConfig } from "@mlc-ai/web-llm";
import type { Intent, Place } from "./api";

export const GEMMA_MODEL_ID = "gemma-2-2b-it-q4f16_1-MLC";
export const FALLBACK_MODEL_ID = "gemma3-1b-it-q4f16_1-MLC";

const CACHE_BACKENDS = ["opfs", "indexeddb", "cache"] as const;
const MODEL_CANDIDATES = [GEMMA_MODEL_ID, FALLBACK_MODEL_ID];

export type ChatEngine = {
  chat: {
    completions: {
      create: (args: {
        messages: Array<{ role: "system" | "user" | "assistant"; content: string }>;
        temperature?: number;
        max_tokens?: number;
      }) => Promise<{ choices: Array<{ message?: { content?: string } }> }>;
    };
  };
  unload: () => Promise<void>;
};

export type GemmaLoadResult = {
  engine: ChatEngine;
  modelId: string;
};

function buildAppConfig(
  prebuiltAppConfig: AppConfig,
  backend: (typeof CACHE_BACKENDS)[number],
): AppConfig {
  return { ...prebuiltAppConfig, cacheBackend: backend };
}

function isModelCacheError(err: unknown): boolean {
  const msg = err instanceof Error ? err.message : String(err);
  return /cache\.add|network error|cannot fetch|failed to fetch|unable to fetch/i.test(msg);
}

function modelLoadHelp(err: unknown): string {
  const detail = err instanceof Error ? err.message : String(err);
  return [
    detail,
    "",
    "Olası nedenler:",
    "• HuggingFace indirmesi engellenmiş olabilir (VPN, kurumsal ağ, DNS)",
    "• Yetersiz disk alanı (~3GB+ boş alan gerekir)",
    "• WebGPU desteklemeyen tarayıcı (Chrome/Edge önerilir)",
    "",
    "Deneyin:",
    "• Chrome kullanın, VPN kapatın",
    "• DevTools → Application → Storage → Clear site data",
    "• Tekrar «Önbelleği temizle ve tekrar dene»",
  ].join("\n");
}

async function loadEngine(
  modelId: string,
  appConfig: AppConfig,
  onProgress?: (text: string) => void,
): Promise<ChatEngine> {
  const { CreateMLCEngine } = await import("@mlc-ai/web-llm");
  return (await CreateMLCEngine(modelId, {
    initProgressCallback: (report: { text: string }) => onProgress?.(report.text),
    appConfig,
  })) as ChatEngine;
}

export async function clearGemmaCache(modelIds: string[] = MODEL_CANDIDATES): Promise<void> {
  const { deleteModelInCache, prebuiltAppConfig } = await import("@mlc-ai/web-llm");
  for (const modelId of modelIds) {
    for (const backend of CACHE_BACKENDS) {
      await deleteModelInCache(modelId, buildAppConfig(prebuiltAppConfig, backend));
    }
  }
}

export async function createGemmaEngine(
  onProgress?: (text: string) => void,
): Promise<GemmaLoadResult> {
  const { prebuiltAppConfig } = await import("@mlc-ai/web-llm");
  let lastErr: unknown;

  for (const modelId of MODEL_CANDIDATES) {
    if (modelId !== GEMMA_MODEL_ID) {
      onProgress?.(
        `Gemma 2B yüklenemedi — daha küçük model deneniyor: ${modelId} (~700MB)`,
      );
    }

    for (const backend of CACHE_BACKENDS) {
      const appConfig = buildAppConfig(prebuiltAppConfig, backend);
      try {
        onProgress?.(`Önbellek: ${backend} · model: ${modelId}`);
        const engine = await loadEngine(modelId, appConfig, onProgress);
        return { engine, modelId };
      } catch (err) {
        lastErr = err;
        if (!isModelCacheError(err)) {
          throw new Error(modelLoadHelp(err));
        }
        onProgress?.(`${backend} indirmesi başarısız, sonraki yöntem deneniyor...`);
      }
    }
  }

  throw new Error(modelLoadHelp(lastErr));
}

function extractJson(text: string): unknown {
  const fenced = text.match(/```(?:json)?\s*([\s\S]*?)```/i);
  const raw = fenced?.[1]?.trim() || text.trim();
  const start = raw.indexOf("{");
  const end = raw.lastIndexOf("}");
  if (start === -1 || end === -1) throw new Error("Gemma JSON döndürmedi");
  return JSON.parse(raw.slice(start, end + 1));
}

export async function parseIntent(engine: ChatEngine, prompt: string): Promise<Intent> {
  const completion = await engine.chat.completions.create({
    temperature: 0.2,
    max_tokens: 256,
    messages: [
      {
        role: "system",
        content:
          "Sen NavGo seyahat asistanısın. Kullanıcı Türkçe prompt verir. SADECE geçerli JSON döndür, başka metin yok. Şema: {\"area\":\"string\",\"query\":\"string\",\"duration_label\":\"string\",\"max_stops\":number}. place_id, lat, lng UYDURMA. area bölge (ör. Kaleiçi Antalya). query arama ifadesi. max_stops 3-6 arası.",
      },
      { role: "user", content: prompt },
    ],
  });
  const content = completion.choices[0]?.message?.content ?? "";
  const parsed = extractJson(content) as Partial<Intent>;
  return {
    area: parsed.area || "Antalya",
    query: parsed.query || parsed.area || prompt,
    duration_label: parsed.duration_label || "1 gün",
    max_stops: Math.min(6, Math.max(3, Number(parsed.max_stops) || 5)),
  };
}

export async function pickStops(
  engine: ChatEngine,
  prompt: string,
  places: Place[],
  maxStops: number,
): Promise<number[]> {
  const catalog = places
    .map((p, i) => `${i}. ${p.displayName} — ${p.formattedAddress}`)
    .join("\n");
  const completion = await engine.chat.completions.create({
    temperature: 0.2,
    max_tokens: 128,
    messages: [
      {
        role: "system",
        content:
          "Verilen numaralı mekan listesinden gün planı için indeks seç. SADECE JSON: {\"indices\":[number,...]}. Listede olmayan numara kullanma. place_id uydurma.",
      },
      {
        role: "user",
        content: `Prompt: ${prompt}\nMax: ${maxStops}\nMekanlar:\n${catalog}`,
      },
    ],
  });
  const content = completion.choices[0]?.message?.content ?? "";
  try {
    const parsed = extractJson(content) as { indices?: number[] };
    const indices = (parsed.indices || [])
      .map((n) => Number(n))
      .filter((n) => Number.isInteger(n) && n >= 0 && n < places.length);
    const unique = [...new Set(indices)].slice(0, maxStops);
    if (unique.length >= 2) return unique;
  } catch {
    // fall through
  }
  return places.slice(0, maxStops).map((_, i) => i);
}
