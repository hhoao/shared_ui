import 'package:flutter/material.dart';

import '../../../../theme/tp_text_styles.dart';
import '../tp_file_selection_strings.dart';

typedef TpFileSortSelected = void Function(
  String sortType, {
  required bool ascending,
});

/// One selectable sort criterion, e.g. `(id: 'date', label: 'Created time')`.
typedef TpFileSortOption = ({String id, String label});

Future<void> showTpFileSortSheet({
  required BuildContext context,
  required TpFileSelectionStrings strings,
  required String currentSortType,
  required bool currentAscending,
  required List<TpFileSortOption> options,
  required TpFileSortSelected onSelected,
}) {
  var ascending = currentAscending;

  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    builder: (context) {
      final styles = TpTextStyles.of(context);

      return StatefulBuilder(
        builder: (context, setSheetState) {
          return SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                  child: Text(
                    strings.sortOptionsTitle,
                    style: styles.mdSemibold,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      Expanded(
                        child: _TpSortDirectionButton(
                          key: const Key('tp_file_sort_ascending'),
                          icon: Icons.arrow_upward,
                          label: strings.sortAscending,
                          selected: ascending,
                          onTap: () => setSheetState(() => ascending = true),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _TpSortDirectionButton(
                          key: const Key('tp_file_sort_descending'),
                          icon: Icons.arrow_downward,
                          label: strings.sortDescending,
                          selected: !ascending,
                          onTap: () => setSheetState(() => ascending = false),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                for (final option in options)
                  ListTile(
                    key: Key('tp_file_sort_option_${option.id}'),
                    title: Text(option.label, style: styles.sm),
                    trailing: currentSortType == option.id
                        ? Icon(
                            Icons.check,
                            color: Theme.of(context).colorScheme.primary,
                          )
                        : null,
                    onTap: () {
                      Navigator.pop(context);
                      onSelected(option.id, ascending: ascending);
                    },
                  ),
              ],
            ),
          );
        },
      );
    },
  );
}

class _TpSortDirectionButton extends StatelessWidget {
  const _TpSortDirectionButton({
    super.key,
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return OutlinedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 16),
      label: Text(label),
      style: OutlinedButton.styleFrom(
        foregroundColor: selected ? cs.primary : cs.onSurfaceVariant,
        backgroundColor: selected ? cs.primaryContainer : Colors.transparent,
        side: BorderSide(
          color: selected ? cs.primary : cs.outlineVariant,
        ),
      ),
    );
  }
}