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
/// Prefer [BuildContext.tpIconSizes] for standalone toolbar icons; use
/// [iconSizeForTextFontSize] beside labels; use [resolveIconMultiplier] for
/// [TpThemeData] `iconScale` (OS baseline only).
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

  /// Optical tuning so [md] (~18) reads ~1.3× [bodyMedium] (14) at scale 1.0.
  static const double baselineScale = 1.32;

  /// [md] icon size paired to a resolved text [fontSize] whose design baseline
  /// (multiplier 1.0) is [textBaseAtScale1] — keeps chrome glyphs proportional
  /// when text size and interface zoom are adjusted independently.
  static double iconSizeForTextFontSize(
    double fontSize, {
    required double textBaseAtScale1,
  }) {
    if (fontSize <= 0 || textBaseAtScale1 <= 0) {
      return mdBase * baselineScale;
    }
    return fontSize * (mdBase * baselineScale) / textBaseAtScale1;
  }

  /// Maps OS auto text baseline → icon multiplier for [TpThemeData.iconScale].
  ///
  /// In-app **text size** adjusts [ThemeData.textTheme] only; **interface zoom**
  /// scales the whole tree via [UiZoom]. Icons follow the OS baseline (mobile
  /// accessibility / desktop DPI) here, and pair to adjacent labels via
  /// [iconSizeForTextFontSize] where chrome must track label size.
  static double resolveIconMultiplier({
    required double textBaseline,
  }) {
    final baseline = textBaseline <= 0 ? 1.0 : textBaseline;
    return baselineScale * baseline;
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
