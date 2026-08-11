part of 'planner_view_model.dart';

abstract class PlannerEvent {}

class PlannerPlanDayEvent extends PlannerEvent {
  PlannerPlanDayEvent({
    required this.area,
    required this.query,
    this.title = '',
    this.maxResults = 5,
    this.travelMode = 'WALK',
  });

  final String area;
  final String query;
  final String title;
  final int maxResults;
  final String travelMode;
}

class PlannerResetEvent extends PlannerEvent {}

class PlannerRetryEvent extends PlannerEvent {}

class PlannerDismissErrorEvent extends PlannerEvent {}
