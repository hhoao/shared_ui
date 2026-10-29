import 'package:flutter/foundation.dart';

enum TpDateTimeRangeField { start, end }

@immutable
class TpDateTimeRange {
  const TpDateTimeRange({
    required this.start,
    required this.end,
    this.liveEnd = false,
  });

  final DateTime start;
  final DateTime end;
  final bool liveEnd;

  TpDateTimeRange copyWith({
    DateTime? start,
    DateTime? end,
    bool? liveEnd,
  }) {
    return TpDateTimeRange(
      start: start ?? this.start,
      end: end ?? this.end,
      liveEnd: liveEnd ?? this.liveEnd,
    );
  }

  @override
  bool operator ==(Object other) {
    return other is TpDateTimeRange &&
        other.start == start &&
        other.end == end &&
        other.liveEnd == liveEnd;
  }

  @override
  int get hashCode => Object.hash(start, end, liveEnd);
}

@immutable
class TpDateTimeRangePreset {
  const TpDateTimeRangePreset({required this.id, required this.label});

  final String id;
  final String label;
}

@immutable
class TpDateTimeRangePickerLabels {
  const TpDateTimeRangePickerLabels({
    this.start = 'Start time',
    this.end = 'End time',
    this.confirm = 'Confirm',
    this.cancel = 'Cancel',
    this.hint = 'Date and time, up to 30 days',
    this.liveEnd = 'End time follows now',
    this.invalidOrder = 'Start time cannot be later than end time',
    this.tooLong = 'Range cannot exceed 30 days',
  });

  final String start;
  final String end;
  final String confirm;
  final String cancel;
  final String hint;
  final String liveEnd;
  final String invalidOrder;
  final String tooLong;
}
