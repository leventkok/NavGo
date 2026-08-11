part of 'planner_view_model.dart';

abstract class PlannerEvent {}

class PlannerPlanDayEvent extends PlannerEvent {
  PlannerPlanDayEvent({
    required this.area,
    required this.query,
    this.title = '',
  });

  final String area;
  final String query;
  final String title;
}

class PlannerResetEvent extends PlannerEvent {}
