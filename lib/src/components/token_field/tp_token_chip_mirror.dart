import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'tp_token_edit.dart';
import 'tp_token_palette.dart';

/// Visual bleed used by legacy [tpTokenPillWidth] callers.
const double tpTokenPillLeftBleed = 4;

/// Horizontal breathing room on both sides of a chip label.
///
/// The pill is painted behind the text, so this does not move the glyphs; it
/// extends the background into the leading edge and into the following
/// whitespace, which is what makes a stadium chip look padded.
const double tpTokenPillHorizontalPadding = 8;

List<InlineSpan> buildTpTokenMirrorLayoutSpans({
  required String text,
  required TextStyle baseStyle,
  required List<TpTokenRange> tokenRanges,
  ColorScheme? colorScheme,
  TpTokenPaletteResolver? resolvePalette,
}) {
  if (text.isEmpty) return [TextSpan(text: '', style: baseStyle)];

  final spans = <InlineSpan>[];
  var start = 0;
  for (final range in tokenRanges) {
    if (range.start < start || range.end > text.length) continue;
    if (range.start > start) {
      spans.add(
        TextSpan(text: text.substring(start, range.start), style: baseStyle),
      );
    }
    final token = text.substring(range.start, range.end);
    final foreground = (colorScheme != null && resolvePalette != null)
        ? resolvePalette(token, colorScheme).foreground
        : (baseStyle.color ?? Colors.black);
    // Keep font metrics identical to [baseStyle] so caret/selection stay
    // aligned with the transparent TextField glyphs above.
    spans.add(
      TextSpan(
        text: token,
        style: baseStyle.copyWith(color: foreground),
      ),
    );
    start = range.end;
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

/// Background-only chip chrome — one [Positioned] pill per layout [TextBox].
///
/// Token glyphs are painted by the mirror [Text.rich] spans; wrapping a long
/// `@path` must not squeeze the full string through [FittedBox].
List<Widget> buildTpTokenPillOverlays({
  required String text,
  required TextStyle baseStyle,
  required ColorScheme colorScheme,
  required TextPainter painter,
  required List<TpTokenRange> tokenRanges,
  required TpTokenPaletteResolver resolvePalette,
  int? caretOffset,
}) {
  final overlays = <Widget>[];
  for (final range in tokenRanges) {
    if (range.start < 0 || range.end > text.length || range.end <= range.start) {
      continue;
    }
    final token = text.substring(range.start, range.end);
    final palette = resolvePalette(token, colorScheme);
    final boxes = painter.getBoxesForSelection(
      TextSelection(baseOffset: range.start, extentOffset: range.end),
    );
    if (boxes.isEmpty) continue;

    for (var index = 0; index < boxes.length; index++) {
      final box = boxes[index];
      final isLast = index == boxes.length - 1;
      final left = box.left -
          (index == 0
              ? _leadingChipPadding(
                  text: text,
                  rangeStart: range.start,
                  painter: painter,
                  box: box,
                  caretOffset: caretOffset,
                )
              : 0);
      final right = isLast
          ? box.right +
                _trailingChipPadding(
                  text: text,
                  rangeEnd: range.end,
                  painter: painter,
                  box: box,
                  caretOffset: caretOffset,
                )
          : box.right;
      overlays.add(
        Positioned(
          left: left,
          top: box.top + 1,
          width: right - left,
          height: box.bottom - box.top - 2,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: palette.background,
              borderRadius: BorderRadius.circular(
                math.max(0, box.bottom - box.top - 2) / 2,
              ),
            ),
          ),
        ),
      );
    }
  }
  return overlays;
}

/// Extra background to the right of a chip label.
///
/// Extends into following whitespace (stopping just before the next glyph), or
/// into the end-of-text / end-of-line margin. Never paints under a following
/// glyph — that would make ordinary text look like part of the chip.
double _lineX(TextPainter painter, int offset) =>
    painter.getOffsetForCaret(TextPosition(offset: offset), Rect.zero).dx;

/// Padding to the left of a chip label, bounded by the previous glyph and the
/// caret. A caret sitting at the token start (or inside the preceding spaces)
/// must stay outside the pill.
double _leadingChipPadding({
  required String text,
  required int rangeStart,
  required TextPainter painter,
  required TextBox box,
  required int? caretOffset,
}) {
  if (caretOffset == rangeStart) return 0;
  var boundary = rangeStart;
  while (boundary > 0 &&
      (text[boundary - 1] == ' ' || text[boundary - 1] == '\t')) {
    boundary--;
  }
  if (boundary == rangeStart) return 0;
  final limit = math.max(
    box.left - tpTokenPillHorizontalPadding,
    _lineX(painter, boundary),
  );
  final pad = box.left - limit;
  if (caretOffset != null && caretOffset < rangeStart && caretOffset >= boundary) {
    final caretX = _lineX(painter, caretOffset);
    if (caretX > limit) return box.left - caretX;
  }
  return pad;
}

/// Padding to the right of a chip label, bounded by the next glyph and the
/// caret. Ends at the caret when the caret is inside the following spaces.
double _trailingChipPadding({
  required String text,
  required int rangeEnd,
  required TextPainter painter,
  required TextBox box,
  required int? caretOffset,
}) {
  if (caretOffset == rangeEnd) return 0;

  double limit;
  int? trailingEnd;
  if (rangeEnd >= text.length) {
    limit = box.right + tpTokenPillHorizontalPadding;
  } else {
    final next = text[rangeEnd];
    if (next == '\n' || next == '\r') {
      limit = box.right + tpTokenPillHorizontalPadding;
    } else if (next == ' ' || next == '\t') {
      var end = rangeEnd;
      while (end < text.length && (text[end] == ' ' || text[end] == '\t')) {
        end++;
      }
      trailingEnd = end;
      // When the trailing whitespace wraps, the caret after it lands on the
      // next line at a small x, so `available` is <= 0.
      final available = _lineX(painter, end) - box.right;
      limit = box.right +
          math.max(0, math.min(tpTokenPillHorizontalPadding, available - 0.5));
    } else {
      return 0;
    }
  }

  if (caretOffset != null &&
      caretOffset > rangeEnd &&
      trailingEnd != null &&
      caretOffset <= trailingEnd) {
    final caretX = _lineX(painter, caretOffset);
    if (caretX < limit) return math.max(0, caretX - box.right);
  }
  return limit - box.right;
}

/// Decorative mirror of text with inline token chips (sits under the TextField).
class TpTokenChipMirror extends StatelessWidget {
  const TpTokenChipMirror({
    required this.text,
    required this.baseStyle,
    required this.minLines,
    required this.maxLines,
    required this.tokenRanges,
    required this.resolvePalette,
    this.caretOffset,
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
  final List<TpTokenRange> tokenRanges;
  final TpTokenPaletteResolver resolvePalette;

  /// Collapsed caret offset. Padding shrinks to the caret so the caret never
  /// sits inside a chip's rounded end.
  final int? caretOffset;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final lineHeight = (baseStyle.fontSize ?? 14) * (baseStyle.height ?? 1.5);
    final minHeight = lineHeight * minLines;
    final maxHeight = lineHeight * maxLines;
    final strutStyle = tpTokenMirrorStrutStyle(baseStyle);

    return LayoutBuilder(
      builder: (context, constraints) {
        final layoutSpans = buildTpTokenMirrorLayoutSpans(
          text: text,
          baseStyle: baseStyle,
          tokenRanges: tokenRanges,
          colorScheme: cs,
          resolvePalette: resolvePalette,
        );
        final painter = TextPainter(
          text: TextSpan(children: layoutSpans),
          textDirection: Directionality.of(context),
          textScaler: MediaQuery.textScalerOf(context),
          strutStyle: strutStyle,
          maxLines: expands ? null : maxLines,
        )..layout(maxWidth: constraints.maxWidth);

        // When expands, the shell gives a tight viewport height. Layout the
        // full document (not just the viewport) so [scrollOffset] can reveal
        // lines below the fold — otherwise transparent TextField glyphs have
        // nothing underneath once the caret scrolls past ~minLines.
        final contentHeight = expands
            ? math.max(painter.height, constraints.maxHeight)
            : painter.height;

        final body = SizedBox(
          width: constraints.maxWidth,
          height: contentHeight,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              // Backgrounds under glyphs so opaque pills do not cover text.
              ...buildTpTokenPillOverlays(
                text: text,
                baseStyle: baseStyle,
                colorScheme: cs,
                painter: painter,
                tokenRanges: tokenRanges,
                resolvePalette: resolvePalette,
                caretOffset: caretOffset,
              ),
              Text.rich(
                TextSpan(children: layoutSpans),
                maxLines: expands ? null : maxLines,
                strutStyle: strutStyle,
              ),
            ],
          ),
        );

        final scrolled = ClipRect(
          child: Transform.translate(
            offset: Offset(0, -scrollOffset),
            child: expands
                ? OverflowBox(
                    alignment: Alignment.topLeft,
                    minWidth: constraints.maxWidth,
                    maxWidth: constraints.maxWidth,
                    minHeight: contentHeight,
                    maxHeight: contentHeight,
                    child: body,
                  )
                : body,
          ),
        );

        if (expands) {
          return scrolled;
        }

        return ConstrainedBox(
          constraints: BoxConstraints(minHeight: minHeight, maxHeight: maxHeight),
          child: scrolled,
        );
      },
    );
  }
}
