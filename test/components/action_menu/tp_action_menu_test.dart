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

  testWidgets('TpActionMenuItem invokes onTap', (tester) async {
    var tapped = false;
    await tester.pumpWidget(
      wrap(
        TpActionMenuPanel(
          children: [
            TpActionMenuItem(
              icon: Icons.check,
              label: 'Do it',
              onTap: () => tapped = true,
            ),
          ],
        ),
      ),
    );
    await tester.tap(find.text('Do it'));
    await tester.pump();
    expect(tapped, isTrue);
  });

  testWidgets('TpActionMenuShortcut renders muted trailing label', (tester) async {
    await tester.pumpWidget(
      wrap(
        TpActionMenuPanel(
          children: [
            TpActionMenuItem(
              icon: Icons.content_copy,
              label: 'Copy',
              trailing: const TpActionMenuShortcut('⌘C'),
              onTap: () {},
            ),
          ],
        ),
      ),
    );
    expect(find.text('⌘C'), findsOneWidget);
  });
}
