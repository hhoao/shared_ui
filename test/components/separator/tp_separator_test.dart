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

  testWidgets('renders horizontal separator', (tester) async {
    await tester.pumpWidget(
      wrap(
        const SizedBox(
          width: 200,
          child: TpSeparator(),
        ),
      ),
    );

    expect(find.byType(TpSeparator), findsOneWidget);
    final box = tester.renderObject<RenderBox>(find.byType(TpSeparator));
    expect(box.size.width, greaterThan(0));
    expect(box.size.height, greaterThan(0));
    expect(box.size.width, greaterThan(box.size.height));
  });

  testWidgets('renders vertical separator', (tester) async {
    await tester.pumpWidget(
      wrap(
        const SizedBox(
          height: 200,
          child: TpSeparator(axis: Axis.vertical),
        ),
      ),
    );

    expect(find.byType(TpSeparator), findsOneWidget);
    final box = tester.renderObject<RenderBox>(find.byType(TpSeparator));
    expect(box.size.height, greaterThan(box.size.width));
  });
}
