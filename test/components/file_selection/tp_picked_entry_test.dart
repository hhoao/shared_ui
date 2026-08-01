import 'package:flutter_test/flutter_test.dart';
import 'package:shared_ui/shared_ui.dart';

void main() {
  test('TpPickedEntry equality by path+kind', () {
    const a = TpPickedEntry(path: '/a', kind: TpPickedKind.file);
    const b = TpPickedEntry(path: '/a', kind: TpPickedKind.file);
    expect(a, equals(b));
  });

  test('TpFileSelectionOptions defaults match huji FileSelection', () {
    const o = TpFileSelectionOptions();
    expect(o.allowMultiple, isFalse);
    expect(o.selectionMode, TpSelectionMode.files);
    expect(o.showHiddenFiles, isFalse);
    expect(o.initialTab, isNull);
  });
}
