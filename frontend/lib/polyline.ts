import type { Place } from "./api";

/** Google encoded polyline → [lat, lng][] */
export function decodePolyline(encoded: string): [number, number][] {
  if (encoded.startsWith("mock_poly_")) {
    return parseMockPolyline(encoded);
  }

  const points: [number, number][] = [];
  let index = 0;
  let lat = 0;
  let lng = 0;

  while (index < encoded.length) {
    let shift = 0;
    let result = 0;
    let byte: number;
    do {
      byte = encoded.charCodeAt(index++) - 63;
      result |= (byte & 0x1f) << shift;
      shift += 5;
    } while (byte >= 0x20);
    const deltaLat = result & 1 ? ~(result >> 1) : result >> 1;
    lat += deltaLat;

    shift = 0;
    result = 0;
    do {
      byte = encoded.charCodeAt(index++) - 63;
      result |= (byte & 0x1f) << shift;
      shift += 5;
    } while (byte >= 0x20);
    const deltaLng = result & 1 ? ~(result >> 1) : result >> 1;
    lng += deltaLng;

    points.push([lat / 1e5, lng / 1e5]);
  }

  return points;
}

function parseMockPolyline(encoded: string): [number, number][] {
  const raw = encoded.replace("mock_poly_", "");
  const parts = raw.split("_").map(Number);
  if (parts.length >= 4 && parts.every((n) => !Number.isNaN(n))) {
    return [
      [parts[0], parts[1]],
      [parts[2], parts[3]],
    ];
  }
  return [];
}

export function pathFromStops(stops: Place[]): [number, number][] {
  return stops.map((s) => [s.location.latitude, s.location.longitude]);
}

export function resolveRoutePath(polyline: string, stops: Place[]): [number, number][] {
  const decoded = decodePolyline(polyline);
  if (decoded.length >= 2) return decoded;
  return pathFromStops(stops);
}
