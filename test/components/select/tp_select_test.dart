import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import '../../support/tp_test_widgets.dart';
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

  group('TpSelect error state', () {
    Color triggerBorderColor(WidgetTester tester, ColorScheme scheme) {
      final box = tester.widget<Container>(
        find
            .descendant(
              of: find.byType(GestureDetector),
              matching: find.byType(Container),
            )
            .first,
      );
      final decoration = box.decoration! as BoxDecoration;
      return (decoration.border! as Border).top.color;
    }

    testWidgets('hasError draws the error-colored trigger border', (
      tester,
    ) async {
      final scheme = ColorScheme.fromSeed(seedColor: Colors.orange);
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(colorScheme: scheme, useMaterial3: true),
          home: TpTheme(
            data: TpThemeData.fromColorScheme(scheme, scale: 1.0),
            child: Scaffold(
              body: TpSelect<String>(
                items: const ['alpha', 'beta'],
                itemLabel: (item) => item,
                hasError: true,
                onChanged: (_) {},
              ),
            ),
          ),
        ),
      );

      expect(triggerBorderColor(tester, scheme), scheme.error);
    });

    testWidgets('default trigger border is not the error color', (
      tester,
    ) async {
      final scheme = ColorScheme.fromSeed(seedColor: Colors.orange);
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(colorScheme: scheme, useMaterial3: true),
          home: TpTheme(
            data: TpThemeData.fromColorScheme(scheme, scale: 1.0),
            child: Scaffold(
              body: TpSelect<String>(
                items: const ['alpha', 'beta'],
                itemLabel: (item) => item,
                onChanged: (_) {},
              ),
            ),
          ),
        ),
      );

      expect(triggerBorderColor(tester, scheme), isNot(scheme.error));
    });
  });

  group('TpSelect long labels', () {
    const longName = 'deepseek-v4-pro[1m]-a-very-long-model-name-overflow';

    testWidgets('closed header shows a Tooltip with the full item label', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(
          SizedBox(
            width: 160,
            child: TpSelect<String>(
              items: const [longName],
              initialItem: longName,
              searchable: false,
              itemLabel: (item) => item,
              onChanged: (_) {},
            ),
          ),
        ),
      );

      final tooltip = find.byType(Tooltip);
      expect(tooltip, findsOneWidget);
      expect(tester.widget<Tooltip>(tooltip).message, longName);
    });

    testWidgets('short header item does not show a Tooltip', (tester) async {
      await tester.pumpWidget(
        _wrap(
          SizedBox(
            width: 240,
            child: TpSelect<String>(
              items: const ['sonnet'],
              initialItem: 'sonnet',
              searchable: false,
              itemLabel: (item) => item,
              onChanged: (_) {},
            ),
          ),
        ),
      );

      expect(find.byType(Tooltip), findsNothing);
    });

    testWidgets('long open-menu row shows a Tooltip with the full label', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(
          SizedBox(
            width: 160,
            child: TpSelect<String>(
              items: const ['sonnet', longName],
              searchable: false,
              itemLabel: (item) => item,
              onChanged: (_) {},
            ),
          ),
        ),
      );

      await tester.tap(find.byType(TpSelect<String>));
      await tester.pumpAndSettle();

      expect(find.byType(Tooltip), findsWidgets);
      final messages = tester
          .widgetList<Tooltip>(find.byType(Tooltip))
          .map((t) => t.message)
          .toList();
      expect(messages, contains(longName));
    });
  });
}
