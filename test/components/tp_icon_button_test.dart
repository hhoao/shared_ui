import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import '../support/tp_test_widgets.dart';
import 'package:shared_ui/shared_ui.dart';

void main() {
  testWidgets('TpIconButton invokes onTap', (tester) async {
    var taps = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: TpTheme(
          data: TpThemeData.fromColorScheme(
            ColorScheme.fromSeed(seedColor: Colors.orange),
            scale: 1.0,
          ),
          child: Scaffold(
            body: TpIconButton(
              icon: Icons.close,
              onTap: () => taps++,
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.byType(TpIconButton));
    expect(taps, 1);
  });

  testWidgets('TpIconButton selected applies pill-matched chrome', (tester) async {
    final scheme = ColorScheme.fromSeed(seedColor: Colors.orange);
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(colorScheme: scheme, useMaterial3: true),
        home: TpTheme(
          data: TpThemeData.fromColorScheme(scheme, scale: 1.0),
          child: Scaffold(
            body: TpIconButton(
              icon: Icons.menu,
              selected: true,
              onTap: () {},
            ),
          ),
        ),
      ),
    );

    final button = tester.widget<TpIconButton>(find.byType(TpIconButton));
    expect(button.selected, isTrue);

    final fill = tester.widget<AnimatedContainer>(find.descendant(
      of: find.byType(TpIconButton),
      matching: find.byType(AnimatedContainer),
    ));
    final decoration = fill.decoration! as BoxDecoration;
    expect(decoration.color, scheme.primary.withValues(alpha: 0.16));
    expect(decoration.border?.top.color, scheme.primary.withValues(alpha: 0.28));

    final icon = tester.widget<Icon>(find.byIcon(Icons.menu));
    expect(icon.color, scheme.primary);
  });

  testWidgets('TpIconButton selected respects explicit color and backgroundColor', (
    tester,
  ) async {
    final scheme = ColorScheme.fromSeed(seedColor: Colors.orange);
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(colorScheme: scheme, useMaterial3: true),
        home: TpTheme(
          data: TpThemeData.fromColorScheme(scheme, scale: 1.0),
          child: Scaffold(
            body: TpIconButton(
              icon: Icons.menu,
              selected: true,
              color: Colors.red,
              backgroundColor: Colors.transparent,
              onTap: () {},
            ),
          ),
        ),
      ),
    );

    final fill = tester.widget<AnimatedContainer>(find.descendant(
      of: find.byType(TpIconButton),
      matching: find.byType(AnimatedContainer),
    ));
    final decoration = fill.decoration! as BoxDecoration;
    // Fully transparent (alpha 0). TpHover shares the RGB with its hover fill
    // for a smooth Color.lerp fade, so the idle color is not literally
    // Colors.transparent — only its alpha matters.
    expect(decoration.color!.a, 0);
    // Border still applies when selected.
    expect(decoration.border?.top.color, scheme.primary.withValues(alpha: 0.28));
    expect(tester.widget<Icon>(find.byIcon(Icons.menu)).color, Colors.red);
  });

  testWidgets(
    'hover keeps opaque backgroundColor (armed delete / selected chrome)',
    (tester) async {
      const fill = Color(0xFFE53935);
      const iconColor = Color(0xFFFFFFFF);
      final scheme = ColorScheme.fromSeed(seedColor: Colors.orange);
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(colorScheme: scheme, useMaterial3: true),
          home: TpTheme(
            data: TpThemeData.fromColorScheme(scheme, scale: 1.0),
            child: Scaffold(
              body: TpIconButton(
                icon: Icons.delete_outline,
                color: iconColor,
                backgroundColor: fill,
                onTap: () {},
              ),
            ),
          ),
        ),
      );

      final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
      await gesture.addPointer(location: Offset.zero);
      addTearDown(gesture.removePointer);
      await tester.pump();
      await gesture.moveTo(tester.getCenter(find.byType(TpIconButton)));
      await tester.pumpAndSettle();

      final box = tester.widget<AnimatedContainer>(
        find.descendant(
          of: find.byType(TpIconButton),
          matching: find.byType(AnimatedContainer),
        ),
      );
      final hovered = (box.decoration! as BoxDecoration).color!;
      expect(hovered, Color.alphaBlend(iconColor.withValues(alpha: 0.12), fill));
      expect(hovered.a, closeTo(1.0, 0.001));
    },
  );
}
