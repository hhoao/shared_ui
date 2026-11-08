import 'dart:async';

import 'package:flutter/material.dart';
import 'package:shared_ui/shared_ui.dart';

import '../../support/tp_test_widgets.dart';

double _turns(WidgetTester tester) {
  final rotation = find.descendant(
    of: find.byType(TpAnimatedIcon),
    matching: find.byType(RotationTransition),
  );
  return tester.widget<RotationTransition>(rotation).turns.value;
}

Widget _wrap(Widget child) {
  return MaterialApp(
    home: TpTheme(
      data: TpThemeData.fromColorScheme(
        ColorScheme.fromSeed(seedColor: Colors.blue),
        scale: 1.0,
      ),
      child: Scaffold(body: Center(child: child)),
    ),
  );
}

void main() {
  testWidgets('tap plays one full turn', (tester) async {
    await tester.pumpWidget(
      _wrap(TpAnimatedIconButton(icon: Icons.refresh, onPressed: () {})),
    );

    expect(_turns(tester), 0);

    await tester.tap(find.byType(TpAnimatedIconButton));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));
    expect(_turns(tester), greaterThan(0.3));
    expect(_turns(tester), lessThan(0.8));

    await tester.pump(const Duration(milliseconds: 400));
    expect(_turns(tester), 1);
  });

  testWidgets('a pending future keeps the icon spinning until it completes', (
    tester,
  ) async {
    final completer = Completer<void>();
    await tester.pumpWidget(
      _wrap(
        TpAnimatedIconButton(
          icon: Icons.refresh,
          onPressed: () => completer.future,
        ),
      ),
    );

    await tester.tap(find.byType(TpAnimatedIconButton));
    await tester.pump();
    expect(completer.isCompleted, isFalse);

    // Still spinning well past a single turn.
    await tester.pump(const Duration(milliseconds: 2000));
    expect(_turns(tester), isNot(0));

    completer.complete();
    await tester.pumpAndSettle();
    expect(_turns(tester), 0);
  });

  testWidgets('external busy spins and settles back to idle', (tester) async {
    Widget build(bool busy) => _wrap(
      TpAnimatedIconButton(
        icon: Icons.refresh,
        busy: busy,
        onPressed: () {},
      ),
    );

    await tester.pumpWidget(build(true));
    await tester.pump(const Duration(milliseconds: 250));
    final first = _turns(tester);
    await tester.pump(const Duration(milliseconds: 250));
    expect(_turns(tester), isNot(first));

    await tester.pumpWidget(build(false));
    await tester.pumpAndSettle();
    expect(_turns(tester), 0);
  });

  testWidgets('spinner busy style replaces the icon', (tester) async {
    await tester.pumpWidget(
      _wrap(
        const TpAnimatedIconButton(
          icon: Icons.refresh,
          busy: true,
          busyStyle: TpAnimatedIconBusyStyle.spinner,
          onPressed: _noop,
        ),
      ),
    );

    expect(find.byType(TpIndeterminateSpinner), findsOneWidget);
    expect(find.byType(TpAnimatedIcon), findsNothing);
  });

  testWidgets('disabled button does not fire', (tester) async {
    var taps = 0;
    await tester.pumpWidget(
      _wrap(
        TpAnimatedIconButton(
          icon: Icons.refresh,
          enabled: false,
          onPressed: () => taps++,
        ),
      ),
    );

    await tester.tap(find.byType(TpAnimatedIconButton));
    await tester.pump();
    expect(taps, 0);
    expect(_turns(tester), 0);
  });
}

void _noop() {}
