import 'dart:math' as math;

import 'package:navgo_mobile/core/models/place_model.dart';

double haversineMeters(double lat1, double lon1, double lat2, double lon2) {
  const r = 6371000.0;
  final p1 = lat1 * math.pi / 180;
  final p2 = lat2 * math.pi / 180;
  final dp = (lat2 - lat1) * math.pi / 180;
  final dl = (lon2 - lon1) * math.pi / 180;
  final a = math.sin(dp / 2) * math.sin(dp / 2) +
      math.cos(p1) * math.cos(p2) * math.sin(dl / 2) * math.sin(dl / 2);
  return r * 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
}

/// Nearest-neighbor ordering from the user's current position.
List<PlaceModel> orderStopsFromUser({
  required double userLat,
  required double userLng,
  required List<PlaceModel> stops,
}) {
  if (stops.length <= 1) return List<PlaceModel>.from(stops);
  final remaining = List<PlaceModel>.from(stops);
  final ordered = <PlaceModel>[];
  var lat = userLat;
  var lng = userLng;
  while (remaining.isNotEmpty) {
    var bestIdx = 0;
    var bestDist = double.infinity;
    for (var i = 0; i < remaining.length; i++) {
      final s = remaining[i];
      final d = haversineMeters(lat, lng, s.latitude, s.longitude);
      if (d < bestDist) {
        bestDist = d;
        bestIdx = i;
      }
    }
    final pick = remaining.removeAt(bestIdx);
    ordered.add(pick);
    lat = pick.latitude;
    lng = pick.longitude;
  }
  return ordered;
}

/// Greedy compact cluster: seed nearest to the user, then keep adding the
/// closest remaining place that stays within [maxRadiusM] of the seed.
List<PlaceModel> compactClusterNearUser({
  required double userLat,
  required double userLng,
  required List<PlaceModel> candidates,
  required int maxStops,
  double maxRadiusM = 2500,
}) {
  if (candidates.isEmpty) return const [];
  final cap = maxStops.clamp(1, candidates.length);
  final remaining = List<PlaceModel>.from(candidates);
  var seedIdx = 0;
  var seedDist = double.infinity;
  for (var i = 0; i < remaining.length; i++) {
    final d = haversineMeters(
      userLat,
      userLng,
      remaining[i].latitude,
      remaining[i].longitude,
    );
    if (d < seedDist) {
      seedDist = d;
      seedIdx = i;
    }
  }
  final seed = remaining.removeAt(seedIdx);
  final cluster = <PlaceModel>[seed];
  while (cluster.length < cap && remaining.isNotEmpty) {
    var bestIdx = -1;
    var bestDist = double.infinity;
    for (var i = 0; i < remaining.length; i++) {
      final fromSeed = haversineMeters(
        seed.latitude,
        seed.longitude,
        remaining[i].latitude,
        remaining[i].longitude,
      );
      if (fromSeed > maxRadiusM) continue;
      final last = cluster.last;
      final d = haversineMeters(
        last.latitude,
        last.longitude,
        remaining[i].latitude,
        remaining[i].longitude,
      );
      if (d < bestDist) {
        bestDist = d;
        bestIdx = i;
      }
    }
    if (bestIdx < 0) break;
    cluster.add(remaining.removeAt(bestIdx));
  }
  if (cluster.length < 2 && candidates.length >= 2) {
    return orderStopsFromUser(
      userLat: userLat,
      userLng: userLng,
      stops: candidates.take(cap).toList(),
    );
  }
  return orderStopsFromUser(
    userLat: userLat,
    userLng: userLng,
    stops: cluster,
  );
}
