import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
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

    final ink = tester.widget<Ink>(find.descendant(
      of: find.byType(TpIconButton),
      matching: find.byType(Ink),
    ));
    final decoration = ink.decoration! as BoxDecoration;
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

    final ink = tester.widget<Ink>(find.descendant(
      of: find.byType(TpIconButton),
      matching: find.byType(Ink),
    ));
    final decoration = ink.decoration! as BoxDecoration;
    expect(decoration.color, Colors.transparent);
    // Border still applies when selected.
    expect(decoration.border?.top.color, scheme.primary.withValues(alpha: 0.28));
    expect(tester.widget<Icon>(find.byIcon(Icons.menu)).color, Colors.red);
  });
}
