import { WORLD_MAP_PATH } from "@/lib/worldmap-data";

export function WorldMapDefs() {
  return (
    <svg width="0" height="0" style={{ position: "absolute" }} aria-hidden="true">
      <defs>
        <path id="world-map-path" d={WORLD_MAP_PATH} />
      </defs>
    </svg>
  );
}

export function WorldMap({ opacity = 0.08 }: { opacity?: number }) {
  return (
    <div className="h-full w-full" style={{ opacity }}>
      <svg
        viewBox="0 0 1000 1000"
        preserveAspectRatio="xMidYMid slice"
        className="h-full w-full"
      >
        <g transform="translate(90.2,23.3) scale(0.9693)" fill="#414755">
          <use href="#world-map-path" />
        </g>
      </svg>
    </div>
  );
}
