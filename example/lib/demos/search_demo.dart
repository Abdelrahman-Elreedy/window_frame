import 'package:flutter/material.dart';
import 'package:window_frame/window_frame.dart';

import 'demo_page.dart';

const List<String> _fruits = <String>[
  'Apple',
  'Apricot',
  'Banana',
  'Blueberry',
  'Cherry',
  'Date',
  'Fig',
  'Grape',
  'Guava',
  'Lemon',
  'Mango',
  'Orange',
  'Peach',
  'Pear',
  'Plum',
];

final ValueNotifier<String> _query = ValueNotifier<String>('');

/// A breadcrumb as the title (titleBuilder) and a search box in the free area.
final TitleBarController _searchController = TitleBarController(
  initialContent: TitleBarContent(
    titleBuilder: (BuildContext context) => const Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Text('Demos', style: TextStyle(fontSize: 12)),
        Icon(Icons.chevron_right, size: 14),
        Text('Search', style: TextStyle(fontSize: 12)),
      ],
    ),
    contentBuilder: (BuildContext context) => Center(
      child: SizedBox(
        width: 280,
        height: 26,
        child: TextField(
          onChanged: (String value) => _query.value = value,
          style: const TextStyle(fontSize: 12),
          decoration: InputDecoration(
            isDense: true,
            hintText: 'Search fruit...',
            prefixIcon: const Icon(Icons.search, size: 14),
            prefixIconConstraints: const BoxConstraints(
              minWidth: 28,
              minHeight: 26,
            ),
            contentPadding: EdgeInsets.zero,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(6)),
          ),
        ),
      ),
    ),
  ),
);

class SearchDemo extends StatefulWidget {
  const SearchDemo({super.key});

  @override
  State<SearchDemo> createState() => _SearchDemoState();
}

class _SearchDemoState extends State<SearchDemo> {
  @override
  void initState() {
    super.initState();
    _query.value = ''; // the box starts empty every time the page opens
  }

  @override
  Widget build(BuildContext context) {
    return DemoPage(
      title: 'A search box and a breadcrumb',
      explanation:
          'titleBuilder replaces the title text with ANY widget (a '
          'breadcrumb here), and contentBuilder holds a real TextField. Type '
          'in the title bar and the list below filters.',
      codeSample: r'''TitleBarContent(
  titleBuilder: (context) => const Text('Demos > Search'),
  contentBuilder: (context) => Center(child: SizedBox(
    width: 280,
    child: TextField(onChanged: (text) => query.value = text),
  )),
)''',
      child: ValueListenableBuilder<String>(
        valueListenable: _query,
        builder: (BuildContext context, String query, Widget? _) {
          final List<String> matches = _fruits
              .where(
                (String fruit) =>
                    fruit.toLowerCase().contains(query.toLowerCase()),
              )
              .toList();
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text('${matches.length} result(s) for "$query"'),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: <Widget>[
                  for (final String fruit in matches) Chip(label: Text(fruit)),
                ],
              ),
            ],
          );
        },
      ),
    ).withTitleBarController(_searchController);
  }
}
