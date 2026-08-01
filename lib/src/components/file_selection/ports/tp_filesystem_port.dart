import '../models/tp_fs_entry.dart';

abstract class TpFilesystemPort {
  List<TpFilesystemRoot> defaultRoots();

  /// Platform default browse root when [TpFileSelectionOptions.initialPath] is null.
  String defaultBrowsePath();

  Future<List<TpFsEntry>> listDir(String path);

  /// When null, UI hides the full-disk-search sub-tab.
  Future<List<TpFsEntry>>? Function(String rootPath, String query)? get searchFiles =>
      null;

  Future<bool> exists(String path);

  Future<TpFsEntryKind> kindOf(String path);
}
