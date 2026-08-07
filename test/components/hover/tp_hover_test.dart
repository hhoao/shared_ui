import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import '../../support/tp_test_widgets.dart';
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

  group('adaptive touch path', () {
    testWidgets('renders InkWell (ripple) on touch platforms', (tester) async {
      debugDefaultTargetPlatformOverride = TargetPlatform.android;
      addTearDown(() => debugDefaultTargetPlatformOverride = null);
      await tester.pumpWidget(
        wrap(TpHover(onTap: () {}, child: const Text('t'))),
      );
      expect(find.byType(InkWell), findsOneWidget);
      // No animated hover fill on touch.
      expect(find.byType(AnimatedContainer), findsNothing);
    });

    testWidgets('desktop path keeps GestureDetector fill, no InkWell', (
      tester,
    ) async {
      await tester.pumpWidget(
        wrap(TpHover(onTap: () {}, child: const Text('t'))),
      );
      expect(find.byType(InkWell), findsNothing);
      expect(find.byType(AnimatedContainer), findsOneWidget);
    });
  });

  group('shape', () {
    testWidgets('circle derives circular radius for desktop fill', (tester) async {
      await tester.pumpWidget(
        wrap(
          TpHover(
            shape: TpPressableShape.circle,
            width: 36,
            height: 36,
            onTap: () {},
            child: const SizedBox(width: 20, height: 20),
          ),
        ),
      );
      final box = tester.widget<AnimatedContainer>(find.byType(AnimatedContainer));
      final deco = box.decoration! as BoxDecoration;
      expect(deco.borderRadius, BorderRadius.circular(18));
    });

    testWidgets('touch path circle uses CircleBorder', (tester) async {
      debugDefaultTargetPlatformOverride = TargetPlatform.android;
      addTearDown(() => debugDefaultTargetPlatformOverride = null);
      await tester.pumpWidget(
        wrap(
          TpHover(
            shape: TpPressableShape.circle,
            width: 36,
            height: 36,
            onTap: () {},
            child: const SizedBox(width: 20, height: 20),
          ),
        ),
      );
      final material = tester.widget<Material>(
        find.descendant(
          of: find.byType(TpHover),
          matching: find.byType(Material),
        ),
      );
      expect(material.shape, isA<CircleBorder>());
    });

    testWidgets('stadium touch path uses StadiumBorder', (tester) async {
      debugDefaultTargetPlatformOverride = TargetPlatform.android;
      addTearDown(() => debugDefaultTargetPlatformOverride = null);
      await tester.pumpWidget(
        wrap(TpHover(shape: TpPressableShape.stadium, onTap: () {}, child: const Text('x'))),
      );
      final material = tester.widget<Material>(
        find.descendant(
          of: find.byType(TpHover),
          matching: find.byType(Material),
        ),
      );
      expect(material.shape, isA<StadiumBorder>());
    });
  });

  group('tap passthrough', () {
    testWidgets('onTapDown and onTapUp deliver details', (tester) async {
      TapDownDetails? down;
      TapUpDetails? up;
      var cancelled = false;
      await tester.pumpWidget(
        wrap(
          TpHover(
            onTapDown: (d) => down = d,
            onTapUp: (d) => up = d,
            onTapCancel: () => cancelled = true,
            onTap: () {},
            child: const SizedBox(width: 80, height: 40),
          ),
        ),
      );
      await tester.tap(find.byType(TpHover));
      expect(down, isNotNull);
      expect(up, isNotNull);
      expect(cancelled, isFalse);
    });
  });

  testWidgets('canRequestFocus=false keeps focus out of the tap surface', (
    tester,
  ) async {
    await tester.pumpWidget(
      wrap(
        TpHover(
          canRequestFocus: false,
          onTap: () {},
          child: const Text('x'),
        ),
      ),
    );
    await tester.tap(find.byType(TpHover));
    // The MaterialApp route's ModalScope FocusScope holds primary focus; the
    // TpHover tap surface (canRequestFocus: false) must not claim it.
    final primary = tester.binding.focusManager.primaryFocus;
    expect(primary, isNotNull);
    expect(
      find.ancestor(
        of: find.byElementPredicate((Element e) => identical(e, primary!.context)),
        matching: find.byType(TpHover),
      ),
      findsNothing,
    );
  });

  testWidgets(
    'centers a content-hugging child when the surface is stretched (status-bar pill)',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              height: 24,
              child: TpHover(
                onTap: () {},
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const Icon(Icons.memory, size: 13),
                    const SizedBox(width: 6),
                    const Text('512 MB', style: TextStyle(height: 1.0)),
                  ],
                ),
              ),
            ),
          ),
        ),
      );

      final boxRect = tester.getRect(find.byType(TpHover));
      final textRect = tester.getRect(find.text('512 MB'));
      // Vertical center of the content equals the surface center — the child
      // must not be pinned to the top-left of the stretched box.
      expect(textRect.center.dy, closeTo(boxRect.center.dy, 0.5));
      // Width still hugs content (centering must not expand the pill).
      expect(textRect.width, lessThan(boxRect.width));
    },
  );
}
