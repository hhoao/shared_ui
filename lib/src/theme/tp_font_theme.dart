import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Font families attached to [ThemeData.extensions].
///
/// Host apps resolve concrete faces (bundled Google Fonts, system, etc.) and
/// install this extension; [TpTextStyles.mono] and glyph warmup read it.
@immutable
final class TpFontTheme extends ThemeExtension<TpFontTheme> {
  const TpFontTheme({
    this.uiFontFamily,
    this.uiFontFamilyFallback,
    required this.monoFontFamily,
    required this.monoFontFamilyFallback,
  });

  final String? uiFontFamily;
  final List<String>? uiFontFamilyFallback;
  final String monoFontFamily;
  final List<String> monoFontFamilyFallback;

  /// Safe defaults when no extension is installed (tests / missing host wire-up).
  static const TpFontTheme fallback = TpFontTheme(
    monoFontFamily: 'monospace',
    monoFontFamilyFallback: <String>['monospace'],
  );

  @override
  TpFontTheme copyWith({
    String? uiFontFamily,
    List<String>? uiFontFamilyFallback,
    String? monoFontFamily,
    List<String>? monoFontFamilyFallback,
  }) {
    return TpFontTheme(
      uiFontFamily: uiFontFamily ?? this.uiFontFamily,
      uiFontFamilyFallback: uiFontFamilyFallback ?? this.uiFontFamilyFallback,
      monoFontFamily: monoFontFamily ?? this.monoFontFamily,
      monoFontFamilyFallback:
          monoFontFamilyFallback ?? this.monoFontFamilyFallback,
    );
  }

  @override
  TpFontTheme lerp(ThemeExtension<TpFontTheme>? other, double t) {
    if (other is! TpFontTheme) return this;
    return t < 0.5 ? this : other;
  }
}

extension TpFontThemeContext on BuildContext {
  TpFontTheme get tpFonts =>
      Theme.of(this).extension<TpFontTheme>() ?? TpFontTheme.fallback;
}
