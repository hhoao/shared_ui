import 'package:flutter/foundation.dart';

/// Resolved spacing tokens derived from a UI [scale] multiplier.
@immutable
final class TpSpacing {
  const TpSpacing({
    required this.scale,
    required this.xxs,
    required this.xs,
    required this.sm,
    required this.md,
    required this.lg,
    required this.xl,
    required this.xxl,
  });

  /// Raw UI scale multiplier (1.0 = design baseline).
  final double scale;

  final double xxs;
  final double xs;
  final double sm;
  final double md;
  final double lg;
  final double xl;
  final double xxl;

  static const double xxsBase = 2;
  static const double xsBase = 4;
  static const double smBase = 8;
  static const double mdBase = 12;
  static const double lgBase = 16;
  static const double xlBase = 24;
  static const double xxlBase = 32;

  factory TpSpacing.fromScale(double scale) => TpSpacing(
    scale: scale,
    xxs: xxsBase * scale,
    xs: xsBase * scale,
    sm: smBase * scale,
    md: mdBase * scale,
    lg: lgBase * scale,
    xl: xlBase * scale,
    xxl: xxlBase * scale,
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TpSpacing &&
          scale == other.scale &&
          xxs == other.xxs &&
          xs == other.xs &&
          sm == other.sm &&
          md == other.md &&
          lg == other.lg &&
          xl == other.xl &&
          xxl == other.xxl;

  @override
  int get hashCode => Object.hash(scale, xxs, xs, sm, md, lg, xl, xxl);
}
