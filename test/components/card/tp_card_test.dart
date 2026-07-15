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

    final material = tester.widget<Material>(
      find.descendant(
        of: find.byType(TpCard),
        matching: find.byType(Material),
      ).first,
    );
    expect(material.color, isNotNull);

    final padding = tester.widget<Padding>(
      find.descendant(
        of: find.byType(TpCard),
        matching: find.byType(Padding),
      ).first,
    );
    expect(padding.padding, isNot(EdgeInsets.zero));
  });
}
