import 'package:flutter/material.dart';

/// Surface + padding defaults for [TpCard].
@immutable
class TpCardTheme {
  const TpCardTheme({
    this.padding,
    this.borderRadius,
  });

  factory TpCardTheme.defaults() => const TpCardTheme();

  /// Inner padding around the card child. When null, uses [TpSpacing.md].
  final EdgeInsetsGeometry? padding;

  /// Corner radius. When null, uses [TpControlMetrics.radius].
  final double? borderRadius;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TpCardTheme &&
          padding == other.padding &&
          borderRadius == other.borderRadius;

  @override
  int get hashCode => Object.hash(padding, borderRadius);
}
