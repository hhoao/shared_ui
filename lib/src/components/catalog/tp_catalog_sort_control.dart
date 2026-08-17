import 'package:flutter/material.dart';

import '../select/tp_select.dart';

/// Localized sort selector shared by catalog toolbars.
class TpCatalogSortControl<T extends Object> extends StatelessWidget {
  const TpCatalogSortControl({
    super.key,
    required this.items,
    required this.initialItem,
    required this.itemLabel,
    required this.onChanged,
    this.hintText,
  });

  final List<T> items;
  final T initialItem;
  final String Function(T item) itemLabel;
  final ValueChanged<T?> onChanged;
  final String? hintText;

  @override
  Widget build(BuildContext context) {
    return TpSelect<T>(
      items: items,
      initialItem: initialItem,
      itemLabel: itemLabel,
      onChanged: onChanged,
      hintText: hintText,
      searchable: false,
    );
  }
}
