import 'package:flutter/material.dart';

import '../../theme/tp_theme.dart';

/// Thin divider along [axis] using [ColorScheme.outlineVariant].
class TpSeparator extends StatelessWidget {
  const TpSeparator({
    super.key,
    this.axis = Axis.horizontal,
    this.thickness,
    this.color,
    this.indent = 0,
    this.endIndent = 0,
  });

  final Axis axis;
  final double? thickness;
  final Color? color;
  final double indent;
  final double endIndent;

  @override
  Widget build(BuildContext context) {
    final tp = TpTheme.of(context);
    final scheme = Theme.of(context).colorScheme;
    final sepTheme = tp.separatorTheme;
    final resolvedThickness = thickness ?? sepTheme.thickness;
    final resolvedColor =
        color ??
        scheme.outlineVariant.withValues(alpha: sepTheme.outlineAlpha);

    if (axis == Axis.horizontal) {
      return SizedBox(
        width: double.infinity,
        height: resolvedThickness,
        child: Padding(
          padding: EdgeInsetsDirectional.only(start: indent, end: endIndent),
          child: ColoredBox(color: resolvedColor),
        ),
      );
    }

    return SizedBox(
      height: double.infinity,
      width: resolvedThickness,
      child: Padding(
        padding: EdgeInsets.only(top: indent, bottom: endIndent),
        child: ColoredBox(color: resolvedColor),
      ),
    );
  }
}
