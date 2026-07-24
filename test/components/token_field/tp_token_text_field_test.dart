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

  testWidgets(
    'skips chip mirror when text has no token matches',
    (tester) async {
      // Dual TextField+mirror layout paid ~580ms RenderParagraph on landing
      // first-open (test55) even with empty compose — mirror is only needed
      // when chips are visible.
      const style = TextStyle(fontSize: 14, height: 1.5, color: Colors.black);
      final empty = TextEditingController();
      final plain = TextEditingController(text: 'hello world');
      final focusEmpty = FocusNode();
      final focusPlain = FocusNode();
      addTearDown(() {
        empty.dispose();
        plain.dispose();
        focusEmpty.dispose();
        focusPlain.dispose();
      });

      await tester.pumpWidget(
        wrap(
          Column(
            children: [
              TpTokenTextField(
                controller: empty,
                focusNode: focusEmpty,
                hint: 'Type here',
                enabled: true,
                onChanged: (_) {},
                textStyle: style,
                hintStyle: const TextStyle(fontSize: 14, color: Colors.grey),
                cursorColor: Colors.blue,
                tokenPattern: pattern,
                resolveTokenPalette: resolvePalette,
              ),
              TpTokenTextField(
                controller: plain,
                focusNode: focusPlain,
                hint: 'Type here',
                enabled: true,
                onChanged: (_) {},
                textStyle: style,
                hintStyle: const TextStyle(fontSize: 14, color: Colors.grey),
                cursorColor: Colors.blue,
                tokenPattern: pattern,
                resolveTokenPalette: resolvePalette,
              ),
            ],
          ),
        ),
      );

      expect(find.byType(TpTokenChipMirror), findsNothing);
      final fields = tester.widgetList<TextField>(find.byType(TextField)).toList();
      expect(fields, hasLength(2));
      expect(fields[0].style?.color, Colors.black);
      expect(fields[1].style?.color, Colors.black);
    },
  );

  testWidgets(
    'mounts chip mirror when a token appears, unmounts when gone',
    (tester) async {
      const style = TextStyle(fontSize: 14, height: 1.5, color: Colors.black);
      final controller = TextEditingController(text: 'hello');
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
            textStyle: style,
            hintStyle: const TextStyle(fontSize: 14, color: Colors.grey),
            cursorColor: Colors.blue,
            tokenPattern: pattern,
            resolveTokenPalette: resolvePalette,
          ),
        ),
      );
      expect(find.byType(TpTokenChipMirror), findsNothing);

      controller.text = 'hello #token';
      await tester.pump();
      expect(find.byType(TpTokenChipMirror), findsOneWidget);
      expect(
        tester.widget<TextField>(find.byType(TextField)).style?.color,
        Colors.transparent,
      );

      controller.text = 'hello';
      await tester.pump();
      expect(find.byType(TpTokenChipMirror), findsNothing);
      expect(
        tester.widget<TextField>(find.byType(TextField)).style?.color,
        Colors.black,
      );
    },
  );

  testWidgets(
    'keeps EditableText after last token delete and still accepts input',
    (tester) async {
      // Regression: Stack slot shift remounted EditableText when mirror
      // unmounted, leaving IME dead while FocusNode stayed focused.
      const style = TextStyle(fontSize: 14, height: 1.5, color: Colors.black);
      final controller = TextEditingController(text: 'hello #token');
      final focusNode = FocusNode();
      addTearDown(() {
        controller.dispose();
        focusNode.dispose();
      });

      await tester.pumpWidget(
        wrap(
          SizedBox(
            height: 120,
            child: TpTokenTextField(
              controller: controller,
              focusNode: focusNode,
              hint: 'Type here',
              enabled: true,
              onChanged: (_) {},
              textStyle: style,
              hintStyle: const TextStyle(fontSize: 14, color: Colors.grey),
              cursorColor: Colors.blue,
              tokenPattern: pattern,
              resolveTokenPalette: resolvePalette,
              expands: true,
              minLines: 3,
              maxLines: 3,
            ),
          ),
        ),
      );

      focusNode.requestFocus();
      await tester.pump();
      expect(find.byType(TpTokenChipMirror), findsOneWidget);
      final editableBefore = tester.element(find.byType(EditableText));

      final deleted = applyTpTokenBackspace(
        TextEditingValue(
          text: controller.text,
          selection: TextSelection.collapsed(offset: controller.text.length),
        ),
        pattern,
      );
      expect(deleted, isNotNull);
      controller.value = deleted!;
      await tester.pump();

      expect(find.byType(TpTokenChipMirror), findsNothing);
      expect(
        identical(editableBefore, tester.element(find.byType(EditableText))),
        isTrue,
      );

      await tester.enterText(find.byType(TextField), 'typed after delete');
      expect(controller.text, 'typed after delete');
    },
  );

  testWidgets(
    'expands without nesting LayoutBuilder around the TextField',
    (tester) async {
      final controller = TextEditingController();
      final focusNode = FocusNode();
      addTearDown(() {
        controller.dispose();
        focusNode.dispose();
      });

      await tester.pumpWidget(
        wrap(
          SizedBox(
            height: 120,
            child: TpTokenTextField(
              controller: controller,
              focusNode: focusNode,
              hint: 'Type here',
              enabled: true,
              onChanged: (_) {},
              textStyle: const TextStyle(
                fontSize: 14,
                height: 1.5,
                color: Colors.black,
              ),
              hintStyle: const TextStyle(fontSize: 14, color: Colors.grey),
              cursorColor: Colors.blue,
              tokenPattern: pattern,
              resolveTokenPalette: resolvePalette,
              expands: true,
              minLines: 3,
              maxLines: 3,
            ),
          ),
        ),
      );

      // LayoutBuilder around TextField forces BUILD during parent layout and
      // spikes workspace landing first-open (see DevTools test48).
      var nested = false;
      tester.element(find.byType(TextField)).visitAncestorElements((ancestor) {
        if (ancestor.widget is TpTokenTextField) return false;
        if (ancestor.widget is LayoutBuilder) {
          nested = true;
          return false;
        }
        return true;
      });
      expect(nested, isFalse);

      focusNode.requestFocus();
      await tester.pump();
      await tester.enterText(find.byType(TextField), 'ok');
      expect(controller.text, 'ok');
    },
  );

  test('buildTpTokenMirrorLayoutSpans paints token glyphs with palette color', () {
    const style = TextStyle(fontSize: 14, height: 1.5, color: Colors.black);
    const scheme = ColorScheme.light();
    final spans = buildTpTokenMirrorLayoutSpans(
      text: 'hello #token world',
      baseStyle: style,
      tokenPattern: pattern,
      colorScheme: scheme,
      resolvePalette: resolvePalette,
    );

    expect(spans.length, 3);
    expect((spans[0] as TextSpan).text, 'hello ');
    final token = spans[1] as TextSpan;
    expect(token.text, '#token');
    expect(token.style?.color, const Color(0xFF112233));
    expect(token.style?.fontWeight, style.fontWeight);
  });

  test('buildTpTokenPillOverlays emits one background per wrapped line box', () {
    const style = TextStyle(fontSize: 14, height: 1.5, color: Colors.black);
    const path =
        '@/home/user/Documents/TeamPilot/Attachments/'
        'abcdef12-3456-7890-abcd-ef1234567890.png';
    final painter = TextPainter(
      text: TextSpan(text: path, style: style),
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: 120);
    final boxes = painter.getBoxesForSelection(
      TextSelection(baseOffset: 0, extentOffset: path.length),
    );
    expect(boxes.length, greaterThan(1));

    final overlays = buildTpTokenPillOverlays(
      text: path,
      baseStyle: style,
      colorScheme: const ColorScheme.light(),
      painter: painter,
      tokenPattern: RegExp(r'@\S+'),
      resolvePalette: resolvePalette,
    );

    expect(overlays, hasLength(boxes.length));
  });

  testWidgets('token chip mirror has no FittedBox scaleDown label', (
    tester,
  ) async {
    await tester.pumpWidget(
      wrap(
        SizedBox(
          width: 160,
          child: TpTokenChipMirror(
            text:
                '@/home/user/Documents/TeamPilot/Attachments/'
                'abcdef12-3456-7890-abcd-ef1234567890.png',
            baseStyle: const TextStyle(fontSize: 14, height: 1.5),
            minLines: 1,
            maxLines: 8,
            tokenPattern: RegExp(r'@\S+'),
            resolvePalette: resolvePalette,
          ),
        ),
      ),
    );

    expect(find.byType(FittedBox), findsNothing);
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
