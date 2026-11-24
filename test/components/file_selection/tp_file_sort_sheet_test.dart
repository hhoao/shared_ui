import 'package:flutter/material.dart';
import 'package:shared_ui/shared_ui.dart';
import 'package:shared_ui/src/components/file_selection/ui/widgets/tp_file_sort_sheet.dart';

import '../../support/tp_test_widgets.dart';

Widget _wrap(Widget child) {
  return TpTheme(
    data: TpThemeData.fromColorScheme(
      ColorScheme.fromSeed(seedColor: const Color(0xFFD4A06A)),
      scale: 1.0,
    ),
    child: MaterialApp(home: Scaffold(body: child)),
  );
}

class _SortResult {
  String? type;
  bool? ascending;
}

Future<void> _openSheet(
  WidgetTester tester, {
  required TpFileSelectionStrings strings,
  required List<TpFileSortOption> options,
  required String currentSortType,
  required bool currentAscending,
  required _SortResult result,
}) async {
  await tester.pumpWidget(
    _wrap(
      Builder(
        builder: (context) => TextButton(
          key: const Key('open_sheet'),
          onPressed: () {
            showTpFileSortSheet(
              context: context,
              strings: strings,
              currentSortType: currentSortType,
              currentAscending: currentAscending,
              options: options,
              onSelected: (type, {required ascending}) {
                result
                  ..type = type
                  ..ascending = ascending;
              },
            );
          },
          child: const Text('open'),
        ),
      ),
    ),
  );
  await tester.tap(find.byKey(const Key('open_sheet')));
  await tester.pumpAndSettle();
}

void main() {
  final strings = TpFileSelectionStrings.english();

  testWidgets('gallery sheet only offers the created-time option',
      (tester) async {
    await _openSheet(
      tester,
      strings: strings,
      options: [(id: 'date', label: strings.sortByCreatedTime)],
      currentSortType: 'date',
      currentAscending: false,
      result: _SortResult(),
    );

    expect(find.text(strings.sortByCreatedTime), findsOneWidget);
    expect(find.text(strings.sortByName), findsNothing);
    expect(find.text(strings.sortByFileSize), findsNothing);
    expect(find.text(strings.sortByFileType), findsNothing);
  });

  testWidgets('direction toggle applies to the chosen option', (tester) async {
    final result = _SortResult();
    await _openSheet(
      tester,
      strings: strings,
      options: [(id: 'date', label: strings.sortByCreatedTime)],
      currentSortType: 'date',
      currentAscending: false,
      result: result,
    );

    await tester.tap(find.byKey(const Key('tp_file_sort_ascending')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('tp_file_sort_option_date')));
    await tester.pumpAndSettle();

    expect(result.type, 'date');
    expect(result.ascending, isTrue);
  });

  testWidgets('tapping the current option keeps the selected direction',
      (tester) async {
    final result = _SortResult();
    await _openSheet(
      tester,
      strings: strings,
      options: [(id: 'date', label: strings.sortByCreatedTime)],
      currentSortType: 'date',
      currentAscending: false,
      result: result,
    );

    await tester.tap(find.byKey(const Key('tp_file_sort_option_date')));
    await tester.pumpAndSettle();

    expect(result.type, 'date');
    expect(result.ascending, isFalse);
  });
}