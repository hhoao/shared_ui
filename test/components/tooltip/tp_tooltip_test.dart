import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
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
}
