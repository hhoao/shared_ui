class TpGalleryAlbum {
  const TpGalleryAlbum({
    required this.id,
    required this.name,
    this.assetCount,
  });

  final String id;
  final String name;
  final int? assetCount;
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
