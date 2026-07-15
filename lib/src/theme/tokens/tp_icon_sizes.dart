import 'package:flutter/foundation.dart';

/// Resolved icon sizes derived from a UI [scale] multiplier (geometry only).
@immutable
final class TpIconSizes {
  const TpIconSizes({
    required this.scale,
    required this.xxs,
    required this.xs,
    required this.sm,
    required this.md,
    required this.lg,
    required this.xl,
    required this.navRelaxed,
    required this.list,
    required this.empty,
    required this.hero,
    required this.display,
  });

  /// Raw UI scale multiplier (1.0 = design baseline).
  final double scale;

  final double xxs;
  final double xs;
  final double sm;
  final double md;
  final double lg;
  final double xl;
  final double navRelaxed;
  final double list;
  final double empty;
  final double hero;
  final double display;

  static const double xxsBase = 14;
  static const double xsBase = 15;
  static const double smBase = 16;
  static const double mdBase = 18;
  static const double lgBase = 20;
  static const double xlBase = 22;
  static const double navRelaxedBase = 20;
  static const double listBase = 30;
  static const double emptyBase = 34;
  static const double heroBase = 38;
  static const double displayBase = 44;

  factory TpIconSizes.fromScale(double scale) => TpIconSizes(
    scale: scale,
    xxs: xxsBase * scale,
    xs: xsBase * scale,
    sm: smBase * scale,
    md: mdBase * scale,
    lg: lgBase * scale,
    xl: xlBase * scale,
    navRelaxed: navRelaxedBase * scale,
    list: listBase * scale,
    empty: emptyBase * scale,
    hero: heroBase * scale,
    display: displayBase * scale,
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TpIconSizes &&
          scale == other.scale &&
          xxs == other.xxs &&
          xs == other.xs &&
          sm == other.sm &&
          md == other.md &&
          lg == other.lg &&
          xl == other.xl &&
          navRelaxed == other.navRelaxed &&
          list == other.list &&
          empty == other.empty &&
          hero == other.hero &&
          display == other.display;

  @override
  int get hashCode => Object.hash(
    scale,
    xxs,
    xs,
    sm,
    md,
    lg,
    xl,
    navRelaxed,
    list,
    empty,
    hero,
    display,
  );
}
