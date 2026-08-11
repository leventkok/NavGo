"use client";

import { useEffect, useRef } from "react";
import type { Place } from "@/lib/api";
import { resolveRoutePath } from "@/lib/polyline";

type RouteMapProps = {
  polyline: string;
  stops: Place[];
  highlightedStopId?: string | null;
  className?: string;
};

export default function RouteMapInner({
  polyline,
  stops,
  highlightedStopId,
  className = "",
}: RouteMapProps) {
  const containerRef = useRef<HTMLDivElement>(null);
  const mapRef = useRef<import("leaflet").Map | null>(null);

  useEffect(() => {
    if (!containerRef.current || stops.length === 0) return;

    let cancelled = false;

    void (async () => {
      const L = (await import("leaflet")).default;

      if (cancelled || !containerRef.current) return;

      if (mapRef.current) {
        mapRef.current.remove();
        mapRef.current = null;
      }

      const path = resolveRoutePath(polyline, stops);
      const map = L.map(containerRef.current, {
        zoomControl: true,
        attributionControl: true,
      });
      mapRef.current = map;

      L.tileLayer("https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png", {
        attribution: '&copy; <a href="https://www.openstreetmap.org/copyright">OSM</a>',
        maxZoom: 19,
      }).addTo(map);

      const routeLine = L.polyline(path, {
        color: "#0058bc",
        weight: 4,
        opacity: 0.85,
        lineJoin: "round",
      }).addTo(map);

      stops.forEach((stop, index) => {
        const isHighlight = highlightedStopId === stop.place_id;
        const icon = L.divIcon({
          className: "",
          html: `<div style="
            width:28px;height:28px;border-radius:50%;
            background:${isHighlight ? "#9e3d00" : "#0058bc"};
            color:#fff;font-size:12px;font-weight:700;
            display:flex;align-items:center;justify-content:center;
            border:3px solid #fff;box-shadow:0 2px 8px rgba(0,0,0,0.25);
          ">${index + 1}</div>`,
          iconSize: [28, 28],
          iconAnchor: [14, 14],
        });
        L.marker([stop.location.latitude, stop.location.longitude], { icon }).addTo(map);
      });

      const bounds = routeLine.getBounds();
      if (bounds.isValid()) {
        map.fitBounds(bounds.pad(0.2));
      } else if (stops[0]) {
        map.setView([stops[0].location.latitude, stops[0].location.longitude], 14);
      }
    })();

    return () => {
      cancelled = true;
      if (mapRef.current) {
        mapRef.current.remove();
        mapRef.current = null;
      }
    };
  }, [polyline, stops, highlightedStopId]);

  return (
    <div
      ref={containerRef}
      className={`h-full w-full ${className}`}
      aria-label="Rota haritası"
    />
  );
}
