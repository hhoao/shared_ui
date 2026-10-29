import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_ui/shared_ui.dart';

Widget _wrap(Widget child) {
  return MaterialApp(
    home: TpTheme(
      data: TpThemeData.fromColorScheme(
        ColorScheme.fromSeed(seedColor: Colors.indigo),
        scale: 1,
      ),
      child: Scaffold(body: Center(child: child)),
    ),
  );
}

Widget _trigger() {
  return const SizedBox(
    key: Key('open-range'),
    width: 120,
    height: 40,
    child: ColoredBox(color: Colors.transparent),
  );
}

Future<void> _open(WidgetTester tester) async {
  await tester.tap(find.byKey(const Key('open-range')));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('preset click calls onPresetSelected and closes', (tester) async {
    String? selected;
    await tester.pumpWidget(
      _wrap(
        TpDateTimeRangePicker(
          firstDate: DateTime(2020),
          lastDate: DateTime(2030),
          labels: const TpDateTimeRangePickerLabels(),
          presets: const [TpDateTimeRangePreset(id: 'today', label: 'Today')],
          onPresetSelected: (id) => selected = id,
          triggerBuilder: (context, isOpen) => _trigger(),
        ),
      ),
    );

    await _open(tester);
    expect(find.text('Today'), findsOneWidget);
    await tester.tap(find.text('Today'));
    await tester.pumpAndSettle();

    expect(selected, 'today');
  });

  testWidgets('confirm returns the draft range', (tester) async {
    TpDateTimeRange? applied;
    await tester.pumpWidget(
      _wrap(
        TpDateTimeRangePicker(
          firstDate: DateTime(2020),
          lastDate: DateTime(2030),
          value: TpDateTimeRange(
            start: DateTime(2026, 9, 29, 10),
            end: DateTime(2026, 10, 29, 12),
          ),
          labels: const TpDateTimeRangePickerLabels(),
          onChanged: (value) => applied = value,
          triggerBuilder: (context, isOpen) => _trigger(),
        ),
      ),
    );

    await _open(tester);
    await tester.tap(find.text('Confirm'));
    await tester.pumpAndSettle();

    expect(applied, isNotNull);
    expect(applied!.start, DateTime(2026, 9, 29, 10));
    expect(applied!.end, DateTime(2026, 10, 29, 12));
  });

  testWidgets('editing the start hour updates the applied range', (
    tester,
  ) async {
    TpDateTimeRange? applied;
    await tester.pumpWidget(
      _wrap(
        TpDateTimeRangePicker(
          firstDate: DateTime(2020),
          lastDate: DateTime(2030),
          value: TpDateTimeRange(
            start: DateTime(2026, 9, 29, 10),
            end: DateTime(2026, 10, 29, 12),
          ),
          labels: const TpDateTimeRangePickerLabels(),
          onChanged: (value) => applied = value,
          triggerBuilder: (context, isOpen) => _trigger(),
        ),
      ),
    );

    await _open(tester);
    await tester.enterText(
      find.byKey(const Key('tp-time-picker-hour')).first,
      '11',
    );
    await tester.pump();
    await tester.tap(find.text('Confirm'));
    await tester.pumpAndSettle();

    expect(applied!.start.hour, 11);
  });

  testWidgets('invalid order shows an error and keeps the panel open', (
    tester,
  ) async {
    await tester.pumpWidget(
      _wrap(
        TpDateTimeRangePicker(
          firstDate: DateTime(2020),
          lastDate: DateTime(2030),
          value: TpDateTimeRange(
            start: DateTime(2026, 10, 29, 12),
            end: DateTime(2026, 10, 29, 10),
          ),
          labels: const TpDateTimeRangePickerLabels(),
          triggerBuilder: (context, isOpen) => _trigger(),
        ),
      ),
    );

    await _open(tester);
    await tester.tap(find.text('Confirm'));
    await tester.pumpAndSettle();

    expect(
      find.text('Start time cannot be later than end time'),
      findsOneWidget,
    );
    expect(find.text('Confirm'), findsOneWidget);
  });

  testWidgets('range longer than maxDuration shows an error', (tester) async {
    await tester.pumpWidget(
      _wrap(
        TpDateTimeRangePicker(
          firstDate: DateTime(2020),
          lastDate: DateTime(2030),
          maxDuration: const Duration(days: 30),
          value: TpDateTimeRange(
            start: DateTime(2026, 1, 1),
            end: DateTime(2026, 3, 1),
          ),
          labels: const TpDateTimeRangePickerLabels(),
          triggerBuilder: (context, isOpen) => _trigger(),
        ),
      ),
    );

    await _open(tester);
    await tester.tap(find.text('Confirm'));
    await tester.pumpAndSettle();

    expect(find.text('Range cannot exceed 30 days'), findsOneWidget);
  });

  testWidgets('live end disables the end time picker', (tester) async {
    await tester.pumpWidget(
      _wrap(
        TpDateTimeRangePicker(
          firstDate: DateTime(2020),
          lastDate: DateTime(2030),
          value: TpDateTimeRange(
            start: DateTime(2026, 9, 29, 10),
            end: DateTime.now(),
            liveEnd: true,
          ),
          labels: const TpDateTimeRangePickerLabels(),
          triggerBuilder: (context, isOpen) => _trigger(),
        ),
      ),
    );

    await _open(tester);
    final pickers = tester.widgetList<TpTimePicker>(find.byType(TpTimePicker));
    expect(pickers.last.enabled, isFalse);
  });

  testWidgets('narrow viewport opens a dialog', (tester) async {
    tester.view.physicalSize = const Size(500, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      _wrap(
        TpDateTimeRangePicker(
          firstDate: DateTime(2020),
          lastDate: DateTime(2030),
          labels: const TpDateTimeRangePickerLabels(),
          triggerBuilder: (context, isOpen) => _trigger(),
        ),
      ),
    );

    await _open(tester);
    expect(find.byType(TpDialog), findsOneWidget);
  });

  testWidgets('cancel closes without applying', (tester) async {
    TpDateTimeRange? applied;
    await tester.pumpWidget(
      _wrap(
        TpDateTimeRangePicker(
          firstDate: DateTime(2020),
          lastDate: DateTime(2030),
          value: TpDateTimeRange(
            start: DateTime(2026, 9, 29, 10),
            end: DateTime(2026, 10, 29, 12),
          ),
          labels: const TpDateTimeRangePickerLabels(),
          onChanged: (value) => applied = value,
          triggerBuilder: (context, isOpen) => _trigger(),
        ),
      ),
    );

    await _open(tester);
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();

    expect(applied, isNull);
    expect(find.text('Confirm'), findsNothing);
  });

  testWidgets('dialog confirm returns the draft range', (tester) async {
    tester.view.physicalSize = const Size(500, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    TpDateTimeRange? applied;
    await tester.pumpWidget(
      _wrap(
        TpDateTimeRangePicker(
          firstDate: DateTime(2020),
          lastDate: DateTime(2030),
          value: TpDateTimeRange(
            start: DateTime(2026, 9, 29, 10),
            end: DateTime(2026, 10, 29, 12),
          ),
          labels: const TpDateTimeRangePickerLabels(),
          onChanged: (value) => applied = value,
          triggerBuilder: (context, isOpen) => _trigger(),
        ),
      ),
    );

    await _open(tester);
    expect(find.byType(TpDialog), findsOneWidget);
    await tester.tap(find.text('Confirm'));
    await tester.pumpAndSettle();

    expect(applied, isNotNull);
    expect(applied!.start, DateTime(2026, 9, 29, 10));
    expect(applied!.end, DateTime(2026, 10, 29, 12));
    expect(find.byType(TpDialog), findsNothing);
  });

  testWidgets('trigger receives the live open state', (tester) async {
    final states = <bool>[];
    await tester.pumpWidget(
      _wrap(
        TpDateTimeRangePicker(
          firstDate: DateTime(2020),
          lastDate: DateTime(2030),
          labels: const TpDateTimeRangePickerLabels(),
          triggerBuilder: (context, isOpen) {
            states.add(isOpen);
            return _trigger();
          },
        ),
      ),
    );

    expect(states.last, isFalse);
    await _open(tester);
    expect(states.last, isTrue);

    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(states.last, isFalse);
  });
}
