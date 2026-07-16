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

  testWidgets('TpRangeCalendar selects a date range', (tester) async {
    DateTimeRange? selected;
    final first = DateTime(2026, 7, 1);
    final last = DateTime(2026, 7, 31);

    await tester.pumpWidget(
      wrap(
        Center(
          child: SizedBox(
            width: 280,
            child: TpRangeCalendar(
              firstDate: first,
              lastDate: last,
              initialMonth: first,
              onChanged: (range) => selected = range,
            ),
          ),
        ),
      ),
    );

    // Outside-month cells can share the same day number; tap the hoverable
    // (enabled) cell.
    Finder enabledDay(String label) => find.descendant(
          of: find.byType(TpHover),
          matching: find.text(label),
        );

    await tester.tap(enabledDay('5'));
    await tester.pump();
    await tester.tap(enabledDay('10'));
    await tester.pump();

    expect(selected, isNotNull);
    expect(selected!.start, DateTime(2026, 7, 5));
    expect(selected!.end, DateTime(2026, 7, 10));
    expect(find.text('清除'), findsOneWidget);
  });

  testWidgets('TpDateRangePicker opens calendar on trigger tap', (tester) async {
    await tester.pumpWidget(
      wrap(
        TpDateRangePicker(
          firstDate: DateTime(2026, 1, 1),
          lastDate: DateTime(2026, 12, 31),
          triggerBuilder: (context, isOpen) => Text(isOpen ? 'Open' : 'Closed'),
        ),
      ),
    );

    expect(find.text('Closed'), findsOneWidget);
    await tester.tap(find.text('Closed'));
    await tester.pumpAndSettle();

    expect(find.text('Open'), findsOneWidget);
    expect(find.byType(TpRangeCalendar), findsOneWidget);
  });
}
