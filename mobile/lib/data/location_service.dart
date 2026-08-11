import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';

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

  /// Human-readable reason for the manual-entry dialog.
  static String failureMessage(LocationFailure? failure) {
    return switch (failure) {
      LocationFailure.serviceDisabled =>
        'Konum servisi kapalı. Emülatörde Extended controls → Location ile konum aç, veya şehir yaz.',
      LocationFailure.permissionDenied =>
        'Konum izni verilmedi. Şehir veya ilçe yazarak devam edebilirsin.',
      LocationFailure.permissionDeniedForever =>
        'Konum izni kalıcı olarak kapalı. Ayarlardan aç veya şehir yaz.',
      LocationFailure.timeout =>
        'GPS zaman aşımına uğradı (emülatörde sık olur). Extended controls → Location’dan bir nokta seç veya şehir yaz.',
      LocationFailure.geocodeFailed =>
        'Koordinat alındı ama adres çözülemedi. Şehir veya ilçe yaz.',
      LocationFailure.unknown || null =>
        'Konum alınamadı. Şehir veya ilçe yazarak devam edebilirsin.',
    };
  }

  Future<LocationResolveResult?> resolveArea() async {
    final outcome = await resolveAreaDetailed();
    return outcome.result;
  }

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
    try {
      final last = await Geolocator.getLastKnownPosition();
      if (last != null) {
        debugPrint('LocationService: using lastKnownPosition');
        return last;
      }
    } catch (_) {}

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

    try {
      return await Geolocator.getCurrentPosition(locationSettings: settings);
    } on TimeoutException {
      return null;
    } catch (e) {
      debugPrint('LocationService: getCurrentPosition failed: $e');
      return null;
    }
  }

  Future<String?> _reverseGeocode(double lat, double lon) async {
    try {
      final placemarks = await placemarkFromCoordinates(lat, lon);
      if (placemarks.isNotEmpty) {
        final area = formatPlacemark(placemarks.first);
        if (area.isNotEmpty) return area;
      }
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
