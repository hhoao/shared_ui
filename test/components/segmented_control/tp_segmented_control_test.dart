import 'package:flutter/material.dart';
import '../../support/tp_test_widgets.dart';
import 'package:shared_ui/shared_ui.dart';

void main() {
  group('computeTpSegmentedControlWidths', () {
    test('widens segments for longer labels and larger font', () {
      const labels = ['浅色', '深色', '跟随系统'];
      final small = computeTpSegmentedControlWidths(
        labels: labels,
        fontSize: 14,
        iconSize: 18,
        textStyle: const TextStyle(fontSize: 14),
        icons: const [
          Icons.light_mode_outlined,
          Icons.dark_mode_outlined,
          Icons.desktop_windows_outlined,
        ],
      );
      final large = computeTpSegmentedControlWidths(
        labels: labels,
        fontSize: 22,
        iconSize: 18,
        textStyle: const TextStyle(fontSize: 22),
        icons: const [
          Icons.light_mode_outlined,
          Icons.dark_mode_outlined,
          Icons.desktop_windows_outlined,
        ],
      );
      expect(large[2], greaterThan(small[2]));
      expect(large[2], greaterThan(100));
    });

    test('respects minSegmentWidth floor', () {
      final widths = computeTpSegmentedControlWidths(
        labels: const ['A'],
        fontSize: 12,
        iconSize: 16,
        textStyle: const TextStyle(fontSize: 12),
        minSegmentWidth: 120,
      );
      expect(widths.single, 120);
    });
  });

  testWidgets('uses compact height by default', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(useMaterial3: true),
        home: TpTheme(
          data: TpThemeData.fromColorScheme(
            ColorScheme.fromSeed(seedColor: Colors.orange),
            scale: 1.0,
          ),
          child: Scaffold(
            body: Center(
              child: TpSegmentedControl(
                totalSwitches: 2,
                initialLabelIndex: 0,
                labels: const ['浮动', '中间'],
                icons: const [
                  Icons.dashboard_customize_outlined,
                  Icons.vertical_split_outlined,
                ],
                onToggle: (_) {},
              ),
            ),
          ),
        ),
      ),
    );
    final size = tester.getSize(find.byType(TpSegmentedControl));
    expect(size.height, closeTo(tpSegmentedControlMinHeight, 0.5));
  });

  testWidgets('shows full label text at large typography scale', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(
          useMaterial3: true,
          textTheme: const TextTheme(bodyMedium: TextStyle(fontSize: 22)),
        ),
        home: TpTheme(
          data: TpThemeData.fromColorScheme(
            ColorScheme.fromSeed(seedColor: Colors.orange),
            scale: 1.0,
          ),
          child: Scaffold(
            body: Center(
              child: TpSegmentedControl(
                totalSwitches: 3,
                initialLabelIndex: 2,
                labels: const ['浅色', '深色', '跟随系统'],
                icons: const [
                  Icons.light_mode_outlined,
                  Icons.dark_mode_outlined,
                  Icons.desktop_windows_outlined,
                ],
                onToggle: (_) {},
              ),
            ),
          ),
        ),
      ),
    );
    expect(find.text('跟随系统'), findsOneWidget);
  });

  testWidgets('uses ColorScheme roles without workspace surfaces', (
    tester,
  ) async {
    final scheme = ColorScheme.fromSeed(
      seedColor: Colors.teal,
      brightness: Brightness.light,
    );
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(useMaterial3: true, colorScheme: scheme),
        home: TpTheme(
          data: TpThemeData.fromColorScheme(scheme, scale: 1.0),
          child: Scaffold(
            body: TpSegmentedControl(
              totalSwitches: 2,
              initialLabelIndex: 0,
              labels: const ['A', 'B'],
              onToggle: (_) {},
            ),
          ),
        ),
      ),
    );
    expect(find.byType(TpSegmentedControl), findsOneWidget);
    // Smoke: inactive track should resolve against surfaceContainerHighest.
    expect(scheme.surfaceContainerHighest, isNot(equals(scheme.surface)));
  });

  testWidgets('selected segment label stays white even when onPrimary is dark', (
    tester,
  ) async {
    // Amber-like primary yields black onPrimary from Material contrast.
    final scheme = ColorScheme.fromSeed(
      seedColor: const Color(0xFFD4A06A),
      brightness: Brightness.light,
    ).copyWith(onPrimary: Colors.black, onSurface: const Color(0xFF1A1A1A));
    expect(scheme.onPrimary, isNot(Colors.white));

    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: scheme,
          textTheme: TextTheme(
            labelLarge: TextStyle(fontSize: 14, color: scheme.onSurface),
          ),
        ),
        home: TpTheme(
          data: TpThemeData.fromColorScheme(scheme, scale: 1.0),
          child: Scaffold(
            body: TpSegmentedControl(
              totalSwitches: 2,
              initialLabelIndex: 0,
              labels: const ['主页', '恢复'],
              onToggle: (_) {},
            ),
          ),
        ),
      ),
    );

    final activeColor = tester.widget<Text>(find.text('主页')).style?.color;
    final inactiveColor = tester.widget<Text>(find.text('恢复')).style?.color;
    expect(activeColor, Colors.white);
    expect(inactiveColor, isNot(Colors.white));
  });

  testWidgets('optional per-segment tooltips are wired', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(useMaterial3: true),
        home: TpTheme(
          data: TpThemeData.fromColorScheme(
            ColorScheme.fromSeed(seedColor: Colors.orange),
            scale: 1.0,
          ),
          child: Scaffold(
            body: TpSegmentedControl(
              totalSwitches: 2,
              initialLabelIndex: 0,
              labels: const ['', ''],
              icons: const [
                Icons.chat_bubble_outline_rounded,
                Icons.terminal_rounded,
              ],
              tooltips: const ['Chat', 'Terminal'],
              onToggle: (_) {},
            ),
          ),
        ),
      ),
    );

    expect(find.byTooltip('Chat'), findsOneWidget);
    expect(find.byTooltip('Terminal'), findsOneWidget);
    expect(find.byType(TpHover), findsNWidgets(2));
  });
}
