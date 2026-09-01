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

  Finder field(Key key) => find.descendant(
        of: find.byType(TpTimePicker),
        matching: find.byKey(key),
      );

  TextField fieldWidget(WidgetTester tester, Key key) =>
      tester.widget<TextField>(field(key));

  /// Stateful host echoing emissions back into `initialValue`, mirroring the
  /// real consumer pattern where a parent-owned value round-trips.
  _HostShell host(
    List<TimeOfDay> emissions, {
    Key? key,
    required TimeOfDay initialValue,
    bool showSeconds = false,
    Widget? trailing,
  }) {
    return _HostShell(
      key: key,
      emissions: emissions,
      initialValue: initialValue,
      showSeconds: showSeconds,
      trailing: trailing,
    );
  }

  Future<List<TimeOfDay>> pumpHost(
    WidgetTester tester, {
    Key? key,
    required TimeOfDay initialValue,
    bool showSeconds = false,
    Widget? trailing,
  }) async {
    final emissions = <TimeOfDay>[];
    await tester.pumpWidget(
      wrap(
        host(
          emissions,
          key: key,
          initialValue: initialValue,
          showSeconds: showSeconds,
          trailing: trailing,
        ),
      ),
    );
    await tester.pump();
    return emissions;
  }

  testWidgets('TpTimePicker notifies on hour and minute edit', (tester) async {
    final emissions = await pumpHost(
      tester,
      initialValue: const TimeOfDay(hour: 9, minute: 0),
    );

    await tester.enterText(field(const Key('tp-time-picker-hour')), '14');
    await tester.pump();
    await tester.enterText(field(const Key('tp-time-picker-minute')), '30');
    await tester.pump();

    expect(emissions.last, const TimeOfDay(hour: 14, minute: 30));
  });

  testWidgets('TpTimePicker reflects a new initialValue', (tester) async {
    final emissions = await pumpHost(
      tester,
      key: const ValueKey('host'),
      initialValue: const TimeOfDay(hour: 9, minute: 0),
    );

    // Rebuild the same host with a new programmatic initialValue.
    await tester.pumpWidget(
      wrap(
        host(
          emissions,
          key: const ValueKey('host'),
          initialValue: const TimeOfDay(hour: 15, minute: 30),
        ),
      ),
    );
    await tester.pump();

    expect(fieldWidget(tester, const Key('tp-time-picker-hour')).controller!.text,
        '15');
  });

  testWidgets('TpTimePicker keeps in-progress entry when parent echoes value',
      (tester) async {
    final emissions = await pumpHost(
      tester,
      initialValue: const TimeOfDay(hour: 9, minute: 0),
    );

    await tester.enterText(field(const Key('tp-time-picker-hour')), '2');
    await tester.pump();

    // Hour '2' with the seeded minute '00' parses to a complete emission.
    expect(emissions.last, const TimeOfDay(hour: 2, minute: 0));

    // The host echo of that same value must not clobber the in-progress text.
    expect(fieldWidget(tester, const Key('tp-time-picker-hour')).controller!.text,
        '2');
  });

  testWidgets('TpTimePicker clamps out-of-range entries', (tester) async {
    final emissions = await pumpHost(
      tester,
      initialValue: const TimeOfDay(hour: 9, minute: 0),
    );

    await tester.enterText(field(const Key('tp-time-picker-hour')), '27');
    await tester.pump();

    expect(emissions.last, const TimeOfDay(hour: 23, minute: 0));
  });

  testWidgets('TpTimePicker emits once per edit and not on focus', (
    tester,
  ) async {
    final emissions = await pumpHost(
      tester,
      initialValue: const TimeOfDay(hour: 9, minute: 0),
    );

    await tester.tap(field(const Key('tp-time-picker-hour')));
    await tester.pump();

    expect(emissions, isEmpty);

    await tester.enterText(field(const Key('tp-time-picker-hour')), '5');
    await tester.pump();

    expect(emissions, const [TimeOfDay(hour: 5, minute: 0)]);
  });

  testWidgets('TpTimePicker applies programmatic reset after incomplete entry',
      (tester) async {
    final emissions = await pumpHost(
      tester,
      initialValue: const TimeOfDay(hour: 9, minute: 0),
    );

    await tester.enterText(field(const Key('tp-time-picker-hour')), '14');
    await tester.pump();
    expect(emissions.last, const TimeOfDay(hour: 14, minute: 0));

    // Clearing the hour leaves an incomplete entry: no emission, and the echo
    // guard must be invalidated so a later programmatic reset still applies.
    await tester.enterText(field(const Key('tp-time-picker-hour')), '');
    await tester.pump();
    final afterClear = emissions.length;
    expect(emissions, hasLength(afterClear));

    // Rebuild the same host with a programmatic initialValue; the reset must
    // still land because the incomplete entry invalidated the echo guard.
    await tester.pumpWidget(
      wrap(
        host(
          <TimeOfDay>[],
          key: const ValueKey('host'),
          initialValue: const TimeOfDay(hour: 14, minute: 0),
        ),
      ),
    );
    await tester.pump();
    expect(
      fieldWidget(tester, const Key('tp-time-picker-hour')).controller!.text,
      '14',
    );
  });
}

class _HostShell extends StatefulWidget {
  const _HostShell({
    required this.emissions,
    required this.initialValue,
    this.showSeconds = false,
    this.trailing,
    super.key,
  });

  final List<TimeOfDay> emissions;
  final TimeOfDay initialValue;
  final bool showSeconds;
  final Widget? trailing;

  @override
  State<_HostShell> createState() => _HostShellState();
}

class _HostShellState extends State<_HostShell> {
  late TimeOfDay _value = widget.initialValue;

  @override
  void didUpdateWidget(_HostShell oldWidget) {
    super.didUpdateWidget(oldWidget);
    // The parent owns the value: adopt a changed initialValue on rebuild,
    // mirroring how a cubit-owned draft flows back into the picker.
    if (widget.initialValue != oldWidget.initialValue) {
      _value = widget.initialValue;
    }
  }

  @override
  Widget build(BuildContext context) {
    return TpTimePicker(
      initialValue: _value,
      showSeconds: widget.showSeconds,
      trailing: widget.trailing,
      onChanged: (time) => setState(() {
        widget.emissions.add(time);
        _value = time;
      }),
    );
  }
}
