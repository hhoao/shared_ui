import 'package:flutter/material.dart';

/// Shared corner radius for [Dialog] / [AlertDialog] shells.
const double kTpDialogBorderRadius = 32;

/// Outer margin between dialog chrome and the viewport edge.
const EdgeInsets kTpDialogInsetPadding = EdgeInsets.all(24);

/// Total horizontal/vertical inset (left + right, or top + bottom).
const double kTpDialogInsetExtent = 48;

/// Inner padding around a [TpDialog]'s content column.
///
/// `DialogThemeData` deliberately exposes no content padding (only
/// `actionsPadding` / `insetPadding`), so this constant is the single source of
/// truth for the gap between the dialog edge and its body. Override per-call via
/// [TpDialog.contentPadding] when a dialog needs a tighter or wider frame.
const EdgeInsets kTpDialogContentPadding = EdgeInsets.fromLTRB(32, 28, 32, 28);

/// Horizontal inset of [kTpDialogContentPadding]; used to bleed section dividers.
const double kTpDialogContentHorizontalInset = 32;

RoundedRectangleBorder tpDialogShape([
  double radius = kTpDialogBorderRadius,
]) => RoundedRectangleBorder(borderRadius: BorderRadius.circular(radius));

TextStyle tpDialogTitleStyle({
  required TextTheme textTheme,
  required ColorScheme colorScheme,
}) {
  return (textTheme.titleMedium ?? const TextStyle()).copyWith(
    fontWeight: FontWeight.w600,
    height: 1.25,
    color: colorScheme.onSurface,
  );
}

/// Metrics and Material [DialogThemeData] builder for [TpDialog].
@immutable
class TpDialogTheme {
  const TpDialogTheme({
    this.borderRadius = kTpDialogBorderRadius,
    this.insetPadding = kTpDialogInsetPadding,
    this.contentPadding = kTpDialogContentPadding,
    this.contentHorizontalInset = kTpDialogContentHorizontalInset,
    this.barrierAlpha = 0.45,
  });

  factory TpDialogTheme.defaults() => const TpDialogTheme();

  final double borderRadius;
  final EdgeInsets insetPadding;
  final EdgeInsets contentPadding;
  final double contentHorizontalInset;
  final double barrierAlpha;

  double get insetExtent =>
      insetPadding.left + insetPadding.right;

  RoundedRectangleBorder shape() => tpDialogShape(borderRadius);

  /// Builds Material [DialogThemeData] for app-level [ThemeData.dialogTheme].
  ///
  /// Background uses [ColorScheme.surfaceContainerLow] (quiet elevated surface).
  DialogThemeData toDialogThemeData({
    required ColorScheme colorScheme,
    required TextTheme textTheme,
  }) {
    return DialogThemeData(
      clipBehavior: Clip.antiAlias,
      insetPadding: insetPadding,
      shape: shape(),
      backgroundColor: colorScheme.surfaceContainerLow,
      surfaceTintColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: barrierAlpha),
      titleTextStyle: tpDialogTitleStyle(
        textTheme: textTheme,
        colorScheme: colorScheme,
      ),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TpDialogTheme &&
          borderRadius == other.borderRadius &&
          insetPadding == other.insetPadding &&
          contentPadding == other.contentPadding &&
          contentHorizontalInset == other.contentHorizontalInset &&
          barrierAlpha == other.barrierAlpha;

  @override
  int get hashCode => Object.hash(
    borderRadius,
    insetPadding,
    contentPadding,
    contentHorizontalInset,
    barrierAlpha,
  );
}

/// Convenience builder matching the former `buildAppDialogTheme` entry point.
DialogThemeData buildTpDialogTheme({
  required ColorScheme colorScheme,
  required TextTheme textTheme,
  TpDialogTheme theme = const TpDialogTheme(),
}) =>
    theme.toDialogThemeData(colorScheme: colorScheme, textTheme: textTheme);
