import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:google_polyline_algorithm/google_polyline_algorithm.dart'
    as poly;

List<LatLng> decodeRoutePolyline(String encoded) {
  if (encoded.trim().isEmpty) return const [];
  try {
    final points = poly.decodePolyline(encoded, accuracyExponent: 5);
    return [
      for (final p in points) LatLng(p[0].toDouble(), p[1].toDouble()),
    ];
  } catch (_) {
    return const [];
  }
}

/// Collects a drawable path from overview, legs, then steps.
List<LatLng> collectRoutePolylinePoints({
  required String overviewPolyline,
  required List<String> encodedFallbacks,
}) {
  final overview = decodeRoutePolyline(overviewPolyline);
  if (overview.length >= 2) return overview;
  for (final encoded in encodedFallbacks) {
    final pts = decodeRoutePolyline(encoded);
    if (pts.length >= 2) return pts;
  }
  return overview.length >= 2 ? overview : const [];
}

LatLngBounds? boundsForPoints(List<LatLng> points) {
  if (points.isEmpty) return null;
  var minLat = points.first.latitude;
  var maxLat = points.first.latitude;
  var minLng = points.first.longitude;
  var maxLng = points.first.longitude;
  for (final p in points) {
    minLat = mathMin(minLat, p.latitude);
    maxLat = mathMax(maxLat, p.latitude);
    minLng = mathMin(minLng, p.longitude);
    maxLng = mathMax(maxLng, p.longitude);
  }
  return LatLngBounds(
    southwest: LatLng(minLat, minLng),
    northeast: LatLng(maxLat, maxLng),
  );
}

List<LatLng> remainingPolylineAhead(List<LatLng> points, LatLng user) {
  if (points.length < 2) return points;
  var bestIdx = 0;
  var bestDist = double.infinity;
  for (var i = 0; i < points.length; i++) {
    final d = (points[i].latitude - user.latitude) *
            (points[i].latitude - user.latitude) +
        (points[i].longitude - user.longitude) *
            (points[i].longitude - user.longitude);
    if (d < bestDist) {
      bestDist = d;
      bestIdx = i;
    }
  }
  if (bestIdx >= points.length - 1) {
    return points.sublist(points.length - 2);
  }
  return points.sublist(bestIdx);
}

List<LatLng> fallbackStraightPath(LatLng from, LatLng to) {
  if ((from.latitude - to.latitude).abs() < 1e-7 &&
      (from.longitude - to.longitude).abs() < 1e-7) {
    return const [];
  }
  return [from, to];
}

double mathMin(double a, double b) => a < b ? a : b;
double mathMax(double a, double b) => a > b ? a : b;
