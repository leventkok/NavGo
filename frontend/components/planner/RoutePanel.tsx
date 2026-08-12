import type { Place, RouteResponse } from "@/lib/api";
import RouteMap from "@/components/route/RouteMap";
import { WorldMap } from "@/components/WorldMap";
import StopCard from "./StopCard";

type RoutePanelProps = {
  routeVisible: boolean;
  route: RouteResponse | null;
  selected: Place[];
  routeTitle: string;
  durationLabel: string;
  highlightedStopId: string | null;
  mobileExpanded: boolean;
  onToggleMobile: () => void;
  onStopSelect: (id: string) => void;
};

export default function RoutePanel({
  routeVisible,
  route,
  selected,
  routeTitle,
  durationLabel,
  highlightedStopId,
  mobileExpanded,
  onToggleMobile,
  onStopSelect,
}: RoutePanelProps) {
  const travelPerLeg =
    route && selected.length > 1
      ? Math.round(route.durationSeconds / 60 / (selected.length - 1))
      : null;

  return (
    <section
      className={`bg-surface-dim md:relative md:flex md:h-full md:w-3/5 md:flex-col ${
        routeVisible
          ? "pointer-events-none fixed inset-0 z-30 md:pointer-events-auto md:z-0"
          : "hidden md:flex"
      }`}
    >
      <div className="absolute inset-0 z-0 overflow-hidden">
        {routeVisible && route ? (
          <RouteMap
            polyline={route.overviewPolyline}
            stops={selected}
            highlightedStopId={highlightedStopId}
            className="h-full w-full"
          />
        ) : (
          <div className="h-full w-full bg-inverse-surface">
            <div
              className="absolute inset-0 opacity-20"
              style={{
                backgroundImage: "radial-gradient(rgb(193, 198, 215) 1px, transparent 1px)",
                backgroundSize: "24px 24px",
              }}
            />
            <WorldMap opacity={0.12} />
          </div>
        )}
      </div>

      {!routeVisible ? (
        <div className="absolute inset-0 z-10 flex flex-col items-center justify-center bg-inverse-surface/75 p-8 backdrop-blur-sm">
          <div className="mb-6 flex h-20 w-20 animate-pulse items-center justify-center rounded-full border border-outline-variant bg-surface-container-lowest shadow-lg">
            <span className="material-symbols-outlined text-4xl text-primary">explore</span>
          </div>
          <h3 className="mb-2 font-headline-md text-headline-md text-inverse-on-surface">
            Keşfe hazır mısın?
          </h3>
          <p className="max-w-md text-center font-body-md text-body-md text-outline-variant">
            Rotan burada harita üzerinde görünecek.
          </p>
        </div>
      ) : null}

      {routeVisible && route ? (
        <>
          <div
            className={`pointer-events-auto absolute inset-x-0 bottom-0 z-20 flex flex-col transition-all duration-300 md:inset-4 md:left-auto md:w-[380px] ${
              mobileExpanded ? "top-[30%]" : "top-auto max-h-[40vh]"
            } md:top-4 md:max-h-none`}
          >
            <div className="flex min-h-0 flex-1 flex-col overflow-hidden rounded-t-2xl border border-outline-variant bg-surface-container-lowest/95 shadow-[0_-8px_30px_rgba(0,0,0,0.12)] backdrop-blur-md md:rounded-2xl">
              <button
                type="button"
                onClick={onToggleMobile}
                className="flex w-full flex-col items-center border-b border-surface-container-highest py-2 md:hidden"
              >
                <div className="mb-1 h-1.5 w-12 rounded-full bg-outline-variant" />
              </button>

              <div className="flex shrink-0 items-start justify-between gap-3 p-panel-padding pb-3">
                <div>
                  <h3 className="mb-1 font-headline-md text-headline-md text-on-surface">
                    {routeTitle || "Gün planı"}
                  </h3>
                  <div className="flex flex-wrap items-center gap-2 font-body-sm text-body-sm text-on-surface-variant">
                    <span className="flex items-center gap-1">
                      <span className="material-symbols-outlined text-sm">directions_walk</span>
                      Yürüyüş
                    </span>
                    <span>•</span>
                    <span>{durationLabel || `~${Math.round(route.durationSeconds / 60)} dk`}</span>
                    <span>•</span>
                    <span>{selected.length} durak</span>
                    <span>•</span>
                    <span>{(route.distanceMeters / 1000).toFixed(1)} km</span>
                  </div>
                </div>
                <a
                  href={route.googleMapsUrl}
                  target="_blank"
                  rel="noreferrer"
                  className="flex shrink-0 items-center gap-2 rounded-xl bg-primary px-4 py-2 font-label-caps text-label-caps text-on-primary shadow-sm hover:opacity-90"
                >
                  <span className="material-symbols-outlined text-sm">navigation</span>
                  Başlat
                </a>
              </div>

              <div className="chat-scroll min-h-0 flex-1 overflow-y-auto px-panel-padding pb-panel-padding">
                <div className="relative pl-6">
                  <div className="absolute bottom-8 left-[11px] top-4 w-[2px] bg-primary/40" />
                  {selected.map((stop, index) => (
                    <StopCard
                      key={stop.place_id}
                      stop={stop}
                      index={index}
                      active={highlightedStopId === stop.place_id}
                      travelMinutes={
                        index < selected.length - 1 ? travelPerLeg : null
                      }
                      onSelect={() => onStopSelect(stop.place_id)}
                    />
                  ))}
                </div>
              </div>
            </div>
          </div>
        </>
      ) : null}
    </section>
  );
}
