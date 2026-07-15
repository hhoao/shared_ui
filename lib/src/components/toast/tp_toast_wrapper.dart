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
      config: config.toEngineConfig(),
      child: child,
    );
  }
}
