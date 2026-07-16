import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_ui/shared_ui.dart';

void main() {
  testWidgets('md tracks bodyMedium size', (tester) async {
    late TextStyle md;
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(
          textTheme: const TextTheme(
            bodyMedium: TextStyle(fontSize: 15),
          ),
        ),
        home: Builder(
          builder: (context) {
            md = TpTextStyles.of(context).md;
            return const SizedBox();
          },
        ),
      ),
    );
    expect(md.fontSize, 15);
    expect(md.height, 1.35);
  });

  testWidgets('mono uses TpFontTheme', (tester) async {
    late TextStyle mono;
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(
          extensions: const [
            TpFontTheme(
              monoFontFamily: 'JetBrains Mono',
              monoFontFamilyFallback: ['Noto Sans SC', 'monospace'],
            ),
          ],
        ),
        home: Builder(
          builder: (context) {
            mono = TpTextStyles.of(context).mono;
            return const SizedBox();
          },
        ),
      ),
    );
    expect(mono.fontFamily, 'JetBrains Mono');
    expect(mono.fontFamilyFallback, ['Noto Sans SC', 'monospace']);
  });

  test('stylesForWarmup includes mono and italic', () {
    final theme = ThemeData(
      extensions: const [
        TpFontTheme(
          uiFontFamily: 'UI',
          monoFontFamily: 'Mono',
          monoFontFamilyFallback: ['monospace'],
        ),
      ],
    );
    final styles = TpTextStyles(theme).stylesForWarmup();
    expect(styles, isNotEmpty);
    expect(styles.any((s) => s.fontFamily == 'Mono'), isTrue);
    expect(styles.any((s) => s.fontStyle == FontStyle.italic), isTrue);
  });
}
