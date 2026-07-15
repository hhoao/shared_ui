import 'package:flutter/material.dart';

import '../../toast/engine/src/core/toastification_config.dart';

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

  ToastificationConfig toEngineConfig() {
    return ToastificationConfig(
      alignment: alignment,
      itemWidth: itemWidth,
      maxToastLimit: maxToastLimit,
      animationDuration: animationDuration,
      maxTitleLines: maxTitleLines,
      maxDescriptionLines: maxDescriptionLines,
      marginBuilder: marginBuilder ?? _defaultMarginBuilder,
    );
  }
}

EdgeInsetsGeometry _defaultMarginBuilder(
  BuildContext context,
  AlignmentGeometry alignment,
) {
  final y = alignment.resolve(Directionality.of(context)).y;

  return switch (y) {
    <= -0.5 => const EdgeInsets.only(top: 12),
    >= 0.5 => const EdgeInsets.only(bottom: 12),
    _ => EdgeInsets.zero,
  };
}
