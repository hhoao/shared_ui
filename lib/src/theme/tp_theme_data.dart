import 'package:flutter/material.dart';

import 'components/tp_dialog_theme.dart';
import 'components/tp_input_theme.dart';
import 'components/tp_textarea_theme.dart';
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
    this.dialog,
    this.input,
    this.textarea,
  });

  factory TpThemeData.fromColorScheme(
    ColorScheme scheme, {
    required double scale,
    TpDialogTheme? dialog,
    TpInputTheme? input,
    TpTextareaTheme? textarea,
  }) => TpThemeData(
    colorScheme: scheme,
    spacing: TpSpacing.fromScale(scale),
    iconSizes: TpIconSizes.fromScale(scale),
    typography: TpTypography(scale: scale),
    control: TpControlMetrics.fromScale(scale),
    dialog: dialog,
    input: input,
    textarea: textarea,
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

  /// Optional dialog metrics override; resolved via [dialogTheme].
  final TpDialogTheme? dialog;

  /// Optional outline-input metrics override; resolved via [inputTheme].
  final TpInputTheme? input;

  /// Optional textarea metrics override; resolved via [textareaTheme].
  final TpTextareaTheme? textarea;

  /// Resolved dialog theme (defaults when [dialog] is null).
  TpDialogTheme get dialogTheme => dialog ?? TpDialogTheme.defaults();

  /// Resolved input theme (defaults when [input] is null).
  TpInputTheme get inputTheme => input ?? TpInputTheme.defaults();

  /// Resolved textarea theme (defaults when [textarea] is null).
  TpTextareaTheme get textareaTheme => textarea ?? TpTextareaTheme.defaults();

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TpThemeData &&
          colorScheme == other.colorScheme &&
          spacing == other.spacing &&
          iconSizes == other.iconSizes &&
          typography == other.typography &&
          control == other.control &&
          dialogTheme == other.dialogTheme &&
          inputTheme == other.inputTheme &&
          textareaTheme == other.textareaTheme;

  @override
  int get hashCode => Object.hash(
    colorScheme,
    spacing,
    iconSizes,
    typography,
    control,
    dialogTheme,
    inputTheme,
    textareaTheme,
  );
}
