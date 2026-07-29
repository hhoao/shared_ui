import 'package:flutter/material.dart';

/// Layout and color tokens for [TpSidebar] composition.
@immutable
class TpSidebarTheme {
  const TpSidebarTheme({
    this.width = 256,
    this.widthIcon = 48,
    this.widthMobile = 288,
    this.animationDuration = const Duration(milliseconds: 200),
    this.floatingMargin = 8,
    this.floatingRadius = 12,
    this.insetRadius = 16,
    this.backgroundColor,
    this.foregroundColor,
    this.accentColor,
    this.accentForegroundColor,
    this.borderColor,
    this.insetBackgroundColor,
  });

  factory TpSidebarTheme.defaults() => const TpSidebarTheme();

  /// Muted sidebar chrome derived from [ColorScheme] (shadcn-like, theme-tinted).
  ///
  /// Active/hover use a soft on-surface wash instead of brand primary so rows
  /// stay quiet against product themes (e.g. huji workspace surfaces).
  factory TpSidebarTheme.fromColorScheme(ColorScheme cs) {
    final isDark = cs.brightness == Brightness.dark;
    return TpSidebarTheme(
      backgroundColor: cs.surfaceContainerLow,
      foregroundColor: cs.onSurface,
      accentColor: cs.onSurface.withValues(alpha: isDark ? 0.10 : 0.06),
      accentForegroundColor: cs.onSurface,
      borderColor: cs.outlineVariant.withValues(alpha: isDark ? 0.45 : 0.55),
      insetBackgroundColor: cs.surface,
    );
  }

  final double width;
  final double widthIcon;
  final double widthMobile;
  final Duration animationDuration;
  final double floatingMargin;
  final double floatingRadius;
  final double insetRadius;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final Color? accentColor;
  final Color? accentForegroundColor;
  final Color? borderColor;
  final Color? insetBackgroundColor;

  TpSidebarTheme copyWith({
    double? width,
    double? widthIcon,
    double? widthMobile,
    Duration? animationDuration,
    double? floatingMargin,
    double? floatingRadius,
    double? insetRadius,
    Color? backgroundColor,
    Color? foregroundColor,
    Color? accentColor,
    Color? accentForegroundColor,
    Color? borderColor,
    Color? insetBackgroundColor,
  }) {
    return TpSidebarTheme(
      width: width ?? this.width,
      widthIcon: widthIcon ?? this.widthIcon,
      widthMobile: widthMobile ?? this.widthMobile,
      animationDuration: animationDuration ?? this.animationDuration,
      floatingMargin: floatingMargin ?? this.floatingMargin,
      floatingRadius: floatingRadius ?? this.floatingRadius,
      insetRadius: insetRadius ?? this.insetRadius,
      backgroundColor: backgroundColor ?? this.backgroundColor,
      foregroundColor: foregroundColor ?? this.foregroundColor,
      accentColor: accentColor ?? this.accentColor,
      accentForegroundColor:
          accentForegroundColor ?? this.accentForegroundColor,
      borderColor: borderColor ?? this.borderColor,
      insetBackgroundColor: insetBackgroundColor ?? this.insetBackgroundColor,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TpSidebarTheme &&
          width == other.width &&
          widthIcon == other.widthIcon &&
          widthMobile == other.widthMobile &&
          animationDuration == other.animationDuration &&
          floatingMargin == other.floatingMargin &&
          floatingRadius == other.floatingRadius &&
          insetRadius == other.insetRadius &&
          backgroundColor == other.backgroundColor &&
          foregroundColor == other.foregroundColor &&
          accentColor == other.accentColor &&
          accentForegroundColor == other.accentForegroundColor &&
          borderColor == other.borderColor &&
          insetBackgroundColor == other.insetBackgroundColor;

  @override
  int get hashCode => Object.hash(
        width,
        widthIcon,
        widthMobile,
        animationDuration,
        floatingMargin,
        floatingRadius,
        insetRadius,
        backgroundColor,
        foregroundColor,
        accentColor,
        accentForegroundColor,
        borderColor,
        insetBackgroundColor,
      );
}
