import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_ui/shared_ui.dart';

void main() {
  test('TpMobileChrome tokens match locked design values', () {
    expect(TpMobileChrome.leadingInset, 16);
    expect(TpMobileChrome.narrowBreakpointWidth, 840);
  });

  testWidgets('force true always applies leading inset', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: TpMobileLeading(
            force: true,
            child: SizedBox(width: 40, height: 40),
          ),
        ),
      ),
    );

    final padding = tester.widget<Padding>(
      find.descendant(
        of: find.byType(TpMobileLeading),
        matching: find.byType(Padding),
      ),
    );
    expect(padding.padding, const EdgeInsets.only(left: 16));
  });

  testWidgets('wide viewport without force does not pad', (tester) async {
    tester.view.physicalSize = const Size(1200, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: TpMobileLeading(
            child: SizedBox(width: 40, height: 40, key: Key('child')),
          ),
        ),
      ),
    );

    expect(
      find.descendant(
        of: find.byType(TpMobileLeading),
        matching: find.byType(Padding),
      ),
      findsNothing,
    );
    expect(find.byKey(const Key('child')), findsOneWidget);
  });

  testWidgets('narrow viewport without scope applies inset', (tester) async {
    tester.view.physicalSize = const Size(400, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: TpMobileLeading(
            child: SizedBox(width: 40, height: 40),
          ),
        ),
      ),
    );

    final padding = tester.widget<Padding>(
      find.descendant(
        of: find.byType(TpMobileLeading),
        matching: find.byType(Padding),
      ),
    );
    expect(
      padding.padding,
      const EdgeInsets.only(left: TpMobileChrome.leadingInset),
    );
  });

  testWidgets('sidebar scope isMobile true applies inset even if wide', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1200, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        home: TpSidebarProvider(
          // Force mobile classification via tiny breakpoint.
          mobileBreakpoint: 2000,
          child: const Scaffold(
            body: TpMobileLeading(
              child: SizedBox(width: 40, height: 40),
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    final padding = tester.widget<Padding>(
      find.descendant(
        of: find.byType(TpMobileLeading),
        matching: find.byType(Padding),
      ),
    );
    expect(
      padding.padding,
      const EdgeInsets.only(left: TpMobileChrome.leadingInset),
    );
  });
}
