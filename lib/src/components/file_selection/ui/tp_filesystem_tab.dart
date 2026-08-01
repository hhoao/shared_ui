import 'package:flutter/material.dart';

import '../../../theme/tp_text_styles.dart';
import '../../empty_state/tp_empty_state.dart';
import '../../input/tp_input.dart';
import '../controller/tp_file_selection_controller.dart';
import '../controller/tp_file_selection_filters.dart';
import '../controller/tp_file_selection_tab_api.dart';
import '../models/tp_file_selection_options.dart';
import '../models/tp_fs_entry.dart';
import '../models/tp_picked_entry.dart';
import '../ports/tp_file_selection_deps.dart';
import 'tp_file_selection_strings.dart';
import 'widgets/tp_fs_entry_tile.dart';
import 'widgets/tp_full_disk_search_dialog.dart';

class TpFilesystemTab extends StatefulWidget {
  const TpFilesystemTab({
    super.key,
    required this.deps,
    required this.options,
    required this.controller,
    this.onPathNotFound,
  });

  final TpFileSelectionDeps deps;
  final TpFileSelectionOptions options;
  final TpFileSelectionController controller;
  final void Function(String path)? onPathNotFound;

  @override
  State<TpFilesystemTab> createState() => TpFilesystemTabState();
}

class TpFilesystemTabState extends State<TpFilesystemTab>
    implements TpFileSelectionTabApi {
  final _searchController = TextEditingController();

  List<TpFilesystemRoot> _roots = [];
  List<TpFsEntry> _entries = [];
  List<TpFsEntry> _visibleEntries = [];
  bool _hasStoragePermission = false;
  bool _isLoading = false;
  int _selectedSubTabIndex = 0;
  String _currentPath = '';
  String _searchQuery = '';
  String _sortType = 'name';
  bool _sortAscending = true;

  TpFileSelectionStrings get _strings => widget.deps.strings;

  bool get _hasFullDiskSearch => widget.deps.filesystem.searchFiles != null;

  int get _subTabCount => _roots.length + (_hasFullDiskSearch ? 1 : 0);

  @override
  void initState() {
    super.initState();
    widget.controller.registerTabApi(TpFileSelectionTab.filesystem, this);
    _roots = widget.deps.filesystem.defaultRoots();
    _bootstrap();
  }

  @override
  void dispose() {
    widget.controller.unregisterTabApi(TpFileSelectionTab.filesystem);
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _bootstrap() async {
    await _resolveInitialPath();
    await _checkPermissionAndLoad();
  }

  Future<void> _resolveInitialPath() async {
    final initialPath = widget.options.initialPath;
    if (initialPath == null || initialPath.isEmpty) {
      _currentPath = widget.deps.filesystem.defaultBrowsePath();
      return;
    }

    final exists = await widget.deps.filesystem.exists(initialPath);
    if (!exists) {
      widget.onPathNotFound?.call(initialPath);
      _currentPath = widget.deps.filesystem.defaultBrowsePath();
      return;
    }

    final kind = await widget.deps.filesystem.kindOf(initialPath);
    if (kind == TpFsEntryKind.directory) {
      _currentPath = initialPath;
    } else {
      _currentPath = _parentPath(initialPath);
    }
    widget.controller.setCurrentPath(_currentPath);
  }

  Future<void> _checkPermissionAndLoad() async {
    final granted = await widget.deps.permission.ensureStorageAccess();
    if (!mounted) return;

    setState(() => _hasStoragePermission = granted);
    if (granted) {
      await _loadDirectory();
    }
  }

  Future<void> _loadDirectory() async {
    if (!_hasStoragePermission) return;

    setState(() => _isLoading = true);
    try {
      final entries = await widget.deps.filesystem.listDir(_currentPath);
      if (!mounted) return;
      setState(() {
        _entries = entries;
        _isLoading = false;
      });
      _applySortingAndFiltering();
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _entries = [];
        _isLoading = false;
      });
      _applySortingAndFiltering();
    }
  }

  void _applySortingAndFiltering() {
    final filtered = filterFsEntries(
      _entries,
      allowedExtensions: widget.options.allowedExtensions,
      showHiddenFiles: widget.options.showHiddenFiles,
      query: _searchQuery,
    );
    final sorted = sortFsEntries(
      filtered,
      sortType: _sortType,
      ascending: _sortAscending,
    );
    if (!mounted) return;
    setState(() => _visibleEntries = sorted);
  }

  Future<void> _onSubTabSelected(int index) async {
    if (index == _selectedSubTabIndex) return;

    if (_hasFullDiskSearch && index == _subTabCount - 1) {
      setState(() => _selectedSubTabIndex = index);
      _openFullDiskSearchDialog();
      return;
    }

    if (index >= _roots.length) return;

    setState(() => _selectedSubTabIndex = index);
    _currentPath = _roots[index].path;
    widget.controller.setCurrentPath(_currentPath);
    await _loadDirectory();
  }

  void _openFullDiskSearchDialog() {
    final phoneRoot = _roots.isEmpty ? null : _roots.first;
    showDialog<void>(
      context: context,
      builder: (context) => TpFullDiskSearchDialog(
        strings: _strings,
        filesystem: widget.deps.filesystem,
        allowedExtensions: widget.options.allowedExtensions,
        phoneStorageRoot: phoneRoot,
        onFilesSelected: _mergeSearchResults,
      ),
    );
  }

  void _mergeSearchResults(List<TpPickedEntry> picked) {
    if (picked.isEmpty) return;

    if (!widget.options.allowMultiple) {
      widget.controller.replaceSelection(picked.take(1).toList());
      return;
    }

    final merged = List<TpPickedEntry>.from(widget.controller.selection);
    for (final entry in picked) {
      if (merged.contains(entry)) continue;
      final max = widget.options.maxSelectionCount;
      if (max != null && merged.length >= max) {
        widget.controller.onMaxSelectionReached?.call(max);
        break;
      }
      merged.add(entry);
    }
    widget.controller.replaceSelection(merged);
  }

  void _navigateToDirectory(TpFsEntry entry) {
    _currentPath = entry.path;
    widget.controller.setCurrentPath(_currentPath);
    _loadDirectory();
  }

  void _toggleSelection(TpFsEntry entry) {
    final picked = tpFsEntryToPicked(entry);
    final isSelected = widget.controller.selection.contains(picked);
    if (isSelected) {
      widget.controller.deselect(picked);
      return;
    }
    widget.controller.trySelect(picked);
  }

  List<TpPickedEntry> _selectablePickedEntries() {
    return _visibleEntries
        .where((entry) => tpFsEntryIsSelectable(entry, widget.options))
        .where((entry) => tpFsEntryIsAllowed(entry, widget.options))
        .map(tpFsEntryToPicked)
        .toList();
  }

  @override
  void clearSelection() {
    widget.controller.replaceSelection([]);
  }

  @override
  Future<void> selectAll() async {
    widget.controller.selectAllFrom(_selectablePickedEntries());
  }

  @override
  int get selectableCount => _selectablePickedEntries().length;

  @override
  void applySorting(String sortType, {required bool ascending}) {
    setState(() {
      _sortType = sortType;
      _sortAscending = ascending;
    });
    _applySortingAndFiltering();
  }

  @override
  Widget build(BuildContext context) {
    final styles = TpTextStyles.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildSubTabBar(context),
        if (!_hasStoragePermission) _buildPermissionNotice(context),
        if (_hasStoragePermission) ...[
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: TpInput(
              key: const Key('tp_filesystem_search_field'),
              controller: _searchController,
              decoration: InputDecoration(
                hintText: _strings.inputFileNameHint,
                prefixIcon: const Icon(Icons.search),
              ),
              onChanged: (value) {
                _searchQuery = value;
                _applySortingAndFiltering();
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text(
              _currentPath,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: styles.mutedSm,
            ),
          ),
        ],
        Expanded(
          child: ListenableBuilder(
            listenable: widget.controller,
            builder: (context, _) => _buildBody(context),
          ),
        ),
      ],
    );
  }

  Widget _buildSubTabBar(BuildContext context) {
    if (_roots.isEmpty && !_hasFullDiskSearch) {
      return const SizedBox.shrink();
    }

    final labels = <String>[
      for (var i = 0; i < _roots.length; i++)
        i == 0
            ? _strings.phoneStorageTab
            : i == 1
                ? _strings.appFoldersTab
                : _roots[i].label,
      if (_hasFullDiskSearch) _strings.fullDiskSearchTab,
    ];
    final styles = TpTextStyles.of(context);

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: List.generate(labels.length, (index) {
          final selected = index == _selectedSubTabIndex;
          final cs = Theme.of(context).colorScheme;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: Text(
                labels[index],
                style: selected
                    ? styles.smMediumColored(cs.onPrimary)
                    : styles.sm,
              ),
              selected: selected,
              onSelected: (_) => _onSubTabSelected(index),
              selectedColor: cs.primary,
            ),
          );
        }),
      ),
    );
  }

  Widget _buildPermissionNotice(BuildContext context) {
    return Expanded(
      child: TpEmptyState(
        centered: true,
        icon: Icons.folder_off_outlined,
        title: _strings.storagePermissionRequired,
        actionLabel: _strings.goToSettings,
        onAction: widget.deps.permission.openAppSettings,
      ),
    );
  }

  Widget _buildBody(BuildContext context) {
    if (!_hasStoragePermission) {
      return const SizedBox.shrink();
    }

    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_visibleEntries.isEmpty) {
      return TpEmptyState(
        centered: true,
        icon: _searchQuery.isNotEmpty ? Icons.search_off : Icons.folder_open,
        title: _searchQuery.isNotEmpty
            ? _strings.noMatchingFiles
            : _strings.folderEmpty,
      );
    }

    return ListView.builder(
      key: const Key('tp_filesystem_entry_list'),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: _visibleEntries.length,
      itemBuilder: (context, index) {
        final entry = _visibleEntries[index];
        final picked = tpFsEntryToPicked(entry);
        return TpFsEntryTile(
          entry: entry,
          options: widget.options,
          strings: _strings,
          isSelected: widget.controller.selection.contains(picked),
          isSelectable: tpFsEntryIsSelectable(entry, widget.options),
          isAllowed: tpFsEntryIsAllowed(entry, widget.options),
          onToggle: _toggleSelection,
          onNavigate: _navigateToDirectory,
        );
      },
    );
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
