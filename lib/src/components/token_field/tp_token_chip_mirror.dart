import 'package:flutter/material.dart';

import 'tp_token_palette.dart';

/// Visual bleed on the left only; right edge stays at the layout token end.
const double tpTokenPillLeftBleed = 4;

/// Inner horizontal inset reserved when measuring chip chrome (legacy).
const double tpTokenPillHorizontalPadding = 6;

List<InlineSpan> buildTpTokenMirrorLayoutSpans({
  required String text,
  required TextStyle baseStyle,
  required RegExp tokenPattern,
  ColorScheme? colorScheme,
  TpTokenPaletteResolver? resolvePalette,
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

/// Background-only chip chrome — one [Positioned] pill per layout [TextBox].
///
/// Token glyphs are painted by the mirror [Text.rich] spans; wrapping a long
/// `@path` must not squeeze the full string through [FittedBox].
List<Widget> buildTpTokenPillOverlays({
  required String text,
  required TextStyle baseStyle,
  required ColorScheme colorScheme,
  required TextPainter painter,
  required RegExp tokenPattern,
  required TpTokenPaletteResolver resolvePalette,
}) {
  final overlays = <Widget>[];
  for (final match in tokenPattern.allMatches(text)) {
    final token = match.group(0)!;
    final palette = resolvePalette(token, colorScheme);
    final boxes = painter.getBoxesForSelection(
      TextSelection(baseOffset: match.start, extentOffset: match.end),
    );
    if (boxes.isEmpty) continue;

    for (final box in boxes) {
      overlays.add(
        Positioned(
          left: box.left - tpTokenPillLeftBleed,
          top: box.top + 1,
          width: tpTokenPillWidth(box.right - box.left),
          height: box.bottom - box.top - 2,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: palette.background,
              borderRadius: BorderRadius.circular(6),
            ),
          ),
        ),
      );
    }
  }
  return overlays;
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

    final content = ClipRect(
      clipBehavior: Clip.none,
      child: Transform.translate(
        offset: Offset(0, -scrollOffset),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final layoutSpans = buildTpTokenMirrorLayoutSpans(
              text: text,
              baseStyle: baseStyle,
              tokenPattern: tokenPattern,
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

            return SizedBox(
              width: constraints.maxWidth,
              height: expands
                  ? constraints.maxHeight
                  : painter.height,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  // Backgrounds under glyphs so opaque pills do not cover text.
                  ...buildTpTokenPillOverlays(
                    text: text,
                    baseStyle: baseStyle,
                    colorScheme: cs,
                    painter: painter,
                    tokenPattern: tokenPattern,
                    resolvePalette: resolvePalette,
                  ),
                  Text.rich(
                    TextSpan(children: layoutSpans),
                    maxLines: expands ? null : maxLines,
                    strutStyle: strutStyle,
                  ),
                ],
              ),
            );
          },
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
