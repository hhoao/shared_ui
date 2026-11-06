import 'package:flutter/material.dart';

import '../../theme/tp_theme.dart';

/// Single source of truth for the stadium radius used by every search input.
const double tpSearchPillRadius = 999;

/// Stadium-shaped search/filter decoration.
///
/// Callers keep their own [TextField], controller, and callbacks; only the
/// chrome changes. Pass [prefixIcon] to replace the default search glyph, and
/// [fillColor] when a surface needs to keep its previous fill.
InputDecoration tpSearchPillDecoration(
  BuildContext context, {
  String? hintText,
  Widget? prefixIcon,
  Widget? suffixIcon,
  Color? fillColor,
  EdgeInsetsGeometry? contentPadding,
}) {
  final theme = Theme.of(context);
  final scheme = theme.colorScheme;
  final inputTheme = theme.inputDecorationTheme;
  final tp = TpTheme.of(context);
  final metrics = tp.inputTheme;
  const radius = BorderRadius.all(Radius.circular(tpSearchPillRadius));

  OutlineInputBorder border(Color color, [double width = 1]) =>
      OutlineInputBorder(
        borderRadius: radius,
        borderSide: BorderSide(color: color, width: width),
      );

  final hintBase = theme.textTheme.bodyMedium ?? theme.textTheme.bodyLarge!;
  final hintStyle = (inputTheme.hintStyle ?? hintBase).copyWith(
    color: scheme.onSurfaceVariant.withValues(alpha: metrics.hintAlpha),
    height: 1.25,
    fontWeight: FontWeight.w400,
  );

  return InputDecoration(
    hintText: hintText,
    hintStyle: hintStyle,
    isDense: true,
    filled: true,
    fillColor: fillColor ?? scheme.surfaceContainer,
    contentPadding:
        contentPadding ??
        EdgeInsets.symmetric(
          horizontal: tp.control.input.horizontalPadding + 2,
          vertical: tp.control.input.verticalPadding,
        ),
    prefixIcon:
        prefixIcon ??
        Icon(
          Icons.search_rounded,
          size: context.tpIconSizes.md,
          color: scheme.onSurfaceVariant,
        ),
    prefixIconConstraints: const BoxConstraints(minWidth: 34, minHeight: 34),
    suffixIcon: suffixIcon,
    floatingLabelBehavior: FloatingLabelBehavior.never,
    border: border(scheme.outlineVariant),
    enabledBorder: border(scheme.outlineVariant.withValues(alpha: 0.7)),
    focusedBorder: border(scheme.primary, metrics.focusedBorderWidth),
  );
}
