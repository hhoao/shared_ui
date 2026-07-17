import 'package:flutter/material.dart';

import 'tp_token_palette.dart';

/// Visual bleed on the left only; right edge stays at the layout token end.
const double tpTokenPillLeftBleed = 4;

/// Inner text padding inside the pill background.
const double tpTokenPillHorizontalPadding = 6;

List<InlineSpan> buildTpTokenMirrorLayoutSpans({
  required String text,
  required TextStyle baseStyle,
  required RegExp tokenPattern,
}) {
  if (text.isEmpty) return [TextSpan(text: '', style: baseStyle)];

  final spans = <InlineSpan>[];
  var start = 0;
  for (final match in tokenPattern.allMatches(text)) {
    if (match.start > start) {
      spans.add(
        TextSpan(text: text.substring(start, match.start), style: baseStyle),
      );
    }
    final token = match.group(0)!;
    spans.add(
      TextSpan(
        text: token,
        style: baseStyle.copyWith(color: Colors.transparent),
      ),
    );
    start = match.end;
  }
  if (start < text.length) {
    spans.add(TextSpan(text: text.substring(start), style: baseStyle));
  }
  return spans;
}

StrutStyle tpTokenMirrorStrutStyle(TextStyle baseStyle) {
  return StrutStyle(
    fontSize: baseStyle.fontSize,
    height: baseStyle.height,
    fontFamily: baseStyle.fontFamily,
    fontFamilyFallback: baseStyle.fontFamilyFallback,
    forceStrutHeight: true,
  );
}

TextStyle tpTokenPillLabelStyle(TextStyle baseStyle, Color foreground) {
  return baseStyle.copyWith(
    color: foreground,
    fontWeight: FontWeight.w600,
    height: 1.1,
  );
}

double tpTokenPillWidth(double layoutWidth) {
  return layoutWidth + tpTokenPillLeftBleed;
}

/// Paints token pill chrome using [size] from the child (no [LayoutBuilder]).
///
/// A [LayoutBuilder] here forced nested BUILD during LAYOUT on workspace
/// landing first-open (~667 ms in DevTools test53).
class _TpTokenPillOverlayPainter extends CustomPainter {
  _TpTokenPillOverlayPainter({
    required this.text,
    required this.baseStyle,
    required this.colorScheme,
    required this.tokenPattern,
    required this.resolvePalette,
    required this.textDirection,
    required this.textScaler,
    required this.strutStyle,
    required this.maxLines,
  });

  final String text;
  final TextStyle baseStyle;
  final ColorScheme colorScheme;
  final RegExp tokenPattern;
  final TpTokenPaletteResolver resolvePalette;
  final TextDirection textDirection;
  final TextScaler textScaler;
  final StrutStyle strutStyle;
  final int? maxLines;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || text.isEmpty) return;

    final layoutSpans = buildTpTokenMirrorLayoutSpans(
      text: text,
      baseStyle: baseStyle,
      tokenPattern: tokenPattern,
    );
    final painter = TextPainter(
      text: TextSpan(children: layoutSpans),
      textDirection: textDirection,
      textScaler: textScaler,
      strutStyle: strutStyle,
      maxLines: maxLines,
    )..layout(maxWidth: size.width);

    for (final match in tokenPattern.allMatches(text)) {
      final token = match.group(0)!;
      final palette = resolvePalette(token, colorScheme);
      final boxes = painter.getBoxesForSelection(
        TextSelection(baseOffset: match.start, extentOffset: match.end),
      );
      if (boxes.isEmpty) continue;

      final left = boxes.first.left;
      final top = boxes.map((box) => box.top).reduce((a, b) => a < b ? a : b);
      final bottom = boxes
          .map((box) => box.bottom)
          .reduce((a, b) => a > b ? a : b);
      final layoutWidth = boxes.last.right - left;
      final pillWidth = tpTokenPillWidth(layoutWidth);
      final pillHeight = bottom - top - 2;
      if (pillWidth <= 0 || pillHeight <= 0) continue;

      final rect = RRect.fromRectAndRadius(
        Rect.fromLTWH(
          left - tpTokenPillLeftBleed,
          top + 1,
          pillWidth,
          pillHeight,
        ),
        const Radius.circular(6),
      );
      canvas.drawRRect(rect, Paint()..color = palette.background);

      final labelPainter = TextPainter(
        text: TextSpan(
          text: token,
          style: tpTokenPillLabelStyle(baseStyle, palette.foreground),
        ),
        textDirection: textDirection,
        textScaler: textScaler,
        maxLines: 1,
        ellipsis: '',
      )..layout(maxWidth: (pillWidth - 2 * tpTokenPillHorizontalPadding).clamp(
          0.0,
          double.infinity,
        ));

      final labelDx =
          left - tpTokenPillLeftBleed + tpTokenPillHorizontalPadding;
      final labelDy = top + 1 + (pillHeight - labelPainter.height) / 2;
      labelPainter.paint(canvas, Offset(labelDx, labelDy));
    }
  }

  @override
  bool shouldRepaint(covariant _TpTokenPillOverlayPainter oldDelegate) {
    return oldDelegate.text != text ||
        oldDelegate.baseStyle != baseStyle ||
        oldDelegate.colorScheme != colorScheme ||
        oldDelegate.tokenPattern != tokenPattern ||
        oldDelegate.textDirection != textDirection ||
        oldDelegate.textScaler != textScaler ||
        oldDelegate.strutStyle != strutStyle ||
        oldDelegate.maxLines != maxLines ||
        oldDelegate.resolvePalette != resolvePalette;
  }
}

/// Decorative mirror of text with inline token chips (sits under the TextField).
class TpTokenChipMirror extends StatelessWidget {
  const TpTokenChipMirror({
    required this.text,
    required this.baseStyle,
    required this.minLines,
    required this.maxLines,
    required this.tokenPattern,
    required this.resolvePalette,
    this.scrollOffset = 0,
    this.expands = false,
    super.key,
  });

  final String text;
  final TextStyle baseStyle;
  final int minLines;
  final int maxLines;
  final double scrollOffset;
  final bool expands;
  final RegExp tokenPattern;
  final TpTokenPaletteResolver resolvePalette;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final lineHeight = (baseStyle.fontSize ?? 14) * (baseStyle.height ?? 1.5);
    final minHeight = lineHeight * minLines;
    final maxHeight = lineHeight * maxLines;
    final strutStyle = tpTokenMirrorStrutStyle(baseStyle);
    final layoutSpans = buildTpTokenMirrorLayoutSpans(
      text: text,
      baseStyle: baseStyle,
      tokenPattern: tokenPattern,
    );
    final effectiveMaxLines = expands ? null : maxLines;

    final mirrorText = Text.rich(
      TextSpan(children: layoutSpans),
      maxLines: effectiveMaxLines,
      strutStyle: strutStyle,
    );

    // Size from parent constraints via SizedBox/CustomPaint — do not use
    // LayoutBuilder (nested BUILD during LAYOUT; see test53).
    final content = ClipRect(
      clipBehavior: Clip.none,
      child: Transform.translate(
        offset: Offset(0, -scrollOffset),
        child: CustomPaint(
          painter: _TpTokenPillOverlayPainter(
            text: text,
            baseStyle: baseStyle,
            colorScheme: cs,
            tokenPattern: tokenPattern,
            resolvePalette: resolvePalette,
            textDirection: Directionality.of(context),
            textScaler: MediaQuery.textScalerOf(context),
            strutStyle: strutStyle,
            maxLines: effectiveMaxLines,
          ),
          child: expands
              ? SizedBox.expand(
                  child: Align(
                    alignment: Alignment.topLeft,
                    child: mirrorText,
                  ),
                )
              : SizedBox(width: double.infinity, child: mirrorText),
        ),
      ),
    );

    if (expands) {
      return content;
    }

    return ConstrainedBox(
      constraints: BoxConstraints(minHeight: minHeight, maxHeight: maxHeight),
      child: content,
    );
  }
}
