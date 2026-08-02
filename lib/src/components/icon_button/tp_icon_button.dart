import 'package:flutter/material.dart';

import '../../theme/tp_theme.dart';

/// Compact icon control for toolbars and list rows: square hit target, rounded
/// ink splash (AppFlowy-style).
class TpIconButton extends StatelessWidget {
  static const double kDefaultSize = 32;
  static const double kDefaultBorderRadius = 6;

  /// Dense toolbar preset (file tree header, terminal tabs, etc.).
  static const double kCompactSize = 28;

  /// Mobile title-bar / drawer controls — Material minimum tap target.
  static const double kMobileTapSize = 48;

  const TpIconButton({
    super.key,
    this.icon,
    this.iconWidget,
    required this.onTap,
    this.tooltip,
    this.size = kDefaultSize,
    this.iconSize,
    this.compact = false,
    this.borderRadius = kDefaultBorderRadius,
    this.color,
    this.backgroundColor,
    this.enabled = true,
    this.selected = false,
  }) : assert(icon != null || iconWidget != null);

  final IconData? icon;
  final Widget? iconWidget;
  final VoidCallback? onTap;
  final String? tooltip;
  final double size;
  final double? iconSize;
  final bool compact;
  final double borderRadius;
  final Color? color;
  final Color? backgroundColor;
  final bool enabled;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final sizes = context.tpIconSizes;
    final cs = Theme.of(context).colorScheme;
    final resolvedIconSize = iconSize ?? (compact ? sizes.sm : sizes.md);
    // Explicit [Icon.color] ignores IconTheme, so disabled must swap the paint
    // color — use muted gray, not a faded accent (e.g. run green).
    final Color effectiveColor;
    if (!enabled) {
      effectiveColor = cs.onSurface.withValues(alpha: 0.38);
    } else if (color != null) {
      effectiveColor = color!;
    } else if (selected) {
      effectiveColor = cs.primary;
    } else {
      effectiveColor = cs.onSurface;
    }

    final Color? fill = backgroundColor ??
        (selected ? cs.primary.withValues(alpha: 0.16) : null);

    final Border? border = selected
        ? Border.all(color: cs.primary.withValues(alpha: 0.28))
        : null;
    final radius = BorderRadius.circular(borderRadius);

    Widget iconChild =
        iconWidget ?? Icon(icon, size: resolvedIconSize, color: effectiveColor);
    if (!enabled && iconWidget != null) {
      iconChild = Opacity(opacity: 0.38, child: iconChild);
    }

    Widget ink = Ink(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: radius,
        color: fill,
        border: border,
      ),
      child: InkWell(
        borderRadius: radius,
        hoverColor: effectiveColor.withValues(alpha: 0.12),
        splashColor: effectiveColor.withValues(alpha: 0.2),
        mouseCursor: enabled && onTap != null
            ? SystemMouseCursors.click
            : SystemMouseCursors.basic,
        onTap: enabled ? onTap : null,
        child: Center(child: iconChild),
      ),
    );

    if (tooltip != null && tooltip!.isNotEmpty) {
      ink = Tooltip(message: tooltip!, child: ink);
    }

    return Material(
      color: Colors.transparent,
      borderRadius: radius,
      child: ink,
    );
  }
}
