"use client";

import dynamic from "next/dynamic";
import type { Place } from "@/lib/api";

const RouteMapInner = dynamic(() => import("./RouteMapInner"), {
  ssr: false,
  loading: () => (
    <div className="flex h-full w-full items-center justify-center bg-surface-container-low">
      <div className="dot-flashing" />
    </div>
  ),
});

type RouteMapProps = {
  polyline: string;
  stops: Place[];
  highlightedStopId?: string | null;
  className?: string;
};

export default function RouteMap(props: RouteMapProps) {
  return <RouteMapInner {...props} />;
}
