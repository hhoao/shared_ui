import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Resolved icon sizes derived from a UI [scale] multiplier.
///
/// Four roles only — chrome triad + one illustration size:
/// - [sm] dense chrome (tabs, compact toolbars)
/// - [md] default interactive ([IconTheme])
/// - [lg] emphasized chrome / search
/// - [hero] empty-state / feature illustrations
///
/// Prefer [BuildContext.tpIconSizes] at runtime; use [resolveIconMultiplier]
/// when the host maps text-size prefs → [TpThemeData] `iconScale`.
@immutable
final class TpIconSizes {
  const TpIconSizes({
    required this.scale,
    required this.sm,
    required this.md,
    required this.lg,
    required this.hero,
  });

  /// Raw UI scale multiplier (1.0 = design baseline).
  final double scale;

  final double sm;
  final double md;
  final double lg;
  final double hero;

  // --- Baselines at multiplier 1.0 ---
  //
  // md sits ~1.3× bodyMedium (14) so toolbar glyphs optically match text.
  // Steps are 2px apart so roles stay distinguishable.

  /// Dense chrome (editor/terminal tab actions, compact lists).
  static const double smBase = 16;

  /// Default interactive icon: lists, toolbars, title bars, buttons.
  static const double mdBase = 18;

  /// Emphasized nav / search fields.
  static const double lgBase = 20;

  /// Empty-state / feature illustration.
  static const double heroBase = 38;

  /// Global shrink on icon baselines (design tuning).
  static const double baselineScale = 1.32;

  /// Portion of the **user** text-size delta (compact / comfortable / custom,
  /// relative to the per-system auto baseline) applied to icon sizes. The OS
  /// auto text baseline is not passed through — see [resolveIconMultiplier].
  static const double userScaleTracking = 0.75;

  /// Maps effective text multiplier → icon multiplier for [TpThemeData.iconScale].
  ///
  /// Text uses [effectiveTextMultiplier] (includes OS auto baseline on high-DPI).
  /// Icons keep a fixed baseline on screen and only pick up user preset changes,
  /// damped by [userScaleTracking] and [baselineScale].
  static double resolveIconMultiplier({
    required double effectiveTextMultiplier,
    required double textBaseline,
  }) {
    final baseline = textBaseline <= 0 ? 1.0 : textBaseline;
    final userRelative = effectiveTextMultiplier / baseline;
    final userMapped = 1.0 + (userRelative - 1.0) * userScaleTracking;
    return baselineScale * userMapped;
  }

  factory TpIconSizes.fromScale(double scale) => TpIconSizes(
    scale: scale,
    sm: smBase * scale,
    md: mdBase * scale,
    lg: lgBase * scale,
    hero: heroBase * scale,
  );

  /// Default [IconThemeData] ([md] = [mdBase] × [scale]).
  static IconThemeData iconTheme(
    ColorScheme scheme, {
    double scale = 1.0,
  }) => IconThemeData(
    size: mdBase * scale,
    color: scheme.tpIcon,
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TpIconSizes &&
          scale == other.scale &&
          sm == other.sm &&
          md == other.md &&
          lg == other.lg &&
          hero == other.hero;

  @override
  int get hashCode => Object.hash(scale, sm, md, lg, hero);
}

extension TpIconColors on ColorScheme {
  /// Default interactive glyph ([ThemeData.iconTheme]).
  Color get tpIcon => onSurface;

  /// Secondary / hint glyphs (search fields, placeholders).
  Color get tpIconMuted => onSurfaceVariant;

  /// Disabled toolbar and list icons (Material 3 disabled opacity).
  Color get tpIconDisabled => tpIcon.withValues(alpha: 0.38);
}
