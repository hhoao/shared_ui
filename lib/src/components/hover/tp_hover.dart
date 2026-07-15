import 'package:flutter/material.dart';

/// Subtle hover background for sidebar rows and toolbars.
class TpHover extends StatefulWidget {
  const TpHover({
    super.key,
    required this.child,
    this.hoverColor,
    this.onTap,
    this.onSecondaryTap,
    this.padding,
    this.borderRadius = const BorderRadius.all(Radius.circular(8)),
    this.duration = const Duration(milliseconds: 120),
    this.cursor,
    this.forceHover = false,
    this.onHoverChanged,
    this.width,
    this.height,
  });

  final Widget child;
  final Color? hoverColor;
  final VoidCallback? onTap;
  final VoidCallback? onSecondaryTap;
  final EdgeInsetsGeometry? padding;
  final BorderRadius borderRadius;
  final Duration duration;
  final MouseCursor? cursor;

  /// Keeps the hover fill visible (e.g. while an anchored menu is open).
  final bool forceHover;
  final ValueChanged<bool>? onHoverChanged;
  final double? width;
  final double? height;

  /// Default sidebar row hover tint.
  static Color defaultHoverColor(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return isDark
        ? Colors.white.withValues(alpha: 0.06)
        : Colors.black.withValues(alpha: 0.04);
  }

  @override
  State<TpHover> createState() => _TpHoverState();
}

class _TpHoverState extends State<TpHover> {
  var _hovered = false;

  bool get _showHover => _hovered || widget.forceHover;

  void _setHovered(bool value) {
    if (_hovered == value) return;
    setState(() => _hovered = value);
    widget.onHoverChanged?.call(value);
  }

  @override
  Widget build(BuildContext context) {
    final interactive = widget.onTap != null || widget.onSecondaryTap != null;
    final cursor =
        widget.cursor ??
        (interactive ? SystemMouseCursors.click : SystemMouseCursors.basic);

    Widget content = AnimatedContainer(
      width: widget.width,
      height: widget.height,
      duration: widget.duration,
      padding: widget.padding,
      decoration: BoxDecoration(
        color: _showHover
            ? (widget.hoverColor ?? TpHover.defaultHoverColor(context))
            : Colors.transparent,
        borderRadius: widget.borderRadius,
      ),
      child: widget.child,
    );

    if (interactive) {
      content = GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: widget.onTap,
        onSecondaryTap: widget.onSecondaryTap,
        child: content,
      );
    }

    return MouseRegion(
      onEnter: (_) => _setHovered(true),
      onExit: (_) => _setHovered(false),
      cursor: cursor,
      child: content,
    );
  }
}
