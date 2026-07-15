import 'package:flutter/material.dart';
import 'package:toggle_switch/toggle_switch.dart';

import '../../theme/tp_theme.dart';

/// Default icon size for [TpSegmentedControl] — resolved from theme in [build].
const tpSegmentedControlMinHeight = 38.0;

/// Default corner radius for [TpSegmentedControl].
const tpSegmentedControlCornerRadius = 30.0;

/// Horizontal padding inside each [ToggleSwitch] segment (see package default).
const _segmentHorizontalPadding = 20.0;

/// Gap between icon and label inside each segment.
const _segmentIconTextGap = 5.0;

/// Extra width so labels are not clipped at the ellipsis edge.
const _segmentWidthSlack = 4.0;

/// Per-segment widths from [labels], [fontSize], and optional [icons].
///
/// Matches [toggle_switch] segment layout: horizontal padding, optional icon
/// + gap, then label. Used when [TpSegmentedControl.customWidths] is omitted so
/// controls stay readable at larger typography scales.
List<double> computeTpSegmentedControlWidths({
  required List<String> labels,
  required double fontSize,
  required double iconSize,
  required TextStyle textStyle,
  List<IconData?>? icons,
  double minSegmentWidth = 100,
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
/// Uses [toggle_switch]; this is **not** a binary on/off switch.
class TpSegmentedControl extends StatelessWidget {
  const TpSegmentedControl({
    super.key,
    required this.totalSwitches,
    required this.initialLabelIndex,
    required this.labels,
    required this.onToggle,
    this.icons,
    this.minWidth,
    this.customWidths,
    this.minHeight = tpSegmentedControlMinHeight,
    this.cornerRadius = tpSegmentedControlCornerRadius,
  });

  final int totalSwitches;
  final int initialLabelIndex;
  final List<String> labels;
  final List<IconData?>? icons;
  final OnToggle? onToggle;
  final double? minWidth;
  final List<double>? customWidths;
  final double minHeight;
  final double cornerRadius;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final theme = Theme.of(context);
    final tp = context.tpTheme;
    final textStyle =
        theme.textTheme.bodyMedium ??
        TextStyle(fontSize: tp.typography.bodySize);
    final textBase = cs.onSurface;
    final inactiveFg = textBase.withValues(alpha: 0.72);
    final n = totalSwitches;
    final resolvedMinWidth = minWidth ?? (n == 2 ? 112.0 : 100.0);
    final fontSize = textStyle.fontSize ?? tp.typography.bodySize;
    final iconSize = context.tpIconSizes.md;
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

    return ToggleSwitch(
      totalSwitches: n,
      initialLabelIndex: initialLabelIndex,
      labels: labels,
      icons: icons,
      cornerRadius: cornerRadius,
      radiusStyle: true,
      minHeight: minHeight,
      minWidth: resolvedMinWidth,
      customWidths: resolvedCustomWidths,
      fontSize: fontSize,
      iconSize: iconSize,
      activeFgColor: cs.onPrimary,
      inactiveFgColor: inactiveFg,
      inactiveBgColor: cs.surfaceContainerHighest,
      dividerColor: Colors.transparent,
      dividerMargin: 0,
      activeBgColors: List.generate(n, (_) => <Color>[cs.primary]),
      animate: false,
      onToggle: onToggle,
    );
  }
}
