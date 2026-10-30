import 'package:flutter/material.dart';

import 'tp_data_table_body.dart';
import 'tp_data_table_header.dart';
import 'tp_table_column.dart';
import 'tp_table_column_menu.dart';
import 'tp_table_state.dart';

class TpDataTable<T> extends StatefulWidget {
  const TpDataTable({
    required this.columns,
    required this.rows,
    required this.rowKey,
    required this.state,
    required this.onStateChanged,
    this.defaultSort,
    this.toolbar,
    this.footer,
    this.emptyState,
    this.rowHeight = 40,
    this.headerHeight = 36,
    this.minTableWidth = 720,
    this.labels = const TpDataTableLabels(),
    super.key,
  });

  final List<TpTableColumn<T>> columns;
  final List<T> rows;
  final String Function(T row) rowKey;
  final TpTableState state;
  final ValueChanged<TpTableState> onStateChanged;
  final TpTableSort? defaultSort;
  final Widget? toolbar;
  final Widget? footer;
  final Widget? emptyState;
  final double rowHeight;
  final double headerHeight;
  final double minTableWidth;
  final TpDataTableLabels labels;

  @override
  State<TpDataTable<T>> createState() => _TpDataTableState<T>();
}

class _TpDataTableState<T> extends State<TpDataTable<T>> {
  int? _hoveredRow;
  final Map<String, double> _draftWidths = {};

  void _setHovered(int index, bool hovered) {
    setState(() {
      if (hovered) {
        _hoveredRow = index;
      } else if (_hoveredRow == index) {
        _hoveredRow = null;
      }
    });
  }

  void _handleSort(String columnId) {
    final current = widget.state.sort ?? widget.defaultSort;
    final TpTableSort? next;
    if (current?.columnId != columnId) {
      next = TpTableSort(columnId: columnId, ascending: false);
    } else if (current!.ascending) {
      next = widget.defaultSort;
    } else {
      next = TpTableSort(columnId: columnId, ascending: true);
    }
    widget.onStateChanged(
      widget.state.copyWith(sort: next, clearSort: next == null),
    );
  }

  List<String> get _orderedColumnIds => orderedTableColumns(
    widget.columns,
    widget.state,
  ).map((column) => column.id).toList(growable: false);

  void _handleReorder(String draggedId, String targetId) {
    final next = reorderTableColumnIds(_orderedColumnIds, draggedId, targetId);
    widget.onStateChanged(widget.state.copyWith(order: next));
  }

  void _handleResize(String columnId, double width) {
    setState(() => _draftWidths[columnId] = width);
  }

  void _handleResizeEnd(String columnId) {
    final width = _draftWidths.remove(columnId);
    if (width == null) return;
    setState(() {});
    widget.onStateChanged(
      widget.state.copyWith(widths: {...widget.state.widths, columnId: width}),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final visible = visibleTableColumns(widget.columns, widget.state);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (widget.toolbar != null) ...[
          widget.toolbar!,
          const SizedBox(height: 10),
        ],
        Divider(height: 1, color: cs.outlineVariant.withValues(alpha: 0.5)),
        if (widget.rows.isEmpty)
          SizedBox(
            height: 160,
            child: Center(
              child: widget.emptyState ?? Text(widget.labels.empty),
            ),
          )
        else
          LayoutBuilder(
            builder: (context, constraints) {
              final widthOverrides = {...widget.state.widths, ..._draftWidths};
              final layout = TpTableLayout.resolve(
                columns: visible,
                availableWidth: constraints.maxWidth,
                minTableWidth: widget.minTableWidth,
                widthOverrides: widthOverrides,
              );
              final pinned = visible
                  .where((column) => column.locked)
                  .toList(growable: false);
              final scrollable = visible
                  .where((column) => !column.locked)
                  .toList(growable: false);
              final pinnedWidth = pinned.fold<double>(
                0,
                (sum, column) => sum + layout.widthOf(column.id),
              );
              final scrollableWidth = scrollable.fold<double>(
                0,
                (sum, column) => sum + layout.widthOf(column.id),
              );
              final firstId = visible.isEmpty ? '' : visible.first.id;
              final lastId = visible.isEmpty ? '' : visible.last.id;
              final effectiveSort = widget.state.sort ?? widget.defaultSort;

              Widget rowsFor(List<TpTableColumn<T>> columns) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TpTableHeader<T>(
                      columns: columns,
                      layout: layout,
                      sort: effectiveSort,
                      onSort: _handleSort,
                      onReorder: _handleReorder,
                      onResize: _handleResize,
                      onResizeEnd: _handleResizeEnd,
                      allColumnIds: _orderedColumnIds,
                      labels: widget.labels,
                      firstId: firstId,
                      lastId: lastId,
                      headerHeight: widget.headerHeight,
                    ),
                    for (var index = 0; index < widget.rows.length; index++)
                      TpTableRow<T>(
                        key: ValueKey(widget.rowKey(widget.rows[index])),
                        columns: columns,
                        layout: layout,
                        row: widget.rows[index],
                        firstId: firstId,
                        lastId: lastId,
                        rowHeight: widget.rowHeight,
                        hovered: _hoveredRow == index,
                        onHoverChanged: (hovered) =>
                            _setHovered(index, hovered),
                      ),
                  ],
                );
              }

              if (pinned.isEmpty) {
                final width = layout.totalWidth < constraints.maxWidth
                    ? constraints.maxWidth
                    : layout.totalWidth;
                return SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: SizedBox(width: width, child: rowsFor(visible)),
                );
              }

              final remainingWidth = constraints.maxWidth - pinnedWidth;
              final scrollWidth = remainingWidth > scrollableWidth
                  ? remainingWidth
                  : scrollableWidth;
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(width: pinnedWidth, child: rowsFor(pinned)),
                  Expanded(
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: SizedBox(
                        width: scrollWidth < 0 ? 0 : scrollWidth,
                        child: rowsFor(scrollable),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        if (widget.footer != null) widget.footer!,
      ],
    );
  }
}
