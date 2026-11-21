import 'package:flutter/material.dart';

import 'example_state.dart';

/// Widgets that need an Overlay / Navigator (Tooltip, showDialog, a popup menu),
/// living in the title bar. They work because the bar is built inside the
/// window's Navigator.
class BarActions extends StatelessWidget {
  const BarActions({super.key});

  @override
  Widget build(BuildContext context) {
    // This `context` belongs to the bar, so showDialog works.
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        IconButton(
          tooltip: 'Tooltip in the bar: toggle dark mode',
          icon: const Icon(Icons.dark_mode),
          iconSize: 16,
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints.tightFor(width: 40),
          onPressed: () => themeMode.value = themeMode.value == ThemeMode.dark
              ? ThemeMode.light
              : ThemeMode.dark,
        ),
        IconButton(
          tooltip: 'showDialog from the bar',
          icon: const Icon(Icons.info_outline),
          iconSize: 16,
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints.tightFor(width: 40),
          onPressed: () => showDialog<void>(
            context: context,
            builder: (BuildContext _) => const AlertDialog(
              title: Text('Dialog opened from the title bar'),
            ),
          ),
        ),
        PopupMenuButton<String>(
          tooltip: 'PopupMenuButton in the bar',
          iconSize: 16,
          padding: EdgeInsets.zero,
          position: PopupMenuPosition.under,
          itemBuilder: (BuildContext context) => const <PopupMenuEntry<String>>[
            PopupMenuItem<String>(value: 'a', child: Text('Item A')),
            PopupMenuItem<String>(value: 'b', child: Text('Item B')),
          ],
        ),
      ],
    );
  }
}
