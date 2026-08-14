import 'package:flutter/material.dart';
import 'package:navgo_mobile/core/extensions/core_extensions.dart';
import 'package:navgo_mobile/core/models/place_model.dart';
import 'package:navgo_mobile/core/themes/app_colors.dart';
import 'package:navgo_mobile/core/widgets/primary_button.dart';
import 'package:navgo_mobile/i18n/strings.g.dart';
import 'package:navgo_mobile/views/plan/models/plan_suggestion.dart';

mixin PlannerWidgets {
  String greetingForNow(Translations t) {
    final h = DateTime.now().hour;
    if (h < 12) return t.plan.greetingMorning;
    if (h < 18) return t.plan.greetingAfternoon;
    return t.plan.greetingEvening;
  }

  Widget homeHeader(
    BuildContext context, {
    required String name,
  }) {
    final t = context.t;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          t.plan.greetingLine(greeting: greetingForNow(t)),
          style: context.textTheme.bodyLarge?.copyWith(color: AppColors.neutral),
        ),
        const SizedBox(height: 2),
        Text(name, style: context.textTheme.headlineMedium),
      ],
    );
  }

  Widget heroCard(
    BuildContext context, {
    required VoidCallback onStart,
  }) {
    final t = context.t;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primary,
            Color(0xFF1B7BB5),
            Color(0xFF0F5F8A),
          ],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              t.plan.heroBadge,
              style: context.textTheme.labelLarge?.copyWith(color: Colors.white),
            ),
          ),
          const SizedBox(height: 14),
          Text(
            t.plan.heroTitle,
            style: context.textTheme.headlineMedium?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            t.plan.heroBody,
            style: context.textTheme.bodyMedium?.copyWith(
              color: Colors.white.withValues(alpha: 0.9),
              height: 1.4,
            ),
          ),
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: AppColors.primary,
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              onPressed: onStart,
              child: Text(t.plan.heroCta),
            ),
          ),
        ],
      ),
    );
  }

  Widget suggestionCard(
    BuildContext context, {
    required PlanSuggestion suggestion,
    required VoidCallback onTap,
  }) {
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          width: 210,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColors.surfaceMuted),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: suggestion.accent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(suggestion.icon, color: suggestion.accent),
              ),
              const Spacer(),
              Text(suggestion.title, style: context.textTheme.titleMedium),
              const SizedBox(height: 4),
              Text(
                suggestion.subtitle,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: context.textTheme.bodyMedium,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget planErrorBanner(
    BuildContext context, {
    required String message,
    required VoidCallback onRetry,
    required VoidCallback onDismiss,
    bool canRetry = true,
  }) {
    final t = context.t;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.danger.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.danger.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.error_outline, color: AppColors.danger, size: 22),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      t.plan.errorTitle,
                      style: context.textTheme.titleMedium?.copyWith(
                        color: AppColors.danger,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(message, style: context.textTheme.bodyMedium),
                  ],
                ),
              ),
              IconButton(
                visualDensity: VisualDensity.compact,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                onPressed: onDismiss,
                icon: Icon(
                  Icons.close,
                  size: 20,
                  color: AppColors.neutral.withValues(alpha: 0.8),
                ),
              ),
            ],
          ),
          if (canRetry) ...[
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh, size: 18),
                label: Text(t.common.retry),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget tipBanner(BuildContext context) {
    final t = context.t;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.tertiary.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          const Icon(Icons.wb_sunny_outlined, color: AppColors.tertiary),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              t.plan.tipBanner,
              style: context.textTheme.bodyMedium?.copyWith(
                color: AppColors.secondary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget progressBody(BuildContext context, {required String message}) {
    final t = context.t;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(t.common.brand, style: context.textTheme.headlineMedium),
          context.sizedHeightBoxMedium,
          const SizedBox(
            width: 28,
            height: 28,
            child: CircularProgressIndicator(strokeWidth: 2.5),
          ),
          context.sizedHeightBoxNormal,
          Text(message, style: context.textTheme.bodyLarge),
        ],
      ),
    );
  }

  Widget stopsTimeline(BuildContext context, {required List<PlaceModel> stops}) {
    return ListView.separated(
      padding: EdgeInsets.zero,
      itemCount: stops.length,
      separatorBuilder: (context, index) => Divider(
        height: 28,
        color: context.cSurfaceMuted,
      ),
      itemBuilder: (context, i) {
        final p = stops[i];
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 36,
              height: 36,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(18),
              ),
              child: Text(
                '${i + 1}',
                style: context.textTheme.labelLarge?.copyWith(color: Colors.white),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(p.displayName, style: context.textTheme.titleMedium),
                  const SizedBox(height: 4),
                  Text(p.formattedAddress, style: context.textTheme.bodyMedium),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget planActions({
    required BuildContext context,
    required VoidCallback onOpenMaps,
    required VoidCallback onReset,
  }) {
    final t = context.t;
    return Column(
      children: [
        PrimaryButton(label: t.plan.openInGoogleMaps, onPressed: onOpenMaps),
        const SizedBox(height: 12),
        SecondaryButton(label: t.plan.backToHome, onPressed: onReset),
      ],
    );
  }
}
