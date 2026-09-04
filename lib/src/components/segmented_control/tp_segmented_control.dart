import 'package:flutter/material.dart';

import '../../theme/tp_theme.dart';
import '../hover/tp_hover.dart';

/// Compact pill height for preference-row segmented controls.
const tpSegmentedControlMinHeight = 32.0;

/// Default corner radius for filled (pill) [TpSegmentedControl].
const tpSegmentedControlCornerRadius = 30.0;

/// Content-driven floor for short labels.
const tpSegmentedControlMinSegmentWidth = 72.0;

/// Content-driven floor for outlined compact segments.
const tpSegmentedControlOutlinedMinSegmentWidth = 56.0;

/// Segment horizontal padding (10 px per side).
const _segmentHorizontalPadding = 20.0;

/// Icon → label gap.
const _segmentIconTextGap = 5.0;

/// Extra width so CJK / custom UI fonts are not ellipsized at the edge.
const _segmentWidthSlack = 12.0;

/// Hairline width between outlined segments.
const _outlinedDividerWidth = 1.0;

typedef TpSegmentedOnToggle = void Function(int? index);

/// Visual style for [TpSegmentedControl].
enum TpSegmentedControlVariant {
  /// Filled track; selected segment uses a solid primary chip (default pill).
  filled,

  /// Bordered track with hairline vertical dividers; selected segment uses a soft tint.
  outlined,
}

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

/// Multi-segment control styled from [ColorScheme] + [TpTheme] tokens.
///
/// This is **not** a binary on/off switch. Each segment is a [TpHover] target
/// (hover tint + hand cursor) with optional per-segment [tooltips].
///
/// [TpSegmentedControlVariant.filled] is the preference-row pill. Use
/// [TpSegmentedControlVariant.outlined] for a bordered control with plain
/// vertical dividers and a non-stadium [cornerRadius].
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
    this.cornerRadius,
    this.variant = TpSegmentedControlVariant.filled,
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

  /// Outer corner radius. Defaults to a stadium pill for [filled], or the
  /// theme control radius for [outlined].
  final double? cornerRadius;

  /// Filled pill vs bordered + vertical dividers.
  final TpSegmentedControlVariant variant;

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
    final outlined = variant == TpSegmentedControlVariant.outlined;
    // Filled: always white on the primary chip — Material onPrimary is black
    // for some mid-light seeds (amber/forest). Outlined: tinted primary text.
    final activeFg = outlined ? cs.primary : Colors.white;
    final activeBg = outlined
        ? cs.primary.withValues(alpha: 0.12)
        : cs.primary;
    final trackColor = outlined ? cs.surface : cs.surfaceContainerHighest;
    final resolvedMinHeight = minHeight ?? tpSegmentedControlMinHeight;
    final resolvedCornerRadius =
        cornerRadius ??
        (outlined ? tp.control.radius : tpSegmentedControlCornerRadius);
    final resolvedMinWidth =
        minWidth ??
        (outlined
            ? tpSegmentedControlOutlinedMinSegmentWidth
            : tpSegmentedControlMinSegmentWidth);
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
    final dividerCount = outlined ? (labels.length - 1).clamp(0, labels.length) : 0;
    final totalWidth =
        resolvedCustomWidths.fold<double>(0, (a, b) => a + b) +
        dividerCount * _outlinedDividerWidth;

    return SizedBox(
      width: totalWidth,
      child: _TpSegmentedControlTrack(
        selectedIndex: initialLabelIndex,
        labels: labels,
        icons: icons,
        tooltips: tooltips,
        segmentWidths: resolvedCustomWidths,
        minHeight: resolvedMinHeight,
        cornerRadius: resolvedCornerRadius,
        variant: variant,
        activeFgColor: activeFg,
        inactiveFgColor: inactiveFg,
        trackColor: trackColor,
        activeBgColor: activeBg,
        borderColor: cs.outlineVariant,
        dividerColor: cs.outlineVariant,
        textStyle: textStyle,
        iconSize: iconSize,
        onSelected: onToggle,
      ),
    );
  }
}

class _TpSegmentedControlTrack extends StatefulWidget {
  const _TpSegmentedControlTrack({
    super.key,
    required this.selectedIndex,
    required this.labels,
    required this.icons,
    required this.tooltips,
    required this.segmentWidths,
    required this.minHeight,
    required this.cornerRadius,
    required this.variant,
    required this.activeFgColor,
    required this.inactiveFgColor,
    required this.trackColor,
    required this.activeBgColor,
    required this.borderColor,
    required this.dividerColor,
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
  final TpSegmentedControlVariant variant;
  final Color activeFgColor;
  final Color inactiveFgColor;
  final Color trackColor;
  final Color activeBgColor;
  final Color borderColor;
  final Color dividerColor;
  final TextStyle textStyle;
  final double iconSize;
  final TpSegmentedOnToggle? onSelected;

  @override
  State<_TpSegmentedControlTrack> createState() =>
      _TpSegmentedControlTrackState();
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

  bool get _outlined => widget.variant == TpSegmentedControlVariant.outlined;

  @override
  Widget build(BuildContext context) {
    final icons = widget.icons;
    final radius = BorderRadius.circular(widget.cornerRadius);
    final children = <Widget>[];
    for (var i = 0; i < widget.labels.length; i++) {
      if (_outlined && i > 0) {
        children.add(
          VerticalDivider(
            width: _outlinedDividerWidth,
            thickness: _outlinedDividerWidth,
            color: widget.dividerColor,
          ),
        );
      }
      children.add(
        _buildSegment(
          index: i,
          label: widget.labels[i],
          icon: icons != null && i < icons.length ? icons[i] : null,
          width: widget.segmentWidths[i],
        ),
      );
    }

    return DecoratedBox(
      key: const ValueKey('tp-segmented-control-track'),
      decoration: BoxDecoration(
        color: widget.trackColor,
        borderRadius: radius,
        border: _outlined
            ? Border.all(color: widget.borderColor)
            : null,
      ),
      child: ClipRRect(
        borderRadius: radius,
        child: SizedBox(
          height: widget.minHeight,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: children,
          ),
        ),
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
    final radius = BorderRadius.circular(widget.cornerRadius);
    // Filled keeps stadium when the radius is large enough to read as a pill;
    // outlined (and smaller radii) use rounded so corners follow [cornerRadius].
    final shape = (!_outlined && widget.cornerRadius >= widget.minHeight / 2)
        ? TpPressableShape.stadium
        : TpPressableShape.rounded;

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
      shape: shape,
      borderRadius: radius,
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
