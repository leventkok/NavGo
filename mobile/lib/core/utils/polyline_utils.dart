import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:google_polyline_algorithm/google_polyline_algorithm.dart'
    as poly;

List<LatLng> decodeRoutePolyline(String encoded) {
  if (encoded.trim().isEmpty) return const [];
  try {
    final points = poly.decodePolyline(encoded, accuracyExponent: 5);
    return points
        .map((p) => LatLng(p[0].toDouble(), p[1].toDouble()))
        .toList(growable: false);
  } catch (_) {
    return const [];
  }
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
    return [points.last];
  }
  return points.sublist(bestIdx);
}

double mathMin(double a, double b) => a < b ? a : b;
double mathMax(double a, double b) => a > b ? a : b;
