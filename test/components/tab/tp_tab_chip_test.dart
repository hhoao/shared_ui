import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_ui/shared_ui.dart';

void main() {
  Widget wrap(Widget child) {
    return MaterialApp(
      home: TpTheme(
        data: TpThemeData.fromColorScheme(
          ColorScheme.fromSeed(seedColor: Colors.blue),
          scale: 1.0,
        ),
        child: Scaffold(body: child),
      ),
    );
  }

  testWidgets('renders title and invokes onTap / onClose', (tester) async {
    var tapped = false;
    var closed = false;

    await tester.pumpWidget(
      wrap(
        TpTabChip(
          title: 'Session A',
          active: true,
          onTap: () => tapped = true,
          onClose: () => closed = true,
        ),
      ),
    );

    expect(find.text('Session A'), findsOneWidget);
    await tester.tap(find.text('Session A'));
    expect(tapped, isTrue);

    await tester.tap(find.byIcon(Icons.close));
    expect(closed, isTrue);
  });

  testWidgets('preview mutes and italicizes title', (tester) async {
    await tester.pumpWidget(
      wrap(
        TpTabChip(
          title: 'Draft',
          active: false,
          preview: true,
          onTap: () {},
          onClose: () {},
        ),
      ),
    );

    final text = tester.widget<Text>(find.text('Draft'));
    expect(text.style?.fontStyle, FontStyle.italic);
    expect(text.style?.color?.a, lessThan(1.0));
  });
}
