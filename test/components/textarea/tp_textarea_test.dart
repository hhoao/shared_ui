import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_ui/shared_ui.dart';

void main() {
  ThemeData themeWithTightInput() {
    final base = ThemeData.light();
    final control = TpControlMetrics.fromScale(1.0);
    return base.copyWith(
      inputDecorationTheme: buildTpOutlineInputDecorationTheme(
        colorScheme: base.colorScheme,
        textTheme: base.textTheme,
        control: control,
      ),
    );
  }

  Widget wrap(Widget child, {ThemeData? theme}) {
    return MaterialApp(
      theme: theme ?? themeWithTightInput(),
      home: Scaffold(
        body: TpTheme(
          data: TpThemeData.fromColorScheme(
            (theme ?? themeWithTightInput()).colorScheme,
            scale: 1.0,
          ),
          child: child,
        ),
      ),
    );
  }

  testWidgets('accepts typed text', (tester) async {
    await tester.pumpWidget(wrap(const TpTextarea()));
    await tester.enterText(find.byType(TextField), 'hello');
    expect(find.text('hello'), findsOneWidget);
  });

  testWidgets('respects enabled: false', (tester) async {
    await tester.pumpWidget(wrap(const TpTextarea(enabled: false)));
    final field = tester.widget<TextField>(find.byType(TextField));
    expect(field.enabled, isFalse);
  });

  testWidgets('expands and wraps — never maxLines: 1', (tester) async {
    await tester.pumpWidget(wrap(const TpTextarea(minHeight: 80)));
    final field = tester.widget<TextField>(find.byType(TextField));
    expect(field.expands, isTrue);
    expect(field.maxLines, isNull);
    expect(field.minLines, isNull);
    expect(field.keyboardType, TextInputType.multiline);
  });

  testWidgets('hides platform scrollbar', (tester) async {
    await tester.pumpWidget(wrap(const TpTextarea(minHeight: 80)));
    final scrollConfig = tester.widget<ScrollConfiguration>(
      find.descendant(
        of: find.byType(TpTextarea),
        matching: find.byType(ScrollConfiguration),
      ),
    );
    expect(scrollConfig.behavior, isA<TpTextareaScrollBehavior>());
    expect(find.byType(Scrollbar), findsNothing);
  });

  testWidgets('decoration clears single-line tight height', (tester) async {
    await tester.pumpWidget(
      wrap(const TpTextarea(minHeight: 120, maxHeight: 300)),
    );
    final field = tester.widget<TextField>(find.byType(TextField));
    final c = field.decoration?.constraints;
    expect(c, isNotNull);
    expect(c!.maxHeight, isNot(equals(c.minHeight)));
  });

  testWidgets('fill color matches single-line outline inputs', (tester) async {
    final theme = themeWithTightInput();
    await tester.pumpWidget(wrap(const TpTextarea(), theme: theme));
    final field = tester.widget<TextField>(find.byType(TextField));
    expect(
      field.decoration?.fillColor,
      theme.colorScheme.surfaceContainer,
    );
    expect(
      field.decoration?.fillColor,
      theme.inputDecorationTheme.fillColor,
    );
  });

  testWidgets('uses muted placeholder and shadcn-like padding', (tester) async {
    await tester.pumpWidget(
      wrap(
        const TpTextarea(
          decoration: InputDecoration(hintText: 'Type here'),
        ),
      ),
    );
    final field = tester.widget<TextField>(find.byType(TextField));
    final decoration = field.decoration!;
    expect(decoration.hintStyle?.color?.a, lessThan(0.7));
    expect(
      decoration.contentPadding,
      kTpTextareaContentPadding,
    );
  });

  testWidgets('focus border matches single-line outline inputs', (tester) async {
    final theme = themeWithTightInput();
    await tester.pumpWidget(wrap(const TpTextarea(minHeight: 80), theme: theme));

    expect(find.byType(AnimatedContainer), findsNothing);

    final field = tester.widget<TextField>(find.byType(TextField));
    final focused = field.decoration!.focusedBorder! as OutlineInputBorder;
    final themeFocused =
        theme.inputDecorationTheme.focusedBorder! as OutlineInputBorder;
    expect(focused.borderSide.width, 1.5);
    expect(focused.borderSide.color, themeFocused.borderSide.color);
  });

  testWidgets('resize grip has enlarged hit target', (tester) async {
    await tester.pumpWidget(wrap(const TpTextarea()));
    final grip = tester.getSize(find.byKey(const Key('tp-textarea-resize-grip')));
    expect(grip.width, kTpTextareaResizeGripHitSize);
    expect(grip.height, kTpTextareaResizeGripHitSize);
  });

  testWidgets('default minHeight is 80 like ShadTextarea', (tester) async {
    await tester.pumpWidget(wrap(const TpTextarea()));
    final shellSize = tester.getSize(find.byType(TpTextarea));
    expect(shellSize.height, 80);
  });

  testWidgets('3-line chrome-inclusive minHeight does not overflow', (
    tester,
  ) async {
    const style = TextStyle(fontSize: 14, height: 20 / 14);
    FlutterError? overflow;
    final oldOnError = FlutterError.onError;
    FlutterError.onError = (details) {
      final message = details.exceptionAsString();
      if (message.contains('overflowed')) {
        overflow = details.exception is FlutterError
            ? details.exception as FlutterError
            : FlutterError(message);
      }
      oldOnError?.call(details);
    };
    addTearDown(() => FlutterError.onError = oldOnError);

    await tester.pumpWidget(
      wrap(
        TpTextarea(
          style: style,
          minHeight: tpTextareaHeightForLines(style, lines: 3),
          maxHeight: tpTextareaHeightForLines(style, lines: 6),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(TextField), findsOneWidget);
    expect(overflow, isNull);
    expect(tester.takeException(), isNull);
  });

  test('tpTextareaHeightForLines includes padding and border chrome', () {
    const style = TextStyle(fontSize: 14, height: 20 / 14);
    expect(
      tpTextareaHeightForLines(style, lines: 3),
      3 * 20 +
          kTpTextareaTopPadding +
          kTpTextareaBottomPadding +
          kTpTextareaBottomInset +
          kTpTextareaBorderWidth * 2,
    );
  });
}
