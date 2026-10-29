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
    required this.firstId,
    required this.lastId,
    required this.headerHeight,
    super.key,
  });

  final List<TpTableColumn<T>> columns;
  final TpTableLayout layout;
  final TpTableSort? sort;
  final ValueChanged<String> onSort;
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
                onSort: onSort,
              ),
            ),
        ],
      ),
    );
  }
}

class _HeaderCell<T> extends StatelessWidget {
  const _HeaderCell({
    required this.column,
    required this.sorted,
    required this.ascending,
    required this.first,
    required this.last,
    required this.onSort,
    super.key,
  });

  final TpTableColumn<T> column;
  final bool sorted;
  final bool ascending;
  final bool first;
  final bool last;
  final ValueChanged<String> onSort;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final styles = TpTextStyles.of(context);
    return InkWell(
      onTap: column.sortValue == null ? null : () => onSort(column.id),
      child: Padding(
        padding: tpTableCellPadding(
          first: first,
          last: last,
          groupStart: column.groupStart,
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                column.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: styles.xs.copyWith(
                  color: cs.onSurface.withValues(alpha: 0.56),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            if (sorted) ...[
              const SizedBox(width: 2),
              Icon(
                ascending ? Icons.arrow_upward : Icons.arrow_downward,
                size: 12,
                color: cs.onSurface.withValues(alpha: 0.56),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
