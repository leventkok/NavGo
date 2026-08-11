import 'package:flutter/material.dart';
import 'package:navgo_mobile/core/themes/app_colors.dart';

extension BuildContextX on BuildContext {
  ThemeData get theme => Theme.of(this);
  TextTheme get textTheme => theme.textTheme;
  ColorScheme get colors => theme.colorScheme;

  Color get cPrimary => AppColors.primary;
  Color get cSecondary => AppColors.secondary;
  Color get cTertiary => AppColors.tertiary;
  Color get cNeutral => AppColors.neutral;
  Color get cBackground => AppColors.background;
  Color get cSurface => AppColors.surface;
  Color get cSurfaceMuted => AppColors.surfaceMuted;

  EdgeInsets get paddingNormal => const EdgeInsets.all(20);
  BorderRadius get normalBorderRadius => BorderRadius.circular(16);
  BorderRadius get largeBorderRadius => BorderRadius.circular(24);

  SizedBox get sizedHeightBoxNormal => const SizedBox(height: 16);
  SizedBox get sizedHeightBoxMedium => const SizedBox(height: 24);
}
