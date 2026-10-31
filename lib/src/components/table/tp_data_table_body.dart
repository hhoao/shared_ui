import 'package:flutter/material.dart';

import 'tp_table_column.dart';

class TpTableRow<T> extends StatelessWidget {
  const TpTableRow({
    required this.columns,
    required this.layout,
    required this.row,
    required this.firstId,
    required this.lastId,
    required this.rowHeight,
    required this.hovered,
    required this.onHoverChanged,
    super.key,
  });

  final List<TpTableColumn<T>> columns;
  final TpTableLayout layout;
  final T row;
  final String firstId;
  final String lastId;
  final double rowHeight;
  final bool hovered;
  final ValueChanged<bool> onHoverChanged;

  Widget _cellWithTooltip(
    BuildContext context,
    TpTableColumn<T> column,
    T row,
  ) {
    final cell = column.cellBuilder(context, row);
    final message = column.tooltip?.call(row);
    if (message == null || message.isEmpty) return cell;
    return Tooltip(
      message: message,
      waitDuration: const Duration(milliseconds: 400),
      child: cell,
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return MouseRegion(
      onEnter: (_) => onHoverChanged(true),
      onExit: (_) => onHoverChanged(false),
      child: Container(
        height: rowHeight,
        decoration: BoxDecoration(
          color: hovered
              ? cs.surfaceContainerHighest.withValues(alpha: 0.4)
              : null,
          border: Border(
            top: BorderSide(
              color: cs.outlineVariant.withValues(alpha: 0.35),
            ),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (final column in columns)
              SizedBox(
                width: layout.widthOf(column.id),
                child: Padding(
                  padding: tpTableCellPadding(
                    first: column.id == firstId,
                    last: column.id == lastId,
                    groupStart: column.groupStart,
                  ),
                  child: Align(
                    alignment: column.alignment,
                    child: _cellWithTooltip(context, column, row),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
