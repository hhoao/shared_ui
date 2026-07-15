import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_ui/shared_ui.dart';

Widget _wrap(Widget child) {
  final scheme = ColorScheme.fromSeed(seedColor: Colors.orange);
  return MaterialApp(
    theme: ThemeData(colorScheme: scheme, useMaterial3: true),
    home: TpTheme(
      data: TpThemeData.fromColorScheme(scheme, scale: 1.0),
      child: Scaffold(body: child),
    ),
  );
}

void main() {
  group('TpSelect searchable', () {
    testWidgets('filters options by label', (tester) async {
      String? selected;
      await tester.pumpWidget(
        _wrap(
          TpSelect<String>(
            items: const ['alpha', 'beta', 'gamma'],
            initialItem: 'alpha',
            searchable: true,
            searchMinItems: 0,
            itemLabel: (item) => item,
            onChanged: (value) => selected = value,
          ),
        ),
      );

      await tester.tap(find.byType(TpSelect<String>));
      await tester.pumpAndSettle();

      expect(find.byType(TpSelectSearchField), findsOneWidget);
      expect(find.text('beta'), findsOneWidget);
      expect(find.text('gamma'), findsOneWidget);

      await tester.enterText(find.byType(TpSelectSearchField), 'bet');
      await tester.pump();

      expect(find.text('beta'), findsOneWidget);
      expect(find.text('gamma'), findsNothing);
      expect(
        find.descendant(
          of: find.byType(ListView),
          matching: find.text('alpha'),
        ),
        findsNothing,
      );

      await tester.tap(find.text('beta'));
      await tester.pumpAndSettle();

      expect(selected, 'beta');
      expect(find.byType(TpSelectSearchField), findsNothing);
    });

    testWidgets('shows empty state when nothing matches', (tester) async {
      await tester.pumpWidget(
        _wrap(
          TpSelect<String>(
            items: const ['alpha', 'beta'],
            searchable: true,
            searchMinItems: 0,
            emptySearchText: 'Nothing here',
            itemLabel: (item) => item,
            onChanged: (_) {},
          ),
        ),
      );

      await tester.tap(find.byType(TpSelect<String>));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TpSelectSearchField), 'zzz');
      await tester.pump();

      expect(find.text('Nothing here'), findsOneWidget);
      expect(find.text('alpha'), findsNothing);
      expect(find.text('beta'), findsNothing);
    });

    testWidgets('notifies onSearchChanged and clears on close', (tester) async {
      final queries = <String>[];
      await tester.pumpWidget(
        _wrap(
          TpSelect<String>(
            items: const ['alpha', 'beta'],
            searchable: true,
            searchMinItems: 0,
            itemLabel: (item) => item,
            onSearchChanged: queries.add,
            onChanged: (_) {},
          ),
        ),
      );

      await tester.tap(find.byType(TpSelect<String>));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TpSelectSearchField), 'a');
      await tester.pump();
      expect(queries, ['a']);

      await tester.tap(find.text('alpha'));
      await tester.pumpAndSettle();

      expect(queries.last, '');
    });

    testWidgets('filters unmatched options out of the list tree', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(
          TpSelect<String>(
            items: const ['alpha', 'beta', 'gamma'],
            searchable: true,
            searchMinItems: 0,
            itemLabel: (item) => item,
            onChanged: (_) {},
          ),
        ),
      );

      await tester.tap(find.byType(TpSelect<String>));
      await tester.pumpAndSettle();

      final search = find.byType(TpSelectSearchField);
      await tester.enterText(search, 'bet');
      await tester.pump();

      expect(find.text('beta'), findsOneWidget);
      expect(find.text('gamma'), findsNothing);
      expect(
        find.descendant(
          of: find.byType(ListView),
          matching: find.text('alpha'),
        ),
        findsNothing,
      );
      expect(
        tester.widget<TpSelectSearchField>(search).focusNode.hasFocus,
        isTrue,
      );
    });

    testWidgets('keeps search focus while typing filters', (tester) async {
      await tester.pumpWidget(
        _wrap(
          TpSelect<String>(
            items: List.generate(40, (i) => 'item-$i'),
            searchable: true,
            searchMinItems: 0,
            itemLabel: (item) => item,
            onChanged: (_) {},
          ),
        ),
      );

      await tester.tap(find.byType(TpSelect<String>));
      await tester.pumpAndSettle();

      final search = find.byType(TpSelectSearchField);
      await tester.enterText(search, 'item-1');
      await tester.pump();
      await tester.enterText(search, 'item-12');
      await tester.pump();

      expect(
        tester.widget<TpSelectSearchField>(search).focusNode.hasFocus,
        isTrue,
      );
      expect(
        find.descendant(
          of: find.byType(ListView),
          matching: find.text('item-12'),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: find.byType(ListView),
          matching: find.text('item-13'),
        ),
        findsNothing,
      );
    });

    testWidgets('hides search below searchMinItems threshold', (tester) async {
      await tester.pumpWidget(
        _wrap(
          TpSelect<String>(
            items: const ['one', 'two'],
            searchable: true,
            searchMinItems: 3,
            itemLabel: (item) => item,
            onChanged: (_) {},
          ),
        ),
      );

      await tester.tap(find.byType(TpSelect<String>));
      await tester.pumpAndSettle();

      expect(find.byType(TpSelectSearchField), findsNothing);
      expect(find.text('one'), findsOneWidget);
      expect(find.text('two'), findsOneWidget);
    });

    testWidgets('onHighlightChanged tracks hover and clears on close', (
      tester,
    ) async {
      final highlights = <String?>[];
      await tester.pumpWidget(
        _wrap(
          TpSelect<String>(
            items: const ['alpha', 'beta'],
            searchable: false,
            itemLabel: (item) => item,
            onChanged: (_) {},
            onHighlightChanged: highlights.add,
          ),
        ),
      );

      await tester.tap(find.byType(TpSelect<String>));
      await tester.pumpAndSettle();

      final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
      await gesture.addPointer(location: Offset.zero);
      addTearDown(gesture.removePointer);
      await gesture.moveTo(tester.getCenter(find.text('beta')));
      await tester.pumpAndSettle();

      expect(highlights, contains('beta'));

      await tester.tap(find.text('alpha'));
      await tester.pumpAndSettle();

      expect(highlights.last, isNull);
    });
  });

  group('TpSelect plain list height', () {
    testWidgets(
      'short menus shrink to content instead of default overlay height',
      (tester) async {
        await tester.pumpWidget(
          _wrap(
            TpSelect<String>(
              items: const ['adaptive', 'classicDark', 'highContrast'],
              initialItem: 'adaptive',
              itemLabel: (item) => item,
              onChanged: (_) {},
            ),
          ),
        );

        await tester.tap(find.byType(TpSelect<String>));
        await tester.pumpAndSettle();

        final list = tester.widget<ListView>(find.byType(ListView));
        expect(list.shrinkWrap, isTrue);

        final listSize = tester.getSize(find.byType(ListView));
        expect(
          listSize.height,
          lessThan(kTpSelectDefaultOverlayHeight),
          reason:
              '3-option menus must not expand to the 260px overlay max '
              '(leaves empty space under the last row)',
        );
      },
    );
  });
}
