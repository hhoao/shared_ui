import 'package:flutter/material.dart';

import '../../toast/engine/toastification.dart';
import 'tp_toast_config.dart';

/// Hosts the private toast overlay engine with [TpToastConfig] defaults.
class TpToastWrapper extends StatelessWidget {
  const TpToastWrapper({
    super.key,
    required this.child,
    this.config = const TpToastConfig(),
  });

  final Widget child;
  final TpToastConfig config;

  @override
  Widget build(BuildContext context) {
    return ToastificationWrapper(
      config: _toEngineConfig(config),
      child: child,
    );
  }
}

ToastificationConfig _toEngineConfig(TpToastConfig config) {
  return ToastificationConfig(
    alignment: config.alignment,
    itemWidth: config.itemWidth,
    maxToastLimit: config.maxToastLimit,
    animationDuration: config.animationDuration,
    maxTitleLines: config.maxTitleLines,
    maxDescriptionLines: config.maxDescriptionLines,
    marginBuilder: config.marginBuilder ?? _defaultMarginBuilder,
  );
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
