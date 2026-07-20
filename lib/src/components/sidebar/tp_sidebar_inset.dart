import 'package:flutter/material.dart';

import '../../theme/tp_theme.dart';

/// Main content chrome for [TpSidebarVariant.inset] layouts.
///
/// Applies theme-driven background, radius, border, and light elevation.
class TpSidebarInset extends StatelessWidget {
  const TpSidebarInset({
    super.key,
    required this.child,
  });

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = context.tpTheme.sidebarTheme;
    final cs = Theme.of(context).colorScheme;
    final radius = BorderRadius.circular(theme.insetRadius);
    final background =
        theme.insetBackgroundColor ?? cs.surface;
    final borderColor = theme.borderColor ??
        cs.outlineVariant.withValues(alpha: 0.6);

    return ClipRRect(
      key: const Key('tp-sidebar-inset'),
      borderRadius: radius,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: background,
          borderRadius: radius,
          border: Border.all(color: borderColor),
          boxShadow: [
            BoxShadow(
              color: cs.shadow.withValues(alpha: 0.06),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: child,
      ),
    );
  }
}
