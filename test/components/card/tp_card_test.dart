import 'package:flutter/material.dart';
import '../../support/tp_test_widgets.dart';
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

  testWidgets('wraps child with padded surface', (tester) async {
    await tester.pumpWidget(
      wrap(
        const TpCard(
          child: Text('Card body'),
        ),
      ),
    );

    expect(find.text('Card body'), findsOneWidget);
    expect(find.byType(TpCard), findsOneWidget);

    final box = tester.widget<DecoratedBox>(
      find.descendant(
        of: find.byType(TpCard),
        matching: find.byType(DecoratedBox),
      ).first,
    );
    expect(box.decoration, isA<BoxDecoration>());
    final decoration = box.decoration! as BoxDecoration;
    expect(decoration.color, isNotNull);

    final padding = tester.widget<Padding>(
      find.descendant(
        of: find.byType(TpCard),
        matching: find.byType(Padding),
      ).first,
    );
    expect(padding.padding, isNot(EdgeInsets.zero));
  });

  testWidgets('TpCard.elevated uses surface fill and shadow', (tester) async {
    await tester.pumpWidget(
      wrap(const TpCard.elevated(child: Text('Elevated'))),
    );

    final box = tester.widget<DecoratedBox>(
      find.descendant(
        of: find.byType(TpCard),
        matching: find.byType(DecoratedBox),
      ).first,
    );
    final decoration = box.decoration! as BoxDecoration;
    expect(decoration.boxShadow, isNotEmpty);
    expect(decoration.border, isNull);
  });

  testWidgets('TpCard.tiled uses border and shadow', (tester) async {
    await tester.pumpWidget(
      wrap(const TpCard.tiled(child: Text('Tile'))),
    );

    final box = tester.widget<DecoratedBox>(
      find.descendant(
        of: find.byType(TpCard),
        matching: find.byType(DecoratedBox),
      ).first,
    );
    final decoration = box.decoration! as BoxDecoration;
    expect(decoration.border, isNotNull);
    expect(decoration.boxShadow, isNotEmpty);
  });
}
