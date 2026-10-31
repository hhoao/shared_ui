import 'package:flutter/material.dart';

import '../../theme/tp_text_styles.dart';
import 'tp_table_column.dart';
import 'tp_table_column_menu.dart';
import 'tp_table_state.dart';

class TpTableHeader<T> extends StatelessWidget {
  const TpTableHeader({
    required this.columns,
    required this.layout,
    required this.sort,
    required this.onSort,
    required this.onReorder,
    required this.onResize,
    required this.onResizeStart,
    required this.onResizeEnd,
    required this.onResizeCancel,
    required this.onResizeReset,
    required this.allColumnIds,
    required this.labels,
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
  final void Function(String columnId, double width) onResize;
  final ValueChanged<String> onResizeStart;
  final ValueChanged<String> onResizeEnd;
  final ValueChanged<String> onResizeCancel;
  final ValueChanged<String> onResizeReset;

  /// Every column id in display order, including locked and hidden ones.
  final List<String> allColumnIds;
  final TpDataTableLabels labels;
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
                width: layout.widthOf(column.id),
                resizable: column.resizable,
                onSort: onSort,
                onReorder: onReorder,
                onResize: onResize,
                onResizeStart: onResizeStart,
                onResizeEnd: onResizeEnd,
                onResizeCancel: onResizeCancel,
                onResizeReset: onResizeReset,
                allColumnIds: allColumnIds,
                labels: labels,
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
    required this.width,
    required this.resizable,
    required this.onSort,
    required this.onReorder,
    required this.onResize,
    required this.onResizeStart,
    required this.onResizeEnd,
    required this.onResizeCancel,
    required this.onResizeReset,
    required this.allColumnIds,
    required this.labels,
    super.key,
  });

  final TpTableColumn<T> column;
  final bool sorted;
  final bool ascending;
  final bool first;
  final bool last;
  final double height;
  final double width;
  final bool resizable;
  final ValueChanged<String> onSort;
  final void Function(String draggedId, String targetId) onReorder;
  final void Function(String columnId, double width) onResize;
  final ValueChanged<String> onResizeStart;
  final ValueChanged<String> onResizeEnd;
  final ValueChanged<String> onResizeCancel;
  final ValueChanged<String> onResizeReset;
  final List<String> allColumnIds;
  final TpDataTableLabels labels;

  @override
  State<_HeaderCell<T>> createState() => _HeaderCellState<T>();
}

class _HeaderCellState<T> extends State<_HeaderCell<T>> {
  bool _hovered = false;
  bool _dragging = false;
  bool _resizeHovered = false;
  double _resizeStartWidth = 0;
  int? _resizePointer;
  double _resizeStartX = 0;
  bool _resizeMoved = false;

  bool get _canDrag => widget.column.draggable && !widget.column.locked;

  bool get _canAccept => !widget.column.locked;

  void _finishResize() {
    _resizePointer = null;
    if (_resizeMoved) {
      widget.onResizeEnd(widget.column.id);
    } else {
      widget.onResizeCancel(widget.column.id);
    }
  }

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
    final sortControl = InkWell(
      onTap: widget.column.sortValue == null
          ? null
          : () => widget.onSort(widget.column.id),
      onLongPress: _canDrag ? () => setState(() => _hovered = true) : null,
      child: Padding(
        padding: tpTableCellPadding(
          first: widget.first,
          last: widget.last,
          groupStart: widget.column.groupStart,
        ).copyWith(end: 8),
        child: Row(
          children: [
            Expanded(
              child: Text(
                widget.column.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: styles.mdSemibold.copyWith(
                  color: cs.onSurface.withValues(alpha: 0.56),
                ),
              ),
            ),
            if (widget.sorted) ...[
              const SizedBox(width: 2),
              Icon(
                widget.ascending ? Icons.arrow_upward : Icons.arrow_downward,
                size: 12,
                color: cs.onSurface.withValues(alpha: 0.56),
              ),
            ],
          ],
        ),
      ),
    );
    final header = widget.column.sortValue == null
        ? sortControl
        : Tooltip(
            message: widget.sorted && !widget.ascending
                ? widget.labels.sortAscending
                : widget.labels.sortDescending,
            triggerMode: TooltipTriggerMode.manual,
            child: sortControl,
          );

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
              Positioned.fill(child: header),
              if (candidates.isNotEmpty)
                PositionedDirectional(
                  start: indicatorOnRight ? null : 0,
                  end: indicatorOnRight ? 0 : null,
                  top: 0,
                  bottom: 0,
                  width: 2,
                  child: ColoredBox(color: cs.primary),
                ),
              if (_canDrag && (_hovered || _dragging))
                PositionedDirectional(
                  end: 14,
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
              if (widget.resizable && !widget.last)
                PositionedDirectional(
                  end: 0,
                  top: 0,
                  bottom: 0,
                  child: MouseRegion(
                    cursor: SystemMouseCursors.resizeColumn,
                    onEnter: (_) => setState(() => _resizeHovered = true),
                    onExit: (_) => setState(() => _resizeHovered = false),
                    child: GestureDetector(
                      onDoubleTap: () => widget.onResizeReset(widget.column.id),
                      child: Listener(
                        key: ValueKey('resize-${widget.column.id}'),
                        behavior: HitTestBehavior.opaque,
                        onPointerDown: (event) {
                          if (_resizePointer != null) return;
                          _resizePointer = event.pointer;
                          _resizeStartX = event.position.dx;
                          _resizeStartWidth = widget.width;
                          _resizeMoved = false;
                          widget.onResizeStart(widget.column.id);
                        },
                        onPointerMove: (event) {
                          if (event.pointer != _resizePointer) return;
                          final delta = event.position.dx - _resizeStartX;
                          if (delta.abs() > 2) _resizeMoved = true;
                          widget.onResize(
                            widget.column.id,
                            _resizeStartWidth + delta,
                          );
                        },
                        onPointerUp: (event) {
                          if (event.pointer != _resizePointer) return;
                          _finishResize();
                        },
                        onPointerCancel: (event) {
                          if (event.pointer != _resizePointer) return;
                          _finishResize();
                        },
                        child: SizedBox(
                          width: 12,
                          child: Center(
                            child: Container(
                              width: _resizeHovered ? 3 : 1,
                              color: _resizeHovered
                                  ? cs.primary
                                  : cs.outlineVariant.withValues(alpha: 0.6),
                            ),
                          ),
                        ),
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
