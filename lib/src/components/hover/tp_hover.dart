import 'package:flutter/material.dart';

/// Subtle hover / press wrapper for interactive rows, chips, and chrome.
///
/// Provides click cursor when interactive, animated hover fill, and optional
/// press scale. Prefer this over a bare [GestureDetector] for onTap-only UI.
///
/// The fill animates only the hover tint's alpha (same RGB as [hoverColor]),
/// so hover fades stay clean. When the fill's color family changes — e.g. a
/// caller flips [backgroundColor] to a selected/active fill — it is applied
/// instantly: lerping between two different RGB colors paints muddy
/// intermediate frames (a transparent hover tint → opaque selected fill reads
/// as a bright flash on click).
class TpHover extends StatefulWidget {
  const TpHover({
    super.key,
    required this.child,
    this.hoverColor,
    this.backgroundColor,
    this.border,
    this.onTap,
    this.onSecondaryTap,
    this.onSecondaryTapDown,
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

  /// Drawn on the same decoration as [backgroundColor] / hover fill so the
  /// stroke sits on the outer edge (not inside [padding]).
  final BoxBorder? border;
  final VoidCallback? onTap;
  final VoidCallback? onSecondaryTap;
  final GestureTapDownCallback? onSecondaryTapDown;
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
          widget.onSecondaryTapDown != null ||
          widget.onLongPress != null);

  bool get _showHover => widget.enabled && (_hovered || widget.forceHover);

  /// Fully transparent idle must share [hoverFill]'s RGB so [Color.lerp]
  /// fades opacity instead of interpolating from black.
  static Color _animationIdleColor(Color idleColor, Color hoverFill) {
    if (idleColor.a == 0) {
      return hoverFill.withValues(alpha: 0);
    }
    return idleColor;
  }

  void _setHovered(bool value) {
    if (_hovered == value) return;
    setState(() => _hovered = value);
    widget.onHoverChanged?.call(value);
  }

  @override
  Widget build(BuildContext context) {
    final hoverFill = widget.hoverColor ?? TpHover.defaultHoverColor(context);
    // Keep the idle fill on the hover RGB at alpha 0 so the hover fade only
    // interpolates alpha. Colors.transparent is 0x00000000; a plain
    // transparent idle would make mid-tweens flash dark.
    final idleColor = _animationIdleColor(
      widget.backgroundColor ?? Colors.transparent,
      hoverFill,
    );
    final Color fill = _showHover ? hoverFill : idleColor;
    final cursor =
        widget.cursor ??
        (_interactive ? SystemMouseCursors.click : SystemMouseCursors.basic);

    Widget content = Container(
      width: widget.width,
      height: widget.height,
      child: Stack(
        children: [
          // Fill + border behind the child. Keyed by RGB (alpha masked off) so
          // a fill color-family change — selection / active state — replaces
          // this layer instantly instead of Color.lerp-ing through muddy
          // intermediate colors (transparent hover tint → opaque selected fill
          // reads as a bright flash). Alpha-only changes (hover fade) keep the
          // key and animate. The child stays a Stack sibling so its State is
          // not recreated by fill changes.
          Positioned.fill(
            child: AnimatedContainer(
              key: ValueKey<int>(fill.toARGB32() & 0x00FFFFFF),
              duration: widget.duration,
              decoration: BoxDecoration(
                color: fill,
                borderRadius: widget.borderRadius,
                border: widget.border,
              ),
            ),
          ),
          Padding(
            padding: widget.padding ?? EdgeInsets.zero,
            child: widget.child,
          ),
        ],
      ),
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
        onSecondaryTapDown: widget.onSecondaryTapDown,
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
