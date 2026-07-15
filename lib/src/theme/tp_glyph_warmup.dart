import 'package:flutter/painting.dart';

/// Glyph-cache fingerprint: family / size / weight / style.
///
/// Height, letterSpacing, color, and decoration do not need separate shaping
/// for the same glyphs.
typedef TpTextStyleShapeKey = ({
  String? family,
  double? size,
  FontWeight? weight,
  FontStyle? style,
});

/// Pure glyph-shaping helpers for boot warmup.
///
/// Hosts supply the glyph charset (often generated from l10n) and any extra
/// styles (markdown, outline input). Semantic UI styles come from
/// [TpTextStyles.stylesForWarmup].
abstract final class TpGlyphWarmup {
  TpGlyphWarmup._();

  static TpTextStyleShapeKey shapeKey(TextStyle style) => (
    family: style.fontFamily,
    size: style.fontSize,
    weight: style.fontWeight,
    style: style.fontStyle,
  );

  /// Keeps the first style for each [shapeKey] — same coverage, less work.
  static List<TextStyle> dedupeByShapeKey(Iterable<TextStyle> styles) {
    final seen = <TpTextStyleShapeKey>{};
    final out = <TextStyle>[];
    for (final style in styles) {
      if (seen.add(shapeKey(style))) {
        out.add(style);
      }
    }
    return out;
  }

  /// Lays out [glyphs] once with [style] to populate the glyph cache.
  static void shape({
    required TextStyle style,
    required String glyphs,
    double maxWidth = 1200,
  }) {
    final painter = TextPainter(
      text: TextSpan(text: glyphs, style: style),
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: maxWidth);
    painter.dispose();
  }

  static void shapeAll({
    required Iterable<TextStyle> styles,
    required String glyphs,
    double maxWidth = 1200,
  }) {
    for (final style in styles) {
      shape(style: style, glyphs: glyphs, maxWidth: maxWidth);
    }
  }
}
