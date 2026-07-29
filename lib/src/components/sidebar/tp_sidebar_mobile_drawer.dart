import 'package:flutter/material.dart';

import '../../theme/components/tp_sidebar_theme.dart';
import 'tp_sidebar_config.dart';

/// Full-screen mobile overlay: edge-open strip, scrim, sliding panel, back dismiss.
class TpSidebarMobileDrawer extends StatefulWidget {
  const TpSidebarMobileDrawer({
    super.key,
    required this.side,
    required this.theme,
    required this.openMobile,
    required this.edgeOpenEnabled,
    required this.onOpenMobileChange,
    required this.child,
  });

  final TpSidebarSide side;
  final TpSidebarTheme theme;
  final bool openMobile;
  final bool edgeOpenEnabled;
  final ValueChanged<bool> onOpenMobileChange;
  final Widget child;

  @override
  State<TpSidebarMobileDrawer> createState() => _TpSidebarMobileDrawerState();
}

class _TpSidebarMobileDrawerState extends State<TpSidebarMobileDrawer> {
  static const double _edgeHitWidth = 20;

  double _dragExtent = 0;
  bool _isDragging = false;
  bool _wasOpenAtDragStart = false;

  double get _drawerWidth => widget.theme.widthMobile;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isDragging) {
      _syncExtentFromOpen();
    }
  }

  @override
  void didUpdateWidget(covariant TpSidebarMobileDrawer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_isDragging) {
      _syncExtentFromOpen();
    }
  }

  void _syncExtentFromOpen() {
    final target = widget.openMobile ? _drawerWidth : 0.0;
    if (_dragExtent != target) {
      setState(() => _dragExtent = target);
    }
  }

  void _setOpenMobile(bool open) {
    widget.onOpenMobileChange(open);
    if (!_isDragging) {
      setState(() => _dragExtent = open ? _drawerWidth : 0);
    }
  }

  double _signedDelta(double delta) {
    return widget.side == TpSidebarSide.left ? delta : -delta;
  }

  void _onDragStart(DragStartDetails details) {
    _isDragging = true;
    _wasOpenAtDragStart = widget.openMobile;
  }

  void _onDragUpdate(DragUpdateDetails details) {
    final next = (_dragExtent + _signedDelta(details.delta.dx))
        .clamp(0.0, _drawerWidth);
    if (next != _dragExtent) {
      setState(() => _dragExtent = next);
    }
  }

  void _onDragEnd(DragEndDetails details) {
    _isDragging = false;
    final velocity = details.primaryVelocity ?? 0;
    final signedVelocity =
        widget.side == TpSidebarSide.left ? velocity : -velocity;

    bool open;
    if (signedVelocity.abs() > 500) {
      open = signedVelocity > 0;
    } else if (_wasOpenAtDragStart && _dragExtent < _drawerWidth) {
      open = false;
    } else {
      open = _dragExtent > _drawerWidth * 0.5;
    }

    widget.onOpenMobileChange(open);
    setState(() => _dragExtent = open ? _drawerWidth : 0);
  }

  double get _panelOffset {
    if (widget.side == TpSidebarSide.left) {
      return _dragExtent - _drawerWidth;
    }
    return _drawerWidth - _dragExtent;
  }

  Widget _buildPanel(BuildContext overlayContext) {
    final scheme = Theme.of(overlayContext).colorScheme;
    return Material(
      elevation: 8,
      color: widget.theme.backgroundColor ?? scheme.surfaceContainerLow,
      child: SizedBox(
        width: _drawerWidth,
        height: double.infinity,
        child: widget.child,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final showDrawer = _dragExtent > 0;
    final showEdgeStrip = widget.edgeOpenEnabled &&
        !widget.openMobile &&
        _dragExtent == 0 &&
        !_isDragging;

    Widget stack = Stack(
      fit: StackFit.expand,
      children: [
        if (showDrawer)
          ModalBarrier(
            dismissible: true,
            color: Colors.black54,
            onDismiss: () => _setOpenMobile(false),
          ),
        if (showDrawer)
          Positioned(
            left: widget.side == TpSidebarSide.left ? _panelOffset : null,
            right: widget.side == TpSidebarSide.right ? _panelOffset : null,
            top: 0,
            bottom: 0,
            child: GestureDetector(
              onHorizontalDragStart: _onDragStart,
              onHorizontalDragUpdate: _onDragUpdate,
              onHorizontalDragEnd: _onDragEnd,
              child: _buildPanel(context),
            ),
          ),
        if (showEdgeStrip)
          Positioned(
            left: widget.side == TpSidebarSide.left ? 0 : null,
            right: widget.side == TpSidebarSide.right ? 0 : null,
            top: 0,
            bottom: 0,
            width: _edgeHitWidth,
            child: GestureDetector(
              behavior: HitTestBehavior.translucent,
              onHorizontalDragStart: _onDragStart,
              onHorizontalDragUpdate: _onDragUpdate,
              onHorizontalDragEnd: _onDragEnd,
              child: const SizedBox.expand(),
            ),
          ),
      ],
    );

    if (widget.openMobile) {
      stack = PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, _) {
          if (!didPop) {
            _setOpenMobile(false);
          }
        },
        child: stack,
      );
    }

    return stack;
  }
}
