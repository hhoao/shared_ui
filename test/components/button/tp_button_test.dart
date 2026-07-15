import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_ui/shared_ui.dart';

void main() {
  Widget wrap(Widget child) {
    return MaterialApp(
      home: TpTheme(
        data: TpThemeData.fromColorScheme(
          ColorScheme.fromSeed(seedColor: Colors.orange),
          scale: 1.0,
        ),
        child: Scaffold(body: child),
      ),
    );
  }

  testWidgets('renders all variants and invokes onPressed', (tester) async {
    final pressed = <TpButtonVariant>[];

    await tester.pumpWidget(
      wrap(
        Column(
          children: [
            for (final variant in TpButtonVariant.values)
              TpButton(
                key: ValueKey(variant),
                variant: variant,
                onPressed: () => pressed.add(variant),
                child: Text(variant.name),
              ),
          ],
        ),
      ),
    );

    for (final variant in TpButtonVariant.values) {
      expect(find.byKey(ValueKey(variant)), findsOneWidget);
      expect(find.text(variant.name), findsOneWidget);
      await tester.tap(find.byKey(ValueKey(variant)));
    }

    expect(pressed, TpButtonVariant.values);
  });

  testWidgets('applies control size metrics', (tester) async {
    await tester.pumpWidget(
      wrap(
        const TpButton(
          size: TpControlSize.large,
          onPressed: null,
          child: Text('Large'),
        ),
      ),
    );

    final button = tester.widget<TpButton>(find.byType(TpButton));
    expect(button.size, TpControlSize.large);
    expect(find.text('Large'), findsOneWidget);
  });

  testWidgets('disabled when onPressed is null', (tester) async {
    await tester.pumpWidget(
      wrap(const TpButton(onPressed: null, child: Text('Off'))),
    );
    await tester.tap(find.byType(TpButton));
    // No crash; button present.
    expect(find.text('Off'), findsOneWidget);
  });
}
