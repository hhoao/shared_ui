import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_ui/shared_ui.dart';

void main() {
  testWidgets('renders title, hint, and action', (tester) async {
    var taps = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: TpTheme(
          data: TpThemeData.fromColorScheme(
            ColorScheme.fromSeed(seedColor: Colors.orange),
            scale: 1.0,
          ),
          child: Scaffold(
            body: TpEmptyState(
              icon: Icons.inbox_outlined,
              title: 'Nothing here',
              hint: 'Add an item to get started',
              actionLabel: 'Add',
              onAction: () => taps++,
            ),
          ),
        ),
      ),
    );

    expect(find.text('Nothing here'), findsOneWidget);
    expect(find.text('Add an item to get started'), findsOneWidget);
    expect(find.text('Add'), findsOneWidget);
    await tester.tap(find.text('Add'));
    expect(taps, 1);
  });

  testWidgets('centered wraps content in Center', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: TpTheme(
          data: TpThemeData.fromColorScheme(
            ColorScheme.fromSeed(seedColor: Colors.orange),
            scale: 1.0,
          ),
          child: const Scaffold(
            body: TpEmptyState(
              icon: Icons.inbox_outlined,
              title: 'Empty',
              centered: true,
            ),
          ),
        ),
      ),
    );

    expect(
      find.ancestor(of: find.text('Empty'), matching: find.byType(Center)),
      findsWidgets,
    );
  });
}
