class TpGalleryAlbum {
  const TpGalleryAlbum({
    required this.id,
    required this.name,
    this.assetCount,
    this.isAll = false,
  });

  final String id;
  final String name;
  final int? assetCount;

  /// Whether this is the device-wide "all media" album.
  final bool isAll;
}

class TpGalleryAsset {
  const TpGalleryAsset({
    required this.id,
    this.displayName,
    required this.isVideo,
    this.duration,
    this.createDateTime,
  });

  final String id;
  final String? displayName;
  final bool isVideo;
  final Duration? duration;
  final DateTime? createDateTime;
}
