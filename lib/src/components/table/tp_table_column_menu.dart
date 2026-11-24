import 'package:flutter/material.dart';

import '../action_menu/tp_action_menu.dart';
import '../icon_button/tp_icon_button.dart';
import '../popover/tp_popover.dart';
import 'tp_table_column.dart';
import 'tp_table_state.dart';

@immutable
class TpDataTableLabels {
  const TpDataTableLabels({
    this.columns = 'Columns',
    this.reset = 'Reset to default',
    this.empty = 'No data',
    this.sortAscending = 'Sort ascending',
    this.sortDescending = 'Sort descending',
  });

  final String columns;
  final String reset;
  final String empty;
  final String sortAscending;
  final String sortDescending;
}

class TpTableColumnMenu<T> extends StatefulWidget {
  const TpTableColumnMenu({
    required this.columns,
    required this.state,
    required this.onChanged,
    required this.labels,
    super.key,
  });

  final List<TpTableColumn<T>> columns;
  final TpTableState state;
  final ValueChanged<TpTableState> onChanged;
  final TpDataTableLabels labels;

  @override
  State<TpTableColumnMenu<T>> createState() => _TpTableColumnMenuState<T>();
}

class _TpTableColumnMenuState<T> extends State<TpTableColumnMenu<T>> {
  late final TpPopoverController _controller = TpPopoverController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _toggle(TpTableColumn<T> column) {
    final hidden = Set<String>.of(widget.state.hidden);
    if (!hidden.add(column.id)) hidden.remove(column.id);
    widget.onChanged(widget.state.copyWith(hidden: hidden));
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final columns = orderedTableColumns(
      widget.columns,
      widget.state,
    ).where((column) => !column.locked).toList(growable: false);

    return TpPopover(
      controller: _controller,
      panelWidth: 220,
      padding: EdgeInsets.zero,
      decoration: TpActionMenuMetrics.panelDecoration(context),
      capHeightToAnchorSide: true,
      anchor: const TpAnchor(
        childAlignment: Alignment.topRight,
        overlayAlignment: Alignment.bottomRight,
        offset: Offset(0, 4),
      ),
      popover: (context) => TpActionMenuPanel(
        children: [
          for (final column in columns)
            TpActionMenuItem(
              label: column.label,
              enabled: column.hideable,
              trailing: Icon(
                Icons.check,
                size: 16,
                color: !widget.state.hidden.contains(column.id)
                    ? cs.primary
                    : Colors.transparent,
              ),
              onTap: column.hideable ? () => _toggle(column) : null,
            ),
          const TpActionMenuDivider(),
          TpActionMenuItem(
            label: widget.labels.reset,
            onTap: () => widget.onChanged(
              widget.state.copyWith(order: const [], hidden: const {}),
            ),
          ),
        ],
      ),
      child: TpIconButton(
        icon: Icons.view_column_outlined,
        tooltip: widget.labels.columns,
        onTap: _controller.toggle,
      ),
    );
  }
}
