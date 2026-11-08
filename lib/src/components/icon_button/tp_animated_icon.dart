import 'package:flutter/material.dart';

/// Icon that can spin: continuously while [loading], or one turn per
/// [TpAnimatedIconState.spinOnce] call.
///
/// Use directly inside labelled buttons (`OutlinedButton.icon`, `TpButton`,
/// ...). For icon-only toolbar controls use [TpAnimatedIconButton], which wires
/// the spin to taps and to the action's future.
class TpAnimatedIcon extends StatefulWidget {
  const TpAnimatedIcon({
    super.key,
    required this.icon,
    this.loading = false,
    this.size,
    this.color,
    this.spinDuration = const Duration(milliseconds: 700),
  });

  final IconData icon;

  /// While true the icon rotates continuously. Turning it off finishes the
  /// current turn before stopping, so the icon never snaps mid-rotation.
  final bool loading;

  final double? size;
  final Color? color;

  /// Duration of one full turn.
  final Duration spinDuration;

  @override
  State<TpAnimatedIcon> createState() => TpAnimatedIconState();
}

class TpAnimatedIconState extends State<TpAnimatedIcon>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: widget.spinDuration,
  );

  @override
  void initState() {
    super.initState();
    if (widget.loading) _controller.repeat();
  }

  @override
  void didUpdateWidget(TpAnimatedIcon oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.loading == oldWidget.loading) return;
    if (widget.loading) {
      _controller.repeat();
    } else {
      _finishTurn();
    }
  }

  /// Plays one full turn. Ignored while [TpAnimatedIcon.loading] owns the
  /// animation.
  void spinOnce() {
    if (widget.loading) return;
    _controller.forward(from: 0);
  }

  /// Completes the in-flight turn instead of jumping back to 0.
  Future<void> _finishTurn() async {
    if (!_controller.isAnimating) {
      _controller.value = 0;
      return;
    }
    final remaining = 1 - _controller.value;
    if (remaining <= 0.01) {
      _controller.value = 0;
      return;
    }
    await _controller.animateTo(
      1,
      duration: Duration(
        milliseconds: (widget.spinDuration.inMilliseconds * remaining).round(),
      ),
    );
    // A new [loading] round may have taken over while settling.
    if (mounted && !widget.loading) _controller.value = 0;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RotationTransition(
      turns: _controller,
      child: Icon(widget.icon, size: widget.size, color: widget.color),
    );
  }
}
