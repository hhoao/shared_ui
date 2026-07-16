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

    final left = boxes.first.left;
    final top = boxes.map((box) => box.top).reduce((a, b) => a < b ? a : b);
    final bottom = boxes.map((box) => box.bottom).reduce((a, b) => a > b ? a : b);
    final layoutWidth = boxes.last.right - left;

    overlays.add(
      Positioned(
        left: left - tpTokenPillLeftBleed,
        top: top + 1,
        width: tpTokenPillWidth(layoutWidth),
        height: bottom - top - 2,
        child: _TpTokenPill(
          token: token,
          baseStyle: baseStyle,
          palette: palette,
        ),
      ),
    );
  }
  return overlays;
}

class _TpTokenPill extends StatelessWidget {
  const _TpTokenPill({
    required this.token,
    required this.baseStyle,
    required this.palette,
  });

  final String token;
  final TextStyle baseStyle;
  final TpTokenPalette palette;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: palette.background,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: tpTokenPillHorizontalPadding,
        ),
        child: Align(
          alignment: Alignment.centerLeft,
          child: FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              token,
              maxLines: 1,
              softWrap: false,
              style: tpTokenPillLabelStyle(baseStyle, palette.foreground),
            ),
          ),
        ),
      ),
    );
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
                  Text.rich(
                    TextSpan(children: layoutSpans),
                    maxLines: expands ? null : maxLines,
                    strutStyle: strutStyle,
                  ),
                  ...buildTpTokenPillOverlays(
                    text: text,
                    baseStyle: baseStyle,
                    colorScheme: cs,
                    painter: painter,
                    tokenPattern: tokenPattern,
                    resolvePalette: resolvePalette,
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
