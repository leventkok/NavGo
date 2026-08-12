import 'package:flutter/material.dart';
import 'package:navgo_mobile/data/location_service.dart';

/// Permission or location services must be enabled — no manual city entry.
Future<bool> showLocationRequiredDialog(
  BuildContext context, {
  required LocationFailure? failure,
}) async {
  final result = await showDialog<bool>(
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
          onPressed: () => Navigator.pop(ctx, false),
          child: const Text('Vazgeç'),
        ),
        TextButton(
          onPressed: () async {
            await LocationService.openSettingsForFailure(failure);
          },
          child: const Text('Ayarlara git'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(ctx, true),
          child: const Text('Tekrar dene'),
        ),
      ],
    ),
  );
  return result ?? false;
}

/// GPS timeout while permission is granted — retry only, no manual entry.
Future<bool> showLocationRetryDialog(
  BuildContext context, {
  required LocationFailure? failure,
}) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Konum alınamadı'),
      content: Text(
        LocationService.retryMessage(failure),
        style: Theme.of(ctx).textTheme.bodyMedium,
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: const Text('Vazgeç'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(ctx, true),
          child: const Text('Tekrar dene'),
        ),
      ],
    ),
  );
  return result ?? false;
}

/// Manual city entry when permission is OK but reverse geocoding / network failed.
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

/// Handles a failed location resolve: settings, retry, or manual entry.
Future<String?> promptLocationAreaAfterFailure(
  BuildContext context, {
  required LocationFailure? failure,
  required Future<LocationResolveOutcome> Function() resolveAgain,
  String initialValue = '',
}) async {
  if (!context.mounted) return null;

  if (LocationService.requiresSettings(failure)) {
    final retry = await showLocationRequiredDialog(context, failure: failure);
    if (!retry || !context.mounted) return null;
    final outcome = await resolveAgain();
    if (outcome.isOk && outcome.result!.area.isNotEmpty) {
      return outcome.result!.area;
    }
    return promptLocationAreaAfterFailure(
      context,
      failure: outcome.failure,
      resolveAgain: resolveAgain,
      initialValue: initialValue,
    );
  }

  if (LocationService.allowsManualEntry(failure)) {
    final manual = await showManualAreaDialog(
      context,
      initialValue: initialValue,
      failure: failure,
    );
    final trimmed = manual?.trim();
    return (trimmed == null || trimmed.isEmpty) ? null : trimmed;
  }

  final retry = await showLocationRetryDialog(context, failure: failure);
  if (!retry || !context.mounted) return null;
  final outcome = await resolveAgain();
  if (outcome.isOk && outcome.result!.area.isNotEmpty) {
    return outcome.result!.area;
  }
  return promptLocationAreaAfterFailure(
    context,
    failure: outcome.failure,
    resolveAgain: resolveAgain,
    initialValue: initialValue,
  );
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
