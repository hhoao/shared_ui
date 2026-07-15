import 'package:flutter/material.dart';

/// Thickness / opacity defaults for [TpSeparator].
@immutable
class TpSeparatorTheme {
  const TpSeparatorTheme({
    this.thickness = 1,
    this.outlineAlpha = 1,
  });

  factory TpSeparatorTheme.defaults() => const TpSeparatorTheme();

  final double thickness;

  /// Multiplier on [ColorScheme.outlineVariant] alpha.
  final double outlineAlpha;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TpSeparatorTheme &&
          thickness == other.thickness &&
          outlineAlpha == other.outlineAlpha;

  @override
  int get hashCode => Object.hash(thickness, outlineAlpha);
}
