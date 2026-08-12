import type { Place } from "@/lib/api";
import { formatPlaceType } from "./types";

type StopCardProps = {
  stop: Place;
  index: number;
  active?: boolean;
  travelMinutes?: number | null;
  onSelect?: () => void;
};

export default function StopCard({
  stop,
  index,
  active,
  travelMinutes,
  onSelect,
}: StopCardProps) {
  const primaryType = stop.types?.[0];
  const showMustSee = index === 1 && (stop.rating ?? 0) >= 4.5;

  return (
    <div className="relative mb-8">
      <div
        className={`absolute -left-6 top-1 z-10 flex h-6 w-6 items-center justify-center rounded-full font-label-caps text-[10px] ${
          index === 0
            ? "border-4 border-surface-container-lowest bg-primary text-on-primary"
            : active
              ? "border-2 border-tertiary bg-tertiary text-on-primary"
              : "border-2 border-primary bg-surface-container-highest text-on-surface"
        }`}
      >
        {index + 1}
      </div>
      <button
        type="button"
        onClick={onSelect}
        className={`w-full rounded-xl border bg-surface p-4 text-left shadow-sm transition-all hover:shadow-md ${
          active ? "border-tertiary ring-1 ring-tertiary/30" : "border-outline-variant hover:border-primary"
        }`}
      >
        <h4 className="mb-1 text-lg font-headline-lg-mobile text-headline-lg-mobile text-on-surface">
          {stop.displayName}
        </h4>
        <p className="mb-3 font-body-sm text-body-sm text-on-surface-variant">
          {stop.formattedAddress}
        </p>
        <div className="flex flex-wrap gap-2">
          {stop.rating != null ? (
            <span className="flex items-center gap-1 rounded-md bg-surface-container-high px-2 py-1 font-label-caps text-[10px] text-on-surface">
              <span className="material-symbols-outlined filled-icon text-[12px] text-tertiary">
                star
              </span>
              {stop.rating.toFixed(1)}
            </span>
          ) : null}
          {primaryType ? (
            <span className="rounded-md bg-secondary-container/60 px-2 py-1 font-label-caps text-[10px] text-on-secondary-container">
              {formatPlaceType(primaryType)}
            </span>
          ) : null}
          {showMustSee ? (
            <span className="rounded-md bg-tertiary-container/10 px-2 py-1 font-label-caps text-[10px] text-tertiary">
              Must See
            </span>
          ) : null}
        </div>
      </button>
      {travelMinutes != null ? (
        <div className="mb-1 ml-4 mt-3 flex items-center gap-2 font-mono-label text-mono-label text-secondary">
          <span className="material-symbols-outlined text-sm">directions_walk</span>
          {travelMinutes} dk yürüyüş
        </div>
      ) : null}
    </div>
  );
}
