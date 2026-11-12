import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import 'tp_tab_strip_metrics.dart';

/// Horizontal tab strip with optional drag-reorder.
///
/// [inStripTrailing] scrolls with tabs but is excluded from reorder indices.
/// [trailing] sits outside the scroll viewport (pane actions, clear, etc.).
///
/// When [onReorder] is set, a single [CustomScrollView] owns horizontal
/// scrolling and reorder — nested scroll views must not wrap the list or they
/// steal drag gestures. Reorder starts on mouse drags only; touch pointers
/// stay with the scroll view so the strip can be swiped.
class TpTabStrip extends StatelessWidget {
  const TpTabStrip({
    required this.itemCount,
    required this.itemBuilder,
    this.itemKey,
    this.onReorder,
    this.leading,
    this.inStripTrailing,
    this.trailing,
    this.metrics = TpTabStripMetrics.compact,
    this.showBottomBorder = false,
    this.borderColor,
    this.fillWidth = true,
    super.key,
  });

  final int itemCount;
  final IndexedWidgetBuilder itemBuilder;

  /// Stable keys for reorderable items. Defaults to [ValueKey] of the index.
  final Key Function(int index)? itemKey;

  /// [ReorderableListView.onReorderItem] semantics. Null ⇒ scroll only.
  final ReorderCallback? onReorder;

  final Widget? leading;
  final Widget? inStripTrailing;
  final Widget? trailing;
  final TpTabStripMetrics metrics;
  final bool showBottomBorder;
  final Color? borderColor;

  /// When false, the strip sizes to its children (floating title bar) so empty
  /// chrome can receive pan / double-tap under the title Stack.
  final bool fillWidth;

  Key _keyFor(int index) => itemKey?.call(index) ?? ValueKey<int>(index);

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final border = borderColor ?? cs.outlineVariant.withValues(alpha: 0.5);
    final scroll = _buildScrollRegion(context);

    return Container(
      height: metrics.height,
      padding: EdgeInsets.symmetric(horizontal: metrics.horizontalPadding),
      decoration: showBottomBorder
          ? BoxDecoration(
              border: Border(bottom: BorderSide(color: border)),
            )
          : null,
      child: Row(
        mainAxisSize: fillWidth ? MainAxisSize.max : MainAxisSize.min,
        children: [
          if (leading != null) ...[leading!, const SizedBox(width: 2)],
          // Flexible (not a bare child) so the scroll region gets a bounded
          // max width — Row gives non-flex children unbounded main-axis max,
          // which made fillWidth:false content lay out full-bleed then overflow.
          if (fillWidth)
            Expanded(child: scroll)
          else
            Flexible(fit: FlexFit.loose, child: scroll),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }

  Widget _buildScrollRegion(BuildContext context) {
    if (onReorder == null) {
      return ListView(
        scrollDirection: Axis.horizontal,
        shrinkWrap: !fillWidth,
        children: [
          for (var i = 0; i < itemCount; i++) itemBuilder(context, i),
          if (inStripTrailing != null) ...[
            const SizedBox(width: 2),
            inStripTrailing!,
          ],
        ],
      );
    }

    // One scrollable owns both reorder + horizontal scroll (and the + button).
    return CustomScrollView(
      scrollDirection: Axis.horizontal,
      shrinkWrap: !fillWidth,
      slivers: [
        SliverReorderableList(
          itemCount: itemCount,
          onReorderItem: onReorder!,
          itemBuilder: (context, index) {
            return _MouseReorderDragStartListener(
              key: _keyFor(index),
              index: index,
              child: itemBuilder(context, index),
            );
          },
        ),
        if (inStripTrailing != null)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.only(left: 2),
              child: inStripTrailing,
            ),
          ),
      ],
    );
  }
}

/// Starts a reorder on mouse drags only.
///
/// [ReorderableDragStartListener] would start on any pointer: its immediate
/// multi-drag recognizer accepts once the pointer passes the touch slop, and
/// being inside the scroll view it wins the gesture arena over the strip's
/// horizontal drag — a swipe on a tab reordered instead of scrolling. Touch
/// stays with the scroll view; long-press keeps the host chip's menu.
class _MouseReorderDragStartListener extends StatelessWidget {
  const _MouseReorderDragStartListener({
    required this.index,
    required this.child,
    super.key,
  });

  final int index;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerDown: (event) {
        if (event.kind != PointerDeviceKind.mouse) return;
        final list = SliverReorderableList.maybeOf(context);
        if (list == null) return;
        list.startItemDragReorder(
          index: index,
          event: event,
          recognizer: ImmediateMultiDragGestureRecognizer(debugOwner: this)
            ..gestureSettings = MediaQuery.maybeGestureSettingsOf(context),
        );
      },
      child: child,
    );
  }
}
