import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:navgo_mobile/i18n/strings.g.dart';

enum LocationFailure {
  serviceDisabled,
  permissionDenied,
  permissionDeniedForever,
  timeout,
  geocodeFailed,
  unknown,
}

class LocationResolveResult {
  const LocationResolveResult({
    required this.area,
    required this.fromGps,
  });

  final String area;
  final bool fromGps;
}

class LocationResolveOutcome {
  const LocationResolveOutcome.ok(this.result) : failure = null;
  const LocationResolveOutcome.fail(this.failure) : result = null;

  final LocationResolveResult? result;
  final LocationFailure? failure;

  bool get isOk => result != null;
}

/// Resolves current city/district via GPS + reverse geocoding.
class LocationService {
  LocationService({Dio? dio}) : _dio = dio ?? Dio();

  final Dio _dio;

  Future<bool> ensureServiceEnabled() => Geolocator.isLocationServiceEnabled();

  Future<LocationPermission> requestPermission() async {
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    return permission;
  }

  /// Konum izni veya servis kapalı — ayarlara yönlendir.
  static String settingsRequiredMessage(LocationFailure? failure) {
    return switch (failure) {
      LocationFailure.serviceDisabled =>
        t.location.settingsRequired.serviceDisabled,
      LocationFailure.permissionDenied =>
        t.location.settingsRequired.permissionDenied,
      LocationFailure.permissionDeniedForever =>
        t.location.settingsRequired.permissionDeniedForever,
      _ => t.location.settingsRequired.fallback,
    };
  }

  /// GPS timeout — izin var, koordinat alınamadı.
  static String retryMessage(LocationFailure? failure) {
    return switch (failure) {
      _ => t.location.retryMessage,
    };
  }

  /// İzin açık; ağ / adres çözümleme sorunu — manuel giriş.
  static String manualEntryMessage(LocationFailure? failure) {
    return switch (failure) {
      LocationFailure.timeout => t.location.manualEntry.timeout,
      LocationFailure.geocodeFailed => t.location.manualEntry.geocodeFailed,
      LocationFailure.unknown => t.location.manualEntry.unknown,
      LocationFailure.serviceDisabled ||
      LocationFailure.permissionDenied ||
      LocationFailure.permissionDeniedForever =>
        t.location.manualEntry.noPermission,
      _ => t.location.manualEntry.fallback,
    };
  }

  static bool requiresSettings(LocationFailure? failure) {
    return failure == LocationFailure.serviceDisabled ||
        failure == LocationFailure.permissionDenied ||
        failure == LocationFailure.permissionDeniedForever;
  }

  /// GPS / geocode başarısız — manuel şehir girişi sunulabilir.
  static bool allowsManualEntry(LocationFailure? failure) {
    return failure == LocationFailure.timeout ||
        failure == LocationFailure.geocodeFailed ||
        failure == LocationFailure.unknown ||
        requiresSettings(failure);
  }

  static Future<void> openSettingsForFailure(LocationFailure? failure) async {
    if (failure == LocationFailure.serviceDisabled) {
      await Geolocator.openLocationSettings();
    } else {
      await Geolocator.openAppSettings();
    }
  }

  Future<LocationResolveResult?> resolveArea() async {
    final outcome = await resolveAreaDetailed();
    return outcome.result;
  }

  /// Fresh GPS fix shared by planner and route map.
  Future<Position?> currentPosition() => _readPosition();

  Future<LocationResolveOutcome> resolveAreaDetailed() async {
    try {
      final enabled = await ensureServiceEnabled();
      if (!enabled) {
        debugPrint('LocationService: location services disabled');
        return const LocationResolveOutcome.fail(
          LocationFailure.serviceDisabled,
        );
      }

      final permission = await requestPermission();
      if (permission == LocationPermission.denied) {
        debugPrint('LocationService: permission denied');
        return const LocationResolveOutcome.fail(
          LocationFailure.permissionDenied,
        );
      }
      if (permission == LocationPermission.deniedForever) {
        debugPrint('LocationService: permission denied forever');
        return const LocationResolveOutcome.fail(
          LocationFailure.permissionDeniedForever,
        );
      }

      final position = await _readPosition();
      if (position == null) {
        debugPrint('LocationService: position timeout / unavailable');
        return const LocationResolveOutcome.fail(LocationFailure.timeout);
      }

      debugPrint(
        'LocationService: lat=${position.latitude} lon=${position.longitude}',
      );

      final area = await _reverseGeocode(
        position.latitude,
        position.longitude,
      );
      if (area == null || area.isEmpty) {
        debugPrint('LocationService: reverse geocode failed');
        return const LocationResolveOutcome.fail(LocationFailure.geocodeFailed);
      }

      return LocationResolveOutcome.ok(
        LocationResolveResult(area: area, fromGps: true),
      );
    } catch (e, st) {
      debugPrint('LocationService: error $e\n$st');
      return const LocationResolveOutcome.fail(LocationFailure.unknown);
    }
  }

  Future<Position?> _readPosition() async {
    final LocationSettings settings =
        defaultTargetPlatform == TargetPlatform.android
            ? AndroidSettings(
                accuracy: LocationAccuracy.high,
                forceLocationManager: true,
                timeLimit: const Duration(seconds: 15),
              )
            : const LocationSettings(
                accuracy: LocationAccuracy.high,
                timeLimit: Duration(seconds: 15),
              );

    // Prefer a fresh fix — lastKnown is often a stale emulator mock (wrong city).
    try {
      return await Geolocator.getCurrentPosition(locationSettings: settings);
    } on TimeoutException {
      debugPrint('LocationService: getCurrentPosition timed out');
    } catch (e) {
      debugPrint('LocationService: getCurrentPosition failed: $e');
    }

    return null;
  }

  Future<String?> _reverseGeocode(double lat, double lon) async {
    // Platform geocoder (esp. emulator / missing Play Services) can hang
    // indefinitely — always bound it so Nominatim can run.
    try {
      final placemarks = await placemarkFromCoordinates(lat, lon).timeout(
        const Duration(seconds: 5),
      );
      if (placemarks.isNotEmpty) {
        final area = formatPlacemark(placemarks.first);
        if (area.isNotEmpty) return area;
      }
    } on TimeoutException {
      debugPrint('LocationService: platform geocoder timed out');
    } catch (e) {
      debugPrint('LocationService: platform geocoder failed: $e');
    }

    // Emulators without Play Geocoder often fail — OSM Nominatim fallback.
    try {
      final res = await _dio.get<Map<String, dynamic>>(
        'https://nominatim.openstreetmap.org/reverse',
        queryParameters: {
          'lat': lat,
          'lon': lon,
          'format': 'json',
          'accept-language': 'tr',
          'zoom': 12,
        },
        options: Options(
          headers: {
            'User-Agent': 'NavGoMobile/1.0 (dev; contact@navgo.local)',
          },
          connectTimeout: const Duration(seconds: 8),
          receiveTimeout: const Duration(seconds: 8),
          sendTimeout: const Duration(seconds: 8),
        ),
      );
      final addr = res.data?['address'] as Map<String, dynamic>?;
      if (addr == null) return null;
      final district = (addr['suburb'] ??
              addr['neighbourhood'] ??
              addr['city_district'] ??
              addr['town'] ??
              addr['village'] ??
              '')
          .toString()
          .trim();
      final city = (addr['city'] ??
              addr['province'] ??
              addr['state'] ??
              addr['county'] ??
              '')
          .toString()
          .trim();
      if (district.isNotEmpty && city.isNotEmpty && district != city) {
        return '$district, $city';
      }
      if (city.isNotEmpty) return city;
      if (district.isNotEmpty) return district;
      final display = res.data?['display_name']?.toString();
      if (display != null && display.trim().isNotEmpty) {
        final parts = display.split(',');
        if (parts.length >= 2) {
          return '${parts[0].trim()}, ${parts[1].trim()}';
        }
        return display.trim();
      }
    } catch (e) {
      debugPrint('LocationService: nominatim failed: $e');
    }
    return null;
  }

  /// İlçe, Şehir — falls back to locality / administrativeArea.
  static String formatPlacemark(Placemark p) {
    final district = (p.subAdministrativeArea?.trim().isNotEmpty ?? false)
        ? p.subAdministrativeArea!.trim()
        : (p.subLocality?.trim().isNotEmpty ?? false)
            ? p.subLocality!.trim()
            : '';
    final city = (p.administrativeArea?.trim().isNotEmpty ?? false)
        ? p.administrativeArea!.trim()
        : (p.locality?.trim().isNotEmpty ?? false)
            ? p.locality!.trim()
            : '';

    if (district.isNotEmpty && city.isNotEmpty && district != city) {
      return '$district, $city';
    }
    if (city.isNotEmpty) return city;
    if (district.isNotEmpty) return district;
    if (p.locality != null && p.locality!.trim().isNotEmpty) {
      return p.locality!.trim();
    }
    return '';
  }
}
