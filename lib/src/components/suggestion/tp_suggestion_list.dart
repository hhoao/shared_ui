import 'package:flutter/material.dart';

import '../select/tp_select.dart' show kTpSelectListItemGap, kTpSelectListItemPadding;
import '../select/tp_select_menu_item_button.dart';

/// Shared suggestion panel for combobox (and future select reuse).
class TpSuggestionList<T extends Object> extends StatelessWidget {
  const TpSuggestionList({
    super.key,
    required this.items,
    required this.onItemSelected,
    required this.highlightedIndex,
    this.itemLabel,
    this.itemBuilder,
    this.emptyText = 'No results',
    this.listItemPadding,
    this.selectedItem,
    this.scrollController,
    this.highlightColor,
    this.selectedColor,
    this.borderRadius,
  }) : assert(
         itemLabel != null || itemBuilder != null,
         'Provide itemLabel or itemBuilder',
       );

  final List<T> items;
  final ValueChanged<T> onItemSelected;
  final int highlightedIndex;
  final String Function(T item)? itemLabel;
  final Widget Function(BuildContext context, T item)? itemBuilder;
  final String emptyText;
  final EdgeInsetsGeometry? listItemPadding;
  final T? selectedItem;
  final ScrollController? scrollController;
  final Color? highlightColor;
  final Color? selectedColor;
  final BorderRadius? borderRadius;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final padding = listItemPadding ?? kTpSelectListItemPadding;
    final highlight =
        highlightColor ?? cs.onSurface.withValues(alpha: 0.06);
    final selected = selectedColor ?? cs.primary.withValues(alpha: 0.12);

    if (items.isEmpty) {
      return Padding(
        padding: padding,
        child: Text(
          emptyText,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: cs.onSurfaceVariant,
          ),
        ),
      );
    }

    return ListView.separated(
      controller: scrollController,
      padding: EdgeInsets.zero,
      shrinkWrap: true,
      itemCount: items.length,
      separatorBuilder: (_, __) =>
          const SizedBox(height: kTpSelectListItemGap),
      itemBuilder: (context, index) {
        final item = items[index];
        final isHighlighted = index == highlightedIndex;
        final isSelected = selectedItem != null && item == selectedItem;
        final child = itemBuilder?.call(context, item) ??
            Text(itemLabel!(item));

        return TpSelectMenuItemButton(
          padding: padding,
          highlightColor: highlight,
          selectedColor: selected,
          borderRadius: borderRadius,
          isSelected: isSelected || isHighlighted,
          onTap: () => onItemSelected(item),
          child: child,
        );
      },
    );
  }
}
