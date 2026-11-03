import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import '../../support/tp_test_widgets.dart';
import 'package:shared_ui/shared_ui.dart';

void main() {
  testWidgets('empty message returns child only', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: TpTooltip(
            message: '',
            child: Text('target'),
          ),
        ),
      ),
    );
    expect(find.text('target'), findsOneWidget);
    expect(find.byType(OverlayPortal), findsNothing);
  });

  testWidgets('shows message after waitDuration on hover', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: TpTooltip(
            message: 'Helpful tip',
            waitDuration: const Duration(milliseconds: 50),
            child: const Text('target'),
          ),
        ),
      ),
    );

    final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await gesture.addPointer(location: Offset.zero);
    addTearDown(gesture.removePointer);
    await tester.pump();
    await gesture.moveTo(tester.getCenter(find.text('target')));
    await tester.pump(const Duration(milliseconds: 60));

    expect(find.text('Helpful tip'), findsOneWidget);
  });

  testWidgets('placement right anchors the bubble beside the target', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: TpTooltip(
              message: 'Helpful tip',
              placement: TpTooltipPlacement.right,
              waitDuration: const Duration(milliseconds: 50),
              child: const Text('target'),
            ),
          ),
        ),
      ),
    );

    final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await gesture.addPointer(location: Offset.zero);
    addTearDown(gesture.removePointer);
    await tester.pump();
    await gesture.moveTo(tester.getCenter(find.text('target')));
    await tester.pump(const Duration(milliseconds: 60));

    final tip = tester.getTopLeft(find.text('Helpful tip'));
    final target = tester.getTopRight(find.text('target'));
    expect(tip.dx, greaterThanOrEqualTo(target.dx));
  });
}
