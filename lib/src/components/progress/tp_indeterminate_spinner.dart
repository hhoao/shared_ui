import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Circular indeterminate spinner that paints on animation ticks without
/// rebuilding widgets.
///
/// Material [CircularProgressIndicator] drives its arc through
/// [AnimatedBuilder], which floods DevTools widget-rebuild counts on long-lived
/// chat chrome. This widget listens via [CustomPainter.repaint] instead.
class TpIndeterminateSpinner extends StatefulWidget {
  const TpIndeterminateSpinner({
    super.key,
    this.size = 16,
    this.strokeWidth = 2,
    this.color,
  });

  final double size;
  final double strokeWidth;

  /// Defaults to [ColorScheme.primary] when null.
  final Color? color;

  @override
  State<TpIndeterminateSpinner> createState() => _TpIndeterminateSpinnerState();
}

class _TpIndeterminateSpinnerState extends State<TpIndeterminateSpinner>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1200),
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.color ?? Theme.of(context).colorScheme.primary;
    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: RepaintBoundary(
        child: CustomPaint(
          painter: _TpIndeterminateSpinnerPainter(
            animation: _controller,
            color: color,
            strokeWidth: widget.strokeWidth,
          ),
        ),
      ),
    );
  }
}

class _TpIndeterminateSpinnerPainter extends CustomPainter {
  _TpIndeterminateSpinnerPainter({
    required this.animation,
    required this.color,
    required this.strokeWidth,
  }) : super(repaint: animation);

  final Animation<double> animation;
  final Color color;
  final double strokeWidth;

  static const _sweep = 1.4 * math.pi;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..isAntiAlias = true;
    final inset = strokeWidth / 2;
    final rect = Rect.fromLTWH(
      inset,
      inset,
      size.width - strokeWidth,
      size.height - strokeWidth,
    );
    final start = animation.value * 2 * math.pi - math.pi / 2;
    canvas.drawArc(rect, start, _sweep, false, paint);
  }

  @override
  bool shouldRepaint(_TpIndeterminateSpinnerPainter old) =>
      old.animation != animation ||
      old.color != color ||
      old.strokeWidth != strokeWidth;
}
