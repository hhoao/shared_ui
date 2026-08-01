abstract class TpPermissionPort {
  Future<bool> ensureStorageAccess();

  Future<bool> ensureGalleryAccess();

  Future<void> openAppSettings();
}
