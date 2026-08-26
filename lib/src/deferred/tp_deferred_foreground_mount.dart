import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';

/// Defers [builder] until the frame after [active] becomes true so heavy
/// children do not share the activation frame (e.g. tab open / tab switch).
///
/// When [retainWhenInactive] is true, the child stays mounted after the first
/// show even if [active] becomes false — callers should hide it with
/// [TpKeepAliveLayer] / [Offstage] / ignore-pointer wrappers.
class TpDeferredForegroundMount extends StatefulWidget {
  const TpDeferredForegroundMount({
    required this.active,
    required this.builder,
    this.placeholder,
    this.retainWhenInactive = false,
    super.key,
  });

  final bool active;
  final WidgetBuilder builder;
  final Widget? placeholder;

  /// Keep [builder] mounted after the first show when [active] goes false.
  final bool retainWhenInactive;

  @override
  State<TpDeferredForegroundMount> createState() =>
      _TpDeferredForegroundMountState();
}

class _TpDeferredForegroundMountState extends State<TpDeferredForegroundMount> {
  var _showChild = false;

  @override
  void initState() {
    super.initState();
    if (widget.active) {
      _scheduleShow();
    }
  }

  @override
  void didUpdateWidget(covariant TpDeferredForegroundMount oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!widget.active) {
      if (!widget.retainWhenInactive) {
        _showChild = false;
      }
      return;
    }
    if (!oldWidget.active && !_showChild) {
      _scheduleShow();
    }
  }

  void _scheduleShow() {
    // endOfFrame 会主动请求一帧并等它结束。此前用 scheduleFrameCallback
    // 叠加 postFrameCallback 的两层延迟依赖「后续恰好还有帧产生」：面板
    // 静止时（如切换到已打开的浮动工作区的第二个标签）该帧可能永远不到，
    // 内容直到窗口 resize 强制产帧才挂载。
    WidgetsBinding.instance.endOfFrame.then((_) {
      if (!mounted || !widget.active || _showChild) return;
      setState(() => _showChild = true);
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_showChild) {
      return widget.placeholder ?? const SizedBox.expand();
    }
    return widget.builder(context);
  }
}
