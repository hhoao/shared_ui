import 'package:flutter/material.dart';

import '../../theme/tp_theme.dart';

/// Sticky bottom slot inside [TpSidebar] (non-scrolling).
class TpSidebarFooter extends StatelessWidget {
  const TpSidebarFooter({
    super.key,
    required this.child,
    this.padding,
  });

  final Widget child;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    final spacing = context.tpSpacing;
    return Padding(
      padding: padding ?? EdgeInsets.all(spacing.sm),
      child: child,
    );
  }
}
