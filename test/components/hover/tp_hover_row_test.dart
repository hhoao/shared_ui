import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_test/flutter_test.dart' as ft show testWidgets;
import 'package:shared_ui/shared_ui.dart';

/// shared_ui tests default to the desktop platform so [TpHover] renders its
/// desktop path. See `tp_hover_test.dart` for why this is a per-test shim
/// rather than a suite-wide `flutter_test_config.dart` override.
void testWidgets(String description, WidgetTesterCallback callback) {
  ft.testWidgets(description, (tester) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.linux;
    try {
      await callback(tester);
    } finally {
      debugDefaultTargetPlatformOverride = null;
    }
  });
}

void main() {
  Widget wrap(Widget child) {
    return MaterialApp(
      home: Scaffold(body: Center(child: child)),
    );
  }

  Finder innerTpHover(WidgetTester tester) {
    return find.descendant(
      of: find.byType(TpHoverRow),
      matching: find.byType(TpHover),
    );
  }

  testWidgets('trailing appears after mouse enter on desktop', (tester) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.linux;
    try {
      await tester.pumpWidget(
        wrap(
          const TpHoverRow(
            trailing: Text('actions'),
            child: Text('label'),
          ),
        ),
      );
      expect(find.text('actions'), findsNothing);

      final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
      await gesture.addPointer(location: Offset.zero);
      addTearDown(gesture.removePointer);
      await tester.pump();
      await gesture.moveTo(tester.getCenter(find.byType(TpHoverRow)));
      await tester.pumpAndSettle();

      expect(find.text('actions'), findsOneWidget);
    } finally {
      debugDefaultTargetPlatformOverride = null;
    }
  });

  testWidgets('forceShowTrailing shows trailing without hover', (tester) async {
    await tester.pumpWidget(
      wrap(
        const TpHoverRow(
          forceShowTrailing: true,
          trailing: Text('actions'),
          child: Text('label'),
        ),
      ),
    );
    expect(find.text('actions'), findsOneWidget);
  });

  testWidgets('showTrailingOnMobile shows trailing on Android without hover', (
    tester,
  ) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    try {
      await tester.pumpWidget(
        wrap(
          const TpHoverRow(
            showTrailingOnMobile: true,
            trailing: Text('actions'),
            child: Text('label'),
          ),
        ),
      );
      expect(find.text('actions'), findsOneWidget);
    } finally {
      debugDefaultTargetPlatformOverride = null;
    }
  });

  testWidgets('backgroundColor forwarded to inner TpHover', (tester) async {
    await tester.pumpWidget(
      wrap(
        const TpHoverRow(
          backgroundColor: Color(0xFF112233),
          child: SizedBox(width: 40, height: 20),
        ),
      ),
    );
    final box = tester.widget<AnimatedContainer>(
      find.descendant(
        of: innerTpHover(tester),
        matching: find.byType(AnimatedContainer),
      ),
    );
    expect((box.decoration! as BoxDecoration).color, const Color(0xFF112233));
  });

  testWidgets('enabled false does not invoke onTap', (tester) async {
    var taps = 0;
    await tester.pumpWidget(
      wrap(
        TpHoverRow(
          enabled: false,
          onTap: () => taps++,
          child: const Text('label'),
        ),
      ),
    );
    await tester.tap(innerTpHover(tester));
    expect(taps, 0);
  });

  testWidgets('onLongPress forwarded to inner TpHover', (tester) async {
    var pressed = false;
    await tester.pumpWidget(
      wrap(
        TpHoverRow(
          onLongPress: () => pressed = true,
          child: const SizedBox(width: 80, height: 40),
        ),
      ),
    );
    await tester.longPress(innerTpHover(tester));
    expect(pressed, isTrue);
  });

  testWidgets('onSecondaryTapDown forwarded to inner TpHover', (tester) async {
    TapDownDetails? details;
    await tester.pumpWidget(
      wrap(
        TpHoverRow(
          onSecondaryTapDown: (d) => details = d,
          child: const SizedBox(width: 80, height: 40),
        ),
      ),
    );
    await tester.tap(
      innerTpHover(tester),
      buttons: kSecondaryButton,
    );
    await tester.pump();
    expect(details, isNotNull);
  });
}
