part of 'planner_view_model.dart';

abstract class PlannerEvent {}

class PlannerPlanDayEvent extends PlannerEvent {
  PlannerPlanDayEvent({
    required this.area,
    required this.query,
    this.title = '',
    this.prompt = '',
    this.maxResults = 5,
    this.travelMode = 'WALK',
    this.tempo = '',
    this.interests = const [],
    this.groupType = '',
    this.transportMode = '',
  });

  final String area;
  final String query;
  final String title;
  /// Free-form prompt for server LLM; falls back to title + query.
  final String prompt;
  final int maxResults;
  final String travelMode;
  final String tempo;
  final List<String> interests;
  final String groupType;
  final String transportMode;
}

class PlannerResetEvent extends PlannerEvent {}
