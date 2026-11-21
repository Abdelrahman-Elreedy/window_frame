import 'package:flutter/material.dart';

import 'home_page.dart';
import 'simple_example_page.dart';

/// The first page of the example. It selects no title bar controller, so it
/// shows the DEFAULT bar of main.dart (logo, project name, free area, actions).
class ExampleChooserPage extends StatelessWidget {
  const ExampleChooserPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('window_frame examples')),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Text(
              'Choose an example',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (BuildContext _) => const SimpleExamplePage(),
                ),
              ),
              icon: const Icon(Icons.bolt),
              label: const Text('Minimal example'),
            ),
            const SizedBox(height: 8),
            FilledButton.icon(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (BuildContext _) => const HomePage(),
                ),
              ),
              icon: const Icon(Icons.explore),
              label: const Text('Guided tour (every feature)'),
            ),
          ],
        ),
      ),
    );
  }
}
