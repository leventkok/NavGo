import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:navgo_mobile/core/extensions/core_extensions.dart';
import 'package:navgo_mobile/core/themes/app_colors.dart';
import 'package:navgo_mobile/core/utils/maps_launcher.dart';
import 'package:navgo_mobile/core/widgets/manual_area_dialog.dart';
import 'package:navgo_mobile/data/location_service.dart';
import 'package:navgo_mobile/data/session_repository.dart';
import 'package:navgo_mobile/i18n/strings.g.dart';
import 'package:navgo_mobile/views/plan/models/plan_suggestion.dart';
import 'package:navgo_mobile/views/plan/models/preference_query_builder.dart';
import 'package:navgo_mobile/views/plan/view_model/planner_view_model.dart';
import 'package:navgo_mobile/views/plan/widgets/planner_widgets.dart';

class PlanView extends StatelessWidget {
  const PlanView({super.key, required this.session});

  final SessionRepository session;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => PlannerViewModel(),
      child: _PlanViewContent(session: session),
    );
  }
}

class _PlanViewContent extends StatefulWidget {
  const _PlanViewContent({required this.session});

  final SessionRepository session;

  @override
  State<_PlanViewContent> createState() => _PlanViewContentState();
}

class _PlanViewContentState extends State<_PlanViewContent> with PlannerWidgets {
  final _queryBuilder = const PreferenceQueryBuilder();
  final _location = LocationService();
  var _resolvingLocation = false;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PlannerViewModel, PlannerState>(
      builder: (context, state) {
        return Scaffold(
          backgroundColor: context.cBackground,
          body: SafeArea(
            child: switch (state.phase) {
              PlannerPhase.home => _buildHome(context, state),
              PlannerPhase.working => Padding(
                  padding: context.paddingNormal,
                  child: progressBody(context, message: state.statusMessage),
                ),
              PlannerPhase.done => _buildDone(context, state),
            },
          ),
        );
      },
    );
  }

  String get _area => widget.session.defaultArea;

  String _buildQuery(PlanSuggestion s) {
    return _queryBuilder.build(
      interests: widget.session.interests,
      groupType: widget.session.groupType,
      seedQuery: s.query,
    );
  }

  Widget _buildHome(BuildContext context, PlannerState state) {
    final t = context.t;
    final name = widget.session.displayName.isEmpty
        ? t.common.defaultTravelerName
        : widget.session.displayName;
    final areaLabel = _area.isEmpty ? null : _area;
    final suggestions = planSuggestionsFor(t);

    return ListView(
      padding: context.paddingNormal,
      children: [
        homeHeader(context, name: name),
        const SizedBox(height: 4),
        if (areaLabel != null)
          Text(
            areaLabel,
            style: context.textTheme.bodyMedium?.copyWith(
              color: AppColors.primary,
            ),
          )
        else
          TextButton.icon(
            onPressed: _resolvingLocation ? null : () => _resolveOrPromptArea(),
            icon: _resolvingLocation
                ? const SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.my_location, size: 18),
            label: Text(
              t.plan.selectLocation,
              style: context.textTheme.labelLarge?.copyWith(
                color: AppColors.primary,
              ),
            ),
          ),
        const SizedBox(height: 16),
        heroCard(
          context,
          onStart: () => _openStartSheet(context),
        ),
        if (state.errorMessage != null) ...[
          const SizedBox(height: 12),
          planErrorBanner(
            context,
            message: state.errorMessage!,
            canRetry: state.lastPlanEvent != null,
            onRetry: () => context.read<PlannerViewModel>().add(
                  PlannerRetryEvent(),
                ),
            onDismiss: () => context.read<PlannerViewModel>().add(
                  PlannerDismissErrorEvent(),
                ),
          ),
        ],
        const SizedBox(height: 28),
        Text(t.plan.quickStart, style: context.textTheme.titleLarge),
        const SizedBox(height: 6),
        Text(
          areaLabel == null
              ? t.plan.quickStartNeedLocation
              : t.plan.quickStartWithArea(area: areaLabel),
          style: context.textTheme.bodyMedium,
        ),
        const SizedBox(height: 14),
        SizedBox(
          height: 148,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: suggestions.length,
            separatorBuilder: (context, index) => const SizedBox(width: 12),
            itemBuilder: (context, i) {
              final s = suggestions[i];
              return suggestionCard(
                context,
                suggestion: s,
                onTap: () => _startSuggestion(context, s),
              );
            },
          ),
        ),
        const SizedBox(height: 24),
        tipBanner(context),
        const SizedBox(height: 12),
      ],
    );
  }

  Future<String?> _resolveOrPromptArea() async {
    setState(() => _resolvingLocation = true);
    try {
      final outcome = await _location.resolveAreaDetailed();
      if (outcome.result != null && outcome.result!.area.isNotEmpty) {
        await widget.session.setDefaultArea(outcome.result!.area);
        if (mounted) setState(() {});
        return outcome.result!.area;
      }
      if (!mounted) return null;
      final manual = await promptLocationAreaAfterFailure(
        context,
        failure: outcome.failure,
        resolveAgain: _location.resolveAreaDetailed,
        initialValue: _area,
      );
      if (manual == null || manual.trim().isEmpty) return null;
      await widget.session.setDefaultArea(manual.trim());
      if (mounted) setState(() {});
      return manual.trim();
    } finally {
      if (mounted) setState(() => _resolvingLocation = false);
    }
  }

  Future<void> _ensureAreaThen(
    BuildContext context,
    Future<void> Function(String area) run,
  ) async {
    var area = _area.trim();
    if (area.isEmpty) {
      final picked = await _resolveOrPromptArea();
      if (picked == null || picked.trim().isEmpty) return;
      area = picked.trim();
    }
    await run(area);
  }

  void _startSuggestion(BuildContext context, PlanSuggestion s) {
    _ensureAreaThen(context, (area) async {
      if (!context.mounted) return;
      final query = _buildQuery(s);
      final prompt = '${s.title}. $area. ${s.subtitle}. $query';
      context.read<PlannerViewModel>().add(
            PlannerPlanDayEvent(
              area: area,
              query: query,
              title: s.title,
              prompt: prompt,
              maxResults: widget.session.maxResultsForTempo,
              travelMode: widget.session.apiTravelMode,
              tempo: widget.session.tempo,
              interests: widget.session.interests,
              groupType: widget.session.groupType,
              transportMode: widget.session.transportMode,
            ),
          );
    });
  }

  Future<void> _openStartSheet(BuildContext context) async {
    final vm = context.read<PlannerViewModel>();
    final pick = await showModalBottomSheet<_PlanStartPick>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) => _PlanStartSheet(
        initialArea: _area,
        location: _location,
      ),
    );
    if (pick == null || !mounted) return;
    await widget.session.setDefaultArea(pick.area);
    if (!mounted) return;
    final query = _buildQuery(pick.suggestion);
    final prompt =
        '${pick.suggestion.title}. ${pick.area}. ${pick.suggestion.subtitle}. $query';
    vm.add(
      PlannerPlanDayEvent(
        area: pick.area,
        query: query,
        title: pick.suggestion.title,
        prompt: prompt,
        maxResults: widget.session.maxResultsForTempo,
        travelMode: widget.session.apiTravelMode,
        tempo: widget.session.tempo,
        interests: widget.session.interests,
        groupType: widget.session.groupType,
        transportMode: widget.session.transportMode,
      ),
    );
    setState(() {});
  }

  Widget _buildDone(BuildContext context, PlannerState state) {
    final t = context.t;
    final route = state.route!;
    final km = (route.distanceMeters / 1000).toStringAsFixed(1);
    final mins = (route.durationSeconds / 60).round();
    final title =
        state.planTitle.isEmpty ? t.plan.defaultPlanTitle : state.planTitle;

    return Padding(
      padding: context.paddingNormal,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(title, style: context.textTheme.headlineMedium),
          Text(
            t.plan.routeSummary(
              km: km,
              mins: mins,
              provider: route.provider,
            ),
            style: context.textTheme.bodyMedium,
          ),
          context.sizedHeightBoxNormal,
          Expanded(child: stopsTimeline(context, stops: state.stops)),
          context.sizedHeightBoxNormal,
          planActions(
            context: context,
            onOpenMaps: () => openMapsUrl(route.googleMapsUrl),
            onReset: () =>
                context.read<PlannerViewModel>().add(PlannerResetEvent()),
          ),
        ],
      ),
    );
  }
}

class _PlanStartPick {
  const _PlanStartPick({required this.area, required this.suggestion});

  final String area;
  final PlanSuggestion suggestion;
}

class _PlanStartSheet extends StatefulWidget {
  const _PlanStartSheet({
    required this.initialArea,
    required this.location,
  });

  final String initialArea;
  final LocationService location;

  @override
  State<_PlanStartSheet> createState() => _PlanStartSheetState();
}

class _PlanStartSheetState extends State<_PlanStartSheet> {
  late final TextEditingController _areaCtrl;
  var _resolving = false;

  @override
  void initState() {
    super.initState();
    _areaCtrl = TextEditingController(text: widget.initialArea);
  }

  @override
  void dispose() {
    _areaCtrl.dispose();
    super.dispose();
  }

  Future<void> _useLocation() async {
    setState(() => _resolving = true);
    try {
      final outcome = await widget.location.resolveAreaDetailed();
      if (outcome.result != null && outcome.result!.area.isNotEmpty) {
        _areaCtrl.text = outcome.result!.area;
        return;
      }
      if (!mounted) return;
      final area = await promptLocationAreaAfterFailure(
        context,
        failure: outcome.failure,
        resolveAgain: widget.location.resolveAreaDetailed,
        initialValue: _areaCtrl.text,
      );
      if (area != null && area.isNotEmpty) {
        _areaCtrl.text = area;
      }
    } finally {
      if (mounted) setState(() => _resolving = false);
    }
  }

  void _pickSuggestion(PlanSuggestion suggestion) {
    final t = context.t;
    final area = _areaCtrl.text.trim();
    if (area.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(t.plan.startSheet.areaRequiredSnack)),
      );
      return;
    }
    Navigator.pop(
      context,
      _PlanStartPick(area: area, suggestion: suggestion),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final suggestions = planSuggestionsFor(t);
    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 16,
        bottom: MediaQuery.viewInsetsOf(context).bottom +
            MediaQuery.paddingOf(context).bottom +
            20,
      ),
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
          Text(t.plan.startSheet.title, style: context.textTheme.headlineMedium),
          const SizedBox(height: 8),
          Text(
            t.plan.startSheet.body,
            style: context.textTheme.bodyMedium,
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _areaCtrl,
            textCapitalization: TextCapitalization.words,
            decoration: InputDecoration(
              labelText: t.plan.startSheet.destinationLabel,
              hintText: t.plan.startSheet.destinationHint,
            ),
          ),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: _resolving ? null : _useLocation,
              icon: _resolving
                  ? const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.my_location, size: 18),
              label: Text(
                _resolving
                    ? t.plan.startSheet.resolvingLocation
                    : t.plan.startSheet.useMyLocation,
              ),
            ),
          ),
          const SizedBox(height: 4),
          for (final s in suggestions) ...[
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: CircleAvatar(
                backgroundColor: s.accent.withValues(alpha: 0.12),
                child: Icon(s.icon, color: s.accent),
              ),
              title: Text(s.title, style: context.textTheme.titleMedium),
              subtitle: Text(s.subtitle),
              trailing: const Icon(Icons.arrow_forward_ios, size: 14),
              onTap: () => _pickSuggestion(s),
            ),
            const Divider(height: 8),
          ],
        ],
      ),
    );
  }
}
