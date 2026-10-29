import 'package:flutter/material.dart';

import '../../theme/tp_text_styles.dart';
import 'tp_table_column.dart';
import 'tp_table_state.dart';

class TpTableHeader<T> extends StatelessWidget {
  const TpTableHeader({
    required this.columns,
    required this.layout,
    required this.sort,
    required this.onSort,
    required this.onReorder,
    required this.allColumnIds,
    required this.firstId,
    required this.lastId,
    required this.headerHeight,
    super.key,
  });

  final List<TpTableColumn<T>> columns;
  final TpTableLayout layout;
  final TpTableSort? sort;
  final ValueChanged<String> onSort;
  final void Function(String draggedId, String targetId) onReorder;

  /// Every column id in display order, including locked and hidden ones.
  final List<String> allColumnIds;
  final String firstId;
  final String lastId;
  final double headerHeight;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      height: headerHeight,
      color: cs.surfaceContainerHighest.withValues(alpha: 0.45),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final column in columns)
            SizedBox(
              width: layout.widthOf(column.id),
              child: _HeaderCell<T>(
                key: ValueKey(column.id),
                column: column,
                sorted: sort?.columnId == column.id,
                ascending: sort?.ascending ?? false,
                first: column.id == firstId,
                last: column.id == lastId,
                height: headerHeight,
                onSort: onSort,
                onReorder: onReorder,
                allColumnIds: allColumnIds,
              ),
            ),
        ],
      ),
    );
  }
}

class _HeaderCell<T> extends StatefulWidget {
  const _HeaderCell({
    required this.column,
    required this.sorted,
    required this.ascending,
    required this.first,
    required this.last,
    required this.height,
    required this.onSort,
    required this.onReorder,
    required this.allColumnIds,
    super.key,
  });

  final TpTableColumn<T> column;
  final bool sorted;
  final bool ascending;
  final bool first;
  final bool last;
  final double height;
  final ValueChanged<String> onSort;
  final void Function(String draggedId, String targetId) onReorder;
  final List<String> allColumnIds;

  @override
  State<_HeaderCell<T>> createState() => _HeaderCellState<T>();
}

class _HeaderCellState<T> extends State<_HeaderCell<T>> {
  bool _hovered = false;
  bool _dragging = false;

  bool get _canDrag => widget.column.draggable && !widget.column.locked;

  bool get _canAccept => !widget.column.locked;

  /// The dragged column lands in [widget.column]'s slot, so a column dragged
  /// from the left of this one ends up on the right and vice versa.
  bool _indicatorOnRight(String draggedId) {
    final from = widget.allColumnIds.indexOf(draggedId);
    final to = widget.allColumnIds.indexOf(widget.column.id);
    return from >= 0 && to >= 0 && from < to;
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final styles = TpTextStyles.of(context);

    return DragTarget<String>(
      onWillAcceptWithDetails: (details) =>
          _canAccept && details.data != widget.column.id,
      onAcceptWithDetails: (details) =>
          widget.onReorder(details.data, widget.column.id),
      builder: (context, candidates, rejected) {
        final draggedId = candidates.isNotEmpty ? candidates.first : null;
        final indicatorOnRight =
            draggedId != null && _indicatorOnRight(draggedId);
        return MouseRegion(
          onEnter: (_) => setState(() => _hovered = true),
          onExit: (_) => setState(() => _hovered = false),
          child: Stack(
            children: [
              InkWell(
                onTap: widget.column.sortValue == null
                    ? null
                    : () => widget.onSort(widget.column.id),
                onLongPress: _canDrag
                    ? () => setState(() => _hovered = true)
                    : null,
                child: Padding(
                  padding: tpTableCellPadding(
                    first: widget.first,
                    last: widget.last,
                    groupStart: widget.column.groupStart,
                  ).copyWith(right: _canDrag ? 28 : null),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          widget.column.label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: styles.xs.copyWith(
                            color: cs.onSurface.withValues(alpha: 0.56),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      if (widget.sorted) ...[
                        const SizedBox(width: 2),
                        Icon(
                          widget.ascending
                              ? Icons.arrow_upward
                              : Icons.arrow_downward,
                          size: 12,
                          color: cs.onSurface.withValues(alpha: 0.56),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              if (candidates.isNotEmpty)
                Positioned(
                  left: indicatorOnRight ? null : 0,
                  right: indicatorOnRight ? 0 : null,
                  top: 0,
                  bottom: 0,
                  width: 2,
                  child: ColoredBox(color: cs.primary),
                ),
              if (_canDrag && (_hovered || _dragging))
                Positioned(
                  right: 2,
                  top: 0,
                  bottom: 0,
                  child: Center(
                    child: Draggable<String>(
                      data: widget.column.id,
                      axis: Axis.horizontal,
                      onDragStarted: () => setState(() => _dragging = true),
                      onDragEnd: (_) => setState(() => _dragging = false),
                      feedback: Material(
                        color: Colors.transparent,
                        child: Container(
                          width: 160,
                          height: widget.height,
                          alignment: Alignment.centerLeft,
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          decoration: BoxDecoration(
                            color: cs.surfaceContainer,
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: cs.outlineVariant),
                          ),
                          child: Text(
                            widget.column.label,
                            style: styles.xs.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                      child: const MouseRegion(
                        cursor: SystemMouseCursors.grab,
                        child: Icon(Icons.drag_indicator, size: 14),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

