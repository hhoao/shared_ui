import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../components/toast/tp_toast.dart';

/// Visual slot for toast surfaces resolved from a [ColorScheme].
@immutable
class TpToastTheme {
  const TpToastTheme({
    required this.backgroundColor,
    required this.foregroundColor,
    required this.borderSide,
    required this.borderRadius,
    required this.boxShadow,
    required this.padding,
    required this.iconSize,
    required this.infoAccent,
    required this.successAccent,
    required this.warningAccent,
    required this.errorAccent,
  });

  factory TpToastTheme.fromColorScheme(
    ColorScheme scheme, {
    Color? backgroundColor,
    double borderRadius = 10,
    double iconSize = 20,
  }) {
    final isDark = scheme.brightness == Brightness.dark;
    return TpToastTheme(
      backgroundColor: backgroundColor ?? scheme.surfaceContainer,
      foregroundColor: scheme.onSurface,
      borderSide: BorderSide(
        color: scheme.outlineVariant.withValues(alpha: isDark ? 0.45 : 0.55),
      ),
      borderRadius: BorderRadius.circular(borderRadius),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.12),
          blurRadius: 12,
          offset: const Offset(0, 4),
        ),
      ],
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      iconSize: iconSize,
      infoAccent: scheme.primary,
      successAccent: scheme.secondary,
      warningAccent: scheme.primary,
      errorAccent: scheme.error,
    );
  }

  final Color backgroundColor;
  final Color foregroundColor;
  final BorderSide borderSide;
  final BorderRadius borderRadius;
  final List<BoxShadow> boxShadow;
  final EdgeInsetsGeometry padding;
  final double iconSize;
  final Color infoAccent;
  final Color successAccent;
  final Color warningAccent;
  final Color errorAccent;

  Color accentFor(TpToastVariant variant) => switch (variant) {
    TpToastVariant.info => infoAccent,
    TpToastVariant.success => successAccent,
    TpToastVariant.warning => warningAccent,
    TpToastVariant.error => errorAccent,
  };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TpToastTheme &&
          backgroundColor == other.backgroundColor &&
          foregroundColor == other.foregroundColor &&
          borderSide == other.borderSide &&
          borderRadius == other.borderRadius &&
          listEquals(boxShadow, other.boxShadow) &&
          padding == other.padding &&
          iconSize == other.iconSize &&
          infoAccent == other.infoAccent &&
          successAccent == other.successAccent &&
          warningAccent == other.warningAccent &&
          errorAccent == other.errorAccent;

  @override
  int get hashCode => Object.hash(
    backgroundColor,
    foregroundColor,
    borderSide,
    borderRadius,
    Object.hashAll(boxShadow),
    padding,
    iconSize,
    infoAccent,
    successAccent,
    warningAccent,
    errorAccent,
  );
}
