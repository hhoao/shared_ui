/// Applies [ReorderableListView.onReorderItem] indices to [items].
///
/// [newIndex] is the insertion index after the item at [oldIndex] is removed.
List<T> reorderListItems<T>(List<T> items, int oldIndex, int newIndex) {
  if (items.isEmpty) return List<T>.of(items);
  if (oldIndex < 0 || oldIndex >= items.length) return List<T>.of(items);
  if (newIndex < 0 || newIndex >= items.length) return List<T>.of(items);
  if (newIndex == oldIndex) return List<T>.of(items);

  final next = List<T>.of(items);
  final item = next.removeAt(oldIndex);
  next.insert(newIndex, item);
  return next;
}
