import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../../theme/tp_text_styles.dart';
import '../../button/tp_button.dart';
import '../../empty_state/tp_empty_state.dart';
import '../../input/tp_input.dart';
import '../controller/tp_file_selection_controller.dart';
import '../controller/tp_file_selection_filters.dart';
import '../controller/tp_file_selection_tab_api.dart';
import '../models/tp_file_selection_options.dart';
import '../models/tp_gallery_models.dart';
import '../models/tp_picked_entry.dart';
import '../ports/tp_file_selection_deps.dart';
import 'tp_file_selection_strings.dart';
import 'widgets/tp_gallery_asset_tile.dart';

class TpGalleryTab extends StatefulWidget {
  const TpGalleryTab({
    super.key,
    required this.deps,
    required this.options,
    required this.controller,
  });

  final TpFileSelectionDeps deps;
  final TpFileSelectionOptions options;
  final TpFileSelectionController controller;

  @override
  State<TpGalleryTab> createState() => TpGalleryTabState();
}

class TpGalleryTabState extends State<TpGalleryTab>
    implements TpFileSelectionTabApi {
  static const _pageSize = 50;

  final _searchController = TextEditingController();
  final _scrollController = ScrollController();

  List<TpGalleryAlbum> _albums = [];
  List<TpGalleryAsset> _assets = [];
  List<TpGalleryAsset> _visibleAssets = [];
  final Map<String, String> _assetPathCache = {};
  final Map<String, Uint8List?> _thumbnailCache = {};

  String? _selectedAlbumId;
  String _selectedAlbumName = '';
  String _searchQuery = '';
  bool _hasGalleryPermission = false;
  bool _isLoading = false;
  bool _isLoadingMore = false;
  bool _hasMoreData = false;
  int _currentPage = 0;

  TpFileSelectionStrings get _strings => widget.deps.strings;

  bool get _includeImages {
    final kind = resolveGalleryMediaFilter(widget.options.allowedExtensions);
    return kind == TpGalleryMediaKind.all || kind == TpGalleryMediaKind.image;
  }

  bool get _includeVideos {
    final kind = resolveGalleryMediaFilter(widget.options.allowedExtensions);
    return kind == TpGalleryMediaKind.all || kind == TpGalleryMediaKind.video;
  }

  @override
  void initState() {
    super.initState();
    widget.controller.registerTabApi(TpFileSelectionTab.gallery, this);
    _scrollController.addListener(_onScroll);
    _bootstrap();
  }

  @override
  void dispose() {
    widget.controller.unregisterTabApi(TpFileSelectionTab.gallery);
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _bootstrap() async {
    final granted = await widget.deps.permission.ensureGalleryAccess();
    if (!mounted) return;

    setState(() => _hasGalleryPermission = granted);
    if (granted) {
      await _loadAlbumsAndAssets();
    }
  }

  Future<void> _loadAlbumsAndAssets() async {
    final gallery = widget.deps.gallery;
    if (gallery == null) return;

    setState(() => _isLoading = true);
    try {
      final albums = await gallery.listAlbums(
        includeVideos: _includeVideos,
        includeImages: _includeImages,
      );
      if (!mounted) return;

      final selectedAlbum = albums.isEmpty
          ? null
          : albums.firstWhere(
              (album) => album.id == _selectedAlbumId,
              orElse: () => albums.first,
            );

      setState(() {
        _albums = albums;
        _selectedAlbumId = selectedAlbum?.id;
        _selectedAlbumName = selectedAlbum?.name ?? '';
      });

      if (selectedAlbum != null) {
        await _loadAssets(reset: true);
      } else {
        setState(() {
          _assets = [];
          _isLoading = false;
          _hasMoreData = false;
        });
        _applyFiltering();
      }
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _albums = [];
        _assets = [];
        _isLoading = false;
        _hasMoreData = false;
      });
      _applyFiltering();
    }
  }

  Future<void> _loadAssets({required bool reset}) async {
    final gallery = widget.deps.gallery;
    final albumId = _selectedAlbumId;
    if (gallery == null || albumId == null) return;

    if (reset) {
      setState(() {
        _isLoading = true;
        _currentPage = 0;
        _hasMoreData = true;
        _assets = [];
      });
    }

    try {
      final pageAssets = await gallery.listAssets(
        albumId: albumId,
        page: 0,
        pageSize: _pageSize,
        includeVideos: _includeVideos,
        includeImages: _includeImages,
      );
      if (!mounted) return;

      setState(() {
        _assets = pageAssets;
        _isLoading = false;
        _hasMoreData = pageAssets.length >= _pageSize;
        _currentPage = pageAssets.isEmpty ? 0 : 1;
      });
      _preloadPaths(pageAssets);
      _applyFiltering();
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _assets = [];
        _isLoading = false;
        _hasMoreData = false;
      });
      _applyFiltering();
    }
  }

  Future<void> _loadMoreAssets() async {
    final gallery = widget.deps.gallery;
    final albumId = _selectedAlbumId;
    if (gallery == null ||
        albumId == null ||
        _isLoadingMore ||
        !_hasMoreData) {
      return;
    }

    setState(() => _isLoadingMore = true);
    try {
      final moreAssets = await gallery.listAssets(
        albumId: albumId,
        page: _currentPage,
        pageSize: _pageSize,
        includeVideos: _includeVideos,
        includeImages: _includeImages,
      );
      if (!mounted) return;

      setState(() {
        _assets = [..._assets, ...moreAssets];
        _hasMoreData = moreAssets.length >= _pageSize;
        _currentPage++;
        _isLoadingMore = false;
      });
      _preloadPaths(moreAssets);
      _applyFiltering();
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

  void _applyFiltering() {
    final normalizedQuery = _searchQuery.trim().toLowerCase();
    final filtered = _assets.where((asset) {
      if (normalizedQuery.isEmpty) {
        return true;
      }
      final name = asset.displayName?.toLowerCase() ?? '';
      return name.contains(normalizedQuery);
    }).toList();

    if (!mounted) return;
    setState(() => _visibleAssets = filtered);
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

  Future<void> _selectAlbum(TpGalleryAlbum album) async {
    setState(() {
      _selectedAlbumId = album.id;
      _selectedAlbumName = album.name;
    });
    await _loadAssets(reset: true);
  }

  void _showAlbumPicker() {
    final styles = TpTextStyles.of(context);
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    const Icon(Icons.photo_library_outlined),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _strings.selectAlbum,
                        style: styles.smSemibold,
                      ),
                    ),
                    Text(
                      _strings.albumCount(_albums.length),
                      style: styles.mutedSm,
                    ),
                  ],
                ),
              ),
              if (_albums.isEmpty)
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: TpEmptyState(
                    icon: Icons.photo_library_outlined,
                    title: _strings.noAlbumsFound,
                    hint: _strings.checkAlbumPermissionOrEmpty,
                    actionLabel: _strings.actionReload,
                    onAction: () {
                      Navigator.pop(context);
                      _loadAlbumsAndAssets();
                    },
                  ),
                )
              else
                Flexible(
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: _albums.length,
                    itemBuilder: (context, index) {
                      final album = _albums[index];
                      final selected = album.id == _selectedAlbumId;
                      return ListTile(
                        title: Text(album.name, style: styles.smMedium),
                        subtitle: album.assetCount == null
                            ? null
                            : Text(
                                _strings.mediaItemCount(
                                  album.assetCount!,
                                  _mediaTypeLabel(),
                                ),
                                style: styles.mutedSm,
                              ),
                        trailing: selected
                            ? Icon(
                                Icons.check_circle,
                                color: Theme.of(context).colorScheme.primary,
                              )
                            : null,
                        onTap: () {
                          Navigator.pop(context);
                          _selectAlbum(album);
                        },
                      );
                    },
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  String _mediaTypeLabel() {
    final kind = resolveGalleryMediaFilter(widget.options.allowedExtensions);
    return switch (kind) {
      TpGalleryMediaKind.image => _strings.mediaTypeImage,
      TpGalleryMediaKind.video => _strings.mediaTypeVideo,
      TpGalleryMediaKind.all => _strings.mediaTypeAll,
    };
  }

  bool _isAssetSelected(TpGalleryAsset asset) {
    final path = _assetPathCache[asset.id];
    if (path == null) return false;
    return widget.controller.selection.any((entry) => entry.path == path);
  }

  Future<void> _toggleAssetSelection(TpGalleryAsset asset) async {
    final gallery = widget.deps.gallery;
    if (gallery == null) return;

    final path = _assetPathCache[asset.id] ?? await gallery.resolveToPath(asset.id);
    if (path == null || !mounted) return;

    setState(() => _assetPathCache[asset.id] = path);
    final picked = _assetToPicked(asset, path);
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

    final path = _assetPathCache[asset.id] ?? await gallery.resolveToPath(asset.id);
    if (path == null || !mounted) return;

    setState(() => _assetPathCache[asset.id] = path);
    if (asset.isVideo) {
      await preview.previewVideo(context, path);
    } else {
      await preview.previewImage(context, path);
    }
  }

  TpPickedEntry _assetToPicked(TpGalleryAsset asset, String path) {
    return TpPickedEntry(
      path: path,
      kind: TpPickedKind.file,
      displayName: asset.displayName,
    );
  }

  Future<List<TpPickedEntry>> _selectablePickedEntries() async {
    final gallery = widget.deps.gallery;
    if (gallery == null) return [];

    final picked = <TpPickedEntry>[];
    for (final asset in _visibleAssets) {
      final path = _assetPathCache[asset.id] ?? await gallery.resolveToPath(asset.id);
      if (path == null) continue;
      _assetPathCache[asset.id] = path;
      picked.add(_assetToPicked(asset, path));
    }
    return picked;
  }

  @override
  void clearSelection() {
    widget.controller.replaceSelection([]);
  }

  @override
  Future<void> selectAll() async {
    final picked = await _selectablePickedEntries();
    widget.controller.selectAllFrom(picked);
  }

  @override
  int get selectableCount {
    final total = _visibleAssets.length;
    final max = widget.options.maxSelectionCount;
    if (max != null && total > max) {
      return max;
    }
    return total;
  }

  @override
  void applySorting(String sortType, {required bool ascending}) {}

  @visibleForTesting
  int get loadedAssetCount => _assets.length;

  @visibleForTesting
  Future<void> debugLoadMore() => _loadMoreAssets();

  @override
  Widget build(BuildContext context) {
    if (!_hasGalleryPermission) {
      return TpEmptyState(
        centered: true,
        icon: Icons.photo_library_outlined,
        title: _strings.galleryPermissionRequired,
        hint: _strings.galleryPermissionMessage,
        actionLabel: _strings.goToSettings,
        onAction: widget.deps.permission.openAppSettings,
      );
    }

    final styles = TpTextStyles.of(context);
    final cs = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
          child: Row(
            children: [
              TpButton(
                key: const Key('tp_gallery_album_selector'),
                variant: TpButtonVariant.primary,
                onPressed: _albums.isEmpty ? null : _showAlbumPicker,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.photo_library_outlined, size: 16),
                    const SizedBox(width: 4),
                    Text(
                      _selectedAlbumName.isEmpty
                          ? _strings.selectAlbum
                          : _selectedAlbumName,
                      style: styles.smMediumColored(cs.onPrimary),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
          child: TpInput(
            key: const Key('tp_gallery_search_field'),
            controller: _searchController,
            decoration: InputDecoration(
              hintText: _strings.inputKeywordHint,
              prefixIcon: const Icon(Icons.search),
            ),
            onChanged: (value) {
              _searchQuery = value;
              _applyFiltering();
            },
          ),
        ),
        Expanded(
          child: ListenableBuilder(
            listenable: widget.controller,
            builder: (context, _) => _buildBody(context),
          ),
        ),
      ],
    );
  }

  Widget _buildBody(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_visibleAssets.isEmpty) {
      return TpEmptyState(
        centered: true,
        icon: _searchQuery.isNotEmpty
            ? Icons.search_off
            : Icons.photo_library_outlined,
        title: _searchQuery.isNotEmpty
            ? _strings.noMatchingMediaFiles(_mediaTypeLabel())
            : _strings.noMediaFiles(_mediaTypeLabel()),
        hint: _searchQuery.isNotEmpty
            ? _strings.tryModifySearchConditions
            : _strings.checkAlbumPermissionOrEmpty,
        actionLabel: _searchQuery.isNotEmpty ? _strings.clearSearch : _strings.actionReload,
        onAction: () {
          if (_searchQuery.isNotEmpty) {
            _searchController.clear();
            _searchQuery = '';
            _applyFiltering();
          } else {
            _loadAlbumsAndAssets();
          }
        },
      );
    }

    return CustomScrollView(
      key: const Key('tp_gallery_asset_grid'),
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
                final asset = _visibleAssets[index];
                return TpGalleryAssetTile(
                  asset: asset,
                  strings: _strings,
                  isSelected: _isAssetSelected(asset),
                  onTap: _toggleAssetSelection,
                  onPreview: widget.deps.preview == null ? null : _previewAsset,
                  loadThumbnail: () async {
                    if (_thumbnailCache.containsKey(asset.id)) {
                      return _thumbnailCache[asset.id];
                    }
                    final bytes = await widget.deps.gallery?.thumbnail(asset.id);
                    _thumbnailCache[asset.id] = bytes;
                    return bytes;
                  },
                );
              },
              childCount: _visibleAssets.length,
            ),
          ),
        ),
        if (_hasMoreData && !_isLoadingMore)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: TpButton(
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
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _strings.loadMore,
                    style: TpTextStyles.of(context).mutedSm,
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}
