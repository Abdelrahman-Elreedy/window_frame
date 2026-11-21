import 'dart:async';

import 'package:flutter/material.dart';
import 'package:window_frame/window_frame.dart';

import 'demo_page.dart';

/// A plain Dart service: it knows NO widget and NO BuildContext, and still
/// drives the title bar through the controller.
class SyncService {
  final ValueNotifier<double> progress = ValueNotifier<double>(0);
  Timer? _timer;
  int _lastTitlePercent = -1;

  /// About 1.2 seconds. The progress bar moves smoothly (it listens to
  /// [progress] by itself), while the title text changes every 10 %: the whole
  /// title bar is rebuilt only when the controller changes.
  void start() {
    _timer?.cancel();
    progress.value = 0;
    _lastTitlePercent = -1;
    _timer = Timer.periodic(const Duration(milliseconds: 25), (Timer timer) {
      progress.value = (progress.value + 0.02).clamp(0.0, 1.0).toDouble();
      if (progress.value >= 1.0) {
        timer.cancel();
        liveStatusController.setTitle('Sync complete');
        return;
      }
      final int percent = (progress.value * 100).round() ~/ 10 * 10;
      if (percent != _lastTitlePercent) {
        _lastTitlePercent = percent;
        liveStatusController.setTitle('Syncing... $percent%');
      }
    });
  }

  void stop() => _timer?.cancel();
}

final SyncService syncService = SyncService();

final TitleBarController liveStatusController = TitleBarController(
  initialContent: TitleBarContent(
    title: 'Sync: idle',
    contentBuilder: (BuildContext context) => Center(
      // A progress bar only DRAWS something, so by default it counts as empty
      // space of the bar (drag, double-click). WindowNoDragArea keeps it out.
      child: WindowNoDragArea(
        child: SizedBox(
          width: 220,
          child: ValueListenableBuilder<double>(
            valueListenable: syncService.progress,
            builder: (BuildContext context, double value, Widget? _) =>
                LinearProgressIndicator(value: value),
          ),
        ),
      ),
    ),
  ),
);

class LiveStatusDemo extends StatefulWidget {
  const LiveStatusDemo({super.key});

  @override
  State<LiveStatusDemo> createState() => _LiveStatusDemoState();
}

class _LiveStatusDemoState extends State<LiveStatusDemo> {
  @override
  void dispose() {
    syncService.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DemoPage(
      title: 'Update the bar from a service',
      explanation:
          'The title bar follows its controller, so ANY code can '
          'change it: a Bloc, a repository, a timer. Press the button: a '
          'plain Dart class (no widgets, no context) updates the title and '
          'the progress bar in the title bar. The bar is wrapped in a '
          'WindowNoDragArea: dragging or double-clicking it does nothing to '
          'the window.',
      codeSample: r'''// inside a normal Dart class:
liveStatusController.setTitle('Syncing... 40%');''',
      child: FilledButton.icon(
        onPressed: syncService.start,
        icon: const Icon(Icons.sync),
        label: const Text('Start sync'),
      ),
    ).withTitleBarController(liveStatusController);
  }
}
