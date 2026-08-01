import 'package:flutter/material.dart';

import 'tp_tab_strip_metrics.dart';

/// Horizontal tab strip with optional drag-reorder.
///
/// [inStripTrailing] scrolls with tabs but is excluded from [onReorder] indices.
/// [trailing] sits outside the scroll viewport (pane actions, clear, etc.).
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

  /// Material [ReorderableListView.onReorder] semantics. Null ⇒ scroll only.
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
          if (fillWidth) Expanded(child: scroll) else scroll,
          if (trailing != null) trailing!,
        ],
      ),
    );
  }

  Widget _buildScrollRegion(BuildContext context) {
    final tabs = onReorder == null
        ? _scrollOnlyTabs(context)
        : _reorderableTabs(context);

    final scroll = SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          tabs,
          if (inStripTrailing != null) ...[
            const SizedBox(width: 2),
            inStripTrailing!,
          ],
        ],
      ),
    );

    if (fillWidth) return scroll;
    // Shrink-wrap so empty title chrome can receive pan / double-tap.
    return Align(
      alignment: Alignment.centerLeft,
      widthFactor: 1,
      child: scroll,
    );
  }

  Widget _scrollOnlyTabs(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < itemCount; i++) itemBuilder(context, i),
      ],
    );
  }

  Widget _reorderableTabs(BuildContext context) {
    return ReorderableListView.builder(
      shrinkWrap: true,
      scrollDirection: Axis.horizontal,
      physics: const NeverScrollableScrollPhysics(),
      buildDefaultDragHandles: false,
      onReorder: onReorder!,
      itemCount: itemCount,
      itemBuilder: (context, index) {
        return ReorderableDelayedDragStartListener(
          key: _keyFor(index),
          index: index,
          child: itemBuilder(context, index),
        );
      },
    );
  }
}
