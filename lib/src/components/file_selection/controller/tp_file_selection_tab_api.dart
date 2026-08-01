abstract class TpFileSelectionTabApi {
  void clearSelection();

  Future<void> selectAll();

  int get selectableCount;

  /// Filesystem tab only; gallery may no-op. Page app-bar sort calls this.
  void applySorting(String sortType, {required bool ascending});
}
