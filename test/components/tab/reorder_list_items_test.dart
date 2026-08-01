import 'package:flutter_test/flutter_test.dart';
import 'package:shared_ui/shared_ui.dart';

void main() {
  test('reorderListItems applies Material onReorder index rules', () {
    expect(reorderListItems(['a', 'b', 'c'], 0, 2), ['b', 'a', 'c']);
    expect(reorderListItems(['a', 'b', 'c'], 2, 0), ['c', 'a', 'b']);
    expect(reorderListItems(['a', 'b', 'c'], 1, 1), ['a', 'b', 'c']);
  });
}
