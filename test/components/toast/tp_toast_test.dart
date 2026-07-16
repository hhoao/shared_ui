import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_ui/shared_ui.dart';

Widget _harness({
  required Widget child,
  TpToastTheme? toast,
  TpToastConfig? config,
}) {
  final scheme = ColorScheme.fromSeed(seedColor: Colors.indigo);
  return TpToastWrapper(
    config: config ??
        const TpToastConfig(
          alignment: AlignmentDirectional.topEnd,
          itemWidth: 400,
          maxToastLimit: 1,
          animationDuration: Duration(milliseconds: 200),
        ),
    child: MaterialApp(
      theme: ThemeData(colorScheme: scheme),
      home: TpTheme(
        data: TpThemeData.fromColorScheme(scheme, scale: 1, toast: toast),
        child: child,
      ),
    ),
  );
}

void main() {
  tearDown(() {
    TpToast.dismiss();
  });

  testWidgets('show presents message and dismiss removes it', (tester) async {
    await tester.pumpWidget(
      _harness(
        child: Builder(
          builder: (context) {
            return TextButton(
              onPressed: () => TpToast.show(context, message: 'Hello toast'),
              child: const Text('go'),
            );
          },
        ),
      ),
    );
    await tester.tap(find.text('go'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 250));
    expect(find.text('Hello toast'), findsOneWidget);

    TpToast.dismiss();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 250));
    expect(find.text('Hello toast'), findsNothing);
  });

  testWidgets('empty message is a no-op', (tester) async {
    await tester.pumpWidget(
      _harness(
        child: Builder(
          builder: (context) {
            return TextButton(
              onPressed: () => TpToast.show(context, message: '   '),
              child: const Text('go'),
            );
          },
        ),
      ),
    );
    await tester.tap(find.text('go'));
    await tester.pumpAndSettle();
    expect(find.text('   '), findsNothing);
  });

  testWidgets('action dismisses toast and invokes callback', (tester) async {
    var pressed = false;
    await tester.pumpWidget(
      _harness(
        child: Builder(
          builder: (context) {
            return TextButton(
              onPressed: () => TpToast.show(
                context,
                message: 'With action',
                action: TpToastAction(
                  label: 'Undo',
                  onPressed: () => pressed = true,
                ),
              ),
              child: const Text('go'),
            );
          },
        ),
      ),
    );
    await tester.tap(find.text('go'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 250));
    expect(find.text('With action'), findsOneWidget);

    await tester.tap(find.text('Undo'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 250));
    expect(pressed, isTrue);
    expect(find.text('With action'), findsNothing);
  });

  testWidgets('TpToastConfig itemWidth and marginBuilder are applied', (
    tester,
  ) async {
    const customMargin = EdgeInsets.all(42);
    // Distinct alignment so the engine manager is created with this config
    // (managers are keyed by alignment and retain the first config).
    await tester.pumpWidget(
      _harness(
        config: TpToastConfig(
          alignment: AlignmentDirectional.bottomStart,
          itemWidth: 300,
          marginBuilder: (_, _) => customMargin,
        ),
        child: Builder(
          builder: (context) {
            return TextButton(
              onPressed: () => TpToast.show(context, message: 'Sized toast'),
              child: const Text('go'),
            );
          },
        ),
      ),
    );
    await tester.tap(find.text('go'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 250));
    expect(find.text('Sized toast'), findsOneWidget);

    final holder = tester
        .widgetList<Container>(find.byType(Container))
        .firstWhere((c) => c.constraints?.maxWidth == 300);
    expect(holder.constraints?.maxWidth, 300);
    expect(
      holder.margin!.resolve(TextDirection.ltr),
      customMargin,
    );

    TpToast.dismiss();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 250));
  });
}
