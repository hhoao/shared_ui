import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_ui/shared_ui.dart';

void main() {
  test('fromColorScheme maps accents and uses surfaceContainer background', () {
    final scheme = ColorScheme.fromSeed(seedColor: Colors.teal);
    final theme = TpToastTheme.fromColorScheme(scheme);
    expect(theme.backgroundColor, scheme.surfaceContainer);
    expect(theme.foregroundColor, scheme.onSurface);
    expect(theme.accentFor(TpToastVariant.info), scheme.primary);
    expect(theme.accentFor(TpToastVariant.success), scheme.secondary);
    expect(theme.accentFor(TpToastVariant.warning), scheme.primary);
    expect(theme.accentFor(TpToastVariant.error), scheme.error);
    expect(theme.borderRadius, BorderRadius.circular(10));
  });

  test('TpThemeData.toastTheme resolves override', () {
    final scheme = ColorScheme.fromSeed(seedColor: Colors.orange);
    final data = TpThemeData.fromColorScheme(
      scheme,
      scale: 1,
      toast: TpToastTheme.fromColorScheme(
        scheme,
        backgroundColor: const Color(0xFF112233),
      ),
    );
    expect(data.toastTheme.backgroundColor, const Color(0xFF112233));
  });
}
