import 'package:flutter/foundation.dart';

/// Default metrics for [TpPopover] transitions and placement.
@immutable
class TpPopoverTheme {
  const TpPopoverTheme({
    this.transitionDuration = const Duration(milliseconds: 160),
    this.defaultOffsetDy = 4,
  });

  factory TpPopoverTheme.defaults() => const TpPopoverTheme();

  final Duration transitionDuration;
  final double defaultOffsetDy;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TpPopoverTheme &&
          transitionDuration == other.transitionDuration &&
          defaultOffsetDy == other.defaultOffsetDy;

  @override
  int get hashCode => Object.hash(transitionDuration, defaultOffsetDy);
}
