import 'package:flutter/material.dart';

import '../../../../theme/tp_text_styles.dart';
import '../../models/tp_fs_entry.dart';
import '../../models/tp_file_selection_options.dart';
import '../../models/tp_picked_entry.dart';
import '../tp_file_selection_strings.dart';

typedef TpFsEntryToggle = void Function(TpFsEntry entry);
typedef TpFsEntryNavigate = void Function(TpFsEntry entry);

class TpFsEntryTile extends StatelessWidget {
  const TpFsEntryTile({
    super.key,
    required this.entry,
    required this.options,
    required this.strings,
    required this.isSelected,
    required this.isSelectable,
    required this.isAllowed,
    required this.onToggle,
    required this.onNavigate,
    this.subtitle,
  });

  final TpFsEntry entry;
  final TpFileSelectionOptions options;
  final TpFileSelectionStrings strings;
  final bool isSelected;
  final bool isSelectable;
  final bool isAllowed;
  final TpFsEntryToggle onToggle;
  final TpFsEntryNavigate onNavigate;
  final String? subtitle;

  bool get _isDirectory => entry.kind == TpFsEntryKind.directory;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final styles = TpTextStyles.of(context);
    final titleStyle = isAllowed
        ? styles.smMedium
        : styles.smMediumColored(cs.onSurfaceVariant);

    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(
        _isDirectory ? Icons.folder : Icons.insert_drive_file_outlined,
        color: _isDirectory ? cs.tertiary : (isAllowed ? cs.primary : cs.outline),
        size: 32,
      ),
      title: Row(
        children: [
          Expanded(
            child: Text(
              entry.name,
              style: titleStyle,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 10),
          if (isSelectable && isAllowed)
            Checkbox(
              value: isSelected,
              onChanged: (_) => onToggle(entry),
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            )
          else
            const SizedBox(width: 40),
        ],
      ),
      subtitle: subtitle == null ? null : Text(subtitle!, style: styles.mutedSm),
      trailing: _isDirectory
          ? Icon(Icons.chevron_right, color: cs.onSurfaceVariant)
          : null,
      onTap: () => _handleTap(),
    );
  }

  void _handleTap() {
    if (_isDirectory) {
      if (options.selectionMode == TpSelectionMode.directories) {
        onToggle(entry);
        return;
      }
      if (options.selectionMode == TpSelectionMode.both) {
        onToggle(entry);
        return;
      }
      onNavigate(entry);
      return;
    }

    if (isAllowed && options.selectionMode != TpSelectionMode.directories) {
      onToggle(entry);
    }
  }
}

TpPickedEntry tpFsEntryToPicked(TpFsEntry entry) {
  return TpPickedEntry(
    path: entry.path,
    kind: entry.kind == TpFsEntryKind.directory
        ? TpPickedKind.directory
        : TpPickedKind.file,
    displayName: entry.name,
  );
}

bool tpFsEntryIsAllowed(
  TpFsEntry entry,
  TpFileSelectionOptions options,
) {
  if (entry.kind != TpFsEntryKind.file) {
    return true;
  }
  final allowed = options.allowedExtensions;
  if (allowed == null || allowed.isEmpty) {
    return true;
  }
  final dotIndex = entry.name.lastIndexOf('.');
  if (dotIndex <= 0) {
    return false;
  }
  final ext = entry.name.substring(dotIndex + 1).toLowerCase();
  return allowed.any((allowedExt) {
    final normalized = allowedExt.trim().toLowerCase();
    final withoutDot =
        normalized.startsWith('.') ? normalized.substring(1) : normalized;
    return ext == withoutDot;
  });
}

bool tpFsEntryIsSelectable(
  TpFsEntry entry,
  TpFileSelectionOptions options,
) {
  if (entry.kind == TpFsEntryKind.directory) {
    return options.selectionMode != TpSelectionMode.files;
  }
  if (entry.kind == TpFsEntryKind.file) {
    return options.selectionMode != TpSelectionMode.directories;
  }
  return false;
}
