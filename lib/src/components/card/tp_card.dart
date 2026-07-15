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
    this.outlined = false,
    this.borderAlpha = 0.5,
  });

  /// Bordered clip panel with no fill — preference / settings shells.
  const TpCard.outlined({
    super.key,
    required this.child,
    this.padding = EdgeInsets.zero,
    this.borderRadius = 14,
    this.clipBehavior = Clip.antiAlias,
    this.borderAlpha = 0.5,
  }) : color = Colors.transparent,
       outlined = true;

  final Widget child;
  final EdgeInsetsGeometry? padding;
  final Color? color;
  final double? borderRadius;
  final Clip clipBehavior;

  /// When true, draws an [outlineVariant] border (see [TpCard.outlined]).
  final bool outlined;
  final double borderAlpha;

  @override
  Widget build(BuildContext context) {
    final tp = TpTheme.of(context);
    final scheme = Theme.of(context).colorScheme;
    final cardTheme = tp.cardTheme;
    final radius = borderRadius ?? cardTheme.borderRadius ?? tp.control.radius;
    final resolvedPadding = outlined
        ? (padding ?? EdgeInsets.zero)
        : (padding ?? cardTheme.padding ?? EdgeInsets.all(tp.spacing.md));
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(radius),
      side: outlined
          ? BorderSide(
              color: scheme.outlineVariant.withValues(alpha: borderAlpha),
            )
          : BorderSide.none,
    );

    return Material(
      color: color ?? (outlined ? Colors.transparent : scheme.surfaceContainer),
      shape: shape,
      clipBehavior: clipBehavior,
      child: Padding(
        padding: resolvedPadding,
        child: child,
      ),
    );
  }
}
