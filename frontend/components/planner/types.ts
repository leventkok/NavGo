export type PlanStep = "intent" | "search" | "pick" | "route" | "save";

export const PLAN_STEPS: { id: PlanStep; label: string }[] = [
  { id: "intent", label: "Intent" },
  { id: "search", label: "Mekanlar" },
  { id: "pick", label: "Duraklar" },
  { id: "route", label: "Rota" },
  { id: "save", label: "Kayıt" },
];

export type PlannerStep =
  | "idle"
  | "auth"
  | "loading_model"
  | "ready"
  | PlanStep
  | "done"
  | "error";

export type ChatMessage = {
  id: number;
  role: "user" | "assistant";
  text: string;
};

export const EXAMPLE_PROMPTS = [
  "Antalya Kaleiçi'nde tüm gün gezmek istiyorum.",
  "İstanbul'da 4 saatlik tarihi tur.",
  "Kapadokya'da gün batımına kadar gezi.",
];

export const DEFAULT_PROMPT =
  "Antalya'ya yeni geldim, Kaleiçi'ni gezmek istiyorum, tüm gün buradayım.";

export function isPlanStep(step: PlannerStep): step is PlanStep {
  return PLAN_STEPS.some((s) => s.id === step);
}

export function formatPlaceType(type: string): string {
  return type.replace(/_/g, " ");
}
