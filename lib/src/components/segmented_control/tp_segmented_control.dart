import 'package:flutter/material.dart';

import '../../theme/tp_theme.dart';
import '../hover/tp_hover.dart';

/// Compact pill height for preference-row segmented controls.
const tpSegmentedControlMinHeight = 32.0;

/// Default corner radius for [TpSegmentedControl].
const tpSegmentedControlCornerRadius = 30.0;

/// Content-driven floor for short labels.
const tpSegmentedControlMinSegmentWidth = 72.0;

/// Segment horizontal padding (10 px per side).
const _segmentHorizontalPadding = 20.0;

/// Icon → label gap.
const _segmentIconTextGap = 5.0;

/// Extra width so CJK / custom UI fonts are not ellipsized at the edge.
const _segmentWidthSlack = 12.0;

typedef TpSegmentedOnToggle = void Function(int? index);

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
/// This is **not** a binary on/off switch. Each segment is a [TpHover] target
/// (hover tint + hand cursor) with optional per-segment [tooltips].
///
/// Lays out at the full content width ([customWidths] sum). Narrow parents
/// should scroll (see [TpSegmentedPicker]), same idea as theme-color chips —
/// not [FittedBox] scale-down.
class TpSegmentedControl extends StatelessWidget {
  const TpSegmentedControl({
    super.key,
    required this.totalSwitches,
    required this.initialLabelIndex,
    required this.labels,
    required this.onToggle,
    this.icons,
    this.tooltips,
    this.minWidth,
    this.customWidths,
    this.minHeight,
    this.cornerRadius = tpSegmentedControlCornerRadius,
  });

  final int totalSwitches;
  final int initialLabelIndex;
  final List<String> labels;
  final List<IconData?>? icons;

  /// Optional per-segment tooltip (same length as [labels] when set).
  final List<String>? tooltips;
  final TpSegmentedOnToggle? onToggle;
  final double? minWidth;
  final List<double>? customWidths;

  /// Track height. Defaults to [tpSegmentedControlMinHeight].
  final double? minHeight;
  final double cornerRadius;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final theme = Theme.of(context);
    final tp = context.tpTheme;
    final baseStyle =
        theme.textTheme.labelLarge ??
        theme.textTheme.bodyMedium ??
        TextStyle(fontSize: tp.typography.bodySize);
    final textStyle = TextStyle(
      fontSize: baseStyle.fontSize ?? tp.typography.bodySize,
      fontFamily: baseStyle.fontFamily,
      fontFamilyFallback: baseStyle.fontFamilyFallback,
      fontWeight: baseStyle.fontWeight,
      letterSpacing: baseStyle.letterSpacing,
      height: 1.0,
    );
    final textBase = cs.onSurface;
    final inactiveFg = textBase.withValues(alpha: 0.72);
    // Always white on the primary pill — Material onPrimary is black for some
    // mid-light seeds (amber/forest).
    const activeFg = Colors.white;
    final n = totalSwitches;
    final resolvedMinHeight = minHeight ?? tpSegmentedControlMinHeight;
    final resolvedMinWidth = minWidth ?? tpSegmentedControlMinSegmentWidth;
    final fontSize = textStyle.fontSize ?? tp.typography.bodySize;
    final iconSize = context.tpIconSizes.sm;
    final resolvedCustomWidths =
        customWidths ??
        computeTpSegmentedControlWidths(
          labels: labels,
          fontSize: fontSize,
          iconSize: iconSize,
          icons: icons,
          minSegmentWidth: resolvedMinWidth,
          textStyle: textStyle,
        );
    final totalWidth = resolvedCustomWidths.fold<double>(0, (a, b) => a + b);

    return SizedBox(
      width: totalWidth,
      child: _TpSegmentedControlTrack(
        selectedIndex: initialLabelIndex,
        labels: labels,
        icons: icons,
        tooltips: tooltips,
        segmentWidths: resolvedCustomWidths,
        minHeight: resolvedMinHeight,
        cornerRadius: cornerRadius,
        activeFgColor: activeFg,
        inactiveFgColor: inactiveFg,
        trackColor: cs.surfaceContainerHighest,
        activeBgColor: cs.primary,
        textStyle: textStyle,
        iconSize: iconSize,
        onSelected: onToggle,
      ),
    );
  }
}

class _TpSegmentedControlTrack extends StatefulWidget {
  const _TpSegmentedControlTrack({
    required this.selectedIndex,
    required this.labels,
    required this.icons,
    required this.tooltips,
    required this.segmentWidths,
    required this.minHeight,
    required this.cornerRadius,
    required this.activeFgColor,
    required this.inactiveFgColor,
    required this.trackColor,
    required this.activeBgColor,
    required this.textStyle,
    required this.iconSize,
    required this.onSelected,
  });

  final int selectedIndex;
  final List<String> labels;
  final List<IconData?>? icons;
  final List<String>? tooltips;
  final List<double> segmentWidths;
  final double minHeight;
  final double cornerRadius;
  final Color activeFgColor;
  final Color inactiveFgColor;
  final Color trackColor;
  final Color activeBgColor;
  final TextStyle textStyle;
  final double iconSize;
  final TpSegmentedOnToggle? onSelected;

  @override
  State<_TpSegmentedControlTrack> createState() => _TpSegmentedControlTrackState();
}

class _TpSegmentedControlTrackState extends State<_TpSegmentedControlTrack> {
  late int _selectedIndex;

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.selectedIndex;
  }

  @override
  void didUpdateWidget(covariant _TpSegmentedControlTrack oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.selectedIndex != oldWidget.selectedIndex) {
      _selectedIndex = widget.selectedIndex;
    }
  }

  void _handleTap(int index) {
    setState(() => _selectedIndex = index);
    widget.onSelected?.call(index);
  }

  @override
  Widget build(BuildContext context) {
    final icons = widget.icons;
    return Container(
      height: widget.minHeight,
      decoration: BoxDecoration(
        color: widget.trackColor,
        borderRadius: BorderRadius.circular(widget.cornerRadius),
      ),
      clipBehavior: Clip.antiAlias,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < widget.labels.length; i++)
            _buildSegment(
              index: i,
              label: widget.labels[i],
              icon: icons != null && i < icons.length ? icons[i] : null,
              width: widget.segmentWidths[i],
            ),
        ],
      ),
    );
  }

  Widget _buildSegment({
    required int index,
    required String label,
    required IconData? icon,
    required double width,
  }) {
    final active = _selectedIndex == index;
    final fgColor = active ? widget.activeFgColor : widget.inactiveFgColor;
    final tooltip = widget.tooltips != null && index < widget.tooltips!.length
        ? widget.tooltips![index]
        : null;

    Widget content = Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (icon != null) Icon(icon, size: widget.iconSize, color: fgColor),
        if (label.isNotEmpty) ...[
          if (icon != null) const SizedBox(width: _segmentIconTextGap),
          Text(label, style: widget.textStyle.copyWith(color: fgColor)),
        ],
      ],
    );

    Widget segment = TpHover(
      width: width,
      height: widget.minHeight,
      shape: TpPressableShape.stadium,
      borderRadius: BorderRadius.circular(widget.cornerRadius),
      backgroundColor: active ? widget.activeBgColor : Colors.transparent,
      onTap: () => _handleTap(index),
      child: Center(
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: content,
        ),
      ),
    );

    if (tooltip != null && tooltip.isNotEmpty) {
      segment = Tooltip(message: tooltip, child: segment);
    }

    return segment;
  }
}
