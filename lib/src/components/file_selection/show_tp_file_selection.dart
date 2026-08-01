import 'package:flutter/material.dart';

import 'models/tp_file_selection_options.dart';
import 'models/tp_picked_entry.dart';
import 'ports/tp_file_selection_deps.dart';
import 'ui/tp_file_selection_page.dart';

Future<List<TpPickedEntry>?> showTpFileSelection({
  required BuildContext context,
  required TpFileSelectionDeps deps,
  TpFileSelectionOptions options = const TpFileSelectionOptions(),
}) async {
  if (deps.isDesktop() && deps.desktop != null) {
    final desktop = deps.desktop!;
    switch (options.selectionMode) {
      case TpSelectionMode.directories:
        return desktop.pickDirectory(
          dialogTitle: options.title,
          initialDirectory: options.initialPath,
        );
      case TpSelectionMode.files:
      case TpSelectionMode.both:
        return desktop.pickFiles(
          allowMultiple: options.allowMultiple,
          allowedExtensions: options.allowedExtensions,
          dialogTitle: options.title,
          initialDirectory: options.initialPath,
          maxSelectionCount: options.maxSelectionCount,
        );
    }
  }
  return Navigator.of(context).push<List<TpPickedEntry>>(
    MaterialPageRoute(
      builder: (_) => TpFileSelectionPage(deps: deps, options: options),
    ),
  );
}
