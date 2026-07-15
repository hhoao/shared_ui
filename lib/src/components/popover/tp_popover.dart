// Popover overlay adapted from AppFlowy UI (AFPopover).

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../theme/tp_theme.dart';
import 'tp_anchor.dart';
import 'tp_popover_controller.dart';
import 'tp_portal.dart';

export 'tp_anchor.dart';
export 'tp_popover_controller.dart';
export 'tp_portal.dart';
/// Anchored overlay panel.
class TpPopover extends StatefulWidget {
  const TpPopover({
    super.key,
    required this.child,
    required this.popover,
    required this.controller,
    this.closeOnTapOutside = true,
    this.anchor,
    this.padding,
    this.decoration,
    this.panelWidth,
    this.overlayVisible,
    this.groupId,
    this.useSameGroupIdForChild = true,
    this.transitionDuration,
    this.transitionCurve = Curves.easeOutCubic,
  });

  final Widget child;
  final WidgetBuilder popover;
  final TpPopoverController controller;
  final bool closeOnTapOutside;
  final TpAnchorBase? anchor;
  final EdgeInsetsGeometry? padding;
  final BoxDecoration? decoration;

  /// When set, the full panel (decoration + padding + content) matches this width.
  final double? panelWidth;

  /// When false, keeps [controller] open state but hides the overlay (e.g. until width is measured).
  final bool? overlayVisible;
  final Object? groupId;
  final bool useSameGroupIdForChild;
  final Duration? transitionDuration;
  final Curve transitionCurve;

  @override
  State<TpPopover> createState() => _TpPopoverState();
}

class _TpPopoverState extends State<TpPopover> {
  static final List<_TpPopoverState> _openPopovers = [];
  static int? _lastPopoverClosedTimestamp;

  static void _markPopoverClosedThisFrame() {
    _lastPopoverClosedTimestamp = DateTime.now().microsecondsSinceEpoch;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _lastPopoverClosedTimestamp = null;
    });
  }

  late final Object _groupId;
  bool get _isTopMostPopover =>
      _openPopovers.isNotEmpty && _openPopovers.last == this;

  TpPopoverController get controller => widget.controller;

  @override
  void initState() {
    super.initState();
    _groupId = widget.groupId ?? UniqueKey();
    controller.addListener(_onControllerChanged);
    if (controller.isOpen) {
      _registerPopover();
    }
  }

  @override
  void dispose() {
    controller.removeListener(_onControllerChanged);
    _unregisterPopover();
    super.dispose();
  }

  void _onControllerChanged() {
    if (controller.isOpen) {
      _registerPopover();
    } else {
      _unregisterPopover();
    }
  }

  @override
  Widget build(BuildContext context) {
    final popoverTheme = context.tpTheme.popoverTheme;
    final spacing = context.tpSpacing;
    final effectivePadding =
        widget.padding ??
        EdgeInsets.fromLTRB(spacing.sm, spacing.md, spacing.sm, spacing.md);
    final effectiveAnchor =
        widget.anchor ??
        TpAnchor(
          childAlignment: Alignment.topCenter,
          overlayAlignment: Alignment.bottomCenter,
          offset: Offset(0, popoverTheme.defaultOffsetDy),
        );
    final effectiveDecoration = widget.decoration;
    final transitionDuration =
        widget.transitionDuration ?? popoverTheme.transitionDuration;

    final bridgeInsets = widget.closeOnTapOutside
        ? tapRegionBridgeInsetsForAnchor(effectiveAnchor)
        : EdgeInsets.zero;
    final hasBridge = bridgeInsets.top > 0 || bridgeInsets.bottom > 0;
    final panelWidth = widget.panelWidth;

    Widget panel = DecoratedBox(
      decoration: effectiveDecoration ?? const BoxDecoration(),
      child: Padding(
        padding: effectivePadding,
        child: Builder(builder: widget.popover),
      ),
    );

    if (hasBridge && panelWidth != null) {
      panel = Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (bridgeInsets.top > 0) SizedBox(height: bridgeInsets.top),
          panel,
          if (bridgeInsets.bottom > 0) SizedBox(height: bridgeInsets.bottom),
        ],
      );
    }

    if (panelWidth != null) {
      panel = SizedBox(width: panelWidth, child: panel);
    }

    if (widget.closeOnTapOutside) {
      panel = TapRegion(
        groupId: _groupId,
        behavior: HitTestBehavior.opaque,
        onTapOutside: (_) {
          final now = DateTime.now().microsecondsSinceEpoch;
          if (_isTopMostPopover &&
              (_lastPopoverClosedTimestamp == null ||
                  now - _lastPopoverClosedTimestamp! > 1000)) {
            controller.hide();
            _markPopoverClosedThisFrame();
          }
        },
        child: panel,
      );
    }

    Widget child = ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        return CallbackShortcuts(
          bindings: {
            const SingleActivator(LogicalKeyboardKey.escape): controller.hide,
          },
          child: TpPortal(
            visible: controller.isOpen && (widget.overlayVisible ?? true),
            anchor: effectiveAnchor,
            transitionDuration: transitionDuration,
            transitionCurve: widget.transitionCurve,
            portalBuilder: (_) => panel,
            child: widget.child,
          ),
        );
      },
    );

    if (widget.useSameGroupIdForChild) {
      child = TapRegion(groupId: _groupId, child: child);
    }
    return child;
  }

  void _registerPopover() {
    if (!_openPopovers.contains(this)) {
      _openPopovers.add(this);
    }
  }

  void _unregisterPopover() {
    _openPopovers.remove(this);
  }
}
