import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../input/tp_input.dart';
import '../../theme/tp_text_styles.dart';
import '../../theme/tp_theme.dart';

/// 24-hour hour/minute entry control.
///
/// Two (optionally three, with [TpTimePicker.showSeconds]) numeric fields with
/// a `:` separator. Emissions fire only on a user edit that changes at least
/// one field's text, only when the hour and minute fields both parse, and only
/// when the resulting clamped value differs from the last emitted value.
///
/// Clamping is emit-time only: the display text may temporarily exceed the
/// valid range (e.g. `27` is shown while `23:00` is emitted) until the next
/// programmatic [TpTimePicker.initialValue] update rewrites the fields.
///
/// Programmatic updates echo through [TpTimePicker.initialValue]. An echo of
/// the value the user just emitted is consumed (fields keep their in-progress
/// text); any other update — including after an incomplete entry, which
/// invalidates the echo guard — restores the fields from the widget.
class TpTimePicker extends StatefulWidget {
  const TpTimePicker({
    super.key,
    this.initialValue,
    this.onChanged,
    this.enabled = true,
    this.trailing,
    this.showSeconds = false,
  });

  final TimeOfDay? initialValue;
  final ValueChanged<TimeOfDay>? onChanged;
  final bool enabled;

  /// Optional widget rendered after the numeric fields.
  final Widget? trailing;

  /// Shows a third editable seconds field. Seconds are display-only for now:
  /// they are clamped to 0-59 but excluded from [onChanged] emissions.
  final bool showSeconds;

  @override
  State<TpTimePicker> createState() => _TpTimePickerState();
}

class _TpTimePickerState extends State<TpTimePicker> {
  static const _hourKey = Key('tp-time-picker-hour');
  static const _minuteKey = Key('tp-time-picker-minute');
  static const _secondKey = Key('tp-time-picker-second');

  late final TextEditingController _hour;
  late final TextEditingController _minute;
  TextEditingController? _second;
  TimeOfDay? _lastEmitted;
  String _lastHourText = '';
  String _lastMinuteText = '';
  bool _restoringFromWidget = false;

  @override
  void initState() {
    super.initState();
    final initial = widget.initialValue;
    _hour = TextEditingController(text: _twoDigits(initial?.hour));
    _minute = TextEditingController(text: _twoDigits(initial?.minute));
    _lastHourText = _hour.text;
    _lastMinuteText = _minute.text;
    _second = _createSecond();
    _hour.addListener(_notify);
    _minute.addListener(_notify);
  }

  TextEditingController? _createSecond() {
    if (!widget.showSeconds) return null;
    // Seconds are display-only; seeding from zero keeps a full HH:mm:ss view.
    return TextEditingController(text: _twoDigits(0));
  }

  @override
  void didUpdateWidget(TpTimePicker oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.showSeconds != widget.showSeconds) {
      _second?.dispose();
      _second = _createSecond();
    }
    final initial = widget.initialValue;
    if (initial == oldWidget.initialValue) return;
    // Echo consumption: a parent that echoes the just-emitted value back must
    // not clobber the in-progress entry, so only non-echo updates restore.
    if (initial != null && initial == _lastEmitted) {
      _lastEmitted = null;
      return;
    }
    _lastEmitted = null;
    _restoringFromWidget = true;
    try {
      _setIfChanged(_hour, _twoDigits(initial?.hour));
      _setIfChanged(_minute, _twoDigits(initial?.minute));
      if (widget.showSeconds) {
        _setIfChanged(_second!, _twoDigits(0));
      }
    } finally {
      _restoringFromWidget = false;
    }
    _lastHourText = _hour.text;
    _lastMinuteText = _minute.text;
  }

  @override
  void dispose() {
    _hour.removeListener(_notify);
    _minute.removeListener(_notify);
    _hour.dispose();
    _minute.dispose();
    _second?.dispose();
    super.dispose();
  }

  void _setIfChanged(TextEditingController controller, String text) {
    if (controller.text != text) controller.text = text;
  }

  String _twoDigits(int? value) =>
      value == null ? '' : value.toString().padLeft(2, '0');

  void _notify() {
    if (_restoringFromWidget) return;
    final hourText = _hour.text;
    final minuteText = _minute.text;
    // Text-only baseline: focus/selection changes re-fire listeners with
    // unchanged text and must not re-emit.
    if (hourText == _lastHourText && minuteText == _lastMinuteText) return;
    _lastHourText = hourText;
    _lastMinuteText = minuteText;
    final hour = int.tryParse(hourText);
    final minute = int.tryParse(minuteText);
    if (hour == null || minute == null) {
      // Incomplete entry: no emission, and the echo guard is invalidated so a
      // later programmatic reset still applies.
      _lastEmitted = null;
      return;
    }
    final time = TimeOfDay(
      hour: hour.clamp(0, 23),
      minute: minute.clamp(0, 59),
    );
    if (time == _lastEmitted) return;
    _lastEmitted = time;
    widget.onChanged?.call(time);
  }

  @override
  Widget build(BuildContext context) {
    final fields = <Widget>[
      _field(
        context,
        key: _hourKey,
        controller: _hour,
        textInputAction: TextInputAction.next,
      ),
      _separator(context),
      _field(
        context,
        key: _minuteKey,
        controller: _minute,
        textInputAction: widget.showSeconds
            ? TextInputAction.next
            : TextInputAction.done,
      ),
    ];
    final second = _second;
    if (widget.showSeconds && second != null) {
      fields
        ..add(_separator(context))
        ..add(
          _field(
            context,
            key: _secondKey,
            controller: second,
            textInputAction: TextInputAction.done,
          ),
        );
    }
    final trailing = widget.trailing;
    if (trailing != null) fields.add(trailing);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: fields,
    );
  }

  Widget _separator(BuildContext context) {
    final styles = TpTextStyles.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: Text(':', style: styles.md),
    );
  }

  Widget _field(
    BuildContext context, {
    required Key key,
    required TextEditingController controller,
    required TextInputAction textInputAction,
  }) {
    final styles = TpTextStyles.of(context);
    final scale = TpTheme.of(context).control.scale;
    return SizedBox(
      width: 48 * scale,
      child: TextField(
        key: key,
        controller: controller,
        enabled: widget.enabled,
        textAlign: TextAlign.center,
        keyboardType: TextInputType.number,
        inputFormatters: [
          FilteringTextInputFormatter.digitsOnly,
          LengthLimitingTextInputFormatter(2),
        ],
        textInputAction: textInputAction,
        style: styles.md,
        decoration: tpOutlineInputDecoration(context),
      ),
    );
  }
}
