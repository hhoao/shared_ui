/// Applies Material [ReorderableListView.onReorder] indices to [items].
///
/// When [newIndex] > [oldIndex], decrements before insert (Flutter docs).
List<T> reorderListItems<T>(List<T> items, int oldIndex, int newIndex) {
  if (items.isEmpty) return List<T>.of(items);
  if (oldIndex < 0 || oldIndex >= items.length) return List<T>.of(items);
  if (newIndex < 0 || newIndex > items.length) return List<T>.of(items);

  var target = newIndex;
  if (target > oldIndex) target -= 1;
  if (target == oldIndex) return List<T>.of(items);

  final next = List<T>.of(items);
  final item = next.removeAt(oldIndex);
  next.insert(target, item);
  return next;
}
