import 'package:navgo_mobile/core/models/place_model.dart';

class LatLngModel {
  const LatLngModel({required this.latitude, required this.longitude});

  final double latitude;
  final double longitude;

  factory LatLngModel.fromJson(Map<String, dynamic> json) {
    return LatLngModel(
      latitude: (json['latitude'] as num?)?.toDouble() ?? 0,
      longitude: (json['longitude'] as num?)?.toDouble() ?? 0,
    );
  }
}

class RouteStepModel {
  const RouteStepModel({
    required this.travelMode,
    this.instructions = '',
    this.distanceMeters = 0,
    this.durationSeconds = 0,
    this.transitLine = '',
    this.transitVehicle = '',
    this.departureStop = '',
    this.arrivalStop = '',
    this.departureLat = 0,
    this.departureLng = 0,
    this.arrivalLat = 0,
    this.arrivalLng = 0,
    this.headsign = '',
    this.stopCount = 0,
    this.encodedPolyline = '',
  });

  final String travelMode;
  final String instructions;
  final int distanceMeters;
  final int durationSeconds;
  final String transitLine;
  final String transitVehicle;
  final String departureStop;
  final String arrivalStop;
  final double departureLat;
  final double departureLng;
  final double arrivalLat;
  final double arrivalLng;
  final String headsign;
  final int stopCount;
  final String encodedPolyline;

  bool get isTransit => travelMode.toUpperCase() == 'TRANSIT';
  bool get isWalk => travelMode.toUpperCase() == 'WALK';

  factory RouteStepModel.fromJson(Map<String, dynamic> json) {
    return RouteStepModel(
      travelMode: (json['travelMode'] ?? '') as String,
      instructions: (json['instructions'] ?? '') as String,
      distanceMeters: (json['distanceMeters'] as num?)?.toInt() ?? 0,
      durationSeconds: (json['durationSeconds'] as num?)?.toInt() ?? 0,
      transitLine: (json['transitLine'] ?? '') as String,
      transitVehicle: (json['transitVehicle'] ?? '') as String,
      departureStop: (json['departureStop'] ?? '') as String,
      arrivalStop: (json['arrivalStop'] ?? '') as String,
      departureLat: (json['departureLat'] as num?)?.toDouble() ?? 0,
      departureLng: (json['departureLng'] as num?)?.toDouble() ?? 0,
      arrivalLat: (json['arrivalLat'] as num?)?.toDouble() ?? 0,
      arrivalLng: (json['arrivalLng'] as num?)?.toDouble() ?? 0,
      headsign: (json['headsign'] ?? '') as String,
      stopCount: (json['stopCount'] as num?)?.toInt() ?? 0,
      encodedPolyline: (json['encodedPolyline'] ?? '') as String,
    );
  }
}

class RouteLegModel {
  const RouteLegModel({
    required this.startAddress,
    required this.endAddress,
    required this.distanceMeters,
    required this.durationSeconds,
    required this.start,
    required this.end,
    this.encodedPolyline = '',
    this.steps = const [],
  });

  final String startAddress;
  final String endAddress;
  final int distanceMeters;
  final int durationSeconds;
  final LatLngModel start;
  final LatLngModel end;
  final String encodedPolyline;
  final List<RouteStepModel> steps;

  factory RouteLegModel.fromJson(Map<String, dynamic> json) {
    return RouteLegModel(
      startAddress: (json['startAddress'] ?? '') as String,
      endAddress: (json['endAddress'] ?? '') as String,
      distanceMeters: (json['distanceMeters'] as num?)?.toInt() ?? 0,
      durationSeconds: (json['durationSeconds'] as num?)?.toInt() ?? 0,
      start: LatLngModel.fromJson(
        Map<String, dynamic>.from(json['startLocation'] as Map? ?? {}),
      ),
      end: LatLngModel.fromJson(
        Map<String, dynamic>.from(json['endLocation'] as Map? ?? {}),
      ),
      encodedPolyline: (json['encodedPolyline'] ?? '') as String,
      steps: (json['steps'] as List<dynamic>? ?? [])
          .whereType<Map<String, dynamic>>()
          .map(RouteStepModel.fromJson)
          .toList(),
    );
  }
}

class RouteModel {
  const RouteModel({
    required this.googleMapsUrl,
    required this.distanceMeters,
    required this.durationSeconds,
    required this.provider,
    this.overviewPolyline = '',
    this.waypointOrder = const [],
    this.legs = const [],
    this.transitAvailable = false,
  });

  final String googleMapsUrl;
  final int distanceMeters;
  final int durationSeconds;
  final String provider;
  final String overviewPolyline;
  final List<int> waypointOrder;
  final List<RouteLegModel> legs;
  final bool transitAvailable;

  bool get hasTransitSteps {
    if (transitAvailable) return true;
    for (final leg in legs) {
      if (leg.steps.any((s) => s.isTransit)) return true;
    }
    return false;
  }

  factory RouteModel.fromJson(Map<String, dynamic> json) {
    return RouteModel(
      googleMapsUrl: (json['googleMapsUrl'] ?? '') as String,
      distanceMeters: (json['distanceMeters'] as num?)?.toInt() ?? 0,
      durationSeconds: (json['durationSeconds'] as num?)?.toInt() ?? 0,
      provider: (json['provider'] ?? '') as String,
      overviewPolyline: (json['overviewPolyline'] ?? '') as String,
      waypointOrder: (json['waypointOrder'] as List<dynamic>? ?? [])
          .map((e) => (e as num).toInt())
          .toList(),
      legs: (json['legs'] as List<dynamic>? ?? [])
          .whereType<Map<String, dynamic>>()
          .map(RouteLegModel.fromJson)
          .toList(),
      transitAvailable: json['transitAvailable'] as bool? ?? false,
    );
  }

  List<PlaceModel> orderedStops(List<PlaceModel> stops) {
    if (waypointOrder.isEmpty || waypointOrder.length != stops.length) {
      return stops;
    }
    return [for (final i in waypointOrder) if (i >= 0 && i < stops.length) stops[i]];
  }
}
