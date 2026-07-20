import 'package:flutter/material.dart';

/// Subtle hover / press wrapper for interactive rows, chips, and chrome.
///
/// Provides click cursor when interactive, animated hover fill, and optional
/// press scale. Prefer this over a bare [GestureDetector] for onTap-only UI.
class TpHover extends StatefulWidget {
  const TpHover({
    super.key,
    required this.child,
    this.hoverColor,
    this.backgroundColor,
    this.onTap,
    this.onSecondaryTap,
    this.onLongPress,
    this.padding,
    this.borderRadius = const BorderRadius.all(Radius.circular(8)),
    this.duration = const Duration(milliseconds: 120),
    this.cursor,
    this.forceHover = false,
    this.onHoverChanged,
    this.width,
    this.height,
    this.enabled = true,
    this.pressScale = 1.0,
  });

  final Widget child;
  final Color? hoverColor;

  /// Idle fill behind [child]. Transparent when null.
  final Color? backgroundColor;
  final VoidCallback? onTap;
  final VoidCallback? onSecondaryTap;
  final VoidCallback? onLongPress;
  final EdgeInsetsGeometry? padding;
  final BorderRadius borderRadius;
  final Duration duration;
  final MouseCursor? cursor;

  /// Keeps the hover fill visible (e.g. while an anchored menu is open).
  final bool forceHover;
  final ValueChanged<bool>? onHoverChanged;
  final double? width;
  final double? height;
  final bool enabled;

  /// Scale applied while the pointer is down. `1.0` disables press feedback.
  final double pressScale;

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
  var _pressed = false;

  bool get _interactive =>
      widget.enabled &&
      (widget.onTap != null ||
          widget.onSecondaryTap != null ||
          widget.onLongPress != null);

  bool get _showHover => widget.enabled && (_hovered || widget.forceHover);

  void _setHovered(bool value) {
    if (_hovered == value) return;
    setState(() => _hovered = value);
    widget.onHoverChanged?.call(value);
  }

  @override
  Widget build(BuildContext context) {
    final idleColor = widget.backgroundColor ?? Colors.transparent;
    final hoverFill = widget.hoverColor ?? TpHover.defaultHoverColor(context);
    final cursor =
        widget.cursor ??
        (_interactive ? SystemMouseCursors.click : SystemMouseCursors.basic);

    Widget content = AnimatedContainer(
      width: widget.width,
      height: widget.height,
      duration: widget.duration,
      padding: widget.padding,
      decoration: BoxDecoration(
        color: _showHover ? hoverFill : idleColor,
        borderRadius: widget.borderRadius,
      ),
      child: widget.child,
    );

    if (widget.pressScale != 1.0) {
      content = AnimatedScale(
        scale: _pressed && _interactive ? widget.pressScale : 1.0,
        duration: widget.duration,
        curve: Curves.easeOut,
        child: content,
      );
    }

    if (_interactive) {
      content = GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: widget.onTap,
        onSecondaryTap: widget.onSecondaryTap,
        onLongPress: widget.onLongPress,
        onTapDown: widget.pressScale != 1.0
            ? (_) => setState(() => _pressed = true)
            : null,
        onTapUp: widget.pressScale != 1.0
            ? (_) => setState(() => _pressed = false)
            : null,
        onTapCancel: widget.pressScale != 1.0
            ? () => setState(() => _pressed = false)
            : null,
        child: content,
      );
    }

    return MouseRegion(
      onEnter: (_) {
        if (widget.enabled) _setHovered(true);
      },
      onExit: (_) {
        _setHovered(false);
        if (_pressed) setState(() => _pressed = false);
      },
      cursor: cursor,
      child: content,
    );
  }
}
