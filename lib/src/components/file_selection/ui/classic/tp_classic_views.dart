import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../../../../theme/tp_text_styles.dart';
import '../../../button/tp_button.dart';
import '../../../empty_state/tp_empty_state.dart';
import '../../../hover/tp_hover.dart';
import '../../../icon_button/tp_icon_button.dart';
import '../../controller/tp_file_selection_controller.dart';
import '../../controller/tp_file_selection_filters.dart';
import '../../models/tp_file_selection_options.dart';
import '../../models/tp_fs_entry.dart';
import '../../models/tp_gallery_models.dart';
import '../../models/tp_picked_entry.dart';
import '../../ports/tp_file_selection_deps.dart';
import '../tp_file_selection_strings.dart';
import '../widgets/tp_full_disk_search_dialog.dart';
import '../widgets/tp_fs_entry_tile.dart';
import '../widgets/tp_gallery_asset_tile.dart';

/// Contract the classic page uses to delegate select-all and sorting to the
/// currently visible tab.
abstract class TpClassicViewApi {
  Future<void> selectAll();

  int get selectableCount;

  void applySorting(String sortType, {required bool ascending});
}

/// Legacy 文件 tab, ported from the pre-migration huji picker: pill sub-tabs
/// (手机存储 / 应用文件夹 / 全盘搜索), permission notice, breadcrumb with
/// search, quick-access circles and the folder list.
class TpClassicStorageTab extends StatefulWidget {
  const TpClassicStorageTab({
    super.key,
    required this.deps,
    required this.options,
    required this.controller,
    this.initialPath,
  });

  final TpFileSelectionDeps deps;
  final TpFileSelectionOptions options;
  final TpFileSelectionController controller;

  /// When provided, start browsing at this path instead of the phone root.
  final String? initialPath;

  @override
  State<TpClassicStorageTab> createState() => TpClassicStorageTabState();
}

class TpClassicStorageTabState extends State<TpClassicStorageTab>
    implements TpClassicViewApi {
  String _currentPath = '';
  List<TpFsEntry> _entities = [];
  List<TpFsEntry> _filteredEntities = [];
  bool _isLoading = false;
  bool _hasStoragePermission = false;
  String _searchQuery = '';
  String _sortType = 'name';
  bool _sortAscending = true;

  late final List<TpFilesystemRoot> _roots;
  final Map<String, Future<int>> _dirCounts = {};
  final TextEditingController _searchController = TextEditingController();

  TpFileSelectionStrings get _strings => widget.deps.strings;

  TpFilesystemRoot get _phoneRoot => _roots.first;

  bool get _hasFullDiskSearch => widget.deps.filesystem.searchFiles != null;

  @override
  void initState() {
    super.initState();
    _roots = widget.deps.filesystem.defaultRoots();
    if (_roots.isEmpty) {
      _roots = [
        TpFilesystemRoot(
          id: 'phone_storage',
          label: 'phone_storage',
          path: widget.deps.filesystem.defaultBrowsePath(),
        ),
      ];
    }
    _currentPath = widget.initialPath ?? _phoneRoot.path;
    widget.controller.setCurrentPath(_currentPath);
    _checkPermissionAndLoadDirectory();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _checkPermissionAndLoadDirectory() async {
    final granted = await widget.deps.permission.ensureStorageAccess();
    if (!mounted) return;
    setState(() => _hasStoragePermission = granted);
    if (granted) {
      await _loadDirectory();
    }
  }

  Future<void> _loadDirectory() async {
    if (!_hasStoragePermission) return;
    if (!mounted) return;
    setState(() => _isLoading = true);

    try {
      final entries = await widget.deps.filesystem.listDir(_currentPath);
      if (!mounted) return;
      setState(() {
        _entities = entries;
        _isLoading = false;
      });
      _applySortingAndFiltering();
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _entities = [];
        _isLoading = false;
      });
      _applySortingAndFiltering();
    }
  }

  void _applySortingAndFiltering() {
    if (!mounted) return;

    final query = _searchQuery.trim().toLowerCase();
    var filtered = _entities.where((entry) {
      if (!widget.options.showHiddenFiles && entry.name.startsWith('.')) {
        return false;
      }
      if (query.isNotEmpty &&
          !entry.name.toLowerCase().contains(query)) {
        return false;
      }
      return true;
    }).toList();

    filtered = sortFsEntries(
      filtered,
      sortType: _sortType,
      ascending: _sortAscending,
    );

    setState(() => _filteredEntities = filtered);
  }

  void _handleSubTab(int index) {
    if (index == 2) {
      _openFullDiskSearch();
      return;
    }
    if (index == 1 && _roots.length > 1) {
      _navigateToPath(_roots[1].path);
      return;
    }
    _navigateToPath(_phoneRoot.path);
  }

  void _openFullDiskSearch() {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => TpFullDiskSearchDialog(
        strings: _strings,
        filesystem: widget.deps.filesystem,
        allowedExtensions: widget.options.allowedExtensions,
        phoneStorageRoot: _phoneRoot,
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

  void _navigateToPath(String path) {
    setState(() => _currentPath = path);
    widget.controller.setCurrentPath(path);
    _searchController.clear();
    _searchQuery = '';
    _loadDirectory();
  }

  void _toggleSelection(TpFsEntry entry) {
    final picked = tpFsEntryToPicked(entry);
    if (widget.controller.selection.contains(picked)) {
      widget.controller.deselect(picked);
      return;
    }
    widget.controller.trySelect(picked);
  }

  List<TpPickedEntry> _selectablePickedEntries() {
    return _filteredEntities
        .where((entry) => tpFsEntryIsSelectable(entry, widget.options))
        .where((entry) => tpFsEntryIsAllowed(entry, widget.options))
        .map(tpFsEntryToPicked)
        .toList();
  }

  @override
  Future<void> selectAll() async {
    widget.controller.selectAllFrom(_selectablePickedEntries());
  }

  @override
  int get selectableCount {
    final total = _selectablePickedEntries().length;
    final max = widget.options.maxSelectionCount;
    if (max != null && total > max) return max;
    return total;
  }

  @override
  void applySorting(String sortType, {required bool ascending}) {
    setState(() {
      _sortType = sortType;
      _sortAscending = ascending;
    });
    _applySortingAndFiltering();
  }

  Future<int> _directoryCount(String path) {
    final cached = _dirCounts[path];
    if (cached != null) return cached;
    final future = widget.deps.filesystem
        .listDir(path)
        .then((entries) => entries.length)
        .catchError((_) => 0);
    _dirCounts[path] = future;
    return future;
  }

  void _showSearchDialog() {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(_strings.searchFilesTitle),
        content: TextField(
          controller: _searchController,
          decoration: InputDecoration(
            hintText: _strings.inputFileNameHint,
            prefixIcon: const Icon(Icons.search),
          ),
          onChanged: (value) {
            setState(() => _searchQuery = value);
            _applySortingAndFiltering();
          },
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () {
              _searchController.clear();
              setState(() => _searchQuery = '');
              _applySortingAndFiltering();
              Navigator.pop(dialogContext);
            },
            child: Text(_strings.actionClear),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(_strings.actionConfirm),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildSubTabBar(context),
        _buildPermissionNotice(),
        Expanded(
          child: !_hasStoragePermission
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.folder_off,
                        size: 64,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        _strings.storagePermissionRequired,
                        style: TpTextStyles.of(context).mutedSm,
                      ),
                    ],
                  ),
                )
              : Column(
                  children: [
                    _buildNavigationBar(context),
                    _buildQuickAccess(context),
                    const SizedBox(height: 16),
                    Expanded(child: _buildFolderList(context)),
                  ],
                ),
        ),
      ],
    );
  }

  /// Legacy pill sub-tabs: 手机存储 / 应用文件夹 / 全盘搜索.
  Widget _buildSubTabBar(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    final isPhoneRoot = _currentPath == _phoneRoot.path;
    final isAppFoldersRoot =
        _roots.length > 1 && _currentPath == _roots[1].path;
    final activeLabel = isAppFoldersRoot && !isPhoneRoot
        ? _strings.appFoldersTab
        : _strings.phoneStorageTab;

    final pills = <({String label, bool selected, VoidCallback onTap})>[
      (
        label: _strings.phoneStorageTab,
        selected: activeLabel == _strings.phoneStorageTab,
        onTap: () => _handleSubTab(0),
      ),
      if (_roots.length > 1)
        (
          label: _strings.appFoldersTab,
          selected: activeLabel == _strings.appFoldersTab,
          onTap: () => _handleSubTab(1),
        ),
      if (_hasFullDiskSearch)
        (
          label: _strings.fullDiskSearchTab,
          selected: false,
          onTap: () => _handleSubTab(2),
        ),
    ];

    return Column(
      children: [
        Container(
          key: const Key('tp_classic_storage_subtabs'),
          color: cs.surface,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                for (final pill in pills)
                  TpHover(
                    key: Key('tp_classic_subtab_${pill.label}'),
                    onTap: pill.onTap,
                    borderRadius: BorderRadius.circular(8),
                    backgroundColor: pill.selected
                        ? cs.onSurface
                        : cs.surfaceContainerHighest,
                    pressScale: 0.97,
                    child: Container(
                      margin: const EdgeInsets.only(right: 16),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      child: Text(
                        pill.label,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: pill.selected
                              ? cs.surface
                              : cs.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
        Divider(height: 1, color: cs.outlineVariant.withValues(alpha: 0.4)),
      ],
    );
  }

  /// Orange permission notice shown above the list while storage access is
  /// missing.
  Widget _buildPermissionNotice() {
    if (_hasStoragePermission) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.orange.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.orange.shade200),
      ),
      child: Row(
        children: [
          Icon(Icons.warning, color: Colors.orange.shade700, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _strings.storagePermissionRequired,
              style: const TextStyle(fontSize: 14),
            ),
          ),
          TextButton(
            onPressed: _checkPermissionAndLoadDirectory,
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              minimumSize: Size.zero,
            ),
            child: Text(
              _strings.authorize,
              style: const TextStyle(fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }

  /// Breadcrumb row with a trailing search icon.
  Widget _buildNavigationBar(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: _buildBreadcrumbSegments(context),
              ),
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            key: const Key('tp_classic_folder_search'),
            icon: const Icon(Icons.search, size: 20),
            onPressed: _showSearchDialog,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildBreadcrumbSegments(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final widgets = <Widget>[];

    final segments = <({String name, String path})>[
      (name: _strings.phoneStorageTab, path: _phoneRoot.path),
    ];
    final root = _phoneRoot.path.replaceAll(RegExp(r'/+$'), '');
    final current = _currentPath.replaceAll(RegExp(r'/+$'), '');
    if (current.length > root.length) {
      var built = root;
      for (final part in current
          .substring(root.length)
          .split('/')
          .where((p) => p.isNotEmpty)) {
        built = '$built/$part';
        segments.add((name: part, path: built));
      }
    }

    for (var i = 0; i < segments.length; i++) {
      final segment = segments[i];
      final isLast = i == segments.length - 1;
      final isFirst = i == 0;

      widgets.add(
        TpHover(
          key: Key('tp_classic_breadcrumb_${segment.name}'),
          onTap: isLast ? null : () => _navigateToPath(segment.path),
          borderRadius: BorderRadius.circular(6),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (isFirst) ...[
                Icon(Icons.home, size: 16, color: cs.onSurfaceVariant),
                const SizedBox(width: 4),
              ],
              Text(
                segment.name,
                style: TextStyle(
                  fontSize: 15,
                  color: isLast ? cs.onSurface : cs.onSurfaceVariant,
                  fontWeight: isLast ? FontWeight.w600 : FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      );
      widgets.add(
        Icon(
          Icons.chevron_right,
          size: 16,
          color: cs.onSurfaceVariant,
        ),
      );
    }

    return widgets;
  }

  /// Quick-access circles: 下载 / 文档 / 图片 / 视频 / 相机.
  Widget _buildQuickAccess(BuildContext context) {
    final phoneRoot = _phoneRoot.path.replaceAll(RegExp(r'/+$'), '');
    final items = <({IconData icon, String label, String path, Color color})>[
      (
        icon: Icons.download,
        label: _strings.quickAccessDownload,
        path: '$phoneRoot/Download',
        color: Colors.blue,
      ),
      (
        icon: Icons.description,
        label: _strings.quickAccessDocuments,
        path: '$phoneRoot/Documents',
        color: Colors.orange,
      ),
      (
        icon: Icons.photo_library,
        label: _strings.quickAccessPictures,
        path: '$phoneRoot/Pictures',
        color: Colors.green,
      ),
      (
        icon: Icons.videocam,
        label: _strings.quickAccessVideos,
        path: '$phoneRoot/Movies',
        color: Colors.red,
      ),
      (
        icon: Icons.camera_alt,
        label: _strings.quickAccessCamera,
        path: '$phoneRoot/DCIM',
        color: Colors.teal,
      ),
    ];

    return Container(
      key: const Key('tp_classic_quick_access'),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          for (final item in items)
            Expanded(
              child: FutureBuilder<int>(
                future: _directoryCount(item.path),
                builder: (context, snapshot) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 16),
                    child: _buildQuickAccessItem(
                      context,
                      item.icon,
                      item.label,
                      item.path,
                      item.color,
                      '${snapshot.data ?? 0}',
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildQuickAccessItem(
    BuildContext context,
    IconData icon,
    String label,
    String path,
    Color color,
    String count,
  ) {
    return TpHover(
      key: Key('tp_classic_quick_$label'),
      onTap: () => _navigateToPath(path),
      borderRadius: BorderRadius.circular(8),
      pressScale: 0.97,
      child: Column(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            child: Icon(icon, color: Colors.white, size: 24),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(fontSize: 12),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            count,
            style: TextStyle(
              fontSize: 12,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFolderList(BuildContext context) {
    final styles = TpTextStyles.of(context);
    final cs = Theme.of(context).colorScheme;

    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_filteredEntities.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _searchQuery.isNotEmpty
                  ? Icons.search_off
                  : Icons.folder_open,
              size: 64,
              color: cs.onSurfaceVariant,
            ),
            const SizedBox(height: 16),
            Text(
              _searchQuery.isNotEmpty
                  ? _strings.noMatchingFiles
                  : _strings.folderEmpty,
              style: styles.mutedSm,
            ),
            if (_searchQuery.isNotEmpty) ...[
              const SizedBox(height: 8),
              TextButton(
                onPressed: () {
                  _searchController.clear();
                  setState(() => _searchQuery = '');
                  _applySortingAndFiltering();
                },
                child: Text(_strings.clearSearch),
              ),
            ],
          ],
        ),
      );
    }

    return ListView.builder(
      key: const Key('tp_classic_folder_list'),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: _filteredEntities.length,
      itemBuilder: (context, index) {
        final entry = _filteredEntities[index];
        final isDirectory = entry.kind == TpFsEntryKind.directory;
        final picked = tpFsEntryToPicked(entry);
        final isAllowed = tpFsEntryIsAllowed(entry, widget.options);
        final isSelectable =
            tpFsEntryIsSelectable(entry, widget.options) && isAllowed;

        return ListTile(
          contentPadding: EdgeInsets.zero,
          leading: Icon(
            isDirectory
                ? Icons.folder
                : _fileIconFor(entry.name),
            color: isDirectory
                ? Colors.orange
                : (isAllowed ? cs.primary : cs.outline),
            size: 32,
          ),
          title: Row(
            children: [
              Expanded(
                child: Text(
                  entry.name,
                  style: isAllowed
                      ? styles.smMedium
                      : styles.smMedium.copyWith(color: cs.outline),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 10),
              if (isSelectable)
                Checkbox(
                  value: widget.controller.selection.contains(picked),
                  onChanged: (_) => _toggleSelection(entry),
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                )
              else
                const SizedBox(width: 40),
            ],
          ),
          subtitle: FutureBuilder<String>(
            future: _entityInfo(entry),
            builder: (context, snapshot) {
              if (!snapshot.hasData) return const Text('');
              return Text(
                snapshot.data!,
                style: styles.mutedSm,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              );
            },
          ),
          trailing: isDirectory
              ? Icon(Icons.chevron_right, color: cs.onSurfaceVariant)
              : null,
          onTap: () {
            if (isDirectory) {
              _navigateToPath(entry.path);
              return;
            }
            if (isAllowed &&
                widget.options.selectionMode != TpSelectionMode.directories) {
              _toggleSelection(entry);
            }
          },
        );
      },
    );
  }

  Future<String> _entityInfo(TpFsEntry entry) async {
    final modified = entry.modifiedAt;
    final date = modified == null
        ? ''
        : '${modified.year}-${modified.month.toString().padLeft(2, '0')}-${modified.day.toString().padLeft(2, '0')}';

    if (entry.kind == TpFsEntryKind.directory) {
      final count = await _directoryCount(entry.path);
      if (date.isEmpty) return _strings.itemCountUnit(count);
      return _strings.entityInfoDateAndItemCount(date, count);
    }

    final size = entry.sizeBytes;
    if (date.isEmpty) {
      return size == null ? '' : _formatFileSize(size);
    }
    return size == null
        ? date
        : '$date ${_formatFileSize(size)}';
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '${bytes}B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)}KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)}MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)}GB';
  }
}

/// What a [TpClassicMediaGrid] displays: a gallery album filtered by media
/// kind.
class TpClassicMediaSource {
  const TpClassicMediaSource({
    required this.albumId,
    required this.title,
    required this.includeVideos,
    required this.includeImages,
  });

  final String albumId;
  final String title;
  final bool includeVideos;
  final bool includeImages;
}

/// Legacy-style 3-column media grid backed by a gallery album.
class TpClassicMediaGrid extends StatefulWidget {
  const TpClassicMediaGrid({
    super.key,
    required this.deps,
    required this.options,
    required this.controller,
    required this.source,
    required this.onBack,
    this.showHeader = true,
    this.viewMode = TpClassicMediaViewMode.grid,
    this.query = '',
  });

  final TpFileSelectionDeps deps;
  final TpFileSelectionOptions options;
  final TpFileSelectionController controller;
  final TpClassicMediaSource source;
  final VoidCallback onBack;

  /// Whether to render the back-arrow title row (hidden when embedded in the
  /// gallery tab).
  final bool showHeader;

  /// Grid or legacy list rendering.
  final TpClassicMediaViewMode viewMode;

  /// Optional display-name filter applied to the loaded assets.
  final String query;

  @override
  State<TpClassicMediaGrid> createState() => TpClassicMediaGridState();
}

/// How [TpClassicMediaGrid] renders its assets.
enum TpClassicMediaViewMode { grid, list }

class TpClassicMediaGridState extends State<TpClassicMediaGrid>
    implements TpClassicViewApi {
  static const _pageSize = 50;

  List<TpGalleryAsset> _assets = [];
  final Map<String, String> _assetPathCache = {};
  final Map<String, Uint8List?> _thumbnailCache = {};
  final _scrollController = ScrollController();

  bool _isLoading = false;
  bool _isLoadingMore = false;
  bool _hasMoreData = false;
  int _currentPage = 0;

  TpFileSelectionStrings get _strings => widget.deps.strings;

  List<TpGalleryAsset> get _visibleAssets {
    final query = widget.query.trim().toLowerCase();
    if (query.isEmpty) return _assets;
    return _assets
        .where(
          (asset) =>
              (asset.displayName ?? '').toLowerCase().contains(query),
        )
        .toList();
  }

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _loadAssets();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadAssets() async {
    final gallery = widget.deps.gallery;
    if (gallery == null) return;

    setState(() {
      _isLoading = true;
      _currentPage = 0;
      _hasMoreData = true;
      _assets = [];
    });

    try {
      final assets = await gallery.listAssets(
        albumId: widget.source.albumId,
        page: 0,
        pageSize: _pageSize,
        includeVideos: widget.source.includeVideos,
        includeImages: widget.source.includeImages,
      );
      if (!mounted) return;

      setState(() {
        _assets = assets;
        _isLoading = false;
        _hasMoreData = assets.length >= _pageSize;
        _currentPage = assets.isEmpty ? 0 : 1;
      });
      _preloadPaths(assets);
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _assets = [];
        _isLoading = false;
        _hasMoreData = false;
      });
    }
  }

  Future<void> _loadMoreAssets() async {
    final gallery = widget.deps.gallery;
    if (gallery == null || _isLoadingMore || !_hasMoreData) return;

    setState(() => _isLoadingMore = true);
    try {
      final more = await gallery.listAssets(
        albumId: widget.source.albumId,
        page: _currentPage,
        pageSize: _pageSize,
        includeVideos: widget.source.includeVideos,
        includeImages: widget.source.includeImages,
      );
      if (!mounted) return;

      setState(() {
        _assets = [..._assets, ...more];
        _hasMoreData = more.length >= _pageSize;
        _currentPage++;
        _isLoadingMore = false;
      });
      _preloadPaths(more);
    } catch (_) {
      if (!mounted) return;
      setState(() => _isLoadingMore = false);
    }
  }

  void _preloadPaths(List<TpGalleryAsset> assets) {
    final gallery = widget.deps.gallery;
    if (gallery == null) return;

    for (final asset in assets) {
      if (_assetPathCache.containsKey(asset.id)) continue;
      gallery.resolveToPath(asset.id).then((path) {
        if (path != null && mounted) {
          setState(() => _assetPathCache[asset.id] = path);
        }
      });
    }
  }

  void _onScroll() {
    if (!_scrollController.hasClients || _isLoadingMore || !_hasMoreData) {
      return;
    }
    final position = _scrollController.position;
    if (position.pixels >= position.maxScrollExtent - 100) {
      _loadMoreAssets();
    }
  }

  bool _isAssetSelected(TpGalleryAsset asset) {
    final path = _assetPathCache[asset.id];
    if (path == null) return false;
    return widget.controller.selection.any((entry) => entry.path == path);
  }

  bool _isPathAllowed(String path) {
    final entry = TpFsEntry(
      path: path,
      name: path.split('/').last,
      kind: TpFsEntryKind.file,
    );
    return tpFsEntryIsAllowed(entry, widget.options);
  }

  Future<void> _toggleAssetSelection(TpGalleryAsset asset) async {
    final gallery = widget.deps.gallery;
    if (gallery == null) return;

    final path =
        _assetPathCache[asset.id] ?? await gallery.resolveToPath(asset.id);
    if (path == null || !mounted) return;
    if (!_isPathAllowed(path)) return;

    setState(() => _assetPathCache[asset.id] = path);
    final picked = TpPickedEntry(
      path: path,
      kind: TpPickedKind.file,
      displayName: asset.displayName,
    );
    if (widget.controller.selection.contains(picked)) {
      widget.controller.deselect(picked);
      return;
    }
    widget.controller.trySelect(picked);
  }

  Future<void> _previewAsset(TpGalleryAsset asset) async {
    final preview = widget.deps.preview;
    final gallery = widget.deps.gallery;
    if (preview == null || gallery == null) return;

    final path =
        _assetPathCache[asset.id] ?? await gallery.resolveToPath(asset.id);
    if (path == null || !mounted) return;

    setState(() => _assetPathCache[asset.id] = path);
    if (asset.isVideo) {
      await preview.previewVideo(context, path);
    } else {
      await preview.previewImage(context, path);
    }
  }

  @override
  Future<void> selectAll() async {
    final gallery = widget.deps.gallery;
    if (gallery == null) return;

    final picked = <TpPickedEntry>[];
    for (final asset in _visibleAssets) {
      final path =
          _assetPathCache[asset.id] ?? await gallery.resolveToPath(asset.id);
      if (path == null || !_isPathAllowed(path)) continue;
      _assetPathCache[asset.id] = path;
      picked.add(
        TpPickedEntry(
          path: path,
          kind: TpPickedKind.file,
          displayName: asset.displayName,
        ),
      );
    }
    widget.controller.selectAllFrom(picked);
  }

  @override
  int get selectableCount {
    final total = _visibleAssets.length;
    final max = widget.options.maxSelectionCount;
    if (max != null && total > max) return max;
    return total;
  }

  @override
  void applySorting(String sortType, {required bool ascending}) {}

  @override
  Widget build(BuildContext context) {
    final styles = TpTextStyles.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (widget.showHeader)
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 4, 16, 4),
            child: Row(
              children: [
                TpIconButton(
                  key: const Key('tp_classic_media_back'),
                  icon: Icons.arrow_back,
                  tooltip: _strings.backToParent,
                  onTap: widget.onBack,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    widget.source.title,
                    style: styles.smSemibold,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : ListenableBuilder(
                  listenable: widget.controller,
                  builder: (context, _) => _buildContent(context),
                ),
        ),
      ],
    );
  }

  Widget _buildContent(BuildContext context) {
    if (widget.viewMode == TpClassicMediaViewMode.list) {
      return _buildList(context);
    }
    return _buildGrid(context);
  }

  /// Legacy list rows: thumbnail with duration badge, type label and a
  /// preview + checkbox trailing.
  Widget _buildList(BuildContext context) {
    final styles = TpTextStyles.of(context);
    final cs = Theme.of(context).colorScheme;
    final assets = _visibleAssets;

    if (assets.isEmpty) {
      return _buildEmptyState();
    }

    return ListView.builder(
      key: const Key('tp_classic_media_list'),
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: assets.length,
      itemBuilder: (context, index) {
        final asset = assets[index];
        return ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 0, vertical: 8),
          leading: SizedBox(
            width: 60,
            height: 60,
            child: Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: ColoredBox(
                    color: cs.surfaceContainerHighest,
                    child: FutureBuilder<Uint8List?>(
                      future: _loadThumbnail(asset),
                      builder: (context, snapshot) {
                        if (snapshot.data != null) {
                          return Image.memory(
                            snapshot.data!,
                            fit: BoxFit.cover,
                            width: 60,
                            height: 60,
                          );
                        }
                        return Icon(
                          asset.isVideo ? Icons.videocam : Icons.image,
                          color: cs.onSurfaceVariant,
                          size: 24,
                        );
                      },
                    ),
                  ),
                ),
                if (asset.isVideo && asset.duration != null)
                  Positioned(
                    bottom: 2,
                    right: 2,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 4,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.7),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        _formatDuration(asset.duration!),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          title: Text(
            asset.isVideo ? _strings.videoFileLabel : _strings.imageFileLabel,
            style: styles.smMedium,
          ),
          subtitle: Text(
            asset.displayName ??
                (asset.isVideo ? _strings.videoLabel : _strings.imageLabel),
            style: styles.mutedSm,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (widget.deps.preview != null)
                IconButton(
                  icon: const Icon(Icons.visibility),
                  onPressed: () => _previewAsset(asset),
                  tooltip: _strings.previewTitle,
                ),
              Checkbox(
                value: _isAssetSelected(asset),
                onChanged: (_) => _toggleAssetSelection(asset),
              ),
            ],
          ),
          onTap: () => _toggleAssetSelection(asset),
        );
      },
    );
  }

  Future<Uint8List?> _loadThumbnail(TpGalleryAsset asset) {
    if (_thumbnailCache.containsKey(asset.id)) {
      return Future.value(_thumbnailCache[asset.id]);
    }
    final gallery = widget.deps.gallery;
    if (gallery == null) return Future.value(null);
    return gallery.thumbnail(asset.id).then((bytes) {
      _thumbnailCache[asset.id] = bytes;
      return bytes;
    });
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);
    return '${minutes.toString().padLeft(2, '0')}:'
        '${seconds.toString().padLeft(2, '0')}';
  }

  Widget _buildGrid(BuildContext context) {
    final assets = _visibleAssets;
    if (assets.isEmpty) {
      return _buildEmptyState();
    }

    return CustomScrollView(
      key: const Key('tp_classic_media_grid'),
      controller: _scrollController,
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.all(8),
          sliver: SliverGrid(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 4,
              mainAxisSpacing: 4,
              childAspectRatio: 1,
            ),
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final asset = assets[index];
                return TpGalleryAssetTile(
                  asset: asset,
                  strings: _strings,
                  isSelected: _isAssetSelected(asset),
                  onTap: _toggleAssetSelection,
                  onPreview:
                      widget.deps.preview == null ? null : _previewAsset,
                  loadThumbnail: () => _loadThumbnail(asset),
                );
              },
              childCount: assets.length,
            ),
          ),
        ),
        if (_hasMoreData && !_isLoadingMore)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: TpButton(
                key: const Key('tp_classic_media_load_more'),
                variant: TpButtonVariant.outline,
                onPressed: _loadMoreAssets,
                child: Text(_strings.loadMore),
              ),
            ),
          ),
        if (_isLoadingMore)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Center(
                child: SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return TpEmptyState(
      centered: true,
      icon: Icons.photo_library_outlined,
      title: _strings.noMediaFiles(
        widget.source.includeVideos && widget.source.includeImages
            ? _strings.mediaTypeAll
            : widget.source.includeVideos
                ? _strings.mediaTypeVideo
                : _strings.mediaTypeImage,
      ),
      actionLabel: _strings.actionReload,
      onAction: _loadAssets,
    );
  }
}

/// Legacy 相册 tab: album selector pill, view toggle and a media grid over the
/// current album.
class TpClassicGalleryTab extends StatefulWidget {
  const TpClassicGalleryTab({
    super.key,
    required this.deps,
    required this.options,
    required this.controller,
  });

  final TpFileSelectionDeps deps;
  final TpFileSelectionOptions options;
  final TpFileSelectionController controller;

  @override
  State<TpClassicGalleryTab> createState() => TpClassicGalleryTabState();
}

class TpClassicGalleryTabState extends State<TpClassicGalleryTab>
    implements TpClassicViewApi {
  List<TpGalleryAlbum> _albums = [];
  TpGalleryAlbum? _currentAlbum;
  TpClassicMediaViewMode _viewMode = TpClassicMediaViewMode.grid;
  String _query = '';
  bool _hasGalleryPermission = false;
  bool _isLoading = true;

  final _mediaGridKey = GlobalKey<TpClassicMediaGridState>();
  final TextEditingController _searchController = TextEditingController();
  final Map<String, Future<Uint8List?>> _albumThumbnails = {};

  TpFileSelectionStrings get _strings => widget.deps.strings;

  TpGalleryMediaKind get _mediaKind =>
      resolveGalleryMediaFilter(widget.options.allowedExtensions);

  bool get _includeVideos =>
      _mediaKind == TpGalleryMediaKind.all ||
      _mediaKind == TpGalleryMediaKind.video;

  bool get _includeImages =>
      _mediaKind == TpGalleryMediaKind.all ||
      _mediaKind == TpGalleryMediaKind.image;

  String get _mediaTypeLabel => switch (_mediaKind) {
        TpGalleryMediaKind.image => _strings.mediaTypeImage,
        TpGalleryMediaKind.video => _strings.mediaTypeVideo,
        TpGalleryMediaKind.all => _strings.mediaTypeAll,
      };

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _bootstrap() async {
    final gallery = widget.deps.gallery;
    if (gallery == null) return;

    final granted = await widget.deps.permission.ensureGalleryAccess();
    if (!mounted) return;
    setState(() => _hasGalleryPermission = granted);

    if (granted) {
      await _loadAlbums();
    }
    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _loadAlbums() async {
    final gallery = widget.deps.gallery;
    if (gallery == null) return;

    try {
      final albums = await gallery.listAlbums(
        includeVideos: _includeVideos,
        includeImages: _includeImages,
      );
      if (!mounted) return;
      setState(() {
        _albums = albums;
        final current = _currentAlbum;
        if (current != null) {
          _currentAlbum = albums
              .where((album) => album.id == current.id)
              .firstOrNull;
        }
        _currentAlbum ??= albums.firstOrNull;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _albums = []);
    }
  }

  Future<Uint8List?> _albumThumbnail(TpGalleryAlbum album) {
    final existing = _albumThumbnails[album.id];
    if (existing != null) return existing;
    final gallery = widget.deps.gallery;
    if (gallery == null) return Future.value(null);

    final future = gallery
        .listAssets(
          albumId: album.id,
          page: 0,
          pageSize: 1,
          includeVideos: _includeVideos,
          includeImages: _includeImages,
        )
        .then((assets) async {
      if (assets.isEmpty) return null;
      return gallery.thumbnail(assets.first.id);
    });
    _albumThumbnails[album.id] = future;
    return future;
  }

  void _changeAlbum(TpGalleryAlbum? album) {
    setState(() => _currentAlbum = album);
  }

  Future<void> _requestGalleryAgain() async {
    final granted = await widget.deps.permission.ensureGalleryAccess();
    if (!mounted) return;
    setState(() => _hasGalleryPermission = granted);
    if (granted) {
      await _loadAlbums();
    }
  }

  void _showAlbumSheet() {
    final cs = Theme.of(context).colorScheme;
    final styles = TpTextStyles.of(context);

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (sheetContext) => SizedBox(
        height: MediaQuery.of(sheetContext).size.height * 0.6,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Icon(Icons.photo_library, color: cs.primary),
                  const SizedBox(width: 8),
                  Text(
                    _strings.selectAlbum,
                    style: styles.mdSemibold,
                  ),
                  const Spacer(),
                  Text(
                    _strings.albumCount(_albums.length),
                    style: styles.mutedSm,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: _albums.isEmpty
                  ? Center(
                      child: Text(
                        _strings.noAlbumsFound,
                        style: styles.mutedSm,
                      ),
                    )
                  : ListView(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      children: [
                        for (final album in _albums)
                          ListTile(
                            contentPadding: const EdgeInsets.symmetric(
                              vertical: 8,
                            ),
                            leading: ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: SizedBox(
                                width: 60,
                                height: 60,
                                child: FutureBuilder<Uint8List?>(
                                  future: _albumThumbnail(album),
                                  builder: (context, snapshot) {
                                    if (snapshot.data != null) {
                                      return Image.memory(
                                        snapshot.data!,
                                        fit: BoxFit.cover,
                                        width: 60,
                                        height: 60,
                                      );
                                    }
                                    return ColoredBox(
                                      color: cs.surfaceContainerHighest,
                                      child: Icon(
                                        Icons.folder,
                                        color: cs.onSurfaceVariant,
                                        size: 24,
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ),
                            title: Text(
                              album.name,
                              style: styles.smMedium,
                            ),
                            subtitle: album.assetCount == null
                                ? null
                                : Text(
                                    _strings.mediaItemCount(
                                      album.assetCount!,
                                      _mediaTypeLabel,
                                    ),
                                    style: styles.mutedSm,
                                  ),
                            trailing: _currentAlbum?.id == album.id
                                ? Icon(
                                    Icons.check_circle,
                                    color: cs.primary,
                                  )
                                : null,
                            onTap: () {
                              _changeAlbum(album);
                              Navigator.pop(sheetContext);
                            },
                          ),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }

  void _showSearchDialog() {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(_strings.searchMediaTitle),
        content: TextField(
          controller: _searchController,
          decoration: InputDecoration(
            hintText: _strings.inputKeywordHint,
            prefixIcon: const Icon(Icons.search),
          ),
          onChanged: (value) => setState(() => _query = value),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () {
              _searchController.clear();
              setState(() => _query = '');
              Navigator.pop(dialogContext);
            },
            child: Text(_strings.actionClear),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(_strings.actionConfirm),
          ),
        ],
      ),
    );
  }

  @override
  Future<void> selectAll() {
    return _mediaGridKey.currentState?.selectAll() ?? Future.value();
  }

  @override
  int get selectableCount => _mediaGridKey.currentState?.selectableCount ?? 0;

  @override
  void applySorting(String sortType, {required bool ascending}) {
    _mediaGridKey.currentState?.applySorting(sortType, ascending: ascending);
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (!_hasGalleryPermission) {
      return TpEmptyState(
        centered: true,
        icon: Icons.photo_library_outlined,
        title: _strings.galleryPermissionRequired,
        actionLabel: _strings.authorize,
        onAction: _requestGalleryAgain,
      );
    }

    final album = _currentAlbum;
    return Column(
      children: [
        _buildFilterRow(context),
        Divider(height: 1, color: cs.outlineVariant.withValues(alpha: 0.4)),
        Expanded(
          child: album == null
              ? TpEmptyState(
                  centered: true,
                  icon: Icons.photo_library_outlined,
                  title: _strings.noAlbumsFound,
                  actionLabel: _strings.actionReload,
                  onAction: _loadAlbums,
                )
              : TpClassicMediaGrid(
                  key: ValueKey(
                    'tp_classic_gallery_grid_${album.id}_$_viewMode',
                  ),
                  deps: widget.deps,
                  options: widget.options,
                  controller: widget.controller,
                  source: TpClassicMediaSource(
                    albumId: album.id,
                    title: album.name,
                    includeVideos: _includeVideos,
                    includeImages: _includeImages,
                  ),
                  onBack: () {},
                  showHeader: false,
                  viewMode: _viewMode,
                  query: _query,
                ),
        ),
      ],
    );
  }

  Widget _buildFilterRow(BuildContext context) {
    return Container(
      key: const Key('tp_classic_gallery_filter_row'),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        children: [
          TpHover(
            key: const Key('tp_classic_gallery_album_pill'),
            onTap: _showAlbumSheet,
            borderRadius: BorderRadius.circular(16),
            pressScale: 0.97,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.photo_library,
                    size: 16,
                    color: Theme.of(context).colorScheme.onPrimary,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    _currentAlbum?.name ?? _strings.selectAlbum,
                    style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context).colorScheme.onPrimary,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),
          TextButton.icon(
            onPressed: () {
              setState(() {
                _viewMode = _viewMode == TpClassicMediaViewMode.grid
                    ? TpClassicMediaViewMode.list
                    : TpClassicMediaViewMode.grid;
              });
            },
            icon: Icon(
              _viewMode == TpClassicMediaViewMode.grid
                  ? Icons.view_list
                  : Icons.grid_view,
              size: 16,
            ),
            label: Text(
              _viewMode == TpClassicMediaViewMode.grid
                  ? _strings.switchToListMode
                  : _strings.switchToGridMode,
              style: const TextStyle(fontSize: 12),
            ),
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.onSurfaceVariant,
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          ),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.search, size: 20),
            onPressed: _showSearchDialog,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }
}

IconData _fileIconFor(String name) {
  final dot = name.lastIndexOf('.');
  final ext = dot <= 0 ? '' : name.substring(dot + 1).toLowerCase();
  return switch (ext) {
    'pdf' => Icons.picture_as_pdf,
    'doc' || 'docx' || 'txt' || 'md' || 'log' => Icons.description,
    'xls' || 'xlsx' || 'csv' => Icons.table_chart,
    'ppt' || 'pptx' => Icons.slideshow,
    'zip' || 'rar' || '7z' || 'tar' || 'gz' => Icons.folder_zip,
    'apk' => Icons.android,
    'mp3' || 'wav' || 'flac' || 'aac' || 'ogg' || 'm4a' => Icons.audio_file,
    'json' || 'xml' || 'html' || 'js' || 'dart' || 'py' || 'sh' => Icons.code,
    _ => Icons.insert_drive_file,
  };
}
