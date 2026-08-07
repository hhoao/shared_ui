import 'package:flutter/widgets.dart';
import '../support/tp_test_widgets.dart';
import 'package:shared_ui/shared_ui.dart';

void main() {
  group('TpWidthScale sparse anchors', () {
    test('single anchor is constant', () {
      expect(
        TpWidthScale.of(0, lg: 20),
        20,
      );
      expect(
        TpWidthScale.of(TpBreakpoints.xxl, lg: 20),
        20,
      );
    });

    test('two anchors lerp across the span', () {
      expect(
        TpWidthScale.of(TpBreakpoints.sm, sm: 10, xxl: 50),
        10,
      );
      expect(
        TpWidthScale.of(TpBreakpoints.xxl, sm: 10, xxl: 50),
        50,
      );
      final mid = (TpBreakpoints.sm + TpBreakpoints.xxl) / 2;
      expect(
        TpWidthScale.of(mid, sm: 10, xxl: 50),
        closeTo(30, 0.001),
      );
    });

    test('three anchors skip missing stops', () {
      // md omitted — lerp sm→lg across [640, 1024], then lg→xxl.
      expect(
        TpWidthScale.of(TpBreakpoints.md, sm: 10, lg: 30, xxl: 50),
        closeTo(
          10 +
              (30 - 10) *
                  ((TpBreakpoints.md - TpBreakpoints.sm) /
                      (TpBreakpoints.lg - TpBreakpoints.sm)),
          0.001,
        ),
      );
      expect(
        TpWidthScale.of(TpBreakpoints.lg, sm: 10, lg: 30, xxl: 50),
        30,
      );
    });

    test('holds outside first/last provided stop', () {
      expect(TpWidthScale.of(100, md: 20, xl: 40), 20);
      expect(TpWidthScale.of(2000, md: 20, xl: 40), 40);
    });
  });

  group('TpScaledEdgeInsets', () {
    test('two-stop forWidth', () {
      const scaled = TpScaledEdgeInsets(
        sm: EdgeInsets.all(4),
        xxl: EdgeInsets.all(24),
      );
      expect(scaled.forWidth(TpBreakpoints.sm), const EdgeInsets.all(4));
      expect(scaled.forWidth(TpBreakpoints.xxl), const EdgeInsets.all(24));
    });
  });

  testWidgets('TpWidthValueHost provides resolved value', (tester) async {
    late double seen;
    late double seenWidth;
    tester.view.physicalSize = const Size(1600, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: Align(
          alignment: Alignment.topLeft,
          child: SizedBox(
            width: TpBreakpoints.xxl,
            height: 100,
            child: TpWidthValueHost<double>(
              resolve: (w) => TpWidthScale.of(w, sm: 1, xxl: 5),
              child: Builder(
                builder: (context) {
                  seen = TpWidthValueScope.of<double>(context);
                  seenWidth =
                      TpWidthValueScope.maybeWidthOf<double>(context)!;
                  return const SizedBox.shrink();
                },
              ),
            ),
          ),
        ),
      ),
    );
    expect(seenWidth, TpBreakpoints.xxl);
    expect(seen, 5);
  });
}
