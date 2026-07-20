import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../../theme/components/tp_sidebar_theme.dart';
import '../../theme/tp_theme.dart';
import 'tp_sidebar_config.dart';
import 'tp_sidebar_scope.dart';

/// Sized sidebar panel with collapse animation and mobile overlay drawer.
class TpSidebar extends StatefulWidget {
  const TpSidebar({
    super.key,
    this.side = TpSidebarSide.left,
    this.variant = TpSidebarVariant.sidebar,
    this.collapsible = TpSidebarCollapsible.offcanvas,
    this.themeOverride,
    required this.child,
  });

  final TpSidebarSide side;
  final TpSidebarVariant variant;
  final TpSidebarCollapsible collapsible;
  final TpSidebarTheme? themeOverride;
  final Widget child;

  @override
  State<TpSidebar> createState() => _TpSidebarState();
}

class _TpSidebarState extends State<TpSidebar> {
  final OverlayPortalController _overlayController = OverlayPortalController();
  bool _overlayShown = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _scheduleOverlaySync();
  }

  @override
  void didUpdateWidget(TpSidebar oldWidget) {
    super.didUpdateWidget(oldWidget);
    _scheduleOverlaySync();
  }

  @override
  void dispose() {
    _hideOverlay();
    super.dispose();
  }

  void _showOverlay() {
    if (!_overlayController.isShowing) {
      _overlayController.show();
    }
  }

  void _hideOverlay() {
    if (_overlayController.isShowing) {
      _overlayController.hide();
    }
  }

  void _scheduleOverlaySync() {
    SchedulerBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final current = TpSidebarScope.maybeOf(context);

      // Portal is only in the tree while mobile. Never hide() after it detaches.
      if (current == null || !current.isMobile) {
        _overlayShown = false;
        return;
      }

      final show = current.openMobile;
      if (show == _overlayShown) return;
      if (show) {
        _showOverlay();
      } else {
        _hideOverlay();
      }
      _overlayShown = show;
    });
  }

  double _desktopWidth({
    required TpSidebarScope scope,
    required TpSidebarTheme theme,
  }) {
    if (widget.collapsible == TpSidebarCollapsible.none || scope.open) {
      return theme.width;
    }
    return switch (widget.collapsible) {
      TpSidebarCollapsible.icon => theme.widthIcon,
      TpSidebarCollapsible.offcanvas => 0,
      TpSidebarCollapsible.none => theme.width,
    };
  }

  BoxDecoration _decoration(TpSidebarTheme theme, ColorScheme scheme) {
    final bg = theme.backgroundColor ?? scheme.surfaceContainerLow;
    final border = theme.borderColor ??
        scheme.outlineVariant.withValues(alpha: 0.6);

    return switch (widget.variant) {
      TpSidebarVariant.sidebar => BoxDecoration(
          color: bg,
          border: Border(
            left: widget.side == TpSidebarSide.right
                ? BorderSide(color: border)
                : BorderSide.none,
            right: widget.side == TpSidebarSide.left
                ? BorderSide(color: border)
                : BorderSide.none,
          ),
        ),
      TpSidebarVariant.floating => BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(theme.floatingRadius),
          border: Border.all(color: border),
          boxShadow: [
            BoxShadow(
              color: scheme.shadow.withValues(alpha: 0.08),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
      TpSidebarVariant.inset => BoxDecoration(
          color: bg.withValues(alpha: 0.5),
        ),
    };
  }

  EdgeInsets _margin(TpSidebarTheme theme) {
    if (widget.variant != TpSidebarVariant.floating) {
      return EdgeInsets.zero;
    }
    return EdgeInsets.all(theme.floatingMargin);
  }

  Widget _buildPanel({
    required BuildContext context,
    required TpSidebarTheme theme,
    required double width,
    required Widget child,
  }) {
    final scheme = Theme.of(context).colorScheme;
    final margin = _margin(theme);
    final decoration = _decoration(theme, scheme);

    return AnimatedContainer(
      key: const Key('sidebar-panel'),
      duration: theme.animationDuration,
      curve: Curves.easeInOut,
      width: width,
      margin: margin,
      decoration: decoration,
      clipBehavior: Clip.hardEdge,
      child: width <= 0
          ? const SizedBox.shrink()
          : OverflowBox(
              alignment: widget.side == TpSidebarSide.left
                  ? Alignment.centerLeft
                  : Alignment.centerRight,
              minWidth: 0,
              maxWidth: theme.width,
              child: SizedBox(
                width: theme.width,
                child: child,
              ),
            ),
    );
  }

  Widget _buildConfiguredChild(Widget child) {
    return TpSidebarConfig(
      side: widget.side,
      variant: widget.variant,
      collapsible: widget.collapsible,
      child: child,
    );
  }

  @override
  Widget build(BuildContext context) {
    final scope = TpSidebarScope.of(context);
    final theme =
        widget.themeOverride ?? TpTheme.of(context).sidebarTheme;
    final configured = _buildConfiguredChild(widget.child);

    if (!scope.isMobile) {
      // Portal already left the tree with this rebuild — only clear local flag.
      _overlayShown = false;
      final width = _desktopWidth(scope: scope, theme: theme);
      return _buildPanel(
        context: context,
        theme: theme,
        width: width,
        child: configured,
      );
    }

    _scheduleOverlaySync();
    return OverlayPortal(
      controller: _overlayController,
      overlayChildBuilder: (overlayContext) {
        final drawerPanel = Material(
          elevation: 8,
          color: theme.backgroundColor ??
              Theme.of(overlayContext).colorScheme.surfaceContainerLow,
          child: SizedBox(
            width: theme.widthMobile,
            height: double.infinity,
            child: configured,
          ),
        );
        return Stack(
          children: [
            ModalBarrier(
              dismissible: true,
              color: Colors.black54,
              onDismiss: () => TpSidebarScope.maybeOf(overlayContext)
                  ?.setOpenMobile(false),
            ),
            Align(
              alignment: widget.side == TpSidebarSide.left
                  ? Alignment.centerLeft
                  : Alignment.centerRight,
              child: drawerPanel,
            ),
          ],
        );
      },
      child: _buildPanel(
        context: context,
        theme: theme,
        width: 0,
        child: const SizedBox.shrink(),
      ),
    );
  }
}
