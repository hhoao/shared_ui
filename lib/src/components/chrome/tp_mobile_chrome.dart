import 'package:flutter/material.dart';

import '../sidebar/tp_sidebar_scope.dart';

/// Mobile chrome spacing tokens for edge-adjacent controls.
abstract final class TpMobileChrome {
  /// Left inset for edge-adjacent controls on curved / narrow screens.
  /// Matches home title-bar hamburger spacing.
  static const double leadingInset = 16;

  /// Narrow / mobile width fallback when no [TpSidebarScope] is present.
  /// Keep equal to app `WorkspacePanePolicy.narrowBreakpointWidth`.
  static const double narrowBreakpointWidth = 840;
}

/// Pads [child] on the left when the host is mobile / narrow.
class TpMobileLeading extends StatelessWidget {
  const TpMobileLeading({
    required this.child,
    this.force = false,
    super.key,
  });

  final Widget child;
  final bool force;

  static bool _isMobile(BuildContext context) {
    final scoped = TpSidebarScope.maybeOf(context)?.isMobile;
    if (scoped != null) return scoped;
    return MediaQuery.sizeOf(context).width <
        TpMobileChrome.narrowBreakpointWidth;
  }

  @override
  Widget build(BuildContext context) {
    if (!force && !_isMobile(context)) return child;
    return Padding(
      padding: const EdgeInsets.only(left: TpMobileChrome.leadingInset),
      child: child,
    );
  }
}
