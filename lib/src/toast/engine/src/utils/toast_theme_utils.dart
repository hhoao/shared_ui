import 'package:flutter/material.dart';
import 'package:shared_ui/src/toast/engine/toastification.dart';

extension ContextExt on BuildContext {
  ToastificationThemeData get toastTheme => ToastificationTheme.of(this);
}
