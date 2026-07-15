import 'package:flutter/material.dart';

import '../../theme/tp_theme.dart';

/// Generic padded surface container.
class TpCard extends StatelessWidget {
  const TpCard({
    super.key,
    required this.child,
    this.padding,
    this.color,
    this.borderRadius,
    this.clipBehavior = Clip.antiAlias,
  });

  final Widget child;
  final EdgeInsetsGeometry? padding;
  final Color? color;
  final double? borderRadius;
  final Clip clipBehavior;

  @override
  Widget build(BuildContext context) {
    final tp = TpTheme.of(context);
    final scheme = Theme.of(context).colorScheme;
    final cardTheme = tp.cardTheme;
    final radius = borderRadius ?? cardTheme.borderRadius ?? tp.control.radius;
    final resolvedPadding =
        padding ?? cardTheme.padding ?? EdgeInsets.all(tp.spacing.md);
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(radius),
    );

    return Material(
      color: color ?? scheme.surfaceContainer,
      shape: shape,
      clipBehavior: clipBehavior,
      child: Padding(
        padding: resolvedPadding,
        child: child,
      ),
    );
  }
}
