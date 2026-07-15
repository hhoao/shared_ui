import 'package:flutter/material.dart';

import 'tp_theme_data.dart';
import 'tokens/tp_icon_sizes.dart';
import 'tokens/tp_spacing.dart';

/// Inherited design-system theme. Read via [TpTheme.of] / [BuildContext.tpTheme].
class TpTheme extends InheritedWidget {
  const TpTheme({super.key, required this.data, required super.child});

  final TpThemeData data;

  /// Returns the nearest [TpTheme] data, or [TpThemeData.fallback] if absent.
  static TpThemeData of(BuildContext context) =>
      maybeOf(context) ?? TpThemeData.fallback();

  static TpThemeData? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<TpTheme>()?.data;

  @override
  bool updateShouldNotify(TpTheme oldWidget) => data != oldWidget.data;
}

extension TpThemeContext on BuildContext {
  TpThemeData get tpTheme => TpTheme.of(this);
  TpSpacing get tpSpacing => tpTheme.spacing;
  TpIconSizes get tpIconSizes => tpTheme.iconSizes;
}
