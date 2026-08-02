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
/// Warm **TextStyle fingerprints** (family / size / weight / style), not an
/// unbounded content charset. Hosts pass styles from `stylesForWarmup`; use
/// [styleProbe] as the layout sample — enough to open each style's path.
abstract final class TpGlyphWarmup {
  TpGlyphWarmup._();

  /// Fixed short sample for [shape] / [shapeAll] — Latin + one CJK + punct.
  ///
  /// Do not expand this into l10n dumps; arbitrary UI/Markdown text is infinite.
  static const String styleProbe = 'Ag中.';

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
  ///
  /// Pass [strutStyle] when the live UI uses forced strut (e.g. markdown
  /// preview) so first paint does not pay a cold strut layout path.
  static void shape({
    required TextStyle style,
    String glyphs = styleProbe,
    double maxWidth = 1200,
    StrutStyle? strutStyle,
  }) {
    shapeRich(
      text: TextSpan(text: glyphs, style: style),
      maxWidth: maxWidth,
      strutStyle: strutStyle,
    );
  }

  /// Lays out a rich [text] tree (mixed families / weights) once.
  ///
  /// Covers paths a single-style [shape] cannot: e.g. markdown strong text
  /// wrapping an inline mono code span under [forceStrutHeight].
  static void shapeRich({
    required InlineSpan text,
    double maxWidth = 1200,
    StrutStyle? strutStyle,
  }) {
    final painter = TextPainter(
      text: text,
      textDirection: TextDirection.ltr,
      strutStyle: strutStyle,
    )..layout(maxWidth: maxWidth);
    painter.dispose();
  }

  static void shapeAll({
    required Iterable<TextStyle> styles,
    String glyphs = styleProbe,
    double maxWidth = 1200,
    StrutStyle? Function(TextStyle style)? strutFor,
  }) {
    for (final style in styles) {
      shape(
        style: style,
        glyphs: glyphs,
        maxWidth: maxWidth,
        strutStyle: strutFor?.call(style),
      );
    }
  }
}
