import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_ui/shared_ui.dart';

void main() {
  Widget wrap(Widget child) {
    return MaterialApp(
      home: Scaffold(body: Center(child: child)),
    );
  }

  MouseRegion tpHoverRegion(WidgetTester tester) {
    return tester.widget<MouseRegion>(
      find.descendant(
        of: find.byType(TpHover),
        matching: find.byType(MouseRegion),
      ),
    );
  }

  testWidgets('TpHover invokes onTap', (tester) async {
    var taps = 0;
    await tester.pumpWidget(
      wrap(
        TpHover(
          onTap: () => taps++,
          child: const Text('row'),
        ),
      ),
    );
    await tester.tap(find.byType(TpHover));
    expect(taps, 1);
  });

  testWidgets('enabled false does not invoke onTap', (tester) async {
    var taps = 0;
    await tester.pumpWidget(
      wrap(
        TpHover(
          enabled: false,
          onTap: () => taps++,
          child: const Text('row'),
        ),
      ),
    );
    await tester.tap(find.byType(TpHover));
    expect(taps, 0);
  });

  testWidgets('click cursor when onTap set', (tester) async {
    await tester.pumpWidget(
      wrap(TpHover(onTap: () {}, child: const Text('x'))),
    );
    expect(tpHoverRegion(tester).cursor, SystemMouseCursors.click);
  });

  testWidgets('basic cursor when non-interactive', (tester) async {
    await tester.pumpWidget(wrap(const TpHover(child: Text('x'))));
    expect(tpHoverRegion(tester).cursor, SystemMouseCursors.basic);
  });

  testWidgets('basic cursor when disabled even with onTap', (tester) async {
    await tester.pumpWidget(
      wrap(TpHover(enabled: false, onTap: () {}, child: const Text('x'))),
    );
    expect(tpHoverRegion(tester).cursor, SystemMouseCursors.basic);
  });

  testWidgets('backgroundColor shows when not hovered', (tester) async {
    await tester.pumpWidget(
      wrap(
        TpHover(
          backgroundColor: const Color(0xFF112233),
          child: const SizedBox(width: 40, height: 20),
        ),
      ),
    );
    final box = tester.widget<AnimatedContainer>(find.byType(AnimatedContainer));
    final deco = box.decoration! as BoxDecoration;
    expect(deco.color, const Color(0xFF112233));
  });

  testWidgets(
    'transparent idle keeps hover RGB so color animation does not flash dark',
    (tester) async {
      const hover = Color(0xFF445566);
      await tester.pumpWidget(
        wrap(
          TpHover(
            backgroundColor: Colors.transparent,
            hoverColor: hover,
            duration: const Duration(milliseconds: 100),
            onTap: () {},
            child: const SizedBox(width: 40, height: 20),
          ),
        ),
      );

      final box = tester.widget<AnimatedContainer>(
        find.byType(AnimatedContainer),
      );
      final idle = (box.decoration! as BoxDecoration).color!;
      expect(idle.a, 0);
      expect(idle.r, hover.r);
      expect(idle.g, hover.g);
      expect(idle.b, hover.b);

      // Same RGB + alpha fade: mid-lerp stays on the hover hue (not black).
      final mid = Color.lerp(idle, hover, 0.5)!;
      expect(mid.r, closeTo(hover.r, 0.02));
      expect(mid.g, closeTo(hover.g, 0.02));
      expect(mid.b, closeTo(hover.b, 0.02));
      expect(mid.a, closeTo(0.5, 0.02));
    },
  );

  testWidgets(
    'fill color-family change applies instantly (no cross-RGB lerp)',
    (tester) async {
      // A long duration means any RGB lerp would still be mid-animation on the
      // first frame; the fill must already show the new color.
      const duration = Duration(seconds: 30);
      await tester.pumpWidget(
        wrap(
          TpHover(
            backgroundColor: const Color(0xFF112233),
            hoverColor: const Color(0xFF445566),
            duration: duration,
            onTap: () {},
            child: const SizedBox(width: 40, height: 20),
          ),
        ),
      );
      // Selection-style change: a different RGB fill.
      await tester.pumpWidget(
        wrap(
          TpHover(
            backgroundColor: const Color(0xFFAABBCC),
            hoverColor: const Color(0xFF445566),
            duration: duration,
            onTap: () {},
            child: const SizedBox(width: 40, height: 20),
          ),
        ),
      );
      await tester.pump(); // first frame after the change
      final box = tester.widget<AnimatedContainer>(
        find.byType(AnimatedContainer),
      );
      expect(
        (box.decoration! as BoxDecoration).color,
        const Color(0xFFAABBCC),
      );
    },
  );

  testWidgets('border is painted on the outer decoration with padding', (
    tester,
  ) async {
    const border = Border.fromBorderSide(
      BorderSide(color: Color(0xFFAA00FF), width: 2),
    );
    await tester.pumpWidget(
      wrap(
        TpHover(
          backgroundColor: const Color(0xFF112233),
          border: border,
          padding: const EdgeInsets.all(12),
          child: const SizedBox(width: 40, height: 20),
        ),
      ),
    );
    final box = tester.widget<AnimatedContainer>(
      find.byType(AnimatedContainer),
    );
    final deco = box.decoration! as BoxDecoration;
    expect(deco.border, border);
    // Padding lives on the Padding sibling that insets the child (the fill
    // layer covers the full box including padding). AnimatedContainer also
    // emits an internal zero Padding, so match on the value.
    final padding = tester.widget<Padding>(
      find.descendant(
        of: find.byType(TpHover),
        matching: find.byWidgetPredicate(
          (w) => w is Padding && w.padding == const EdgeInsets.all(12),
        ),
      ),
    );
    expect(padding.padding, const EdgeInsets.all(12));
  });

  testWidgets('onHoverChanged and hover fill', (tester) async {
    final events = <bool>[];
    await tester.pumpWidget(
      wrap(
        TpHover(
          hoverColor: const Color(0xFF445566),
          onHoverChanged: events.add,
          onTap: () {},
          child: const SizedBox(width: 40, height: 20),
        ),
      ),
    );
    final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await gesture.addPointer(location: Offset.zero);
    addTearDown(gesture.removePointer);
    await tester.pump();
    await gesture.moveTo(tester.getCenter(find.byType(TpHover)));
    await tester.pumpAndSettle();
    expect(events, contains(true));
    final box = tester.widget<AnimatedContainer>(find.byType(AnimatedContainer));
    expect((box.decoration! as BoxDecoration).color, const Color(0xFF445566));
  });

  testWidgets('forceHover shows hover fill without pointer', (tester) async {
    await tester.pumpWidget(
      wrap(
        TpHover(
          forceHover: true,
          hoverColor: const Color(0xFF778899),
          child: const SizedBox(width: 40, height: 20),
        ),
      ),
    );
    final box = tester.widget<AnimatedContainer>(find.byType(AnimatedContainer));
    expect((box.decoration! as BoxDecoration).color, const Color(0xFF778899));
  });

  testWidgets('enabled false ignores hover enter', (tester) async {
    final events = <bool>[];
    await tester.pumpWidget(
      wrap(
        TpHover(
          enabled: false,
          backgroundColor: const Color(0xFF112233),
          hoverColor: const Color(0xFF445566),
          onHoverChanged: events.add,
          onTap: () {},
          child: const SizedBox(width: 40, height: 20),
        ),
      ),
    );
    final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await gesture.addPointer(location: Offset.zero);
    addTearDown(gesture.removePointer);
    await tester.pump();
    await gesture.moveTo(tester.getCenter(find.byType(TpHover)));
    await tester.pumpAndSettle();
    expect(events, isEmpty);
    final box = tester.widget<AnimatedContainer>(find.byType(AnimatedContainer));
    expect((box.decoration! as BoxDecoration).color, const Color(0xFF112233));
  });

  testWidgets('onSecondaryTapDown delivers details', (tester) async {
    TapDownDetails? details;
    await tester.pumpWidget(
      wrap(
        TpHover(
          onSecondaryTapDown: (d) => details = d,
          child: const SizedBox(width: 80, height: 40),
        ),
      ),
    );
    await tester.tap(
      find.byType(TpHover),
      buttons: kSecondaryButton,
    );
    await tester.pump();
    expect(details, isNotNull);
  });

  testWidgets('onLongPress fires', (tester) async {
    var pressed = false;
    await tester.pumpWidget(
      wrap(
        TpHover(
          onLongPress: () => pressed = true,
          child: const SizedBox(width: 80, height: 40),
        ),
      ),
    );
    await tester.longPress(find.byType(TpHover));
    expect(pressed, isTrue);
  });

  testWidgets('pressScale wraps with AnimatedScale when not 1.0', (tester) async {
    await tester.pumpWidget(
      wrap(
        TpHover(
          pressScale: 0.97,
          onTap: () {},
          child: const Text('x'),
        ),
      ),
    );
    expect(find.byType(AnimatedScale), findsOneWidget);
  });
}
