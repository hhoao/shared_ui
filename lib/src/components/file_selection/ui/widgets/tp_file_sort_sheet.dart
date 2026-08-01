import 'package:flutter/material.dart';

import '../../../../theme/tp_text_styles.dart';
import '../tp_file_selection_strings.dart';

typedef TpFileSortSelected = void Function(String sortType, {required bool ascending});

Future<void> showTpFileSortSheet({
  required BuildContext context,
  required TpFileSelectionStrings strings,
  required String currentSortType,
  required bool currentAscending,
  required TpFileSortSelected onSelected,
}) {
  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    builder: (context) {
      final styles = TpTextStyles.of(context);
      final options = <({String id, String label})>[
        (id: 'name', label: strings.sortByName),
        (id: 'date', label: strings.sortByModifiedTime),
        (id: 'size', label: strings.sortByFileSize),
        (id: 'type', label: strings.sortByFileType),
      ];

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
            for (final option in options)
              ListTile(
                title: Text(option.label, style: styles.sm),
                trailing: currentSortType == option.id
                    ? Icon(
                        currentAscending
                            ? Icons.arrow_upward
                            : Icons.arrow_downward,
                      )
                    : null,
                onTap: () {
                  Navigator.pop(context);
                  if (currentSortType == option.id) {
                    onSelected(option.id, ascending: !currentAscending);
                  } else {
                    onSelected(option.id, ascending: true);
                  }
                },
              ),
          ],
        ),
      );
    },
  );
}
