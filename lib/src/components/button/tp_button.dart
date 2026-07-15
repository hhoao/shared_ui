import 'package:flutter/material.dart';

import '../../theme/tokens/tp_control_metrics.dart';
import '../../theme/tp_theme.dart';

/// Visual style for [TpButton].
enum TpButtonVariant {
  primary,
  secondary,
  outline,
  ghost,
  destructive,
}

/// Design-system button with [TpButtonVariant] colors and [TpControlSize]
/// geometry from [TpControlMetrics].
class TpButton extends StatelessWidget {
  const TpButton({
    super.key,
    required this.child,
    this.onPressed,
    this.variant = TpButtonVariant.primary,
    this.size,
    this.focusNode,
    this.autofocus = false,
    this.clipBehavior = Clip.none,
  });

  final Widget child;
  final VoidCallback? onPressed;
  final TpButtonVariant variant;
  final TpControlSize? size;
  final FocusNode? focusNode;
  final bool autofocus;
  final Clip clipBehavior;

  @override
  Widget build(BuildContext context) {
    final tp = TpTheme.of(context);
    final scheme = Theme.of(context).colorScheme;
    final control = tp.control;
    final buttonTheme = tp.buttonTheme;
    final resolvedSize = size ?? buttonTheme.defaultSize;
    final metrics = control.metricsFor(resolvedSize);
    final style = _styleFor(
      variant: variant,
      scheme: scheme,
      metrics: metrics,
      radius: control.radius,
    );

    return TextButton(
      onPressed: onPressed,
      focusNode: focusNode,
      autofocus: autofocus,
      clipBehavior: clipBehavior,
      style: style,
      child: child,
    );
  }

  static ButtonStyle _styleFor({
    required TpButtonVariant variant,
    required ColorScheme scheme,
    required TpControlSizeMetrics metrics,
    required double radius,
  }) {
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(radius),
    );
    final geometry = ButtonStyle(
      minimumSize: WidgetStatePropertyAll(
        Size(metrics.minWidth, metrics.height),
      ),
      maximumSize: WidgetStatePropertyAll(
        Size(double.infinity, metrics.height),
      ),
      padding: WidgetStatePropertyAll(
        EdgeInsets.symmetric(horizontal: metrics.horizontalPadding),
      ),
      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      visualDensity: VisualDensity.standard,
      shape: WidgetStatePropertyAll(shape),
    );

    final colors = switch (variant) {
      TpButtonVariant.primary => (
        bg: scheme.primary,
        fg: scheme.onPrimary,
        border: null as Color?,
      ),
      TpButtonVariant.secondary => (
        bg: scheme.secondaryContainer,
        fg: scheme.onSecondaryContainer,
        border: null as Color?,
      ),
      TpButtonVariant.outline => (
        bg: Colors.transparent,
        fg: scheme.onSurface,
        border: scheme.outlineVariant,
      ),
      TpButtonVariant.ghost => (
        bg: Colors.transparent,
        fg: scheme.onSurface,
        border: null as Color?,
      ),
      TpButtonVariant.destructive => (
        bg: scheme.error,
        fg: scheme.onError,
        border: null as Color?,
      ),
    };

    return geometry.copyWith(
      backgroundColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.disabled)) {
          return scheme.onSurface.withValues(alpha: 0.12);
        }
        if (variant == TpButtonVariant.ghost ||
            variant == TpButtonVariant.outline) {
          if (states.contains(WidgetState.hovered) ||
              states.contains(WidgetState.pressed)) {
            return scheme.onSurface.withValues(alpha: 0.08);
          }
          return colors.bg;
        }
        if (states.contains(WidgetState.hovered) ||
            states.contains(WidgetState.pressed)) {
          return Color.alphaBlend(
            scheme.onSurface.withValues(alpha: 0.08),
            colors.bg,
          );
        }
        return colors.bg;
      }),
      foregroundColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.disabled)) {
          return scheme.onSurface.withValues(alpha: 0.38);
        }
        return colors.fg;
      }),
      overlayColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.pressed)) {
          return colors.fg.withValues(alpha: 0.12);
        }
        if (states.contains(WidgetState.hovered)) {
          return colors.fg.withValues(alpha: 0.08);
        }
        return null;
      }),
      side: colors.border == null
          ? null
          : WidgetStateProperty.resolveWith((states) {
              final border = colors.border!;
              if (states.contains(WidgetState.disabled)) {
                return BorderSide(
                  color: border.withValues(alpha: 0.38),
                );
              }
              return BorderSide(color: border);
            }),
    );
  }
}
