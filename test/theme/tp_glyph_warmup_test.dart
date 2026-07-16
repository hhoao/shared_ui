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

  test('shapeAll runs without throw', () {
    TpGlyphWarmup.shapeAll(
      styles: const [
        TextStyle(fontSize: 14),
        TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
      ],
      glyphs: 'ABC中文',
    );
  });
}
