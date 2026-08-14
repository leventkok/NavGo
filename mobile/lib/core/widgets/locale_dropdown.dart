import 'package:flutter/material.dart';
import 'package:navgo_mobile/i18n/strings.g.dart';

/// Compact language picker: flag + locale code (🇹🇷 TR, 🇬🇧 EN, …).
/// Scales with [AppLocale.values] when new languages are added via slang.
class LocaleCodeDropdown extends StatelessWidget {
  const LocaleCodeDropdown({
    super.key,
    required this.value,
    required this.onChanged,
  });

  final AppLocale value;
  final ValueChanged<AppLocale> onChanged;

  static String _flagFor(AppLocale locale) => switch (locale) {
        AppLocale.tr => '🇹🇷',
        AppLocale.en => '🇬🇧',
        AppLocale.ru => '🇷🇺',
      };

  static Widget _label(BuildContext context, AppLocale locale) {
    final style = Theme.of(context).textTheme.titleMedium;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(_flagFor(locale), style: style?.copyWith(fontSize: 18)),
        const SizedBox(width: 8),
        Text(locale.languageCode.toUpperCase(), style: style),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return DropdownButtonHideUnderline(
      child: DropdownButton<AppLocale>(
        value: value,
        isDense: true,
        borderRadius: BorderRadius.circular(12),
        selectedItemBuilder: (context) => [
          for (final locale in AppLocale.values)
            Align(
              alignment: Alignment.centerRight,
              child: _label(context, locale),
            ),
        ],
        items: [
          for (final locale in AppLocale.values)
            DropdownMenuItem(
              value: locale,
              child: _label(context, locale),
            ),
        ],
        onChanged: (next) {
          if (next != null) onChanged(next);
        },
      ),
    );
  }
}
