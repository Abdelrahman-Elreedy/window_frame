import 'package:flutter/material.dart';

/// The common layout of every demo: a title, a short explanation, an optional
/// code sample, and the interactive part.
class DemoPage extends StatelessWidget {
  const DemoPage({
    super.key,
    required this.title,
    required this.explanation,
    required this.child,
    this.codeSample,
  });

  final String title;
  final String explanation;
  final String? codeSample;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: <Widget>[
          Text(explanation, style: Theme.of(context).textTheme.bodyLarge),
          if (codeSample != null) ...<Widget>[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: scheme.onSurface.withAlpha(20),
                borderRadius: BorderRadius.circular(8),
              ),
              child: SelectableText(
                codeSample!,
                style: const TextStyle(fontFamily: 'Consolas', fontSize: 13),
              ),
            ),
          ],
          const SizedBox(height: 24),
          child,
        ],
      ),
    );
  }
}
