import 'package:flutter/material.dart';

import '../../theme/tp_theme.dart';

/// Compact pill height for preference-row segmented controls.
const tpSegmentedControlMinHeight = 32.0;

/// Default corner radius for [TpSegmentedControl].
const tpSegmentedControlCornerRadius = 30.0;

/// Content-driven floor for short labels.
const tpSegmentedControlMinSegmentWidth = 72.0;

/// Horizontal padding inside each segment (10 per side).
const _segmentHorizontalPadding = 20.0;

/// Icon → label gap.
const _segmentIconTextGap = 5.0;

/// Extra width so CJK / custom UI fonts are not ellipsized at the edge.
const _segmentWidthSlack = 12.0;

/// Called with the tapped segment index.
typedef OnToggle = void Function(int? index);

/// Per-segment widths from [labels], [fontSize], and optional [icons].
List<double> computeTpSegmentedControlWidths({
  required List<String> labels,
  required double fontSize,
  required double iconSize,
  required TextStyle textStyle,
  List<IconData?>? icons,
  double minSegmentWidth = tpSegmentedControlMinSegmentWidth,
}) {
  final iconList = icons;
  final hasIcons = iconList != null && iconList.isNotEmpty;
  return List.generate(labels.length, (i) {
    final label = labels[i];
    final hasIcon = hasIcons && i < iconList.length && iconList[i] != null;
    final painter = TextPainter(
      text: TextSpan(text: label, style: textStyle),
      textDirection: TextDirection.ltr,
      maxLines: 1,
    )..layout();
    final iconPart = hasIcon ? iconSize + _segmentIconTextGap : 0.0;
    final width =
        _segmentHorizontalPadding +
        iconPart +
        painter.width +
        _segmentWidthSlack;
    return width < minSegmentWidth ? minSegmentWidth : width.ceilToDouble();
  });
}

/// Pill multi-segment control styled from [ColorScheme] + [TpTheme] tokens.
///
/// This is **not** a binary on/off switch.
///
/// Lays out at the full content width ([customWidths] sum) so [Flexible]
/// segments cannot shrink labels into ellipsis. Narrow parents should scroll
/// (see [TpSegmentedPicker]), same idea as theme-color chips — not
/// [FittedBox] scale-down.
class TpSegmentedControl extends StatefulWidget {
  const TpSegmentedControl({
    super.key,
    required this.totalSwitches,
    required this.initialLabelIndex,
    required this.labels,
    required this.onToggle,
    this.icons,
    this.minWidth,
    this.customWidths,
    this.minHeight,
    this.cornerRadius = tpSegmentedControlCornerRadius,
  });

  final int totalSwitches;
  final int initialLabelIndex;
  final List<String> labels;
  final List<IconData?>? icons;
  final OnToggle? onToggle;
  final double? minWidth;
  final List<double>? customWidths;

  /// Track height. Defaults to [tpSegmentedControlMinHeight].
  final double? minHeight;
  final double cornerRadius;

  @override
  State<TpSegmentedControl> createState() => _TpSegmentedControlState();
}

class _TpSegmentedControlState extends State<TpSegmentedControl> {
  late int _selectedIndex = widget.initialLabelIndex;

  @override
  void didUpdateWidget(covariant TpSegmentedControl oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialLabelIndex != widget.initialLabelIndex) {
      _selectedIndex = widget.initialLabelIndex;
    }
  }

  void _handleTap(int index) {
    if (_selectedIndex != index) {
      setState(() => _selectedIndex = index);
    }
    widget.onToggle?.call(index);
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final theme = Theme.of(context);
    final tp = context.tpTheme;
    final baseStyle =
        theme.textTheme.labelLarge ??
        theme.textTheme.bodyMedium ??
        TextStyle(fontSize: tp.typography.bodySize);
    // No color here: TextStyle.copyWith cannot clear an inherited color, so
    // segment foregrounds are applied per selection state below.
    final textStyle = TextStyle(
      fontSize: baseStyle.fontSize ?? tp.typography.bodySize,
      fontFamily: baseStyle.fontFamily,
      fontFamilyFallback: baseStyle.fontFamilyFallback,
      fontWeight: baseStyle.fontWeight,
      letterSpacing: baseStyle.letterSpacing,
      height: 1.0,
    );
    final inactiveFg = cs.onSurface.withValues(alpha: 0.72);
    // Always white on the primary pill — Material onPrimary is black for some
    // mid-light seeds (amber/forest).
    const activeFg = Colors.white;
    final n = widget.totalSwitches;
    final resolvedMinHeight = widget.minHeight ?? tpSegmentedControlMinHeight;
    final resolvedMinWidth = widget.minWidth ?? tpSegmentedControlMinSegmentWidth;
    final fontSize = textStyle.fontSize ?? tp.typography.bodySize;
    final iconSize = context.tpIconSizes.sm;
    final resolvedCustomWidths =
        widget.customWidths ??
        computeTpSegmentedControlWidths(
          labels: widget.labels,
          fontSize: fontSize,
          iconSize: iconSize,
          icons: widget.icons,
          minSegmentWidth: resolvedMinWidth,
          textStyle: textStyle,
        );
    final totalWidth = resolvedCustomWidths.fold<double>(0, (a, b) => a + b);

    return SizedBox(
      width: totalWidth,
      height: resolvedMinHeight,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: cs.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(widget.cornerRadius),
        ),
        child: Row(
          children: List.generate(
            n,
            (index) => _buildSegment(
              index: index,
              width: resolvedCustomWidths[index],
              height: resolvedMinHeight,
              active: index == _selectedIndex,
              activeBg: cs.primary,
              activeFg: activeFg,
              inactiveFg: inactiveFg,
              textStyle: textStyle,
              iconSize: iconSize,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSegment({
    required int index,
    required double width,
    required double height,
    required bool active,
    required Color activeBg,
    required Color activeFg,
    required Color inactiveFg,
    required TextStyle textStyle,
    required double iconSize,
  }) {
    final fgColor = active ? activeFg : inactiveFg;
    final icon = index < (widget.icons?.length ?? 0) ? widget.icons![index] : null;
    final label = index < widget.labels.length ? widget.labels[index] : '';
    final effectiveIconSize = iconSize > width / 3 ? width / 3 : iconSize;

    return SizedBox(
      width: width,
      height: height,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => _handleTap(index),
        child: Container(
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: active
              ? BoxDecoration(
                  color: activeBg,
                  borderRadius: BorderRadius.circular(widget.cornerRadius),
                )
              : null,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (icon != null)
                Icon(icon, color: fgColor, size: effectiveIconSize),
              Flexible(
                child: Container(
                  padding: EdgeInsets.only(
                    left: icon != null ? _segmentIconTextGap : 0,
                  ),
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: textStyle.copyWith(color: fgColor),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}