abstract class TpFileSelectionTabApi {
  void clearSelection();

  Future<void> selectAll();

  int get selectableCount;

  /// Current sort option id (e.g. `'name'`, `'date'`).
  String get sortType;

  /// Whether the current sort is ascending.
  bool get sortAscending;

  void applySorting(String sortType, {required bool ascending});
}
