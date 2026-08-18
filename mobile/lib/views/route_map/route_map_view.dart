import 'dart:async';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:navgo_mobile/core/extensions/core_extensions.dart';
import 'package:navgo_mobile/core/models/place_model.dart';
import 'package:navgo_mobile/core/models/route_models.dart';
import 'package:navgo_mobile/core/themes/app_colors.dart';
import 'package:navgo_mobile/core/utils/location_settings.dart';
import 'package:navgo_mobile/core/utils/map_camera_utils.dart';
import 'package:navgo_mobile/core/utils/polyline_utils.dart';
import 'package:navgo_mobile/core/utils/route_order.dart';
import 'package:navgo_mobile/data/location_service.dart';
import 'package:navgo_mobile/i18n/strings.g.dart';
import 'package:navgo_mobile/views/plan/repository/service/planner_service.dart';
import 'package:navgo_mobile/views/route_map/route_map_args.dart';
import 'package:navgo_mobile/views/route_map/widgets/route_stops_sheet.dart';
import 'package:navgo_mobile/views/route_map/widgets/transport_mode_bar.dart';

class RouteMapView extends StatefulWidget {
  const RouteMapView({
    super.key,
    required this.args,
    this.service,
  });

  final RouteMapArgs args;
  final PlannerService? service;

  @override
  State<RouteMapView> createState() => _RouteMapViewState();
}

class _RouteMapViewState extends State<RouteMapView> {
  final _mapController = Completer<GoogleMapController>();
  final _service = PlannerService();
  final _location = LocationService();

  GoogleMapController? _controller;
  StreamSubscription<Position>? _positionSub;

  var _loading = true;
  var _routeLoading = false;
  var _currentStopIndex = 0;
  var _arrivedCount = 0;
  String _travelMode = 'WALK';
  RouteModel? _route;
  List<PlaceModel> _stops = const [];
  LatLng? _userLatLng;
  Set<Marker> _markers = {};
  Set<Polyline> _polylines = {};
  List<LatLng> _fullPolyline = const [];
  String? _error;

  static const _arrivalRadiusM = 120.0;

  @override
  void initState() {
    super.initState();
    _travelMode = widget.args.travelMode.toUpperCase();
    _route = widget.args.route;
    _stops = List<PlaceModel>.from(widget.args.stops);
    unawaited(_bootstrap());
  }

  @override
  void dispose() {
    unawaited(_positionSub?.cancel());
    _controller?.dispose();
    super.dispose();
  }

  Future<void> _bootstrap() async {
    try {
      final pos = await _location.currentPosition();
      if (pos == null) {
        throw StateError('location unavailable');
      }
      _userLatLng = LatLng(pos.latitude, pos.longitude);
      _stops = compactClusterNearUser(
        userLat: pos.latitude,
        userLng: pos.longitude,
        candidates: widget.args.stops,
        maxStops: widget.args.stops.length,
      );
      await _loadRoute();
      _startTracking();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = context.t.routeMap.locationError;
        _loading = false;
      });
    }
  }

  PlaceModel? get _activeStop {
    if (_currentStopIndex < 0 || _currentStopIndex >= _stops.length) {
      return null;
    }
    return _stops[_currentStopIndex];
  }

  Future<void> _loadRoute() async {
    final target = _activeStop;
    if (target == null) {
      if (!mounted) return;
      setState(() {
        _route = null;
        _routeLoading = false;
        _loading = false;
        _error = null;
      });
      _refreshMapOverlays();
      return;
    }
    setState(() => _routeLoading = true);
    try {
      final token = await _service.ensureSession();
      final route = await _service.buildRoute(
        token: token,
        placeIds: [target.placeId],
        travelMode: _travelMode,
        originLat: _userLatLng?.latitude,
        originLng: _userLatLng?.longitude,
      );
      if (!mounted) return;
      setState(() {
        _route = route;
        _routeLoading = false;
        _loading = false;
        _error = null;
      });
      _refreshMapOverlays();
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _routeLoading = false;
        _loading = false;
        _error = context.t.routeMap.routeError;
      });
    }
  }

  void _startTracking() {
    _positionSub?.cancel();
    _positionSub = Geolocator.getPositionStream(
      locationSettings: navGoLocationSettings(streaming: true),
    ).listen((pos) {
      _userLatLng = LatLng(pos.latitude, pos.longitude);
      _checkArrival(pos.latitude, pos.longitude);
      _trimPassedPolyline(followCamera: true);
    });
  }

  void _checkArrival(double lat, double lng) {
    if (_routeLoading) return;
    final target = _activeStop;
    if (target == null) return;
    final dist = haversineMeters(lat, lng, target.latitude, target.longitude);
    if (dist > _arrivalRadiusM) return;
    if (!mounted) return;
    final name = target.displayName;
    setState(() {
      _arrivedCount = _currentStopIndex + 1;
      _currentStopIndex = (_currentStopIndex + 1).clamp(0, _stops.length);
      if (_userLatLng != null && _currentStopIndex < _stops.length) {
        final remaining = _stops.sublist(_currentStopIndex);
        final next = orderStopsFromUser(
          userLat: _userLatLng!.latitude,
          userLng: _userLatLng!.longitude,
          stops: remaining,
        );
        _stops = [..._stops.sublist(0, _currentStopIndex), ...next];
      }
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(context.t.routeMap.arrived(name: name))),
    );
    unawaited(_loadRoute());
  }

  Future<void> _onTravelModeChanged(String mode) async {
    if (mode == _travelMode || _routeLoading) return;
    setState(() => _travelMode = mode);
    await _loadRoute();
  }

  void _trimPassedPolyline({required bool followCamera}) {
    final user = _userLatLng;
    if (user == null) return;
    if (_travelMode == 'TRANSIT') {
      if (followCamera && _controller != null) {
        unawaited(followUserOnMap(_controller!, user));
      }
      return;
    }
    final ahead = remainingPolylineAhead(_fullPolyline, user);
    setState(() {
      _polylines = ahead.isEmpty
          ? {}
          : {
              Polyline(
                polylineId: const PolylineId('active-leg'),
                points: ahead,
                color: AppColors.primary,
                width: 5,
              ),
            };
    });
    if (followCamera && _controller != null) {
      unawaited(followUserOnMap(_controller!, user));
    }
  }

  void _refreshMapOverlays({bool fitBounds = true}) {
    final target = _activeStop;
    var polylinePoints = decodeRoutePolyline(_route?.overviewPolyline ?? '');
    if (polylinePoints.isEmpty && (_route?.legs.isNotEmpty ?? false)) {
      polylinePoints = decodeRoutePolyline(_route!.legs.first.encodedPolyline);
    }
    if (_userLatLng != null && polylinePoints.isNotEmpty) {
      polylinePoints = remainingPolylineAhead(polylinePoints, _userLatLng!);
    }
    _fullPolyline = polylinePoints;

    final markers = <Marker>{};
    if (target != null) {
      markers.add(
        Marker(
          markerId: MarkerId('stop-${target.placeId}'),
          position: LatLng(target.latitude, target.longitude),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange),
          infoWindow: InfoWindow(
            title: '${_currentStopIndex + 1}. ${target.displayName}',
            snippet: context.t.routeMap.currentStop,
          ),
        ),
      );
    }
    for (final step in _transitSteps) {
      if (step.departureLat != 0 || step.departureLng != 0) {
        final line = step.transitLine.isEmpty ? step.transitVehicle : step.transitLine;
        markers.add(
          Marker(
            markerId: MarkerId('board-${step.departureStop}-${step.departureLat}'),
            position: LatLng(step.departureLat, step.departureLng),
            icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
            infoWindow: InfoWindow(
              title: line.isEmpty ? context.t.routeMap.transitBoard : line,
              snippet: step.departureStop,
            ),
          ),
        );
      }
      if (step.arrivalLat != 0 || step.arrivalLng != 0) {
        markers.add(
          Marker(
            markerId: MarkerId('alight-${step.arrivalStop}-${step.arrivalLat}'),
            position: LatLng(step.arrivalLat, step.arrivalLng),
            icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
            infoWindow: InfoWindow(
              title: step.arrivalStop,
              snippet: step.transitLine,
            ),
          ),
        );
      }
    }

    final leg = _currentLeg;
    final hasTransit = _route?.hasTransitSteps ?? false;

    final polylines = <Polyline>{};
    if (_travelMode == 'TRANSIT' && leg != null && hasTransit) {
      var walkIdx = 0;
      var rideIdx = 0;
      for (final step in leg.steps) {
        final pts = decodeRoutePolyline(step.encodedPolyline);
        if (pts.length < 2) continue;
        if (step.isTransit) {
          polylines.add(
            Polyline(
              polylineId: PolylineId('transit-$rideIdx'),
              points: pts,
              color: AppColors.primary,
              width: 6,
            ),
          );
          rideIdx++;
        } else {
          polylines.add(
            Polyline(
              polylineId: PolylineId('walk-$walkIdx'),
              points: pts,
              color: const Color(0xFF5B8DEF),
              width: 4,
              patterns: [PatternItem.dash(18), PatternItem.gap(10)],
            ),
          );
          walkIdx++;
        }
      }
    } else if (_travelMode != 'TRANSIT' && polylinePoints.isNotEmpty) {
      polylines.add(
        Polyline(
          polylineId: const PolylineId('active-leg'),
          points: polylinePoints,
          color: AppColors.primary,
          width: 5,
        ),
      );
    }

    setState(() {
      _markers = markers;
      _polylines = polylines;
    });

    if (!fitBounds) return;
    final points = <LatLng>[];
    if (_travelMode == 'TRANSIT' && (_route?.hasTransitSteps ?? false)) {
      for (final poly in polylines) {
        points.addAll(poly.points);
      }
    } else {
      points.addAll(polylinePoints);
    }
    if (_userLatLng != null) points.add(_userLatLng!);
    if (target != null) {
      points.add(LatLng(target.latitude, target.longitude));
    }
    if (_controller != null) {
      unawaited(fitMapToPoints(_controller!, points));
    }
  }

  RouteLegModel? get _currentLeg {
    final route = _route;
    if (route == null || route.legs.isEmpty) return null;
    return route.legs.first;
  }

  List<RouteStepModel> get _transitSteps {
    final leg = _currentLeg;
    if (leg == null) return const [];
    return leg.steps.where((s) => s.isTransit).toList();
  }

  @override
  Widget build(BuildContext context) {
    final initial = _userLatLng ??
        (_stops.isNotEmpty
            ? LatLng(_stops.first.latitude, _stops.first.longitude)
            : const LatLng(36.8969, 30.7133));

    return Scaffold(
      body: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: CameraPosition(target: initial, zoom: 13),
            myLocationEnabled: true,
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false,
            markers: _markers,
            polylines: _polylines,
            onMapCreated: (controller) {
              _controller = controller;
              if (!_mapController.isCompleted) {
                _mapController.complete(controller);
              }
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted) _refreshMapOverlays();
              });
            },
          ),
          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
                  child: Row(
                    children: [
                      IconButton.filled(
                        style: IconButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: AppColors.primary,
                        ),
                        onPressed: () => Navigator.of(context).maybePop(),
                        icon: const Icon(Icons.arrow_back),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          widget.args.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: context.textTheme.titleMedium?.copyWith(
                            color: Colors.white,
                            shadows: const [
                              Shadow(color: Colors.black54, blurRadius: 8),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                TransportModeBar(
                  selected: _travelMode,
                  loading: _routeLoading,
                  onChanged: _onTravelModeChanged,
                ),
                if (_travelMode == 'TRANSIT')
                  _TransitBanner(
                    steps: _currentLeg?.steps ?? const [],
                    hasTransit: _route?.hasTransitSteps ?? false,
                  ),
              ],
            ),
          ),
          if (_loading)
            const ColoredBox(
              color: Colors.black26,
              child: Center(child: CircularProgressIndicator()),
            ),
          if (_error != null && !_loading)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  _error!,
                  textAlign: TextAlign.center,
                  style: context.textTheme.bodyLarge?.copyWith(
                    color: Colors.white,
                    shadows: const [Shadow(color: Colors.black87)],
                  ),
                ),
              ),
            ),
          Align(
            alignment: Alignment.bottomCenter,
            child: RouteStopsSheet(
              title: widget.args.title,
              stops: _stops,
              currentIndex: _currentStopIndex,
              arrivedCount: _arrivedCount,
              travelMode: _travelMode,
              route: _route,
              onEnd: () => Navigator.of(context).maybePop(),
            ),
          ),
        ],
      ),
    );
  }
}

class _TransitBanner extends StatelessWidget {
  const _TransitBanner({
    required this.steps,
    required this.hasTransit,
  });

  final List<RouteStepModel> steps;
  final bool hasTransit;

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    if (!hasTransit) {
      return Container(
        margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.95),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          t.routeMap.transitEmpty,
          style: context.textTheme.bodySmall,
        ),
      );
    }
    final lines = <String>[];
    var sawTransit = false;
    for (final step in steps) {
      if (!step.isTransit) continue;
      sawTransit = true;
      if (step.departureStop.isNotEmpty) {
        lines.add(t.routeMap.transitWalkTo(stop: step.departureStop));
      }
      final line = step.transitLine.isNotEmpty
          ? step.transitLine
          : step.transitVehicle;
      if (line.isNotEmpty &&
          step.departureStop.isNotEmpty &&
          step.arrivalStop.isNotEmpty) {
        lines.add(
          t.routeMap.transitRide(
            line: line,
            from: step.departureStop,
            to: step.arrivalStop,
          ),
        );
      } else if (line.isNotEmpty) {
        lines.add(line);
      }
    }
    if (sawTransit) {
      lines.add(t.routeMap.transitWalkDest);
    }
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            t.routeMap.transitHint,
            style: context.textTheme.labelLarge?.copyWith(
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 4),
          for (final line in lines.take(4))
            Text(line, style: context.textTheme.bodySmall),
        ],
      ),
    );
  }
}
