import { isPlanStep, PLAN_STEPS, type PlannerStep } from "./types";

type PlanStepperProps = {
  step: PlannerStep;
  modelLoading?: boolean;
  modelProgress?: string | null;
};

export default function PlanStepper({ step, modelLoading, modelProgress }: PlanStepperProps) {
  if (modelLoading) {
    return (
      <div className="border-b border-surface-container-highest bg-surface-container-lowest px-panel-padding py-3">
        <div className="mb-2 flex items-center justify-between font-label-caps text-label-caps text-on-surface-variant">
          <span>Gemma yükleniyor</span>
          <span className="text-primary">WebGPU</span>
        </div>
        <div className="h-1.5 overflow-hidden rounded-full bg-surface-container-high">
          <div className="h-full w-1/3 animate-pulse rounded-full bg-primary" />
        </div>
        {modelProgress ? (
          <p className="mt-2 truncate font-mono-label text-[11px] text-secondary">
            {modelProgress}
          </p>
        ) : null}
      </div>
    );
  }

  if (!isPlanStep(step)) return null;

  const currentIndex = PLAN_STEPS.findIndex((s) => s.id === step);

  return (
    <div className="border-b border-surface-container-highest bg-surface-container-lowest px-panel-padding py-3">
      <div className="flex items-center gap-1">
        {PLAN_STEPS.map((planStep, index) => {
          const done = index < currentIndex;
          const active = index === currentIndex;
          return (
            <div key={planStep.id} className="flex flex-1 flex-col items-center gap-1">
              <div
                className={`flex h-6 w-6 items-center justify-center rounded-full text-[10px] font-bold transition-colors ${
                  done
                    ? "bg-primary text-on-primary"
                    : active
                      ? "border-2 border-primary bg-secondary-container text-primary"
                      : "bg-surface-container-high text-on-surface-variant"
                }`}
              >
                {done ? (
                  <span className="material-symbols-outlined text-[14px]">check</span>
                ) : (
                  index + 1
                )}
              </div>
              <span
                className={`hidden text-center font-label-caps text-[9px] sm:block ${
                  active ? "text-primary" : "text-on-surface-variant"
                }`}
              >
                {planStep.label}
              </span>
            </div>
          );
        })}
      </div>
    </div>
  );
}
