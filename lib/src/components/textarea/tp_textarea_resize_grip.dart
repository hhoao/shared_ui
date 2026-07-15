import 'package:flutter/material.dart';

import '../../theme/components/tp_textarea_theme.dart';

/// A small visual grip used to indicate that a [TpTextareaShell] is
/// resizable. Drag handling lives on the shell's [GestureDetector].
class TpDefaultResizeGrip extends StatelessWidget {
  const TpDefaultResizeGrip({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return SizedBox(
      key: const Key('tp-textarea-resize-grip'),
      width: kTpTextareaResizeGripHitSize,
      height: kTpTextareaResizeGripHitSize,
      child: Align(
        alignment: Alignment.bottomRight,
        child: Padding(
          padding: const EdgeInsets.only(right: 2, bottom: 2),
          child: SizedBox(
            width: kTpTextareaResizeGripVisualSize,
            height: kTpTextareaResizeGripVisualSize,
            child: CustomPaint(
              painter: TpResizeGripPainter(
                color: scheme.outline.withValues(alpha: 0.7),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Diagonal resize grip lines for the bottom-trailing corner.
class TpResizeGripPainter extends CustomPainter {
  const TpResizeGripPainter({
    required this.color,
    this.strokeWidth = 0.8,
    this.lineCount = 3,
    this.spacing = 4.0,
  });

  final Color color;
  final double strokeWidth;
  final int lineCount;
  final double spacing;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth;

    for (var i = 0; i < lineCount; i++) {
      final offset = spacing * i;
      canvas.drawLine(
        Offset(size.width - offset, size.height),
        Offset(size.width, size.height - offset),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant TpResizeGripPainter oldDelegate) {
    return oldDelegate.color != color ||
        oldDelegate.strokeWidth != strokeWidth ||
        oldDelegate.lineCount != lineCount ||
        oldDelegate.spacing != spacing;
  }
}
