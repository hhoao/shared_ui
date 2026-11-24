// Overlay portal adapted from AppFlowy UI / flutter_shadcn_ui.

import 'package:flutter/material.dart';

import 'tp_anchor.dart';

class TpPortal extends StatefulWidget {
  const TpPortal({
    super.key,
    required this.child,
    required this.portalBuilder,
    required this.visible,
    required this.anchor,
    this.transitionDuration = const Duration(milliseconds: 160),
    this.transitionCurve = Curves.easeOutCubic,
    this.capHeightToAnchorSide = false,
  });

  final Widget child;
  final WidgetBuilder portalBuilder;
  final bool visible;
  final TpAnchorBase anchor;
  final Duration transitionDuration;
  final Curve transitionCurve;

  /// Caps the overlay height to the roomier side around the anchor and scrolls
  /// oversized content instead of letting it cover the anchor.
  final bool capHeightToAnchorSide;

  @override
  State<TpPortal> createState() => _TpPortalState();
}

/// Mirrors an [Alignment] vertically (top ↔ bottom, center stays center).
Alignment _mirrorY(Alignment alignment) => Alignment(alignment.x, -alignment.y);

class _TpPortalState extends State<TpPortal>
    with SingleTickerProviderStateMixin {
  final overlayPortalController = OverlayPortalController();
  final _targetKey = GlobalKey();
  late final AnimationController _transitionController;
  late final Animation<double> _fadeAnimation;
  late final Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _transitionController = AnimationController(
      vsync: this,
      duration: widget.transitionDuration,
    );
    final curved = CurvedAnimation(
      parent: _transitionController,
      curve: widget.transitionCurve,
      reverseCurve: Curves.easeInCubic,
    );
    _fadeAnimation = curved;
    _scaleAnimation = Tween<double>(begin: 0.97, end: 1).animate(curved);
    _updateVisibility();
  }

  @override
  void didUpdateWidget(covariant TpPortal oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.transitionDuration != widget.transitionDuration) {
      _transitionController.duration = widget.transitionDuration;
    }
    _updateVisibility();
  }

  @override
  void dispose() {
    _transitionController.dispose();
    _hide();
    super.dispose();
  }

  void _updateVisibility() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (widget.visible) {
        _show();
        if (widget.transitionDuration == Duration.zero) {
          _transitionController.value = 1.0;
          return;
        }
        // Always forward — handles re-open after reverse, and re-open while
        // reverse is still running (otherwise opacity stays at 0).
        _transitionController.forward();
        return;
      }
      if (widget.transitionDuration == Duration.zero) {
        _transitionController.value = 0.0;
        _hide();
        return;
      }
      if (_transitionController.value <= 0) {
        _hide();
        return;
      }
      _transitionController.reverse().whenComplete(() {
        if (!mounted) return;
        if (widget.visible) {
          _show();
          _transitionController.forward(from: 0);
          return;
        }
        _hide();
      });
    });
  }

  void _hide() {
    if (overlayPortalController.isShowing) {
      overlayPortalController.hide();
    }
  }

  void _show() {
    if (!overlayPortalController.isShowing) {
      overlayPortalController.show();
    }
  }

  Alignment _transitionAlignment(TpAnchorBase anchor) {
    return switch (anchor) {
      TpAnchor anchor => anchor.childAlignment,
      TpAnchorAuto anchor => anchor.followerAnchor,
      TpGlobalAnchor _ => Alignment.topLeft,
    };
  }

  Widget _buildAnimatedPortal(BuildContext context, Widget child) {
    if (widget.transitionDuration == Duration.zero) {
      return child;
    }
    return FadeTransition(
      opacity: _fadeAnimation,
      child: ScaleTransition(
        scale: _scaleAnimation,
        alignment: _transitionAlignment(widget.anchor),
        child: child,
      ),
    );
  }

  Widget _buildPositionedOverlay(BuildContext context, TpAnchorBase anchor) {
    // Keeps the panel tracking the anchor when the viewport changes.
    if (anchor is! TpAnchorAuto || anchor.followTargetOnResize) {
      MediaQuery.sizeOf(context);
    }
    final overlayState = Overlay.of(context, debugRequiredFor: widget);
    final box = _targetKey.currentContext?.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) setState(() {});
      });
      return const SizedBox.shrink();
    }
    final overlayAncestor =
        overlayState.context.findRenderObject()! as RenderBox;

    final Offset targetPoint;
    final Offset flipTargetPoint;
    final Alignment followerAlignment;
    final Alignment flipFollowerAlignment;
    switch (anchor) {
      case TpGlobalAnchor():
        return CustomSingleChildLayout(
          delegate: ContextMenuOverlayPositionDelegate(target: anchor.offset),
          child: _buildAnimatedPortal(context, widget.portalBuilder(context)),
        );
      case TpAnchor():
        targetPoint = box.localToGlobal(
          alignmentPointOnRect(box.size, anchor.overlayAlignment) +
              anchor.offset,
          ancestor: overlayAncestor,
        );
        followerAlignment = anchor.childAlignment;
        flipTargetPoint = box.localToGlobal(
          alignmentPointOnRect(box.size, _mirrorY(anchor.overlayAlignment)) +
              Offset(anchor.offset.dx, -anchor.offset.dy),
          ancestor: overlayAncestor,
        );
        flipFollowerAlignment = _mirrorY(anchor.childAlignment);
      case TpAnchorAuto():
        targetPoint = box.localToGlobal(
          alignmentPointOnRect(box.size, anchor.targetAnchor) + anchor.offset,
          ancestor: overlayAncestor,
        );
        followerAlignment = anchor.followerAnchor;
        flipTargetPoint = box.localToGlobal(
          alignmentPointOnRect(box.size, _mirrorY(anchor.targetAnchor)) +
              Offset(anchor.offset.dx, -anchor.offset.dy),
          ancestor: overlayAncestor,
        );
        flipFollowerAlignment = _mirrorY(anchor.followerAnchor);
    }

    return CustomSingleChildLayout(
      delegate: TpOverlayPositionDelegate(
        targetPoint: targetPoint,
        followerAlignment: followerAlignment,
        flipTargetPoint: flipTargetPoint,
        flipFollowerAlignment: flipFollowerAlignment,
        capHeightToAnchorSide: widget.capHeightToAnchorSide,
      ),
      child: _buildAnimatedPortal(context, widget.portalBuilder(context)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return KeyedSubtree(
      key: _targetKey,
      child: OverlayPortal(
        controller: overlayPortalController,
        overlayChildBuilder: (context) {
          return Material(
            type: MaterialType.transparency,
            child: Center(
              widthFactor: 1,
              heightFactor: 1,
              child: _buildPositionedOverlay(context, widget.anchor),
            ),
          );
        },
        child: widget.child,
      ),
    );
  }
}
