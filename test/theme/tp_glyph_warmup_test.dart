import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_ui/shared_ui.dart';

void main() {
  test('dedupeByShapeKey collapses color-only variants', () {
    const base = TextStyle(
      fontFamily: 'UI',
      fontSize: 14,
      fontWeight: FontWeight.w400,
    );
    final styles = TpGlyphWarmup.dedupeByShapeKey([
      base,
      base.copyWith(color: Colors.red),
      base.copyWith(height: 1.5),
      base.copyWith(fontWeight: FontWeight.w600),
    ]);
    expect(styles, hasLength(2));
  });

  test('shapeAll accepts strutFor without throw', () {
    TpGlyphWarmup.shapeAll(
      styles: const [
        TextStyle(fontSize: 14, height: 1.7),
      ],
      glyphs: 'Aa中',
      strutFor: (style) => StrutStyle(
        fontSize: style.fontSize,
        height: style.height,
        forceStrutHeight: true,
      ),
    );
  });

  test('styleProbe is a short fixed sample, not a charset dump', () {
    expect(TpGlyphWarmup.styleProbe.length, lessThan(16));
    expect(TpGlyphWarmup.styleProbe, contains('中'));
  });

  test('shapeAll defaults to styleProbe', () {
    TpGlyphWarmup.shapeAll(
      styles: const [
        TextStyle(fontSize: 14, height: 1.7),
      ],
    );
  });

  test('shapeRich lays out mixed UI bold + mono under forced strut', () {
    const ui = TextStyle(
      fontFamily: 'UI',
      fontSize: 14,
      height: 1.7,
      fontWeight: FontWeight.w700,
    );
    const mono = TextStyle(
      fontFamily: 'Mono',
      fontSize: 14,
      height: 1.7,
    );
    TpGlyphWarmup.shapeRich(
      text: TextSpan(
        style: ui,
        children: const [
          TextSpan(text: TpGlyphWarmup.styleProbe, style: ui),
          TextSpan(text: 'x', style: mono),
          TextSpan(text: TpGlyphWarmup.styleProbe, style: ui),
        ],
      ),
      strutStyle: const StrutStyle(
        fontFamily: 'UI',
        fontSize: 14,
        height: 1.7,
        forceStrutHeight: true,
      ),
    );
  });
}
