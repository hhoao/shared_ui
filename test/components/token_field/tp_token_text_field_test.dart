import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_ui/shared_ui.dart';

void main() {
  const tokenPattern = r'#\w+';
  final pattern = RegExp(tokenPattern);

  TpTokenPalette resolvePalette(String token, ColorScheme colorScheme) {
    return (
      background: const Color(0xFFAABBCC),
      foreground: const Color(0xFF112233),
    );
  }

  Widget wrap(Widget child) {
    return MaterialApp(
      home: TpTheme(
        data: TpThemeData.fromColorScheme(
          ColorScheme.fromSeed(seedColor: Colors.orange),
          scale: 1.0,
        ),
        child: Scaffold(body: Padding(padding: const EdgeInsets.all(16), child: child)),
      ),
    );
  }

  testWidgets('TpTokenTextField builds with token chip mirror', (tester) async {
    final controller = TextEditingController(text: 'hello #token world');
    final focusNode = FocusNode();
    addTearDown(() {
      controller.dispose();
      focusNode.dispose();
    });

    await tester.pumpWidget(
      wrap(
        TpTokenTextField(
          controller: controller,
          focusNode: focusNode,
          hint: 'Type here',
          enabled: true,
          onChanged: (_) {},
          textStyle: const TextStyle(fontSize: 14, height: 1.5, color: Colors.black),
          hintStyle: const TextStyle(fontSize: 14, color: Colors.grey),
          cursorColor: Colors.blue,
          tokenPattern: pattern,
          resolveTokenPalette: resolvePalette,
        ),
      ),
    );

    expect(find.byType(TpTokenTextField), findsOneWidget);
    expect(find.byType(TpTokenChipMirror), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  test('buildTpTokenMirrorLayoutSpans keeps token glyphs transparent', () {
    const style = TextStyle(fontSize: 14, height: 1.5, color: Colors.black);
    final spans = buildTpTokenMirrorLayoutSpans(
      text: 'hello #token world',
      baseStyle: style,
      tokenPattern: pattern,
    );

    expect(spans.length, 3);
    expect((spans[0] as TextSpan).text, 'hello ');
    final token = spans[1] as TextSpan;
    expect(token.text, '#token');
    expect(token.style?.color, Colors.transparent);
  });

  test('applyTpTokenBackspace deletes whole token when caret inside', () {
    final value = TextEditingValue(
      text: 'hello #token world',
      selection: const TextSelection.collapsed(offset: 10),
    );

    final updated = applyTpTokenBackspace(value, pattern);
    expect(updated, isNotNull);
    expect(updated!.text, 'hello  world');
    expect(updated.selection.baseOffset, 6);
  });

  test('applyTpTokenDelete deletes whole token when caret at start', () {
    final value = TextEditingValue(
      text: 'hello #token world',
      selection: const TextSelection.collapsed(offset: 6),
    );

    final updated = applyTpTokenDelete(value, pattern);
    expect(updated, isNotNull);
    expect(updated!.text, 'hello  world');
    expect(updated.selection.baseOffset, 6);
  });
}
