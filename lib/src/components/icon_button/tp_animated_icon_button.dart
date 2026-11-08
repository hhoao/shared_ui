import 'dart:async';

import 'package:flutter/material.dart';

import '../../theme/tp_theme.dart';
import '../progress/tp_indeterminate_spinner.dart';
import 'tp_animated_icon.dart';
import 'tp_icon_button.dart';

/// How a busy [TpAnimatedIconButton] shows progress.
enum TpAnimatedIconBusyStyle {
  /// Keep the icon and rotate it — refresh, fetch, pull, push.
  spinIcon,

  /// Replace the icon with [TpIndeterminateSpinner] — checks and probes whose
  /// icon has no rotation semantics.
  spinner,
}

/// [TpIconButton] with motion: one turn per tap and a continuous spin (or
/// spinner) while an action is in flight.
///
/// Busy is true while [TpAnimatedIconButton.busy] is true, or while the future
/// returned by [TpAnimatedIconButton.onPressed] is pending — so refresh actions
/// that return a future need no external loading flag. When busy ends the icon
/// finishes its current turn before stopping.
class TpAnimatedIconButton extends StatefulWidget {
  const TpAnimatedIconButton({
    super.key,
    required this.icon,
    required this.onPressed,
    this.tooltip,
    this.size = TpIconButton.kDefaultSize,
    this.iconSize,
    this.compact = false,
    this.borderRadius = TpIconButton.kDefaultBorderRadius,
    this.color,
    this.backgroundColor,
    this.enabled = true,
    this.selected = false,
    this.busy = false,
    this.busyStyle = TpAnimatedIconBusyStyle.spinIcon,
    this.spinOnTap = true,
  });

  final IconData icon;

  /// Invoked on tap. Returning a [Future] keeps the button busy until it
  /// completes.
  final FutureOr<void> Function()? onPressed;

  final String? tooltip;
  final double size;
  final double? iconSize;
  final bool compact;
  final double borderRadius;
  final Color? color;
  final Color? backgroundColor;
  final bool enabled;
  final bool selected;

  /// External busy state, for actions driven by a cubit instead of the tap.
  final bool busy;

  final TpAnimatedIconBusyStyle busyStyle;

  /// Spin one turn on every tap, even for instant actions.
  final bool spinOnTap;

  @override
  State<TpAnimatedIconButton> createState() => _TpAnimatedIconButtonState();
}

class _TpAnimatedIconButtonState extends State<TpAnimatedIconButton> {
  final GlobalKey<TpAnimatedIconState> _iconKey = GlobalKey();
  bool _pending = false;

  bool get _busy => widget.busy || _pending;

  Future<void> _handleTap() async {
    final onPressed = widget.onPressed;
    if (onPressed == null || _pending) return;
    if (widget.spinOnTap) _iconKey.currentState?.spinOnce();
    final result = onPressed();
    if (result is! Future) return;
    setState(() => _pending = true);
    try {
      await result;
    } finally {
      if (mounted) setState(() => _pending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final sizes = context.tpIconSizes;
    final cs = Theme.of(context).colorScheme;
    final iconSize = widget.iconSize ?? (widget.compact ? sizes.sm : sizes.md);
    final enabled = widget.enabled && widget.onPressed != null;

    // [TpIconButton] dims a custom icon widget while disabled, so pass the
    // undimmed color to avoid double-fading.
    final color = widget.color ?? (widget.selected ? cs.primary : cs.onSurface);

    final Widget iconChild =
        widget.busyStyle == TpAnimatedIconBusyStyle.spinner && _busy
        ? TpIndeterminateSpinner(size: iconSize)
        : TpAnimatedIcon(
            key: _iconKey,
            icon: widget.icon,
            size: iconSize,
            color: color,
            loading: widget.busyStyle == TpAnimatedIconBusyStyle.spinIcon
                ? _busy
                : false,
          );

    return TpIconButton(
      iconWidget: iconChild,
      onTap: enabled && !_pending ? _handleTap : null,
      tooltip: widget.tooltip,
      size: widget.size,
      compact: widget.compact,
      borderRadius: widget.borderRadius,
      backgroundColor: widget.backgroundColor,
      enabled: enabled,
      selected: widget.selected,
    );
  }
}
