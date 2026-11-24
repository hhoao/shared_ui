import 'dart:typed_data';

import '../models/tp_gallery_models.dart';

abstract class TpGalleryPort {
  /// Lists albums. [sortType]/[ascending] configure how the underlying
  /// provider should order assets, since paging requires native-side ordering.
  Future<List<TpGalleryAlbum>> listAlbums({
    required bool includeVideos,
    required bool includeImages,
    String sortType = 'date',
    bool ascending = false,
  });

  /// Lists one page of assets. Only `'date'` is required to be supported by
  /// gallery providers; paging must reflect the requested order.
  Future<List<TpGalleryAsset>> listAssets({
    required String albumId,
    required int page,
    required int pageSize,
    required bool includeVideos,
    required bool includeImages,
    String sortType = 'date',
    bool ascending = false,
  });

  Future<Uint8List?> thumbnail(String assetId, {int size = 200});

  Future<String?> resolveToPath(String assetId);
}
