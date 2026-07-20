import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_ui/shared_ui.dart';

void main() {
  testWidgets('TpDeferredMountShell shows child immediately in tests', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(home: TpDeferredMountShell(child: Text('ready'))),
    );

    expect(find.text('ready'), findsOneWidget);
  });

  testWidgets(
    'TpDeferredMountShell awaitIdle still mounts immediately in tests',
    (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: TpDeferredMountShell(
            awaitIdle: true,
            delayFrames: 2,
            placeholder: Text('wait'),
            child: Text('ready'),
          ),
        ),
      );

      expect(find.text('ready'), findsOneWidget);
      expect(find.text('wait'), findsNothing);
    },
  );

  testWidgets('TpDeferredMountAfter mounts immediately under FLUTTER_TEST', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: TpDeferredMountAfter(
            delay: Duration(seconds: 10),
            child: Text('loaded'),
          ),
        ),
      ),
    );

    expect(find.text('loaded'), findsOneWidget);
  });
}
