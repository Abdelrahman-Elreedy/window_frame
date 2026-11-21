import 'dart:async';

import 'package:flutter/material.dart';

/// Runs before the window closes (caption button, Alt+F4, taskbar...).
/// Return true to close, false to stay.
Future<bool> confirmClose(BuildContext context) async {
  final bool? confirmed = await showDialog<bool>(
    context: context,
    builder: (BuildContext dialogContext) => AlertDialog(
      title: const Text('Close the app?'),
      content: const Text('Anything not saved will be lost.'),
      actions: <Widget>[
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(dialogContext).pop(true),
          child: const Text('Close'),
        ),
      ],
    ),
  );
  if (confirmed != true) return false;
  if (!context.mounted) return true;

  // A fake "saving" step: a progress dialog for one second, then close.
  unawaited(
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext _) => const AlertDialog(
        content: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            CircularProgressIndicator(),
            SizedBox(width: 16),
            Text('Saving...'),
          ],
        ),
      ),
    ),
  );
  await Future<void>.delayed(const Duration(seconds: 1));
  if (context.mounted) Navigator.of(context).pop();
  return true;
}
