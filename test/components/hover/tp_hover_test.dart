import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_ui/shared_ui.dart';

void main() {
  testWidgets('TpHover invokes onTap', (tester) async {
    var taps = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: TpHover(
            onTap: () => taps++,
            child: const Text('row'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('row'));
    expect(taps, 1);
  });

  testWidgets('TpHover reports hover changes', (tester) async {
    final hovered = <bool>[];
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: TpHover(
              onHoverChanged: hovered.add,
              child: const SizedBox(
                width: 80,
                height: 40,
                child: Text('row'),
              ),
            ),
          ),
        ),
      ),
    );

    final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await gesture.addPointer(location: Offset.zero);
    addTearDown(gesture.removePointer);
    await tester.pump();
    await gesture.moveTo(tester.getCenter(find.text('row')));
    await tester.pump();
    expect(hovered, contains(true));

    await gesture.moveTo(const Offset(1, 1));
    await tester.pump();
    expect(hovered.last, isFalse);
  });

  testWidgets('TpHoverRow shows trailing when forceShowTrailing', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: TpHoverRow(
            forceShowTrailing: true,
            trailing: Text('actions'),
            child: Text('label'),
          ),
        ),
      ),
    );
    expect(find.text('actions'), findsOneWidget);
  });

  testWidgets('TpHoverRow shows trailing on Android without hover', (
    tester,
  ) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    try {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: TpHoverRow(
              showTrailingOnMobile: true,
              trailing: Text('actions'),
              child: Text('label'),
            ),
          ),
        ),
      );
      expect(find.text('actions'), findsOneWidget);
    } finally {
      debugDefaultTargetPlatformOverride = null;
    }
  });
}
