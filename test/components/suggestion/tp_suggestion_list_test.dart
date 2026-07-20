import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_ui/src/components/suggestion/tp_suggestion_list.dart';
import 'package:shared_ui/shared_ui.dart';

Widget _wrap(Widget child) {
  final scheme = ColorScheme.fromSeed(seedColor: Colors.orange);
  return MaterialApp(
    theme: ThemeData(colorScheme: scheme, useMaterial3: true),
    home: TpTheme(
      data: TpThemeData.fromColorScheme(scheme, scale: 1.0),
      child: Scaffold(body: SizedBox(width: 280, height: 260, child: child)),
    ),
  );
}

void main() {
  testWidgets('renders item labels', (tester) async {
    await tester.pumpWidget(
      _wrap(
        TpSuggestionList<String>(
          items: const ['alpha', 'beta'],
          itemLabel: (i) => i,
          highlightedIndex: 0,
          onItemSelected: (_) {},
        ),
      ),
    );
    expect(find.text('alpha'), findsOneWidget);
    expect(find.text('beta'), findsOneWidget);
  });

  testWidgets('shows emptyText when items empty', (tester) async {
    await tester.pumpWidget(
      _wrap(
        TpSuggestionList<String>(
          items: const [],
          itemLabel: (i) => i,
          emptyText: 'No matches',
          highlightedIndex: -1,
          onItemSelected: (_) {},
        ),
      ),
    );
    expect(find.text('No matches'), findsOneWidget);
  });

  testWidgets('tap calls onItemSelected', (tester) async {
    String? selected;
    await tester.pumpWidget(
      _wrap(
        TpSuggestionList<String>(
          items: const ['alpha', 'beta'],
          itemLabel: (i) => i,
          highlightedIndex: 0,
          onItemSelected: (v) => selected = v,
        ),
      ),
    );
    await tester.tap(find.text('beta'));
    await tester.pump();
    expect(selected, 'beta');
  });

  testWidgets('highlightedIndex marks the highlighted row selected visually', (
    tester,
  ) async {
    await tester.pumpWidget(
      _wrap(
        TpSuggestionList<String>(
          items: const ['alpha', 'beta'],
          itemLabel: (i) => i,
          highlightedIndex: 1,
          onItemSelected: (_) {},
        ),
      ),
    );
    final buttons = tester.widgetList<TpSelectMenuItemButton>(
      find.byType(TpSelectMenuItemButton),
    );
    expect(buttons.elementAt(1).isSelected, isTrue);
    expect(buttons.elementAt(0).isSelected, isFalse);
  });

  testWidgets('uses custom highlight and selected colors when provided', (
    tester,
  ) async {
    const customHighlight = Color(0xFF111111);
    const customSelected = Color(0xFF222222);
    await tester.pumpWidget(
      _wrap(
        TpSuggestionList<String>(
          items: const ['alpha', 'beta'],
          itemLabel: (i) => i,
          highlightedIndex: 0,
          highlightColor: customHighlight,
          selectedColor: customSelected,
          onItemSelected: (_) {},
        ),
      ),
    );
    final buttons = tester.widgetList<TpSelectMenuItemButton>(
      find.byType(TpSelectMenuItemButton),
    );
    expect(buttons.first.highlightColor, customHighlight);
    expect(buttons.first.selectedColor, customSelected);
  });
}
