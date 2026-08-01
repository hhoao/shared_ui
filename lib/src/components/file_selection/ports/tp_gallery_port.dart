import 'dart:typed_data';

import '../models/tp_gallery_models.dart';

abstract class TpGalleryPort {
  Future<List<TpGalleryAlbum>> listAlbums({
    required bool includeVideos,
    required bool includeImages,
  });

  Future<List<TpGalleryAsset>> listAssets({
    required String albumId,
    required int page,
    required int pageSize,
    required bool includeVideos,
    required bool includeImages,
  });

  Future<Uint8List?> thumbnail(String assetId, {int size = 200});

  Future<String?> resolveToPath(String assetId);
}
