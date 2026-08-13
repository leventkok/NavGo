import 'package:flutter/material.dart';
import 'package:navgo_mobile/data/location_service.dart';

enum LocationPromptChoice { dismiss, retry, manual }

/// Permission / location services — settings, retry, or manual city entry.
Future<LocationPromptChoice> showLocationRequiredDialog(
  BuildContext context, {
  required LocationFailure? failure,
}) async {
  final result = await showDialog<LocationPromptChoice>(
    context: context,
    barrierDismissible: false,
    builder: (ctx) => AlertDialog(
      title: const Text('Konum gerekli'),
      content: Text(
        LocationService.settingsRequiredMessage(failure),
        style: Theme.of(ctx).textTheme.bodyMedium,
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, LocationPromptChoice.dismiss),
          child: const Text('Vazgeç'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(ctx, LocationPromptChoice.manual),
          child: const Text('Manuel gir'),
        ),
        TextButton(
          onPressed: () async {
            await LocationService.openSettingsForFailure(failure);
          },
          child: const Text('Ayarlara git'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(ctx, LocationPromptChoice.retry),
          child: const Text('Tekrar dene'),
        ),
      ],
    ),
  );
  return result ?? LocationPromptChoice.dismiss;
}

/// GPS / resolve failed — retry or type city manually.
Future<LocationPromptChoice> showLocationRetryDialog(
  BuildContext context, {
  required LocationFailure? failure,
}) async {
  final result = await showDialog<LocationPromptChoice>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Konum alınamadı'),
      content: Text(
        LocationService.retryMessage(failure),
        style: Theme.of(ctx).textTheme.bodyMedium,
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, LocationPromptChoice.dismiss),
          child: const Text('Vazgeç'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(ctx, LocationPromptChoice.manual),
          child: const Text('Manuel gir'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(ctx, LocationPromptChoice.retry),
          child: const Text('Tekrar dene'),
        ),
      ],
    ),
  );
  return result ?? LocationPromptChoice.dismiss;
}

/// Manual city / district entry.
Future<String?> showManualAreaDialog(
  BuildContext context, {
  String initialValue = '',
  LocationFailure? failure,
}) {
  return showDialog<String>(
    context: context,
    builder: (ctx) => _ManualAreaDialog(
      initialValue: initialValue,
      failure: failure,
    ),
  );
}

Future<String?> _readManualArea(
  BuildContext context, {
  required LocationFailure? failure,
  required String initialValue,
}) async {
  final manual = await showManualAreaDialog(
    context,
    initialValue: initialValue,
    failure: failure,
  );
  final trimmed = manual?.trim();
  return (trimmed == null || trimmed.isEmpty) ? null : trimmed;
}

/// Handles a failed location resolve: settings, retry, or manual entry.
Future<String?> promptLocationAreaAfterFailure(
  BuildContext context, {
  required LocationFailure? failure,
  required Future<LocationResolveOutcome> Function() resolveAgain,
  String initialValue = '',
}) async {
  if (!context.mounted) return null;

  final LocationPromptChoice choice;
  if (LocationService.requiresSettings(failure)) {
    choice = await showLocationRequiredDialog(context, failure: failure);
  } else {
    choice = await showLocationRetryDialog(context, failure: failure);
  }

  if (!context.mounted) return null;

  switch (choice) {
    case LocationPromptChoice.dismiss:
      return null;
    case LocationPromptChoice.manual:
      return _readManualArea(
        context,
        failure: failure,
        initialValue: initialValue,
      );
    case LocationPromptChoice.retry:
      final outcome = await resolveAgain();
      if (outcome.isOk && outcome.result!.area.isNotEmpty) {
        return outcome.result!.area;
      }
      if (!context.mounted) return null;
      return promptLocationAreaAfterFailure(
        context,
        failure: outcome.failure,
        resolveAgain: resolveAgain,
        initialValue: initialValue,
      );
  }
}

class _ManualAreaDialog extends StatefulWidget {
  const _ManualAreaDialog({
    required this.initialValue,
    required this.failure,
  });

  final String initialValue;
  final LocationFailure? failure;

  @override
  State<_ManualAreaDialog> createState() => _ManualAreaDialogState();
}

class _ManualAreaDialogState extends State<_ManualAreaDialog> {
  late final TextEditingController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(text: widget.initialValue);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Şehir veya ilçe'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            LocationService.manualEntryMessage(widget.failure),
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _ctrl,
            autofocus: true,
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(
              hintText: 'Örn. Antalya, Muratpaşa',
            ),
            onSubmitted: (v) => Navigator.pop(context, v),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Vazgeç'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context, _ctrl.text),
          child: const Text('Tamam'),
        ),
      ],
    );
  }
}
