import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_ui/shared_ui.dart';

Widget _wrap(Widget child) {
  final scheme = ColorScheme.fromSeed(seedColor: Colors.orange);
  return MaterialApp(
    theme: ThemeData(colorScheme: scheme, useMaterial3: true),
    home: TpTheme(
      data: TpThemeData.fromColorScheme(scheme, scale: 1.0),
      child: Scaffold(body: Center(child: SizedBox(width: 280, child: child))),
    ),
  );
}

Finder _suggestionText(String text) {
  return find.descendant(
    of: find.byType(TpSuggestionList<String>),
    matching: find.text(text),
  );
}

void main() {
  testWidgets('opens on focus and filters by typing', (tester) async {
    String? selected;
    await tester.pumpWidget(
      _wrap(
        TpCombobox<String>(
          items: const ['alpha', 'beta', 'gamma'],
          itemLabel: (i) => i,
          onChanged: (v) => selected = v,
        ),
      ),
    );

    await tester.tap(find.byType(TpInput));
    await tester.pumpAndSettle();
    expect(find.text('beta'), findsOneWidget);

    await tester.enterText(find.byType(TpInput), 'bet');
    await tester.pumpAndSettle();
    expect(find.text('beta'), findsOneWidget);
    expect(find.text('gamma'), findsNothing);

    await tester.tap(find.text('beta'));
    await tester.pumpAndSettle();
    expect(selected, 'beta');
    expect(find.byType(TpInput), findsOneWidget);
    expect(
      tester.widget<TextField>(find.byType(TextField)).controller!.text,
      'beta',
    );
  });

  testWidgets('shows emptyText when nothing matches', (tester) async {
    await tester.pumpWidget(
      _wrap(
        TpCombobox<String>(
          items: const ['alpha', 'beta'],
          itemLabel: (i) => i,
          emptyText: 'Nothing here',
          onChanged: (_) {},
        ),
      ),
    );
    await tester.tap(find.byType(TpInput));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TpInput), 'zzz');
    await tester.pumpAndSettle();
    expect(find.text('Nothing here'), findsOneWidget);
  });

  testWidgets('clearable clears value', (tester) async {
    String? selected = 'alpha';
    await tester.pumpWidget(
      _wrap(
        StatefulBuilder(
          builder: (context, setState) {
            return TpCombobox<String>(
              items: const ['alpha', 'beta'],
              value: selected,
              clearable: true,
              itemLabel: (i) => i,
              onChanged: (v) => setState(() => selected = v),
            );
          },
        ),
      ),
    );
    await tester.tap(find.byIcon(Icons.clear));
    await tester.pumpAndSettle();
    expect(selected, isNull);
  });

  testWidgets('Enter selects highlighted; Escape closes', (tester) async {
    String? selected;
    await tester.pumpWidget(
      _wrap(
        TpCombobox<String>(
          items: const ['alpha', 'beta', 'gamma'],
          itemLabel: (i) => i,
          autoHighlight: true,
          onChanged: (v) => selected = v,
        ),
      ),
    );
    await tester.tap(find.byType(TpInput));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TpInput), 'a');
    await tester.pumpAndSettle();

    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();
    expect(selected, isNotNull);

    // Re-open then Escape
    await tester.tap(find.byType(TpInput));
    await tester.pumpAndSettle();
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();
    expect(find.text('gamma'), findsNothing);
  });

  testWidgets('value syncs display text when not drafting', (tester) async {
    await tester.pumpWidget(
      _wrap(
        TpCombobox<String>(
          items: const ['alpha', 'beta'],
          value: 'alpha',
          itemLabel: (i) => i,
          onChanged: (_) {},
        ),
      ),
    );
    expect(find.text('alpha'), findsWidgets);
    await tester.pumpWidget(
      _wrap(
        TpCombobox<String>(
          items: const ['alpha', 'beta'],
          value: 'beta',
          itemLabel: (i) => i,
          onChanged: (_) {},
        ),
      ),
    );
    await tester.pump();
    expect(find.text('beta'), findsWidgets);
  });

  testWidgets('reopen with committed value shows all items', (tester) async {
    await tester.pumpWidget(
      _wrap(
        TpCombobox<String>(
          items: const ['alpha', 'beta', 'gamma'],
          value: 'beta',
          itemLabel: (i) => i,
          onChanged: (_) {},
        ),
      ),
    );
    await tester.tap(find.byType(TpInput));
    await tester.pumpAndSettle();
    expect(_suggestionText('alpha'), findsOneWidget);
    expect(_suggestionText('beta'), findsOneWidget);
    expect(_suggestionText('gamma'), findsOneWidget);

    await tester.enterText(find.byType(TpInput), 'gam');
    await tester.pumpAndSettle();
    expect(_suggestionText('gamma'), findsOneWidget);
    expect(_suggestionText('alpha'), findsNothing);
  });

  testWidgets('blur without select reconverges to value label', (tester) async {
    await tester.pumpWidget(
      _wrap(
        TpCombobox<String>(
          items: const ['alpha', 'beta'],
          value: 'alpha',
          itemLabel: (i) => i,
          onChanged: (_) {},
        ),
      ),
    );
    await tester.tap(find.byType(TpInput));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TpInput), 'bet');
    await tester.pumpAndSettle();
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();
    expect(
      tester.widget<TextField>(find.byType(TextField)).controller!.text,
      'alpha',
    );
  });

  testWidgets('blur closes suggestions and reconverges draft text', (tester) async {
    await tester.pumpWidget(
      _wrap(
        TpCombobox<String>(
          items: const ['alpha', 'beta'],
          value: 'alpha',
          itemLabel: (i) => i,
          onChanged: (_) {},
        ),
      ),
    );

    await tester.tap(find.byType(TpInput));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TpInput), 'bet');
    await tester.pumpAndSettle();
    expect(_suggestionText('beta'), findsOneWidget);

    FocusManager.instance.primaryFocus?.unfocus();
    await tester.pumpAndSettle();

    expect(_suggestionText('beta'), findsNothing);
    expect(
      tester
          .widget<TextField>(
            find.descendant(
              of: find.byType(TpInput),
              matching: find.byType(TextField),
            ),
          )
          .controller!
          .text,
      'alpha',
    );
  });
}
