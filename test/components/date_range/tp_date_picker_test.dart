import 'package:flutter/material.dart';
import '../../support/tp_test_widgets.dart';
import 'package:shared_ui/shared_ui.dart';

void main() {
  Widget wrap(Widget child) => MaterialApp(
        home: TpTheme(
          data: TpThemeData.fromColorScheme(
            ColorScheme.fromSeed(seedColor: Colors.orange),
            scale: 1.0,
          ),
          child: Scaffold(body: child),
        ),
      );

  testWidgets('TpCalendar selects a single day', (tester) async {
    DateTime? selected;
    await tester.pumpWidget(
      wrap(
        Center(
          child: SizedBox(
            width: 280,
            child: TpCalendar(
              firstDate: DateTime(2026, 7, 1),
              lastDate: DateTime(2026, 7, 31),
              initialMonth: DateTime(2026, 7, 1),
              onChanged: (d) => selected = d,
            ),
          ),
        ),
      ),
    );
    Finder enabledDay(String label) => find.descendant(
          of: find.byType(TpHover),
          matching: find.text(label),
        );
    await tester.tap(enabledDay('5'));
    await tester.pump();
    expect(selected, DateTime(2026, 7, 5));
  });

  testWidgets('TpDatePicker opens and closes on selection', (tester) async {
    DateTime? selected;
    await tester.pumpWidget(
      wrap(
        TpDatePicker(
          firstDate: DateTime(2026, 1, 1),
          lastDate: DateTime(2026, 12, 31),
          closeOnSelection: true,
          onChanged: (d) => selected = d,
          triggerBuilder: (context, isOpen) =>
              Text(isOpen ? 'Open' : 'Closed'),
        ),
      ),
    );
    await tester.tap(find.text('Closed'));
    await tester.pumpAndSettle();
    expect(find.byType(TpCalendar), findsOneWidget);
    await tester.tap(
      find.descendant(of: find.byType(TpHover), matching: find.text('15')),
    );
    await tester.pumpAndSettle();
    expect(selected, isNotNull);
    expect(find.text('Closed'), findsOneWidget);
  });
}
