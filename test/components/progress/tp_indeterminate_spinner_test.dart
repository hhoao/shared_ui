import 'package:flutter/material.dart';
import '../../support/tp_test_widgets.dart';
import 'package:shared_ui/shared_ui.dart';

Finder _spinnerPaint() {
  return find.descendant(
    of: find.byType(TpIndeterminateSpinner),
    matching: find.byType(CustomPaint),
  );
}

void main() {
  Widget wrap(Widget child) {
    return MaterialApp(
      home: TpTheme(
        data: TpThemeData.fromColorScheme(
          ColorScheme.fromSeed(seedColor: Colors.blue),
          scale: 1.0,
        ),
        child: Scaffold(body: child),
      ),
    );
  }

  testWidgets(
    'animation ticks paint without rebuilding widgets',
    (tester) async {
      await tester.pumpWidget(wrap(const TpIndeterminateSpinner()));

      expect(_spinnerPaint(), findsOneWidget);
      final paintBefore = tester.widget<CustomPaint>(_spinnerPaint());
      final painterBefore = paintBefore.painter;

      await tester.pump(const Duration(milliseconds: 50));
      await tester.pump(const Duration(milliseconds: 50));

      expect(_spinnerPaint(), findsOneWidget);
      final paintAfter = tester.widget<CustomPaint>(_spinnerPaint());
      expect(
        identical(paintBefore, paintAfter),
        isTrue,
        reason:
            'vsync ticks must repaint the spinner layer, not rebuild '
            'CustomPaint / AnimatedBuilder',
      );
      expect(identical(painterBefore, paintAfter.painter), isTrue);
      expect(
        find.descendant(
          of: find.byType(TpIndeterminateSpinner),
          matching: find.byType(AnimatedBuilder),
        ),
        findsNothing,
      );
    },
  );
}
