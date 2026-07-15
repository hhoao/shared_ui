import 'package:flutter/material.dart';

import '../tokens/tp_control_metrics.dart';

/// Thin button metrics override for [TpButton].
@immutable
class TpButtonTheme {
  const TpButtonTheme({
    this.defaultSize = TpControlSize.medium,
  });

  factory TpButtonTheme.defaults() => const TpButtonTheme();

  /// Default [TpControlSize] when a button does not specify [TpButton.size].
  final TpControlSize defaultSize;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TpButtonTheme && defaultSize == other.defaultSize;

  @override
  int get hashCode => defaultSize.hashCode;
}
