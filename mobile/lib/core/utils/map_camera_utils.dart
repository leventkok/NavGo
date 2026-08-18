import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:navgo_mobile/core/utils/polyline_utils.dart';

/// iOS rejects [CameraUpdate.newLatLngBounds] on degenerate or tiny bounds.
LatLngBounds expandBounds(LatLngBounds bounds, {double minDelta = 0.002}) {
  var sw = bounds.southwest;
  var ne = bounds.northeast;
  if ((ne.latitude - sw.latitude).abs() < minDelta) {
    final mid = (ne.latitude + sw.latitude) / 2;
    sw = LatLng(mid - minDelta / 2, sw.longitude);
    ne = LatLng(mid + minDelta / 2, ne.longitude);
  }
  if ((ne.longitude - sw.longitude).abs() < minDelta) {
    final mid = (ne.longitude + sw.longitude) / 2;
    sw = LatLng(sw.latitude, mid - minDelta / 2);
    ne = LatLng(ne.latitude, mid + minDelta / 2);
  }
  return LatLngBounds(southwest: sw, northeast: ne);
}

Future<void> animateMapCamera(
  GoogleMapController controller,
  CameraUpdate update, {
  Duration iosDelay = const Duration(milliseconds: 250),
}) async {
  if (defaultTargetPlatform == TargetPlatform.iOS) {
    await Future<void>.delayed(iosDelay);
  }
  try {
    await controller.animateCamera(update);
  } catch (_) {
    // iOS can throw if the map view is not laid out yet.
  }
}

Future<void> fitMapToPoints(
  GoogleMapController controller,
  List<LatLng> points, {
  double padding = 72,
}) async {
  if (points.isEmpty) return;
  final raw = boundsForPoints(points);
  if (raw == null) return;
  final bounds = expandBounds(raw);
  await animateMapCamera(
    controller,
    CameraUpdate.newLatLngBounds(bounds, padding),
  );
}

Future<void> followUserOnMap(
  GoogleMapController controller,
  LatLng user, {
  double zoom = 16,
}) async {
  await animateMapCamera(
    controller,
    CameraUpdate.newCameraPosition(
      CameraPosition(target: user, zoom: zoom),
    ),
    iosDelay: Duration.zero,
  );
}
