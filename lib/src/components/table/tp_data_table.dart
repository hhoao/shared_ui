import 'dart:math' as math;

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
    this.fit = true,
    this.height,
    this.maxHeight,
    this.alwaysShowScrollbar = false,
    this.showScrollbar = true,
    this.horizontalScroll = true,
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

  /// Stretches the last column without a manual width so the table always
  /// fills its available width. Set to false to leave a gap.
  final bool fit;

  /// Fixed total table height (header + body). When null, the table grows with
  /// its rows and the surrounding page scrolls instead.
  final double? height;

  /// Maximum total table height (header + body). The table grows with its rows
  /// until this cap, then the body scrolls under a sticky header.
  final double? maxHeight;

  /// Keeps the horizontal scrollbar visible instead of showing it on hover.
  final bool alwaysShowScrollbar;

  /// Set to false to hide the horizontal scrollbar entirely.
  final bool showScrollbar;

  /// Set to false to disable horizontal scrolling and fit columns to the
  /// available width.
  final bool horizontalScroll;

  final TpDataTableLabels labels;

  @override
  State<TpDataTable<T>> createState() => _TpDataTableState<T>();
}

class _TpDataTableState<T> extends State<TpDataTable<T>> {
  int? _hoveredRow;
  final Map<String, double> _draftWidths = {};
  bool _resizing = false;

  final ScrollController _pinnedVertical = ScrollController();
  final ScrollController _scrollableVertical = ScrollController();
  final ScrollController _scrollableHorizontal = ScrollController();
  final ScrollController _headerHorizontal = ScrollController();
  bool _syncing = false;

  @override
  void initState() {
    super.initState();
    _pinnedVertical.addListener(_syncPinnedToScrollable);
    _scrollableVertical.addListener(_syncScrollableToPinned);
    _scrollableHorizontal.addListener(_syncBodyToHeader);
    _headerHorizontal.addListener(_syncHeaderToBody);
  }

  @override
  void dispose() {
    _pinnedVertical.dispose();
    _scrollableVertical.dispose();
    _scrollableHorizontal.dispose();
    _headerHorizontal.dispose();
    super.dispose();
  }

  void _syncScroll(ScrollController from, ScrollController to) {
    if (_syncing || !from.hasClients || !to.hasClients) return;
    final target = from.offset.clamp(
      to.position.minScrollExtent,
      to.position.maxScrollExtent,
    );
    if ((to.offset - target).abs() < 0.5) return;
    _syncing = true;
    to.jumpTo(target);
    _syncing = false;
  }

  void _syncPinnedToScrollable() =>
      _syncScroll(_pinnedVertical, _scrollableVertical);

  void _syncScrollableToPinned() =>
      _syncScroll(_scrollableVertical, _pinnedVertical);

  void _syncBodyToHeader() =>
      _syncScroll(_scrollableHorizontal, _headerHorizontal);

  void _syncHeaderToBody() =>
      _syncScroll(_headerHorizontal, _scrollableHorizontal);

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

  void _handleResizeStart(String columnId) {
    setState(() => _resizing = true);
  }

  void _handleResizeCancel(String columnId) {
    _draftWidths.remove(columnId);
    setState(() => _resizing = false);
  }

  void _handleResizeEnd(String columnId) {
    final width = _draftWidths.remove(columnId);
    if (width == null) {
      setState(() => _resizing = false);
      return;
    }
    TpTableColumn<T>? column;
    for (final item in widget.columns) {
      if (item.id == columnId) {
        column = item;
        break;
      }
    }
    final clamped = width.clamp(
      column?.minWidth ?? 60.0,
      column?.maxWidth ?? 640.0,
    );
    setState(() {});
    widget.onStateChanged(
      widget.state.copyWith(
        widths: {...widget.state.widths, columnId: clamped},
      ),
    );
    setState(() => _resizing = false);
  }

  void _handleResizeReset(String columnId) {
    final next = {...widget.state.widths}..remove(columnId);
    _draftWidths.remove(columnId);
    setState(() => _resizing = false);
    widget.onStateChanged(widget.state.copyWith(widths: next));
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
                minTableWidth: widget.horizontalScroll
                    ? widget.minTableWidth
                    : 0,
                widthOverrides: widthOverrides,
                fit: widget.fit,
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
              final tableWidth = !widget.horizontalScroll
                  ? constraints.maxWidth
                  : (layout.totalWidth < constraints.maxWidth
                        ? constraints.maxWidth
                        : layout.totalWidth);
              final remainingWidth = constraints.maxWidth - pinnedWidth;
              final scrollWidth = remainingWidth > scrollableWidth
                  ? remainingWidth
                  : scrollableWidth;

              TpTableHeader<T> header(List<TpTableColumn<T>> columns) {
                return TpTableHeader<T>(
                  columns: columns,
                  layout: layout,
                  sort: effectiveSort,
                  onSort: _handleSort,
                  onReorder: _handleReorder,
                  onResize: _handleResize,
                  onResizeStart: _handleResizeStart,
                  onResizeEnd: _handleResizeEnd,
                  onResizeCancel: _handleResizeCancel,
                  onResizeReset: _handleResizeReset,
                  allColumnIds: _orderedColumnIds,
                  labels: widget.labels,
                  firstId: firstId,
                  lastId: lastId,
                  headerHeight: widget.headerHeight,
                );
              }

              TpTableRow<T> row(List<TpTableColumn<T>> columns, int index) {
                final item = widget.rows[index];
                return TpTableRow<T>(
                  key: ValueKey(widget.rowKey(item)),
                  columns: columns,
                  layout: layout,
                  row: item,
                  firstId: firstId,
                  lastId: lastId,
                  rowHeight: widget.rowHeight,
                  hovered: _hoveredRow == index,
                  onHoverChanged: (hovered) => _setHovered(index, hovered),
                );
              }

              final bounded = widget.height != null || widget.maxHeight != null;
              if (!bounded) {
                return _unboundedBody(
                  visible: visible,
                  pinned: pinned,
                  scrollable: scrollable,
                  pinnedWidth: pinnedWidth,
                  scrollWidth: scrollWidth < 0 ? 0 : scrollWidth,
                  tableWidth: tableWidth,
                  header: header,
                  row: row,
                );
              }

              return _boundedBody(
                visible: visible,
                pinned: pinned,
                scrollable: scrollable,
                pinnedWidth: pinnedWidth,
                scrollWidth: scrollWidth < 0 ? 0 : scrollWidth,
                tableWidth: tableWidth,
                bodyHeight: _bodyHeight(),
                header: header,
                row: row,
              );
            },
          ),
        if (widget.footer != null) widget.footer!,
      ],
    );
  }

  double _bodyHeight() {
    final contentHeight = widget.rows.length * widget.rowHeight;
    final height = widget.height;
    if (height != null) {
      return math.max(0, height - widget.headerHeight);
    }
    return math.max(
      0,
      math.min(contentHeight, widget.maxHeight! - widget.headerHeight),
    );
  }

  Widget _unboundedBody({
    required List<TpTableColumn<T>> visible,
    required List<TpTableColumn<T>> pinned,
    required List<TpTableColumn<T>> scrollable,
    required double pinnedWidth,
    required double scrollWidth,
    required double tableWidth,
    required TpTableHeader<T> Function(List<TpTableColumn<T>>) header,
    required TpTableRow<T> Function(List<TpTableColumn<T>>, int) row,
  }) {
    Widget rowsFor(List<TpTableColumn<T>> columns) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          header(columns),
          for (var index = 0; index < widget.rows.length; index++)
            row(columns, index),
        ],
      );
    }

    if (pinned.isEmpty) {
      return SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        physics: _resizing || !widget.horizontalScroll
            ? const NeverScrollableScrollPhysics()
            : null,
        child: SizedBox(width: tableWidth, child: rowsFor(visible)),
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(width: pinnedWidth, child: rowsFor(pinned)),
        Expanded(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: _resizing || !widget.horizontalScroll
                ? const NeverScrollableScrollPhysics()
                : null,
            child: SizedBox(width: scrollWidth, child: rowsFor(scrollable)),
          ),
        ),
      ],
    );
  }

  Widget _boundedBody({
    required List<TpTableColumn<T>> visible,
    required List<TpTableColumn<T>> pinned,
    required List<TpTableColumn<T>> scrollable,
    required double pinnedWidth,
    required double scrollWidth,
    required double tableWidth,
    required double bodyHeight,
    required TpTableHeader<T> Function(List<TpTableColumn<T>>) header,
    required TpTableRow<T> Function(List<TpTableColumn<T>>, int) row,
  }) {
    Widget horizontalBody({
      required ScrollController controller,
      required double width,
      required Widget child,
    }) {
      final scrollView = SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        physics: _resizing || !widget.horizontalScroll
            ? const NeverScrollableScrollPhysics()
            : null,
        controller: controller,
        child: SizedBox(width: width, child: child),
      );
      if (!widget.showScrollbar) return scrollView;
      return Scrollbar(
        controller: controller,
        thumbVisibility: widget.alwaysShowScrollbar,
        notificationPredicate: (notification) =>
            notification.metrics.axis == Axis.horizontal,
        child: scrollView,
      );
    }

    if (pinned.isEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: _resizing || !widget.horizontalScroll
                ? const NeverScrollableScrollPhysics()
                : null,
            controller: _headerHorizontal,
            child: SizedBox(width: tableWidth, child: header(visible)),
          ),
          SizedBox(
            height: bodyHeight,
            child: horizontalBody(
              controller: _scrollableHorizontal,
              width: tableWidth,
              child: ListView.builder(
                controller: _scrollableVertical,
                itemExtent: widget.rowHeight,
                itemCount: widget.rows.length,
                itemBuilder: (context, index) => row(visible, index),
              ),
            ),
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            SizedBox(width: pinnedWidth, child: header(pinned)),
            Expanded(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                physics: _resizing
                    ? const NeverScrollableScrollPhysics()
                    : null,
                controller: _headerHorizontal,
                child: SizedBox(width: scrollWidth, child: header(scrollable)),
              ),
            ),
          ],
        ),
        SizedBox(
          height: bodyHeight,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: pinnedWidth,
                child: ListView.builder(
                  controller: _pinnedVertical,
                  itemExtent: widget.rowHeight,
                  itemCount: widget.rows.length,
                  itemBuilder: (context, index) => row(pinned, index),
                ),
              ),
              Expanded(
                child: horizontalBody(
                  controller: _scrollableHorizontal,
                  width: scrollWidth,
                  child: ListView.builder(
                    controller: _scrollableVertical,
                    itemExtent: widget.rowHeight,
                    itemCount: widget.rows.length,
                    itemBuilder: (context, index) => row(scrollable, index),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
