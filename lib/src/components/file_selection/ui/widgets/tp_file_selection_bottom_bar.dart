import 'package:flutter/material.dart';

import '../../../../theme/tp_text_styles.dart';
import '../tp_file_selection_strings.dart';

/// Selection bottom bar shared by the file-selection page layouts.
///
/// Renders either the directory-mode bar (current path + select-this-directory)
/// or the multi-select bar (clear / select all + summary + confirm). The
/// [TpFileSelectionPage] keys are preserved so existing tests keep working.
///
/// Set [classic] to restore the legacy restcut look: blue text buttons, a
/// trailing checkbox on select-all, icon-prefixed summary rows and a filled
/// confirm button labelled "选择(N)".
class TpFileSelectionBottomBar extends StatelessWidget {
  const TpFileSelectionBottomBar.file({
    super.key,
    required this.strings,
    required this.selectionCount,
    required this.maxSelectionCount,
    required this.selectionSummary,
    required this.confirmLabel,
    required this.onClearSelection,
    required this.onToggleSelectAll,
    required this.onConfirm,
    this.classic = false,
    this.isAllSelected = false,
    this.selectionPrompt,
  })  : isDirectoryMode = false,
        currentPath = null,
        onConfirmDirectory = null;

  const TpFileSelectionBottomBar.directory({
    super.key,
    required this.strings,
    required this.currentPath,
    required this.onConfirmDirectory,
  })  : isDirectoryMode = true,
        selectionCount = 0,
        maxSelectionCount = null,
        selectionSummary = null,
        confirmLabel = null,
        onClearSelection = null,
        onToggleSelectAll = null,
        onConfirm = null,
        classic = false,
        isAllSelected = false,
        selectionPrompt = null;

  final TpFileSelectionStrings strings;
  final bool isDirectoryMode;

  // Directory mode.
  final String? currentPath;
  final VoidCallback? onConfirmDirectory;

  // File mode.
  final int selectionCount;
  final int? maxSelectionCount;
  final String? selectionSummary;
  final String? confirmLabel;
  final VoidCallback? onClearSelection;
  final VoidCallback? onToggleSelectAll;
  final VoidCallback? onConfirm;

  /// Legacy visual style (restcut-era picker).
  final bool classic;

  /// Whether every selectable item is currently selected (classic checkbox).
  final bool isAllSelected;

  /// Empty-state prompt shown instead of the summary (classic style), e.g.
  /// "请选择视频文件".
  final String? selectionPrompt;

  @override
  Widget build(BuildContext context) {
    final styles = TpTextStyles.of(context);
    final cs = Theme.of(context).colorScheme;

    if (isDirectoryMode) {
      return Row(
        children: [
          Icon(Icons.folder_outlined, color: cs.primary, size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(strings.currentDirectoryLabel, style: styles.mutedXs),
                Text(
                  currentPath ?? '',
                  style: styles.smMediumColored(cs.primary),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          ElevatedButton(
            key: const Key('tp_file_selection_select_directory'),
            onPressed: onConfirmDirectory,
            style: _classicConfirmStyle(cs),
            child: Text(
              strings.selectThisDirectory,
              style: const TextStyle(fontSize: 12),
            ),
          ),
        ],
      );
    }

    if (classic) {
      return _buildClassicFileBar(context, cs);
    }

    final hasSelection = selectionCount > 0;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            TextButton(
              key: const Key('tp_file_selection_clear'),
              onPressed: hasSelection ? onClearSelection : null,
              child: Text(strings.clearSelection),
            ),
            if (maxSelectionCount != null) ...[
              const SizedBox(width: 8),
              Text(
                '$selectionCount/$maxSelectionCount',
                style: styles.mutedSm,
              ),
            ],
            const Spacer(),
            TextButton(
              key: const Key('tp_file_selection_select_all'),
              onPressed: onToggleSelectAll,
              child: Text(strings.selectAll),
            ),
          ],
        ),
        const Divider(height: 16),
        Row(
          children: [
            Expanded(
              child: Text(
                selectionSummary ?? strings.noItemsSelected,
                style: hasSelection
                    ? styles.smMediumColored(cs.primary)
                    : styles.mutedSm,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 12),
            ElevatedButton(
              key: const Key('tp_file_selection_confirm'),
              onPressed: hasSelection ? onConfirm : null,
              child: Text(confirmLabel ?? strings.actionConfirm),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildClassicFileBar(BuildContext context, ColorScheme cs) {
    final hasSelection = selectionCount > 0;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            TextButton(
              key: const Key('tp_file_selection_clear'),
              onPressed: hasSelection ? onClearSelection : null,
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                minimumSize: Size.zero,
                foregroundColor: hasSelection ? cs.primary : cs.outline,
              ),
              child: Text(
                strings.clearSelection,
                style: const TextStyle(fontSize: 13),
              ),
            ),
            if (maxSelectionCount != null) ...[
              const SizedBox(width: 10),
              Text(
                '$selectionCount/$maxSelectionCount',
                style: TextStyle(
                  color: cs.primary.withValues(alpha: 0.8),
                  fontSize: 12,
                ),
              ),
            ],
            const Spacer(),
            TextButton(
              key: const Key('tp_file_selection_select_all'),
              onPressed: onToggleSelectAll,
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                minimumSize: Size.zero,
                foregroundColor: cs.onSurface,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(strings.selectAll, style: const TextStyle(fontSize: 13)),
                  const SizedBox(width: 8),
                  _ClassicSelectAllCheckbox(
                    checked: isAllSelected,
                    color: cs.primary,
                    outline: cs.outline,
                  ),
                ],
              ),
            ),
          ],
        ),
        Container(height: 1, color: cs.outlineVariant.withValues(alpha: 0.4)),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: Row(
                children: [
                  if (hasSelection) ...[
                    Icon(Icons.check_circle, color: cs.primary, size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        selectionSummary ?? '',
                        style: TextStyle(
                          color: cs.primary,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ] else ...[
                    Icon(Icons.folder_open, color: cs.outline, size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        selectionPrompt ?? strings.noItemsSelected,
                        style: TextStyle(
                          color: cs.onSurfaceVariant.withValues(alpha: 0.7),
                          fontSize: 14,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 12),
            ElevatedButton(
              key: const Key('tp_file_selection_confirm'),
              onPressed: hasSelection ? onConfirm : null,
              style: _classicConfirmStyle(cs),
              child: Text(
                confirmLabel ?? strings.actionConfirm,
                style: const TextStyle(fontSize: 12),
              ),
            ),
          ],
        ),
      ],
    );
  }

  ButtonStyle _classicConfirmStyle(ColorScheme cs) {
    return ElevatedButton.styleFrom(
      backgroundColor: cs.primary,
      disabledBackgroundColor: cs.surfaceContainerHighest,
      disabledForegroundColor: cs.onSurfaceVariant,
      foregroundColor: cs.onPrimary,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      minimumSize: const Size(60, 32),
    );
  }
}

class _ClassicSelectAllCheckbox extends StatelessWidget {
  const _ClassicSelectAllCheckbox({
    required this.checked,
    required this.color,
    required this.outline,
  });

  final bool checked;
  final Color color;
  final Color outline;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 20,
      height: 20,
      decoration: BoxDecoration(
        color: checked ? color : Colors.transparent,
        border: Border.all(color: checked ? color : outline, width: 2),
        borderRadius: BorderRadius.circular(4),
      ),
      child: checked
          ? const Icon(Icons.check, color: Colors.white, size: 14)
          : null,
    );
  }
}
