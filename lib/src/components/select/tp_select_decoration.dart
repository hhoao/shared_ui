import 'package:flutter/material.dart';

import '../../theme/tp_theme.dart';

/// Themed select chrome for [TpSelect] (AppFlowy popover style).
class TpSelectDecoration {
  const TpSelectDecoration({
    required this.closedFillColor,
    required this.expandedFillColor,
    required this.closedBorder,
    required this.expandedBorder,
    required this.closedBorderRadius,
    required this.expandedBorderRadius,
    required this.expandedShadow,
    required this.headerStyle,
    required this.hintStyle,
    required this.listItemStyle,
    required this.closedSuffixIcon,
    required this.expandedSuffixIcon,
    required this.suffixIconSize,
    required this.listItemHighlightColor,
    required this.listItemSelectedColor,
    this.menuPadding = const EdgeInsets.fromLTRB(8, 12, 8, 12),
    this.menuFillColor,
    this.menuBorder,
    this.menuBorderRadius,
    this.buttonHoverColor,
    this.listItemBorderRadius,
  });

  final Color closedFillColor;
  final Color expandedFillColor;
  final BoxBorder closedBorder;
  final BoxBorder expandedBorder;
  final BorderRadius closedBorderRadius;
  final BorderRadius expandedBorderRadius;
  final List<BoxShadow> expandedShadow;
  final TextStyle? headerStyle;
  final TextStyle? hintStyle;
  final TextStyle? listItemStyle;
  final Widget closedSuffixIcon;
  final Widget expandedSuffixIcon;
  final double suffixIconSize;
  final Color listItemHighlightColor;
  final Color listItemSelectedColor;
  final EdgeInsetsGeometry menuPadding;
  final Color? menuFillColor;
  final BoxBorder? menuBorder;
  final BorderRadius? menuBorderRadius;
  final Color? buttonHoverColor;
  final BorderRadius? listItemBorderRadius;

  BoxDecoration buttonDecoration({
    required bool menuOpen,
    bool isHovering = false,
  }) {
    Color fill = menuOpen ? expandedFillColor : closedFillColor;
    if (!menuOpen && isHovering && buttonHoverColor != null) {
      fill = buttonHoverColor!;
    }
    return BoxDecoration(
      color: fill,
      border: menuOpen ? expandedBorder : closedBorder,
      borderRadius: menuOpen ? expandedBorderRadius : closedBorderRadius,
    );
  }

  BoxDecoration menuDecoration() {
    return BoxDecoration(
      color: menuFillColor ?? expandedFillColor,
      border: menuBorder ?? expandedBorder,
      borderRadius: menuBorderRadius ?? expandedBorderRadius,
      boxShadow: expandedShadow,
    );
  }
}

TextStyle tpSelectHintTextStyle(BuildContext context, {bool enabled = true}) {
  final scheme = Theme.of(context).colorScheme;
  final base = Theme.of(context).textTheme.bodyMedium ?? const TextStyle();
  final alpha = enabled ? 0.45 : 0.35;
  return base.copyWith(
    color: scheme.onSurface.withValues(alpha: alpha),
    fontWeight: FontWeight.w400,
    height: 1.25,
  );
}

TextStyle _bodyMediumWeight(BuildContext context, FontWeight? weight) {
  final base = Theme.of(context).textTheme.bodyMedium ?? const TextStyle();
  if (weight == null) return base;
  return base.copyWith(fontWeight: weight);
}

/// Themed [TpSelectDecoration] presets from [ColorScheme] + tokens.
abstract final class TpSelectDecorations {
  /// Themed select: outlined trigger, elevated menu with border/shadow.
  static TpSelectDecoration themed(
    BuildContext context, {
    Color? closedFillColor,
    Color? expandedFillColor,
    BoxBorder? closedBorder,
    BoxBorder? expandedBorder,
    double? borderRadius,
    Color? buttonHoverColor,
    Color? menuFillColor,
    BoxBorder? menuBorder,
    double? menuBorderRadius,
    List<BoxShadow>? expandedShadow,
    double expandedShadowBlurRadius = 20,
    Offset expandedShadowOffset = const Offset(0, 4),
    double expandedShadowAlphaDark = 0.48,
    double expandedShadowAlphaLight = 0.10,
    TextStyle? headerStyle,
    TextStyle? hintStyle,
    TextStyle? listItemStyle,
    FontWeight? headerFontWeight,
    FontWeight? listItemFontWeight,
    Widget? closedSuffixIcon,
    Widget? expandedSuffixIcon,
    double? suffixIconSize,
    double suffixIconOpacity = 0.55,
    double highlightAlphaDark = 0.06,
    double highlightAlphaLight = 0.04,
    double selectedPrimaryAlphaDark = 0.2,
    double? listItemBorderRadius,
    EdgeInsetsGeometry? menuPadding,
  }) {
    final selectTheme = context.tpTheme.selectTheme;
    final spacing = context.tpSpacing;
    final resolvedSuffixIconSize = suffixIconSize ?? context.tpIconSizes.md;
    final resolvedBorderRadius = borderRadius ?? selectTheme.triggerBorderRadius;
    final resolvedMenuBorderRadius =
        menuBorderRadius ?? selectTheme.menuBorderRadius;
    final resolvedListItemBorderRadius =
        listItemBorderRadius ?? selectTheme.listItemBorderRadius;
    final cs = Theme.of(context).colorScheme;
    final onSurface = cs.onSurface;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final hoverBg = isDark
        ? Colors.white.withValues(alpha: 0.07)
        : Colors.black.withValues(alpha: 0.04);

    final highlight = isDark
        ? Colors.white.withValues(alpha: highlightAlphaDark)
        : Colors.black.withValues(alpha: highlightAlphaLight);
    final selectedBg = isDark
        ? cs.primary.withValues(alpha: selectedPrimaryAlphaDark)
        : cs.primaryContainer;

    final buttonRadius = BorderRadius.circular(resolvedBorderRadius);
    final outlineVariant = cs.outlineVariant;

    return TpSelectDecoration(
      closedFillColor: closedFillColor ?? Colors.transparent,
      expandedFillColor: expandedFillColor ?? hoverBg,
      closedBorder: closedBorder ?? Border.all(color: outlineVariant, width: 1),
      expandedBorder: expandedBorder ?? Border.all(color: cs.primary, width: 1),
      closedBorderRadius: buttonRadius,
      expandedBorderRadius: buttonRadius,
      buttonHoverColor: buttonHoverColor ?? hoverBg,
      menuFillColor: menuFillColor ?? cs.surfaceContainerHigh,
      menuBorder: menuBorder ?? Border.all(color: outlineVariant),
      menuBorderRadius: BorderRadius.circular(resolvedMenuBorderRadius),
      expandedShadow:
          expandedShadow ??
          [
            BoxShadow(
              color: Colors.black.withValues(
                alpha: isDark
                    ? expandedShadowAlphaDark
                    : expandedShadowAlphaLight,
              ),
              blurRadius: expandedShadowBlurRadius,
              offset: expandedShadowOffset,
            ),
          ],
      headerStyle:
          headerStyle ?? _bodyMediumWeight(context, headerFontWeight),
      hintStyle: hintStyle ?? tpSelectHintTextStyle(context),
      listItemStyle:
          listItemStyle ?? _bodyMediumWeight(context, listItemFontWeight),
      closedSuffixIcon:
          closedSuffixIcon ??
          _suffixIcon(
            Icons.expand_more_rounded,
            onSurface,
            resolvedSuffixIconSize,
            suffixIconOpacity,
          ),
      expandedSuffixIcon:
          expandedSuffixIcon ??
          _suffixIcon(
            Icons.expand_less_rounded,
            onSurface,
            resolvedSuffixIconSize,
            suffixIconOpacity,
          ),
      suffixIconSize: resolvedSuffixIconSize,
      listItemHighlightColor: highlight,
      listItemSelectedColor: selectedBg,
      listItemBorderRadius: BorderRadius.circular(resolvedListItemBorderRadius),
      menuPadding:
          menuPadding ??
          EdgeInsets.fromLTRB(spacing.sm, spacing.md, spacing.sm, spacing.md),
    );
  }

  static Widget _suffixIcon(
    IconData icon,
    Color onSurface,
    double size,
    double opacity,
  ) {
    return Icon(
      icon,
      size: size,
      color: onSurface.withValues(alpha: opacity),
    );
  }
}
