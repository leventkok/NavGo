import 'package:navgo_mobile/core/models/place_model.dart';
import 'package:navgo_mobile/core/models/route_models.dart';

class RouteMapArgs {
  const RouteMapArgs({
    required this.title,
    required this.stops,
    required this.travelMode,
    this.route,
  });

  final String title;
  final List<PlaceModel> stops;
  final String travelMode;
  final RouteModel? route;
}
