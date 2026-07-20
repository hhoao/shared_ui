import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'tp_sidebar_scope.dart';

/// Owns sidebar open state and keyboard shortcuts for the subtree.
class TpSidebarProvider extends StatefulWidget {
  const TpSidebarProvider({
    super.key,
    this.defaultOpen = true,
    this.open,
    this.onOpenChange,
    this.mobileBreakpoint = 768,
    this.enableKeyboardShortcut = true,
    required this.child,
  });

  final bool defaultOpen;
  final bool? open;
  final ValueChanged<bool>? onOpenChange;
  final double mobileBreakpoint;
  final bool enableKeyboardShortcut;
  final Widget child;

  @override
  State<TpSidebarProvider> createState() => _TpSidebarProviderState();
}

class _TpSidebarProviderState extends State<TpSidebarProvider> {
  late bool _open;
  bool _openMobile = false;

  @override
  void initState() {
    super.initState();
    _open = widget.defaultOpen;
  }

  @override
  void didUpdateWidget(TpSidebarProvider oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.open == null && oldWidget.defaultOpen != widget.defaultOpen) {
      _open = widget.defaultOpen;
    }
  }

  bool get _isControlled => widget.open != null;

  bool get _openValue => widget.open ?? _open;

  void _setOpen(bool value) {
    if (_isControlled) {
      widget.onOpenChange?.call(value);
    } else {
      setState(() => _open = value);
    }
  }

  void _setOpenMobile(bool value) {
    setState(() => _openMobile = value);
  }

  void _toggleSidebar() {
    final isMobile =
        MediaQuery.sizeOf(context).width < widget.mobileBreakpoint;
    if (isMobile) {
      _setOpenMobile(!_openMobile);
    } else {
      _setOpen(!_openValue);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isMobile =
        MediaQuery.sizeOf(context).width < widget.mobileBreakpoint;

    Widget child = TpSidebarScope(
      open: _openValue,
      openMobile: _openMobile,
      isMobile: isMobile,
      setOpen: _setOpen,
      setOpenMobile: _setOpenMobile,
      toggleSidebar: _toggleSidebar,
      child: widget.child,
    );

    if (widget.enableKeyboardShortcut) {
      child = CallbackShortcuts(
        bindings: {
          const SingleActivator(LogicalKeyboardKey.keyB, control: true):
              _toggleSidebar,
          const SingleActivator(LogicalKeyboardKey.keyB, meta: true):
              _toggleSidebar,
        },
        child: Focus(autofocus: true, child: child),
      );
    }

    return child;
  }
}
