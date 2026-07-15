import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_ui/shared_ui.dart';

void main() {
  testWidgets('TpTheme exposes spacing and icon sizes', (tester) async {
    late BuildContext captured;
    await tester.pumpWidget(
      TpTheme(
        data: TpThemeData.fromColorScheme(
          ColorScheme.fromSeed(seedColor: const Color(0xFFD4A06A)),
          scale: 1.0,
        ),
        child: Builder(
          builder: (context) {
            captured = context;
            return const SizedBox();
          },
        ),
      ),
    );
    expect(captured.tpSpacing.md, 12);
    expect(captured.tpIconSizes.md, greaterThan(0));
    expect(TpTheme.of(captured).spacing.scale, 1.0);
  });

  testWidgets('scale 1.0 resolves baseline token values', (tester) async {
    late BuildContext captured;
    await tester.pumpWidget(
      TpTheme(
        data: TpThemeData.fromColorScheme(
          ColorScheme.fromSeed(seedColor: const Color(0xFFD4A06A)),
          scale: 1.0,
        ),
        child: Builder(
          builder: (context) {
            captured = context;
            return const SizedBox();
          },
        ),
      ),
    );
    final theme = captured.tpTheme;
    expect(captured.tpIconSizes.md, 18);
    expect(theme.control.medium.height, 26);
    expect(theme.control.radius, 8);
    expect(theme.typography.bodySize, 14);
  });

  testWidgets('scale 2.0 doubles spacing and icon sizes', (tester) async {
    late BuildContext captured;
    await tester.pumpWidget(
      TpTheme(
        data: TpThemeData.fromColorScheme(
          ColorScheme.fromSeed(seedColor: const Color(0xFFD4A06A)),
          scale: 2.0,
        ),
        child: Builder(
          builder: (context) {
            captured = context;
            return const SizedBox();
          },
        ),
      ),
    );
    expect(captured.tpSpacing.md, 24);
    expect(captured.tpIconSizes.md, 36);
  });

  testWidgets('maybeOf is null without ancestor and non-null with one',
      (tester) async {
    late BuildContext outside;
    late BuildContext inside;
    await tester.pumpWidget(
      Builder(
        builder: (context) {
          outside = context;
          return TpTheme(
            data: TpThemeData.fallback(),
            child: Builder(
              builder: (context) {
                inside = context;
                return const SizedBox();
              },
            ),
          );
        },
      ),
    );
    expect(TpTheme.maybeOf(outside), isNull);
    expect(TpTheme.maybeOf(inside), isNotNull);
  });

  testWidgets('of returns fallback when no TpTheme ancestor', (tester) async {
    late BuildContext captured;
    await tester.pumpWidget(
      Builder(
        builder: (context) {
          captured = context;
          return const SizedBox();
        },
      ),
    );
    final theme = TpTheme.of(captured);
    expect(theme.spacing.scale, 1.0);
    expect(theme.spacing.md, 12);
    expect(theme.iconSizes.md, 18);
    expect(theme.control.radius, 8);
    expect(theme.typography.bodySize, 14);
  });
}
