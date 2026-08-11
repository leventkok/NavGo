part of 'planner_view_model.dart';

enum PlannerPhase { home, working, done }

class PlannerState {
  const PlannerState({
    this.status = ViewStatus.initial,
    this.phase = PlannerPhase.home,
    this.planTitle = '',
    this.area = '',
    this.query = '',
    this.stops = const [],
    this.route,
    this.statusMessage = '',
    this.errorMessage,
  });

  final ViewStatus status;
  final PlannerPhase phase;
  final String planTitle;
  final String area;
  final String query;
  final List<PlaceModel> stops;
  final RouteModel? route;
  final String statusMessage;
  final String? errorMessage;

  PlannerState copyWith({
    ViewStatus? status,
    PlannerPhase? phase,
    String? planTitle,
    String? area,
    String? query,
    List<PlaceModel>? stops,
    RouteModel? route,
    bool clearRoute = false,
    String? statusMessage,
    String? errorMessage,
    bool clearError = false,
  }) {
    return PlannerState(
      status: status ?? this.status,
      phase: phase ?? this.phase,
      planTitle: planTitle ?? this.planTitle,
      area: area ?? this.area,
      query: query ?? this.query,
      stops: stops ?? this.stops,
      route: clearRoute ? null : (route ?? this.route),
      statusMessage: statusMessage ?? this.statusMessage,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}
