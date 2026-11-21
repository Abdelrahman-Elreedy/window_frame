import 'package:flutter/material.dart';
import 'package:window_frame/window_frame.dart';

import 'demo_page.dart';

const List<String> _tabNames = <String>['Overview', 'Reports', 'Settings'];

final ValueNotifier<int> _selectedTab = ValueNotifier<int>(0);

/// Tabs living inside the title bar, like in a browser or an IDE.
final TitleBarController _tabsController = TitleBarController(
  initialContent: TitleBarContent(
    leadingBuilder: (BuildContext context) => const Icon(Icons.dashboard),
    title: '', // hide the title: the tabs are enough
    contentBuilder: (BuildContext context) => ValueListenableBuilder<int>(
      valueListenable: _selectedTab,
      builder: (BuildContext context, int selected, Widget? _) => Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          for (int index = 0; index < _tabNames.length; index++)
            _BarTab(
              label: _tabNames[index],
              isSelected: index == selected,
              onTap: () => _selectedTab.value = index,
            ),
        ],
      ),
    ),
  ),
);

class TabsDemo extends StatelessWidget {
  const TabsDemo({super.key});

  @override
  Widget build(BuildContext context) {
    return DemoPage(
      title: 'Tabs in the title bar',
      explanation:
          'The free area of the bar (contentBuilder) can hold any '
          'widget. Here: tabs. The title is hidden with title: \'\'. Click '
          'a tab (even twice, fast): tabs are never delayed and never '
          'maximize the window. Double-click the EMPTY part of the bar: '
          'that maximizes it. Drag the empty part: the window moves.',
      codeSample: r'''TitleBarContent(
  title: '',                       // no title text
  contentBuilder: (context) => Row(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [ /* your tabs */ ],
  ),
)''',
      child: ValueListenableBuilder<int>(
        valueListenable: _selectedTab,
        builder: (BuildContext context, int selected, Widget? _) => Text(
          'Selected tab: ${_tabNames[selected]}',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
      ),
    ).withTitleBarController(_tabsController);
  }
}

class _BarTab extends StatelessWidget {
  const _BarTab({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final Color accent = Theme.of(context).colorScheme.primary;
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: isSelected ? accent : Colors.transparent,
              width: 2,
            ),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}
