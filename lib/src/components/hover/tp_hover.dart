import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Shape of the [TpHover] pressable surface.
///
/// On desktop this drives the [BorderRadius] of the animated fill; on touch it
/// drives the [ShapeBorder] of the [Material] that hosts the [InkWell] ripple.
enum TpPressableShape { rounded, stadium, circle }

/// Platform-adaptive pressable surface — the single tap/hover primitive.
///
/// Desktop (Linux / macOS / Windows / web): `GestureDetector` + animated
/// hover/active fill. [hoverColor] is composited over [backgroundColor] (not
/// swapped in), so selected/armed fills stay visible. Transparent idle shares
/// the hover RGB for an alpha-only fade. Hand cursor when interactive (arrow
/// when disabled), with keyboard `Focus` and `Semantics`.
///
/// Touch (Android / iOS): `Material` + `InkWell` ripple (no hover paint).
///
/// The child is centered within the surface (use a full-size child or
/// `Positioned` / `Align` inside it for custom placement).
///
/// Prefer this over a bare [GestureDetector] or [InkWell] for tappable UI.
class TpHover extends StatefulWidget {
  const TpHover({
    super.key,
    required this.child,
    this.hoverColor,
    this.backgroundColor,
    this.border,
    this.onTap,
    this.onDoubleTap,
    this.onSecondaryTap,
    this.onSecondaryTapDown,
    this.onLongPress,
    this.onTapDown,
    this.onTapUp,
    this.onTapCancel,
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
    this.shape = TpPressableShape.rounded,
    this.canRequestFocus = true,
    this.splashColor,
  });

  final Widget child;

  /// Hover tint composited over [backgroundColor]. A translucent value (the
  /// default) keeps the resting fill; an opaque value still covers it. Null
  /// uses [defaultHoverColor].
  final Color? hoverColor;

  /// Idle fill behind [child]. Transparent when null.
  final Color? backgroundColor;

  /// Drawn on the same decoration as [backgroundColor] / hover fill so the
  /// stroke sits on the outer edge (not inside [padding]).
  final BoxBorder? border;
  final VoidCallback? onTap;

  /// Fired when the surface is double-tapped. When both [onTap] and
  /// [onDoubleTap] are set, a single tap only fires after the double-tap
  /// window (kDoubleTapTimeout) expires.
  final VoidCallback? onDoubleTap;
  final VoidCallback? onSecondaryTap;
  final GestureTapDownCallback? onSecondaryTapDown;
  final VoidCallback? onLongPress;

  /// Fired on pointer down (menu rows that select immediately). When unset and
  /// [pressScale] != 1.0, a press-scale bookkeeping callback is installed.
  final GestureTapDownCallback? onTapDown;
  final GestureTapUpCallback? onTapUp;
  final GestureTapCancelCallback? onTapCancel;
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
  final TpPressableShape shape;

  /// Desktop path: whether the tap surface can take keyboard focus. Mirror of
  /// [InkWell.canRequestFocus] for call sites that must keep focus elsewhere.
  final bool canRequestFocus;

  /// Touch path: the [InkWell] splash color (defaults to theme splash).
  final Color? splashColor;

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

  static bool get _isTouchPlatform =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS);

  bool get _interactive =>
      widget.enabled &&
      (widget.onTap != null ||
          widget.onDoubleTap != null ||
          widget.onSecondaryTap != null ||
          widget.onSecondaryTapDown != null ||
          widget.onLongPress != null ||
          widget.onTapDown != null);

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

  BorderRadius get _desktopRadius {
    return switch (widget.shape) {
      TpPressableShape.rounded => widget.borderRadius,
      TpPressableShape.stadium =>
        BorderRadius.circular((widget.height ?? 999) / 2),
      TpPressableShape.circle =>
        BorderRadius.circular(((widget.width ?? widget.height) ?? 0) / 2),
    };
  }

  ShapeBorder get _touchShape {
    final side = widget.border?.top ?? BorderSide.none;
    return switch (widget.shape) {
      TpPressableShape.rounded =>
        RoundedRectangleBorder(borderRadius: widget.borderRadius, side: side),
      TpPressableShape.stadium => StadiumBorder(side: side),
      TpPressableShape.circle => CircleBorder(side: side),
    };
  }

  GestureTapDownCallback? get _onTapDown {
    final custom = widget.onTapDown;
    if (custom != null) return custom;
    if (widget.pressScale != 1.0) {
      return (_) => setState(() => _pressed = true);
    }
    return null;
  }

  GestureTapUpCallback? get _onTapUp {
    final custom = widget.onTapUp;
    if (custom != null) return custom;
    if (widget.pressScale != 1.0) {
      return (_) => setState(() => _pressed = false);
    }
    return null;
  }

  GestureTapCancelCallback? get _onTapCancel {
    final custom = widget.onTapCancel;
    if (custom != null) return custom;
    if (widget.pressScale != 1.0) {
      return () => setState(() => _pressed = false);
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    if (_isTouchPlatform) return _buildTouch(context);
    return _buildDesktop(context);
  }

  Widget _buildDesktop(BuildContext context) {
    final hoverFill = widget.hoverColor ?? TpHover.defaultHoverColor(context);
    final resting = widget.backgroundColor ?? Colors.transparent;
    final hoveredFill = Color.alphaBlend(hoverFill, resting);
    final idleColor = _animationIdleColor(resting, hoveredFill);
    final Color fill = _showHover ? hoveredFill : idleColor;
    final cursor =
        widget.cursor ??
        (_interactive ? SystemMouseCursors.click : SystemMouseCursors.basic);

    Widget content = Container(
      width: widget.width,
      height: widget.height,
      child: Stack(
        // Center the child within the surface. A child that hugs its content
        // (icon, min-size row) would otherwise be pinned to the top-left when
        // the surface is stretched / fixed-size (e.g. status-bar pills).
        alignment: Alignment.center,
        children: [
          // Fill + border behind the child. Keyed by RGB (alpha masked off) so
          // a fill color-family change replaces this layer instantly instead of
          // Color.lerp-ing through muddy intermediates.
          Positioned.fill(
            child: AnimatedContainer(
              key: ValueKey<int>(fill.toARGB32() & 0x00FFFFFF),
              duration: widget.duration,
              decoration: BoxDecoration(
                color: fill,
                borderRadius: _desktopRadius,
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
        onDoubleTap: widget.onDoubleTap,
        onTapDown: _onTapDown,
        onTapUp: _onTapUp,
        onTapCancel: _onTapCancel,
        onSecondaryTap: widget.onSecondaryTap,
        onSecondaryTapDown: widget.onSecondaryTapDown,
        onLongPress: widget.onLongPress,
        child: content,
      );
    }

    content = Semantics(
      button: _interactive,
      enabled: widget.enabled,
      onTap: widget.onTap != null
          ? () => widget.onTap!()
          : null,
      child: content,
    );

    return Focus(
      canRequestFocus: _interactive && widget.canRequestFocus,
      child: MouseRegion(
        onEnter: (_) {
          if (widget.enabled) _setHovered(true);
        },
        onExit: (_) {
          _setHovered(false);
          if (_pressed) setState(() => _pressed = false);
        },
        cursor: cursor,
        child: content,
      ),
    );
  }

  Widget _buildTouch(BuildContext context) {
    final shape = _touchShape;
    final fill = widget.backgroundColor ?? Colors.transparent;

    Widget content = SizedBox(
      width: widget.width,
      height: widget.height,
      child: Material(
        color: fill,
        shape: shape,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: widget.onTap,
          onDoubleTap: widget.onDoubleTap,
          onTapDown: _onTapDown,
          onTapUp: _onTapUp,
          onTapCancel: _onTapCancel,
          onSecondaryTap: widget.onSecondaryTap,
          onSecondaryTapDown: widget.onSecondaryTapDown,
          onLongPress: widget.onLongPress,
          customBorder: shape,
          canRequestFocus: widget.canRequestFocus,
          splashColor: widget.splashColor,
          hoverColor: Colors.transparent,
          // Mirror the desktop path: center a content-hugging child when the
          // surface is stretched / fixed-size (Stack centers without expanding
          // the child, so a pill keeps hugging its content horizontally).
          child: Stack(
            alignment: Alignment.center,
            children: [
              Padding(
                padding: widget.padding ?? EdgeInsets.zero,
                child: widget.child,
              ),
            ],
          ),
        ),
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

    return MouseRegion(
      cursor:
          widget.cursor ??
          (_interactive ? SystemMouseCursors.click : SystemMouseCursors.basic),
      child: content,
    );
  }
}
