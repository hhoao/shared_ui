import 'package:flutter/material.dart';

import 'tp_theme_data.dart';
import 'tokens/tp_control_metrics.dart';
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
  TpControlMetrics get tpControl => tpTheme.control;

  /// Resolved default icon size from [ThemeData.iconTheme].
  double get tpIconSize => IconTheme.of(this).size ?? tpIconSizes.md;

  /// Resolved default icon color from [ThemeData.iconTheme].
  Color get tpIconColor =>
      IconTheme.of(this).color ?? Theme.of(this).colorScheme.tpIcon;
}
