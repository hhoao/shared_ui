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
