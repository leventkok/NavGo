import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';

/// Shared high-accuracy GPS settings for planner and route map.
LocationSettings navGoLocationSettings({bool streaming = false}) {
  if (defaultTargetPlatform == TargetPlatform.android) {
    return AndroidSettings(
      accuracy: LocationAccuracy.high,
      forceLocationManager: true,
      distanceFilter: streaming ? 8 : 0,
      timeLimit: streaming ? null : const Duration(seconds: 15),
    );
  }
  if (defaultTargetPlatform == TargetPlatform.iOS) {
    return AppleSettings(
      accuracy: LocationAccuracy.best,
      distanceFilter: streaming ? 8 : 0,
      timeLimit: streaming ? null : const Duration(seconds: 15),
      pauseLocationUpdatesAutomatically: false,
      showBackgroundLocationIndicator: false,
    );
  }
  return LocationSettings(
    accuracy: LocationAccuracy.high,
    distanceFilter: streaming ? 8 : 0,
    timeLimit: streaming ? null : const Duration(seconds: 15),
  );
}
