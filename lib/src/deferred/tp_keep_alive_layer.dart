import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

/// Keeps [child] mounted (state preserved) but skips layout/paint/hit-test when
/// [active] is false.
///
/// Unlike [Offstage], inactive children are not laid out — important for
/// keep-alive [Stack] layers where [Offstage] still pays full subtree layout
/// every frame.
class TpKeepAliveLayer extends SingleChildRenderObjectWidget {
  const TpKeepAliveLayer({
    required this.active,
    required super.child,
    super.key,
  });

  final bool active;

  @override
  RenderTpKeepAliveLayer createRenderObject(BuildContext context) {
    return RenderTpKeepAliveLayer(active: active);
  }

  @override
  void updateRenderObject(
    BuildContext context,
    RenderTpKeepAliveLayer renderObject,
  ) {
    renderObject.active = active;
  }
}

class RenderTpKeepAliveLayer extends RenderProxyBox {
  RenderTpKeepAliveLayer({required bool active}) : _active = active;

  bool _active;
  bool get active => _active;
  set active(bool value) {
    if (_active == value) return;
    _active = value;
    markNeedsLayout();
    markNeedsPaint();
  }

  @override
  void performLayout() {
    if (!_active) {
      size = constraints.biggest;
      return;
    }
    if (child != null) {
      child!.layout(constraints, parentUsesSize: true);
      size = child!.size;
    } else {
      size = constraints.smallest;
    }
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    if (!_active) return;
    super.paint(context, offset);
  }

  @override
  bool hitTest(BoxHitTestResult result, {required Offset position}) {
    if (!_active) return false;
    return super.hitTest(result, position: position);
  }

  @override
  void visitChildrenForSemantics(RenderObjectVisitor visitor) {
    if (!_active) return;
    super.visitChildrenForSemantics(visitor);
  }
}
