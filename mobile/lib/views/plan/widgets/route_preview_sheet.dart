import 'package:flutter/material.dart';
import 'package:navgo_mobile/core/extensions/core_extensions.dart';
import 'package:navgo_mobile/core/models/place_model.dart';
import 'package:navgo_mobile/core/themes/app_colors.dart';
import 'package:navgo_mobile/core/widgets/primary_button.dart';
import 'package:navgo_mobile/i18n/strings.g.dart';
import 'package:navgo_mobile/views/plan/models/plan_suggestion.dart';
import 'package:navgo_mobile/views/plan/repository/service/planner_service.dart';
import 'package:shimmer/shimmer.dart';

enum RoutePreviewOutcome { confirmed, cancelled }

class RoutePreviewSheet extends StatefulWidget {
  const RoutePreviewSheet({
    super.key,
    required this.area,
    required this.suggestion,
    required this.query,
    required this.service,
  });

  final String area;
  final PlanSuggestion suggestion;
  final String query;
  final PlannerService service;

  @override
  State<RoutePreviewSheet> createState() => _RoutePreviewSheetState();
}

class _RoutePreviewSheetState extends State<RoutePreviewSheet> {
  var _loading = true;
  var _failed = false;
  List<PlaceModel> _stops = const [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _failed = false;
    });
    try {
      final token = await widget.service.ensureSession();
      final places = await widget.service.searchPlaces(
        token: token,
        area: widget.area,
        query: widget.query,
        maxResults: 4,
      );
      if (!mounted) return;
      setState(() {
        _stops = places;
        _loading = false;
        _failed = places.length < 2;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _stops = const [];
        _loading = false;
        _failed = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final suggestion = widget.suggestion;
    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 16,
        bottom:
            MediaQuery.viewInsetsOf(context).bottom +
            MediaQuery.paddingOf(context).bottom +
            20,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
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
            Text(suggestion.title, style: context.textTheme.headlineMedium),
            const SizedBox(height: 6),
            Text(suggestion.subtitle, style: context.textTheme.bodyMedium),
            const SizedBox(height: 4),
            Text(
              widget.area,
              style: context.textTheme.labelLarge?.copyWith(
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 16),
            if (_loading)
              _PreviewShimmer()
            else if (_failed)
              Text(
                _stops.isEmpty ? t.plan.preview.failed : t.plan.preview.empty,
                style: context.textTheme.bodyMedium,
              )
            else ...[
              for (var i = 0; i < _stops.length; i++) ...[
                if (i > 0) const Divider(height: 16),
                _PreviewStopRow(index: i + 1, place: _stops[i]),
              ],
            ],
            const SizedBox(height: 20),
            if (_loading)
              const SizedBox.shrink()
            else if (_failed) ...[
              PrimaryButton(label: t.common.retry, onPressed: _load),
              const SizedBox(height: 10),
              SecondaryButton(
                label: t.plan.preview.planAnyway,
                onPressed: () =>
                    Navigator.pop(context, RoutePreviewOutcome.confirmed),
              ),
              const SizedBox(height: 10),
              TextButton(
                onPressed: () =>
                    Navigator.pop(context, RoutePreviewOutcome.cancelled),
                child: Text(t.plan.preview.dismiss),
              ),
            ] else ...[
              PrimaryButton(
                label: t.plan.preview.buildRoute,
                onPressed: () =>
                    Navigator.pop(context, RoutePreviewOutcome.confirmed),
              ),
              const SizedBox(height: 10),
              SecondaryButton(
                label: t.plan.preview.dismiss,
                onPressed: () =>
                    Navigator.pop(context, RoutePreviewOutcome.cancelled),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _PreviewStopRow extends StatelessWidget {
  const _PreviewStopRow({required this.index, required this.place});

  final int index;
  final PlaceModel place;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 28,
          height: 28,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Text(
            '$index',
            style: context.textTheme.labelLarge?.copyWith(
              color: AppColors.primary,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(place.displayName, style: context.textTheme.titleMedium),
              const SizedBox(height: 2),
              Text(
                place.formattedAddress,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: context.textTheme.bodyMedium,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _PreviewShimmer extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: AppColors.surfaceMuted,
      highlightColor: Colors.white,
      child: Column(
        children: [
          for (var i = 0; i < 4; i++) ...[
            if (i > 0) const SizedBox(height: 14),
            Row(
              children: [
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        height: 14,
                        width: 160,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        height: 10,
                        width: 220,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
