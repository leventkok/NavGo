import 'package:flutter/material.dart';
import 'package:navgo_mobile/core/extensions/core_extensions.dart';
import 'package:navgo_mobile/core/themes/app_colors.dart';
import 'package:navgo_mobile/i18n/strings.g.dart';

class TransportModeBar extends StatelessWidget {
  const TransportModeBar({
    super.key,
    required this.selected,
    required this.onChanged,
    this.loading = false,
  });

  final String selected;
  final ValueChanged<String> onChanged;
  final bool loading;

  static const modes = [
    ('WALK', Icons.directions_walk, 'walk'),
    ('TRANSIT', Icons.directions_transit, 'transit'),
    ('DRIVE', Icons.directions_car, 'drive'),
    ('BICYCLE', Icons.directions_bike, 'bike'),
  ];

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        children: [
          for (final (mode, icon, labelKey) in modes)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: _ModePill(
                icon: icon,
                label: switch (labelKey) {
                  'walk' => t.routeMap.modeWalk,
                  'transit' => t.routeMap.modeTransit,
                  'drive' => t.routeMap.modeDrive,
                  _ => t.routeMap.modeBike,
                },
                selected: selected == mode,
                loading: loading && selected == mode,
                onTap: loading ? null : () => onChanged(mode),
              ),
            ),
        ],
      ),
    );
  }
}

class _ModePill extends StatelessWidget {
  const _ModePill({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
    this.loading = false,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback? onTap;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? AppColors.primary : const Color(0xFF1E1E1E),
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (loading)
                const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              else
                Icon(icon, color: Colors.white, size: 18),
              const SizedBox(width: 8),
              Text(
                label,
                style: context.textTheme.labelLarge?.copyWith(
                  color: Colors.white,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
