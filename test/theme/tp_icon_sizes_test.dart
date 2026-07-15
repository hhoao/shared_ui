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

  test('resolveIconMultiplier dampens user preset delta', () {
    const baseline = 1.0;
    const comfy = 1.15;
    final mapped = TpIconSizes.resolveIconMultiplier(
      effectiveTextMultiplier: comfy,
      textBaseline: baseline,
    );
    final linearMapped = TpIconSizes.baselineScale * comfy;
    expect(
      mapped,
      closeTo(
        TpIconSizes.baselineScale *
            (1.0 + (comfy - 1.0) * TpIconSizes.userScaleTracking),
        0.001,
      ),
    );
    expect(mapped, lessThan(linearMapped));
  });

  test('iconTheme uses md × scale and tpIcon color', () {
    final scheme = ColorScheme.fromSeed(seedColor: const Color(0xFFD4A06A));
    final theme = TpIconSizes.iconTheme(scheme, scale: 1.32);
    expect(theme.size, TpIconSizes.mdBase * 1.32);
    expect(theme.color, scheme.tpIcon);
  });
}
