import 'package:flutter/material.dart';

typedef TpToastMarginBuilder = EdgeInsetsGeometry Function(
  BuildContext context,
  AlignmentGeometry alignment,
);

/// Public toast overlay configuration for [TpToastWrapper].
class TpToastConfig {
  const TpToastConfig({
    this.alignment = AlignmentDirectional.topEnd,
    this.itemWidth = 400,
    this.maxToastLimit = 1,
    this.animationDuration = const Duration(milliseconds: 200),
    this.maxTitleLines = 3,
    this.maxDescriptionLines = 1,
    this.marginBuilder,
  });

  final AlignmentGeometry alignment;
  final double itemWidth;
  final int maxToastLimit;
  final Duration animationDuration;
  final int maxTitleLines;
  final int maxDescriptionLines;
  final TpToastMarginBuilder? marginBuilder;
}
