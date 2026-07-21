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

  testWidgets('TpPreferenceRow shows title and trailing', (tester) async {
    await tester.pumpWidget(
      wrap(
        const TpPreferenceRow(
          title: 'Label',
          subtitle: 'Hint',
          trailing: Text('Value'),
        ),
      ),
    );
    expect(find.text('Label'), findsOneWidget);
    expect(find.text('Hint'), findsOneWidget);
    expect(find.text('Value'), findsOneWidget);
  });

  testWidgets('TpPreferenceStack places body below title', (tester) async {
    await tester.pumpWidget(
      wrap(
        const TpPreferenceStack(
          title: 'Stack',
          body: Text('Body'),
        ),
      ),
    );
    expect(find.text('Stack'), findsOneWidget);
    expect(find.text('Body'), findsOneWidget);
  });

  testWidgets('TpSectionHeader renders title', (tester) async {
    await tester.pumpWidget(wrap(const TpSectionHeader(title: 'Section')));
    expect(find.text('Section'), findsOneWidget);
  });

  testWidgets('TpCard.outlined has transparent fill', (tester) async {
    await tester.pumpWidget(
      wrap(const TpCard.outlined(child: Text('Panel'))),
    );
    final material = tester.widget<Material>(
      find.descendant(
        of: find.byType(TpCard),
        matching: find.byType(Material),
      ).first,
    );
    expect(material.color, Colors.transparent);
  });

  testWidgets('TpStatusBadge shows label', (tester) async {
    await tester.pumpWidget(
      wrap(
        const TpStatusBadge(
          label: 'Ready',
          tone: TpStatusBadgeTone.success,
          icon: Icons.check,
        ),
      ),
    );
    expect(find.text('Ready'), findsOneWidget);
  });

  testWidgets('TpDisclosure expands lazily', (tester) async {
    await tester.pumpWidget(
      wrap(
        const TpDisclosure(
          title: 'Advanced',
          subtitle: 'Agent preset and extra flags.',
          children: [Text('Secret')],
        ),
      ),
    );
    expect(find.text('Secret'), findsNothing);
    expect(find.text('Agent preset and extra flags.'), findsOneWidget);
    await tester.tap(find.text('Advanced'));
    await tester.pumpAndSettle();
    expect(find.text('Secret'), findsOneWidget);
  });

  testWidgets('TpSegmentedPicker notifies typed value', (tester) async {
    String? selected;
    await tester.pumpWidget(
      wrap(
        TpSegmentedPicker<String>(
          selected: 'a',
          segments: const [
            TpSegmentedOption(value: 'a', label: 'A', icon: Icons.looks_one),
            TpSegmentedOption(value: 'b', label: 'B', icon: Icons.looks_two),
          ],
          onChanged: (v) => selected = v,
        ),
      ),
    );
    await tester.tap(find.text('B'));
    await tester.pumpAndSettle();
    expect(selected, 'b');
  });
}
