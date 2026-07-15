import 'package:flutter/material.dart';

import 'tp_select.dart';
import 'tp_select_decoration.dart';

/// Compact bordered [TpSelect] for preference / settings rows.
class TpCompactSelect<T extends Object> extends StatelessWidget {
  const TpCompactSelect({
    super.key,
    required this.value,
    required this.entries,
    required this.onChanged,
    this.itemKeys,
    this.itemBuilder,
    this.listItemBuilder,
    this.searchHintText,
    this.onHighlightChanged,
    this.enabled = true,
    this.minWidth = 140,
  });

  final T value;
  final List<(T value, String label)> entries;
  final ValueChanged<T?> onChanged;
  final Map<T, Key>? itemKeys;
  final Widget Function(BuildContext context, T item)? itemBuilder;
  final Widget Function(BuildContext context, T item)? listItemBuilder;
  final String? searchHintText;
  final ValueChanged<T?>? onHighlightChanged;
  final bool enabled;
  final double minWidth;

  @override
  Widget build(BuildContext context) {
    final decoration = TpSelectDecorations.themed(context);
    final values = entries.map((e) => e.$1).toList();

    String labelOf(T item) => entries
        .firstWhere((e) => e.$1 == item, orElse: () => (item, '$item'))
        .$2;

    return ConstrainedBox(
      constraints: BoxConstraints(minWidth: minWidth),
      child: TpSelect<T>(
        items: values,
        initialItem: value,
        onChanged: onChanged,
        enabled: enabled,
        decoration: decoration,
        listItemKey: itemKeys == null ? null : (item) => itemKeys![item],
        itemLabel: labelOf,
        itemBuilder: itemBuilder,
        listItemBuilder: listItemBuilder,
        searchHintText: searchHintText,
        onHighlightChanged: onHighlightChanged,
      ),
    );
  }
}
