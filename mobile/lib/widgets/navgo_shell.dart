import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:navgo_mobile/core/extensions/core_extensions.dart';
import 'package:navgo_mobile/core/themes/app_colors.dart';
import 'package:navgo_mobile/i18n/strings.g.dart';

enum NavGoTab { plan, trips, explore, profile }

class NavGoShell extends StatelessWidget {
  const NavGoShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: context.cBackground,
      child: Column(
        children: [
          Expanded(child: navigationShell),
          _NavGoTabBar(
            currentIndex: navigationShell.currentIndex,
            onSelect: (index) {
              navigationShell.goBranch(
                index,
                initialLocation: index == navigationShell.currentIndex,
              );
            },
          ),
        ],
      ),
    );
  }
}

class _NavGoTabBar extends StatelessWidget {
  const _NavGoTabBar({
    required this.currentIndex,
    required this.onSelect,
  });

  final int currentIndex;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final viewPadding = MediaQueryData.fromView(View.of(context)).viewPadding;
    var bottom = viewPadding.bottom;
    if (bottom <= 0) {
      bottom = defaultTargetPlatform == TargetPlatform.iOS ? 28.0 : 10.0;
    }

    final items = <(IconData, String)>[
      (Icons.map_outlined, t.shell.tabPlan),
      (Icons.luggage_outlined, t.shell.tabTrips),
      (Icons.explore_outlined, t.shell.tabExplore),
      (Icons.person_outline, t.shell.tabProfile),
    ];

    return ColoredBox(
      color: AppColors.surface,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const ColoredBox(
            color: AppColors.surfaceMuted,
            child: SizedBox(height: 1, width: double.infinity),
          ),
          SizedBox(
            height: 58,
            child: Row(
              children: [
                for (var i = 0; i < items.length; i++)
                  Expanded(
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () => onSelect(i),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            items[i].$1,
                            size: 22,
                            color: i == currentIndex
                                ? AppColors.primary
                                : AppColors.neutral,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            items[i].$2,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: i == currentIndex
                                  ? FontWeight.w700
                                  : FontWeight.w500,
                              color: i == currentIndex
                                  ? AppColors.secondary
                                  : AppColors.neutral,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
          SizedBox(height: bottom > 0 ? bottom : 10),
        ],
      ),
    );
  }
}
