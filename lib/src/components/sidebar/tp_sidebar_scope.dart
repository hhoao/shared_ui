import 'package:flutter/material.dart';

/// Desktop sidebar expansion derived from [TpSidebarScope.open].
enum TpSidebarDesktopState {
  expanded,
  collapsed,
}

/// Inherited scope exposing sidebar open state and actions.
class TpSidebarScope extends InheritedWidget {
  const TpSidebarScope({
    super.key,
    required this.open,
    required this.openMobile,
    required this.isMobile,
    required this.setOpen,
    required this.setOpenMobile,
    required this.toggleSidebar,
    required super.child,
  });

  final bool open;
  final bool openMobile;
  final bool isMobile;
  final ValueChanged<bool> setOpen;
  final ValueChanged<bool> setOpenMobile;
  final VoidCallback toggleSidebar;

  TpSidebarDesktopState get state =>
      open ? TpSidebarDesktopState.expanded : TpSidebarDesktopState.collapsed;

  static TpSidebarScope of(BuildContext context) {
    final scope = maybeOf(context);
    if (scope == null) {
      throw FlutterError(
        'TpSidebarScope.of() called with a context that does not contain a '
        'TpSidebarScope.\n'
        'No TpSidebarScope ancestor could be found starting from the context '
        'that was passed to TpSidebarScope.of().\n'
        'The context used was:\n'
        '  $context',
      );
    }
    return scope;
  }

  static TpSidebarScope? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<TpSidebarScope>();

  @override
  bool updateShouldNotify(TpSidebarScope oldWidget) =>
      open != oldWidget.open ||
      openMobile != oldWidget.openMobile ||
      isMobile != oldWidget.isMobile;
}
