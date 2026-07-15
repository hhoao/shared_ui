import 'package:flutter/material.dart';

import '../tokens/tp_control_metrics.dart';
import '../tokens/tp_typography.dart';

/// Fills null [TextStyle.fontSize] from [TpTypography]; keeps explicit sizes.
TextStyle tpWithResolvedFontSize(
  TextStyle style, {
  TextStyle? sizeFrom,
  double? fallback,
  TpTypography typography = const TpTypography(scale: 1.0),
}) {
  final resolvedFallback = fallback ?? typography.bodySize;
  final size = style.fontSize ?? sizeFrom?.fontSize ?? resolvedFallback;
  return style.copyWith(
    fontSize: size,
    inherit: false,
    textBaseline:
        style.textBaseline ?? sizeFrom?.textBaseline ?? TextBaseline.alphabetic,
  );
}

/// Remap M3 [TextTheme.bodyLarge] (typed TextField text) to [bodyMedium].
TextTheme applyTpInputTextStyles(
  TextTheme textTheme, {
  TextStyle? inputTextStyle,
}) {
  final inputText =
      inputTextStyle ??
      textTheme.bodyMedium ??
      textTheme.bodySmall ??
      textTheme.bodyLarge!;
  return textTheme.copyWith(bodyLarge: inputText.copyWith(height: 1.25));
}

/// Typed text style for a [TextField] when a widget needs an explicit style.
TextStyle tpTextFieldStyle(TextTheme textTheme) {
  return textTheme.bodyLarge ?? textTheme.bodyMedium ?? const TextStyle();
}

/// Outline input decoration metrics and Material [InputDecorationThemeData] builder.
@immutable
class TpInputTheme {
  const TpInputTheme({
    this.hintAlpha = 0.72,
    this.labelAlpha = 0.9,
    this.focusedBorderWidth = 1.5,
    this.disabledBorderAlpha = 0.38,
  });

  factory TpInputTheme.defaults() => const TpInputTheme();

  final double hintAlpha;
  final double labelAlpha;
  final double focusedBorderWidth;
  final double disabledBorderAlpha;

  /// Builds Material [InputDecorationThemeData] for app-level theme assembly.
  InputDecorationThemeData toInputDecorationTheme({
    required ColorScheme colorScheme,
    required TextTheme textTheme,
    required TpControlMetrics control,
    double? borderRadius,
  }) {
    final outline = colorScheme.outlineVariant;
    final radius = BorderRadius.circular(borderRadius ?? control.radius);

    OutlineInputBorder outlineBorder(Color color, [double width = 1]) =>
        OutlineInputBorder(
          borderRadius: radius,
          borderSide: BorderSide(color: color, width: width),
        );

    final hintColor = colorScheme.onSurfaceVariant.withValues(alpha: hintAlpha);
    final labelColor =
        colorScheme.onSurfaceVariant.withValues(alpha: labelAlpha);
    final hintBase = textTheme.bodyMedium ?? textTheme.bodyLarge!;
    final hintStyle = tpWithResolvedFontSize(
      hintBase.copyWith(
        color: hintColor,
        height: 1.25,
        fontWeight: FontWeight.w400,
      ),
      sizeFrom: textTheme.bodySmall ?? textTheme.bodyMedium,
      fallback: const TpTypography(scale: 1.0).labelSize,
    );

    return InputDecorationThemeData(
      filled: true,
      fillColor: colorScheme.surfaceContainer,
      isDense: true,
      visualDensity: VisualDensity.compact,
      contentPadding: EdgeInsets.symmetric(
        horizontal: control.input.horizontalPadding,
        vertical: control.input.verticalPadding,
      ),
      constraints: BoxConstraints.tightFor(height: control.input.height),
      hintStyle: hintStyle,
      labelStyle: textTheme.bodyMedium?.copyWith(color: labelColor),
      floatingLabelStyle: textTheme.bodyMedium?.copyWith(
        color: colorScheme.primary,
      ),
      border: outlineBorder(outline),
      enabledBorder: outlineBorder(outline),
      focusedBorder: outlineBorder(colorScheme.primary, focusedBorderWidth),
      errorBorder: outlineBorder(colorScheme.error),
      focusedErrorBorder:
          outlineBorder(colorScheme.error, focusedBorderWidth),
      disabledBorder:
          outlineBorder(outline.withValues(alpha: disabledBorderAlpha)),
      floatingLabelBehavior: FloatingLabelBehavior.auto,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TpInputTheme &&
          hintAlpha == other.hintAlpha &&
          labelAlpha == other.labelAlpha &&
          focusedBorderWidth == other.focusedBorderWidth &&
          disabledBorderAlpha == other.disabledBorderAlpha;

  @override
  int get hashCode => Object.hash(
    hintAlpha,
    labelAlpha,
    focusedBorderWidth,
    disabledBorderAlpha,
  );
}

/// Convenience builder matching the former `buildAppOutlineInputDecorationTheme`.
InputDecorationThemeData buildTpOutlineInputDecorationTheme({
  required ColorScheme colorScheme,
  required TextTheme textTheme,
  required TpControlMetrics control,
  double? borderRadius,
  TpInputTheme theme = const TpInputTheme(),
}) =>
    theme.toInputDecorationTheme(
      colorScheme: colorScheme,
      textTheme: textTheme,
      control: control,
      borderRadius: borderRadius,
    );
