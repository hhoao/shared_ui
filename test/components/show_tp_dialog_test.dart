import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_ui/shared_ui.dart';

void main() {
  // Pumps a host page with a button that opens the dialog under test and
  // records the popped result into [results].
  Future<void> pumpHost(
    WidgetTester tester, {
    required List<Object?> results,
    bool barrierDismissible = true,
    bool? escapeDismissible,
    WidgetBuilder? builder,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        home: TpTheme(
          data: TpThemeData.fromColorScheme(
            ColorScheme.fromSeed(seedColor: Colors.orange),
            scale: 1.0,
          ),
          child: Builder(
            builder: (context) {
              return Scaffold(
                body: Center(
                  child: TextButton(
                    onPressed: () {
                      showTpDialog<String?>(
                        context: context,
                        barrierDismissible: barrierDismissible,
                        escapeDismissible: escapeDismissible,
                        builder:
                            builder ??
                            (ctx) => const TpDialog(
                              child: TpDialogHeader(title: 'Escape target'),
                            ),
                      ).then((value) {
                        results.add(value);
                      });
                    },
                    child: const Text('Open'),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
  }

  testWidgets(
    'ESC pops when escapeDismissible is true despite non-dismissible barrier',
    (tester) async {
      final results = <Object?>[];
      await pumpHost(
        tester,
        results: results,
        barrierDismissible: false,
        escapeDismissible: true,
      );
      expect(find.text('Escape target'), findsOneWidget);

      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();

      expect(find.text('Escape target'), findsNothing);
      expect(results, [null]);
    },
  );

  testWidgets('ESC does nothing when escapeDismissible is false', (
    tester,
  ) async {
    final results = <Object?>[];
    await pumpHost(
      tester,
      results: results,
      barrierDismissible: false,
      escapeDismissible: false,
    );
    expect(find.text('Escape target'), findsOneWidget);

    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();

    expect(find.text('Escape target'), findsOneWidget);
    expect(results, isEmpty);
  });

  testWidgets('ESC stays blocked by default when barrierDismissible is false', (
    tester,
  ) async {
    final results = <Object?>[];
    await pumpHost(tester, results: results, barrierDismissible: false);

    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();
    expect(find.text('Escape target'), findsOneWidget);
    expect(results, isEmpty);
  });

  testWidgets('ESC works by default when barrierDismissible is true', (
    tester,
  ) async {
    final results = <Object?>[];
    await pumpHost(tester, results: results);

    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();
    expect(find.text('Escape target'), findsNothing);
    expect(results, [null]);
  });

  testWidgets(
    'ESC reaches the dialog wrapper while a TextField inside has focus',
    (tester) async {
      final results = <Object?>[];
      await pumpHost(
        tester,
        results: results,
        barrierDismissible: false,
        escapeDismissible: true,
        builder: (ctx) => TpDialog(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const TpDialogHeader(title: 'Escape target'),
              TextField(
                controller: TextEditingController(),
                autofocus: true,
                onChanged: (_) {},
              ),
            ],
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byType(EditableText), findsOneWidget);
      expect(FocusManager.instance.primaryFocus?.context, isNotNull);
      expect(
        FocusManager.instance.primaryFocus!.context!
            .findAncestorStateOfType<EditableTextState>(),
        isNotNull,
      );

      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();

      expect(find.text('Escape target'), findsNothing);
      expect(results, [null]);
    },
  );
}
