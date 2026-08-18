import 'package:flutter/material.dart';
import 'package:navgo_mobile/core/extensions/core_extensions.dart';
import 'package:navgo_mobile/core/models/place_model.dart';
import 'package:navgo_mobile/core/models/route_models.dart';
import 'package:navgo_mobile/core/themes/app_colors.dart';
import 'package:navgo_mobile/i18n/strings.g.dart';

class RouteStopsSheet extends StatelessWidget {
  const RouteStopsSheet({
    super.key,
    required this.title,
    required this.stops,
    required this.currentIndex,
    required this.arrivedCount,
    required this.travelMode,
    required this.onEnd,
    this.route,
  });

  final String title;
  final List<PlaceModel> stops;
  final int currentIndex;
  final int arrivedCount;
  final String travelMode;
  final RouteModel? route;
  final VoidCallback onEnd;

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final remaining = (stops.length - arrivedCount).clamp(0, stops.length);
    final km = route == null
        ? ''
        : (route!.distanceMeters / 1000).toStringAsFixed(1);
    final mins = route == null ? 0 : (route!.durationSeconds / 60).round();

    return DraggableScrollableSheet(
      initialChildSize: 0.38,
      minChildSize: 0.22,
      maxChildSize: 0.82,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            boxShadow: [
              BoxShadow(
                color: Color(0x22000000),
                blurRadius: 16,
                offset: Offset(0, -4),
              ),
            ],
          ),
          child: ListView(
            controller: scrollController,
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.surfaceMuted,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(title, style: context.textTheme.titleLarge),
                        const SizedBox(height: 4),
                        Text(
                          t.routeMap.stopsRemaining(
                            count: remaining,
                            status: arrivedCount > 0
                                ? t.routeMap.inProgress
                                : t.routeMap.notStarted,
                          ),
                          style: context.textTheme.bodySmall?.copyWith(
                            color: AppColors.primary,
                          ),
                        ),
                        if (route != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            t.plan.routeSummary(
                              km: km,
                              mins: mins,
                              provider: route!.provider,
                            ),
                            style: context.textTheme.bodySmall,
                          ),
                        ],
                      ],
                    ),
                  ),
                  TextButton.icon(
                    onPressed: onEnd,
                    icon: const Icon(Icons.stop_circle_outlined, color: AppColors.danger),
                    label: Text(
                      t.routeMap.endRoute,
                      style: const TextStyle(color: AppColors.danger),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              for (var i = 0; i < stops.length; i++)
                _StopTile(
                  index: i + 1,
                  stop: stops[i],
                  state: i < arrivedCount
                      ? _StopState.done
                      : i == currentIndex
                      ? _StopState.current
                      : _StopState.upcoming,
                ),
            ],
          ),
        );
      },
    );
  }
}

enum _StopState { done, current, upcoming }

class _StopTile extends StatelessWidget {
  const _StopTile({
    required this.index,
    required this.stop,
    required this.state,
  });

  final int index;
  final PlaceModel stop;
  final _StopState state;

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final isDone = state == _StopState.done;
    final isCurrent = state == _StopState.current;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isCurrent
            ? AppColors.primary.withValues(alpha: 0.08)
            : AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isCurrent ? AppColors.primary : AppColors.surfaceMuted,
        ),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: isDone
                ? AppColors.success
                : isCurrent
                ? AppColors.primary
                : AppColors.surfaceMuted,
            child: Text(
              '$index',
              style: TextStyle(
                color: isDone || isCurrent ? Colors.white : AppColors.neutral,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  stop.displayName,
                  style: context.textTheme.titleSmall?.copyWith(
                    decoration: isDone ? TextDecoration.lineThrough : null,
                    color: isDone ? AppColors.neutral : null,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  isDone
                      ? t.routeMap.completed
                      : isCurrent
                      ? t.routeMap.currentDestination
                      : stop.formattedAddress,
                  style: context.textTheme.bodySmall?.copyWith(
                    color: isCurrent ? AppColors.primary : AppColors.neutral,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          if (isDone)
            const Icon(Icons.check_circle, color: AppColors.success)
          else if (isCurrent)
            const Icon(Icons.navigation, color: AppColors.primary),
        ],
      ),
    );
  }
}
