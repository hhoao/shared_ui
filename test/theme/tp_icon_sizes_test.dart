import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_ui/shared_ui.dart';

void main() {
  test('fromScale uses baseline sizes at multiplier 1.0', () {
    final resolved = TpIconSizes.fromScale(1.0);
    expect(resolved.sm, TpIconSizes.smBase);
    expect(resolved.md, TpIconSizes.mdBase);
    expect(resolved.lg, TpIconSizes.lgBase);
    expect(resolved.hero, TpIconSizes.heroBase);
  });

  test('resolveIconMultiplier tracks OS text baseline only', () {
    const osBaseline = 1.5;
    final mapped = TpIconSizes.resolveIconMultiplier(textBaseline: osBaseline);
    expect(mapped, TpIconSizes.baselineScale * osBaseline);
  });

  test('resolveIconMultiplier ignores in-app text-size multiplier', () {
    const baseline = 1.0;
    expect(
      TpIconSizes.resolveIconMultiplier(textBaseline: baseline),
      TpIconSizes.baselineScale,
    );
  });

  test('iconSizeForTextFontSize keeps md paired to bodyLarge at scale 1.0', () {
    expect(
      TpIconSizes.iconSizeForTextFontSize(
        16,
        textBaseAtScale1: 16,
      ),
      TpIconSizes.mdBase * TpIconSizes.baselineScale,
    );
  });

  test('iconSizeForTextFontSize tracks resolved label fontSize', () {
    const fontSize = 19.2;
    final icon = TpIconSizes.iconSizeForTextFontSize(
      fontSize,
      textBaseAtScale1: 16,
    );
    expect(
      icon / fontSize,
      (TpIconSizes.mdBase * TpIconSizes.baselineScale) / 16,
    );
  });

  test('iconTheme uses md × scale and tpIcon color', () {
    final scheme = ColorScheme.fromSeed(seedColor: const Color(0xFFD4A06A));
    final theme = TpIconSizes.iconTheme(scheme, scale: 1.32);
    expect(theme.size, TpIconSizes.mdBase * 1.32);
    expect(theme.color, scheme.tpIcon);
  });
}
