import 'package:flutter/material.dart';

import '../../../../theme/tp_text_styles.dart';
import '../../../button/tp_button.dart';
import '../../../dialog/tp_dialog.dart';
import '../../../empty_state/tp_empty_state.dart';
import '../../../input/tp_input.dart';
import '../../models/tp_fs_entry.dart';
import '../../models/tp_file_selection_options.dart';
import '../../models/tp_picked_entry.dart';
import '../../ports/tp_filesystem_port.dart';
import '../../../select/tp_select.dart';
import '../tp_file_selection_strings.dart';
import 'tp_fs_entry_tile.dart';

class TpFullDiskSearchDialog extends StatefulWidget {
  const TpFullDiskSearchDialog({
    super.key,
    required this.strings,
    required this.filesystem,
    required this.allowedExtensions,
    required this.onFilesSelected,
    this.phoneStorageRoot,
  });

  final TpFileSelectionStrings strings;
  final TpFilesystemPort filesystem;
  final List<String>? allowedExtensions;
  final ValueChanged<List<TpPickedEntry>> onFilesSelected;
  final TpFilesystemRoot? phoneStorageRoot;

  @override
  State<TpFullDiskSearchDialog> createState() => _TpFullDiskSearchDialogState();
}

class _TpFullDiskSearchDialogState extends State<TpFullDiskSearchDialog> {
  final _queryController = TextEditingController();
  final _selectedPaths = <String>{};
  List<TpFsEntry> _results = [];
  bool _isSearching = false;
  String _query = '';
  late String _selectedSearchPath;
  late List<({String label, String path})> _scopes;

  @override
  void initState() {
    super.initState();
    _scopes = _buildSearchScopes();
    _selectedSearchPath =
        widget.phoneStorageRoot?.path ?? widget.filesystem.defaultBrowsePath();
  }

  @override
  void dispose() {
    _queryController.dispose();
    super.dispose();
  }

  List<({String label, String path})> _buildSearchScopes() {
    final rootPath =
        widget.phoneStorageRoot?.path ?? widget.filesystem.defaultBrowsePath();
    final s = widget.strings;
    return [
      (label: s.searchPathEntireStorage, path: rootPath),
      (label: s.searchPathDcim, path: '$rootPath/DCIM'),
      (label: s.searchPathPictures, path: '$rootPath/Pictures'),
      (label: s.searchPathDownload, path: '$rootPath/Download'),
      (label: s.searchPathDocuments, path: '$rootPath/Documents'),
      (label: s.searchPathMusic, path: '$rootPath/Music'),
      (label: s.searchPathMovies, path: '$rootPath/Movies'),
    ];
  }

  String _scopeLabel(String path) {
    for (final scope in _scopes) {
      if (scope.path == path) return scope.label;
    }
    return path;
  }

  Future<void> _performSearch() async {
    final strings = widget.strings;
    if (_query.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(strings.enterSearchKeyword)),
      );
      return;
    }

    final searchFn = widget.filesystem.searchFiles;
    if (searchFn == null) {
      return;
    }

    setState(() {
      _isSearching = true;
      _results = [];
      _selectedPaths.clear();
    });

    try {
      final results = await searchFn(_selectedSearchPath, _query.trim());
      if (!mounted) return;
      setState(() {
        _results = (results ?? const <TpFsEntry>[])
            .where(
              (entry) => tpFsEntryIsAllowed(
                entry,
                TpFileSelectionOptions(allowedExtensions: widget.allowedExtensions),
              ),
            )
            .toList();
        _isSearching = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() => _isSearching = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(strings.searchFailedWithError('$error'))),
      );
    }
  }

  void _toggleSelection(TpFsEntry entry) {
    setState(() {
      if (_selectedPaths.contains(entry.path)) {
        _selectedPaths.remove(entry.path);
      } else {
        _selectedPaths.add(entry.path);
      }
    });
  }

  void _toggleSelectAll() {
    setState(() {
      if (_selectedPaths.length == _results.length) {
        _selectedPaths.clear();
      } else {
        _selectedPaths
          ..clear()
          ..addAll(_results.map((entry) => entry.path));
      }
    });
  }

  String _formatFileSize(int? bytes) {
    if (bytes == null) return '';
    if (bytes < 1024) return '${bytes}B';
    if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)}KB';
    }
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)}MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)}GB';
  }

  @override
  Widget build(BuildContext context) {
    final strings = widget.strings;
    final cs = Theme.of(context).colorScheme;
    final styles = TpTextStyles.of(context);
    final scopePaths = _scopes.map((scope) => scope.path).toList();

    return TpDialog(
      maxWidth: MediaQuery.sizeOf(context).width * 0.9,
      maxHeight: MediaQuery.sizeOf(context).height * 0.8,
      child: TpDialogPinnedLayout(
        header: TpDialogHeader(
          title: strings.fullDiskSearchTab,
          onClose: () => Navigator.pop(context),
        ),
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(strings.searchScope, style: styles.smMedium),
            const SizedBox(height: 8),
            TpSelect<String>(
              items: scopePaths,
              initialItem: _selectedSearchPath,
              itemLabel: _scopeLabel,
              searchable: false,
              onChanged: (value) {
                if (value == null) return;
                setState(() => _selectedSearchPath = value);
              },
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TpInput(
                    key: const Key('tp_full_disk_search_query'),
                    controller: _queryController,
                    decoration: InputDecoration(
                      hintText: strings.inputFileNameKeywordHint,
                      prefixIcon: const Icon(Icons.search),
                    ),
                    onChanged: (value) => _query = value,
                    onSubmitted: (_) => _performSearch(),
                  ),
                ),
                const SizedBox(width: 8),
                TpButton(
                  onPressed: _isSearching ? null : _performSearch,
                  child: _isSearching
                      ? SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: cs.onPrimary,
                          ),
                        )
                      : Text(strings.actionSearch),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (_results.isNotEmpty || _isSearching)
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: cs.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Text(
                      _isSearching
                          ? strings.searching
                          : strings.foundFileCount(_results.length),
                      style: styles.smMedium,
                    ),
                    const Spacer(),
                    if (_results.isNotEmpty && !_isSearching) ...[
                      TpButton(
                        variant: TpButtonVariant.ghost,
                        onPressed: _toggleSelectAll,
                        child: Text(
                          _selectedPaths.length == _results.length
                              ? strings.deselectAll
                              : strings.selectAll,
                        ),
                      ),
                      Text(
                        strings.selectedCountShort(_selectedPaths.length),
                        style: styles.mutedSm,
                      ),
                    ],
                  ],
                ),
              ),
            const SizedBox(height: 8),
            SizedBox(
              height: MediaQuery.sizeOf(context).height * 0.45,
              child: _buildResults(context),
            ),
          ],
        ),
        footer: _selectedPaths.isEmpty
            ? null
            : TpDialogActions(
                children: [
                  TpButton(
                    variant: TpButtonVariant.outline,
                    onPressed: () => Navigator.pop(context),
                    child: Text(strings.taskStatusCancelledShort),
                  ),
                  TpButton(
                    onPressed: _confirmSelection,
                    child: Text(strings.addSelectedFiles(_selectedPaths.length)),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildResults(BuildContext context) {
    final strings = widget.strings;
    final styles = TpTextStyles.of(context);
    final cs = Theme.of(context).colorScheme;

    if (_isSearching) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text(strings.searchingFiles, style: styles.sm),
          ],
        ),
      );
    }

    if (_results.isEmpty) {
      return TpEmptyState(
        centered: true,
        icon: Icons.search_off,
        title: _query.isEmpty
            ? strings.enterKeywordToStartSearch
            : strings.noMatchingFiles,
      );
    }

    return ListView.builder(
      itemCount: _results.length,
      itemBuilder: (context, index) {
        final entry = _results[index];
        final isSelected = _selectedPaths.contains(entry.path);
        return ListTile(
          contentPadding: EdgeInsets.zero,
          leading: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Checkbox(
                value: isSelected,
                onChanged: (_) => _toggleSelection(entry),
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              Icon(Icons.insert_drive_file_outlined, color: cs.primary),
            ],
          ),
          title: Text(entry.name, style: styles.smMedium),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _parentPath(entry.path),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: styles.mutedSm,
              ),
              if (entry.sizeBytes != null)
                Text(_formatFileSize(entry.sizeBytes), style: styles.mutedSm),
            ],
          ),
          onTap: () => _toggleSelection(entry),
        );
      },
    );
  }

  void _confirmSelection() {
    final picked = _results
        .where((entry) => _selectedPaths.contains(entry.path))
        .map(tpFsEntryToPicked)
        .toList();
    widget.onFilesSelected(picked);
    Navigator.pop(context);
  }
}

String _parentPath(String path) {
  if (path == '/' || path.isEmpty) {
    return path;
  }
  final normalized =
      path.endsWith('/') && path.length > 1 ? path.substring(0, path.length - 1) : path;
  final lastSlash = normalized.lastIndexOf('/');
  if (lastSlash <= 0) {
    return '/';
  }
  return normalized.substring(0, lastSlash);
}
