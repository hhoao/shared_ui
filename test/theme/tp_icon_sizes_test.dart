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

  test('resolveIconMultiplier ignores OS text baseline', () {
    const osBaseline = 1.5;
    final mapped = TpIconSizes.resolveIconMultiplier(
      effectiveTextMultiplier: osBaseline,
      textBaseline: osBaseline,
    );
    expect(mapped, TpIconSizes.baselineScale);
    expect(mapped, lessThan(osBaseline));
  });

  test('resolveIconMultiplier tracks in-app text-size delta 1:1', () {
    const baseline = 1.0;
    const comfy = 1.15;
    final mapped = TpIconSizes.resolveIconMultiplier(
      effectiveTextMultiplier: comfy,
      textBaseline: baseline,
    );
    expect(mapped, TpIconSizes.baselineScale * comfy);
  });

  test('iconSizeForTextFontSize strips OS baseline on high-DPI', () {
    const dpr = 1.5;
    const textBase = 16.0;
    final paired = TpIconSizes.iconSizeForTextFontSize(
      textBase * dpr,
      textBaseAtScale1: textBase,
      textBaseline: dpr,
    );
    expect(paired, TpIconSizes.mdBase * TpIconSizes.baselineScale);
  });

  test('iconSizeForTextFontSize tracks in-app label growth', () {
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
