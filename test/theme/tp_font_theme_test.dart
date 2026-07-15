import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_ui/shared_ui.dart';

void main() {
  testWidgets('tpFonts reads TpFontTheme from ThemeData', (tester) async {
    late TpFontTheme captured;
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(
          extensions: const [
            TpFontTheme(
              uiFontFamily: 'Noto Sans SC',
              monoFontFamily: 'JetBrains Mono',
              monoFontFamilyFallback: ['monospace'],
            ),
          ],
        ),
        home: Builder(
          builder: (context) {
            captured = context.tpFonts;
            return const SizedBox();
          },
        ),
      ),
    );

    expect(captured.uiFontFamily, 'Noto Sans SC');
    expect(captured.monoFontFamily, 'JetBrains Mono');
  });

  test('fallback mono is monospace', () {
    expect(TpFontTheme.fallback.monoFontFamily, 'monospace');
  });

  test('copyWith and lerp', () {
    const a = TpFontTheme(
      monoFontFamily: 'A',
      monoFontFamilyFallback: ['a'],
    );
    const b = TpFontTheme(
      monoFontFamily: 'B',
      monoFontFamilyFallback: ['b'],
    );
    expect(a.copyWith(monoFontFamily: 'C').monoFontFamily, 'C');
    expect(a.lerp(b, 0.0).monoFontFamily, 'A');
    expect(a.lerp(b, 1.0).monoFontFamily, 'B');
  });
}
