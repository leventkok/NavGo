import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:navgo_mobile/core/extensions/core_extensions.dart';
import 'package:navgo_mobile/core/themes/app_colors.dart';
import 'package:navgo_mobile/core/utils/maps_launcher.dart';
import 'package:navgo_mobile/data/session_repository.dart';
import 'package:navgo_mobile/views/plan/models/plan_suggestion.dart';
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
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PlannerViewModel, PlannerState>(
      builder: (context, state) {
        return Scaffold(
          backgroundColor: context.cBackground,
          body: SafeArea(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 350),
              child: switch (state.phase) {
                PlannerPhase.home => _buildHome(context, state),
                PlannerPhase.working => Padding(
                    key: const ValueKey('working'),
                    padding: context.paddingNormal,
                    child: progressBody(context, message: state.statusMessage),
                  ),
                PlannerPhase.done => _buildDone(context, state),
              },
            ),
          ),
        );
      },
    );
  }

  String get _area => widget.session.defaultArea;

  Widget _buildHome(BuildContext context, PlannerState state) {
    final name = widget.session.displayName.isEmpty
        ? 'gezgin'
        : widget.session.displayName;
    final area = _area.isEmpty ? 'destinasyonun' : _area;

    return ListView(
      key: const ValueKey('home'),
      padding: context.paddingNormal,
      children: [
        homeHeader(context, name: name),
        if (_area.isNotEmpty) ...[
          const SizedBox(height: 4),
          Text(
            area,
            style: context.textTheme.bodyMedium?.copyWith(
              color: AppColors.primary,
            ),
          ),
        ],
        const SizedBox(height: 20),
        heroCard(
          context,
          onStart: () => _openStartSheet(context),
        ),
        if (state.errorMessage != null) ...[
          const SizedBox(height: 12),
          Text(
            state.errorMessage!,
            style: context.textTheme.bodyMedium?.copyWith(
              color: AppColors.danger,
            ),
          ),
        ],
        const SizedBox(height: 28),
        Text('Hızlı başlangıç', style: context.textTheme.titleLarge),
        const SizedBox(height: 6),
        Text(
          '$area için bir rota tipi seç — grounded Places ile üretilir.',
          style: context.textTheme.bodyMedium,
        ),
        const SizedBox(height: 14),
        SizedBox(
          height: 148,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: planSuggestions.length,
            separatorBuilder: (context, index) => const SizedBox(width: 12),
            itemBuilder: (context, i) {
              final s = planSuggestions[i];
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

  Future<void> _ensureAreaThen(
    BuildContext context,
    Future<void> Function(String area) run,
  ) async {
    var area = _area.trim();
    if (area.isEmpty) {
      final picked = await _promptArea(context);
      if (picked == null || picked.trim().isEmpty) return;
      area = picked.trim();
      await widget.session.setDefaultArea(area);
      if (mounted) setState(() {});
    }
    await run(area);
  }

  Future<String?> _promptArea(BuildContext context) async {
    final ctrl = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Nerede planlıyorsun?'),
          content: TextField(
            controller: ctrl,
            autofocus: true,
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(
              hintText: 'Şehir veya bölge',
            ),
            onSubmitted: (v) => Navigator.pop(ctx, v),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Vazgeç'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx, ctrl.text),
              child: const Text('Tamam'),
            ),
          ],
        );
      },
    );
  }

  void _startSuggestion(BuildContext context, PlanSuggestion s) {
    _ensureAreaThen(context, (area) async {
      if (!context.mounted) return;
      context.read<PlannerViewModel>().add(
            PlannerPlanDayEvent(
              area: area,
              query: s.query,
              title: s.title,
            ),
          );
    });
  }

  Future<void> _openStartSheet(BuildContext context) async {
    final vm = context.read<PlannerViewModel>();
    final areaCtrl = TextEditingController(text: _area);

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) {
        return Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 16,
            bottom: MediaQuery.viewInsetsOf(sheetContext).bottom +
                MediaQuery.paddingOf(sheetContext).bottom +
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
              Text('Nereye gidelim?', style: sheetContext.textTheme.headlineMedium),
              const SizedBox(height: 8),
              Text(
                'Şehir veya bölgeyi yaz, sonra bir rota tipi seç.',
                style: sheetContext.textTheme.bodyMedium,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: areaCtrl,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(
                  labelText: 'Destinasyon',
                  hintText: 'Örn. İstanbul, Roma, Tokyo…',
                ),
              ),
              const SizedBox(height: 12),
              for (final s in planSuggestions) ...[
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: CircleAvatar(
                    backgroundColor: s.accent.withValues(alpha: 0.12),
                    child: Icon(s.icon, color: s.accent),
                  ),
                  title: Text(s.title, style: sheetContext.textTheme.titleMedium),
                  subtitle: Text(s.subtitle),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 14),
                  onTap: () async {
                    final area = areaCtrl.text.trim();
                    if (area.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Önce şehir veya bölge yaz'),
                        ),
                      );
                      return;
                    }
                    await widget.session.setDefaultArea(area);
                    if (!sheetContext.mounted) return;
                    Navigator.pop(sheetContext);
                    vm.add(
                      PlannerPlanDayEvent(
                        area: area,
                        query: s.query,
                        title: s.title,
                      ),
                    );
                  },
                ),
                const Divider(height: 8),
              ],
            ],
          ),
        );
      },
    );
    areaCtrl.dispose();
    if (mounted) setState(() {});
  }

  Widget _buildDone(BuildContext context, PlannerState state) {
    final route = state.route!;
    final km = (route.distanceMeters / 1000).toStringAsFixed(1);
    final mins = (route.durationSeconds / 60).round();
    final title = state.planTitle.isEmpty ? 'Gün planı' : state.planTitle;

    return Padding(
      key: const ValueKey('done'),
      padding: context.paddingNormal,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(title, style: context.textTheme.headlineMedium),
              ),
              TextButton(
                onPressed: () =>
                    context.read<PlannerViewModel>().add(PlannerResetEvent()),
                child: Text(
                  'Ana sayfa',
                  style: context.textTheme.labelLarge?.copyWith(
                    color: context.cPrimary,
                  ),
                ),
              ),
            ],
          ),
          Text(
            '$km km · ~$mins dk · ${route.provider}',
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
