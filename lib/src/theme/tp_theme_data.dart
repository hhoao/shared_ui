import 'package:flutter/material.dart';

import 'tokens/tp_control_metrics.dart';
import 'tokens/tp_icon_sizes.dart';
import 'tokens/tp_spacing.dart';
import 'tokens/tp_typography.dart';

/// Design-system theme data: tokens built from a [ColorScheme] and UI [scale].
@immutable
class TpThemeData {
  const TpThemeData({
    required this.colorScheme,
    required this.spacing,
    required this.iconSizes,
    required this.typography,
    required this.control,
  });

  factory TpThemeData.fromColorScheme(
    ColorScheme scheme, {
    required double scale,
  }) => TpThemeData(
    colorScheme: scheme,
    spacing: TpSpacing.fromScale(scale),
    iconSizes: TpIconSizes.fromScale(scale),
    typography: TpTypography(scale: scale),
    control: TpControlMetrics.fromScale(scale),
  );

  /// Sane defaults when no [TpTheme] ancestor is present.
  factory TpThemeData.fallback() => TpThemeData.fromColorScheme(
    ColorScheme.fromSeed(seedColor: const Color(0xFFD4A06A)),
    scale: 1.0,
  );

  /// Stored for future component themes; tokens themselves are scale-driven.
  final ColorScheme colorScheme;
  final TpSpacing spacing;
  final TpIconSizes iconSizes;
  final TpTypography typography;
  final TpControlMetrics control;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TpThemeData &&
          colorScheme == other.colorScheme &&
          spacing == other.spacing &&
          iconSizes == other.iconSizes &&
          typography == other.typography &&
          control == other.control;

  @override
  int get hashCode =>
      Object.hash(colorScheme, spacing, iconSizes, typography, control);
}
