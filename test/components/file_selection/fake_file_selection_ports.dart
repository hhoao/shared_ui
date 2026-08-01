import 'dart:typed_data';

import 'package:flutter/widgets.dart';
import 'package:shared_ui/shared_ui.dart';

/// In-memory filesystem port for file_selection tests.
class FakeFilesystemPort implements TpFilesystemPort {
  FakeFilesystemPort({
    Map<String, List<TpFsEntry>>? entriesByPath,
    List<TpFilesystemRoot>? roots,
    String browsePath = '/',
    Future<List<TpFsEntry>>? Function(String rootPath, String query)? searchFiles,
    Set<String>? existingPaths,
  }) {
    _entriesByPath.addAll(entriesByPath ?? {});
    _roots = roots ?? [];
    _browsePath = browsePath;
    _searchFiles = searchFiles;
    _existingPaths.addAll(existingPaths ?? _entriesByPath.keys);
  }

  final Map<String, List<TpFsEntry>> _entriesByPath = {};
  List<TpFilesystemRoot> _roots = [];
  String _browsePath = '/';
  Future<List<TpFsEntry>>? Function(String rootPath, String query)? _searchFiles;
  final Set<String> _existingPaths = {};

  void setEntries(String path, List<TpFsEntry> entries) {
    _entriesByPath[path] = entries;
    _existingPaths.add(path);
    for (final entry in entries) {
      _existingPaths.add(entry.path);
    }
  }

  void setRoots(List<TpFilesystemRoot> roots) => _roots = roots;

  void setBrowsePath(String path) => _browsePath = path;

  void setSearchFiles(
    Future<List<TpFsEntry>>? Function(String rootPath, String query)? fn,
  ) {
    _searchFiles = fn;
  }

  void markExists(String path, {TpFsEntryKind kind = TpFsEntryKind.file}) {
    _existingPaths.add(path);
    _kindByPath[path] = kind;
  }

  final Map<String, TpFsEntryKind> _kindByPath = {};

  @override
  List<TpFilesystemRoot> defaultRoots() => List.unmodifiable(_roots);

  @override
  String defaultBrowsePath() => _browsePath;

  @override
  Future<List<TpFsEntry>> listDir(String path) async {
    return List.unmodifiable(_entriesByPath[path] ?? []);
  }

  @override
  Future<List<TpFsEntry>>? Function(String rootPath, String query)?
      get searchFiles => _searchFiles;

  @override
  Future<bool> exists(String path) async => _existingPaths.contains(path);

  @override
  Future<TpFsEntryKind> kindOf(String path) async {
    if (_kindByPath.containsKey(path)) {
      return _kindByPath[path]!;
    }
    final entries = _entriesByPath[path];
    if (entries != null) {
      return TpFsEntryKind.directory;
    }
    return TpFsEntryKind.file;
  }
}

/// Permission port with configurable grant/deny for tests.
class FakePermissionPort implements TpPermissionPort {
  FakePermissionPort({
    this.grantStorage = true,
    this.grantGallery = true,
  });

  bool grantStorage;
  bool grantGallery;
  int openAppSettingsCallCount = 0;

  @override
  Future<bool> ensureStorageAccess() async => grantStorage;

  @override
  Future<bool> ensureGalleryAccess() async => grantGallery;

  @override
  Future<void> openAppSettings() async {
    openAppSettingsCallCount++;
  }
}

/// Gallery port with canned albums, assets, and thumbnails.
class FakeGalleryPort implements TpGalleryPort {
  FakeGalleryPort({
    List<TpGalleryAlbum>? albums,
    Map<String, List<TpGalleryAsset>>? assetsByAlbum,
    Map<String, Uint8List>? thumbnailsByAssetId,
    Map<String, String>? pathsByAssetId,
  }) {
    _albums.addAll(albums ?? []);
    _assetsByAlbum.addAll(assetsByAlbum ?? {});
    _thumbnailsByAssetId.addAll(thumbnailsByAssetId ?? {});
    _pathsByAssetId.addAll(pathsByAssetId ?? {});
  }

  final List<TpGalleryAlbum> _albums = [];
  final Map<String, List<TpGalleryAsset>> _assetsByAlbum = {};
  final Map<String, Uint8List> _thumbnailsByAssetId = {};
  final Map<String, String> _pathsByAssetId = {};

  void setAlbums(List<TpGalleryAlbum> albums) {
    _albums
      ..clear()
      ..addAll(albums);
  }

  void setAssets(String albumId, List<TpGalleryAsset> assets) {
    _assetsByAlbum[albumId] = assets;
  }

  @override
  Future<List<TpGalleryAlbum>> listAlbums({
    required bool includeVideos,
    required bool includeImages,
  }) async {
    return List.unmodifiable(_albums);
  }

  List<TpGalleryAsset> _filteredAssets(
    String albumId, {
    required bool includeVideos,
    required bool includeImages,
  }) {
    final all = _assetsByAlbum[albumId] ?? [];
    return all.where((asset) {
      if (asset.isVideo && !includeVideos) {
        return false;
      }
      if (!asset.isVideo && !includeImages) {
        return false;
      }
      return true;
    }).toList();
  }

  @override
  Future<List<TpGalleryAsset>> listAssets({
    required String albumId,
    required int page,
    required int pageSize,
    required bool includeVideos,
    required bool includeImages,
  }) async {
    final filtered = _filteredAssets(
      albumId,
      includeVideos: includeVideos,
      includeImages: includeImages,
    );
    final start = page * pageSize;
    if (start >= filtered.length) return [];
    final end = (start + pageSize).clamp(0, filtered.length);
    return List.unmodifiable(filtered.sublist(start, end));
  }

  @override
  Future<Uint8List?> thumbnail(String assetId, {int size = 200}) async {
    return _thumbnailsByAssetId[assetId];
  }

  @override
  Future<String?> resolveToPath(String assetId) async {
    return _pathsByAssetId[assetId];
  }
}

/// Desktop picker port that returns preconfigured picks.
class FakeDesktopPickerPort implements TpDesktopPickerPort {
  FakeDesktopPickerPort({
    List<TpPickedEntry>? pickFilesResult,
    List<TpPickedEntry>? pickDirectoryResult,
  })  : _pickFilesResult = pickFilesResult,
        _pickDirectoryResult = pickDirectoryResult;

  List<TpPickedEntry>? _pickFilesResult;
  List<TpPickedEntry>? _pickDirectoryResult;
  int pickFilesCallCount = 0;
  int pickDirectoryCallCount = 0;

  void setPickFilesResult(List<TpPickedEntry>? result) {
    _pickFilesResult = result;
  }

  void setPickDirectoryResult(List<TpPickedEntry>? result) {
    _pickDirectoryResult = result;
  }

  @override
  Future<List<TpPickedEntry>?> pickFiles({
    bool allowMultiple = false,
    List<String>? allowedExtensions,
    String? dialogTitle,
    String? initialDirectory,
    int? maxSelectionCount,
  }) async {
    pickFilesCallCount++;
    return _pickFilesResult;
  }

  @override
  Future<List<TpPickedEntry>?> pickDirectory({
    String? dialogTitle,
    String? initialDirectory,
  }) async {
    pickDirectoryCallCount++;
    return _pickDirectoryResult;
  }
}

/// Media preview port that records preview calls.
class FakeMediaPreviewPort implements TpMediaPreviewPort {
  List<String> previewedImagePaths = [];
  List<String> previewedVideoPaths = [];

  @override
  Future<void> previewImage(BuildContext context, String path) async {
    previewedImagePaths.add(path);
  }

  @override
  Future<void> previewVideo(BuildContext context, String path) async {
    previewedVideoPaths.add(path);
  }
}
