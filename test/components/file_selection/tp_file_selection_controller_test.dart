import 'package:flutter_test/flutter_test.dart';
import 'package:shared_ui/shared_ui.dart';

class _FakeTabApi implements TpFileSelectionTabApi {
  int clearCalls = 0;

  @override
  void clearSelection() => clearCalls++;

  @override
  Future<void> selectAll() async {}

  @override
  int get selectableCount => 0;

  @override
  void applySorting(String sortType, {required bool ascending}) {}
}

void main() {
  group('TpFileSelectionController', () {
    test('rejects incremental select beyond maxSelectionCount', () {
      int? lastToast;
      final c = TpFileSelectionController(
        options: const TpFileSelectionOptions(
          allowMultiple: true,
          maxSelectionCount: 2,
        ),
        onMaxSelectionReached: (n) => lastToast = n,
      );
      c.replaceSelection([
        const TpPickedEntry(path: '/1', kind: TpPickedKind.file),
        const TpPickedEntry(path: '/2', kind: TpPickedKind.file),
      ]);

      final ok = c.trySelect(
        const TpPickedEntry(path: '/3', kind: TpPickedKind.file),
      );

      expect(ok, isFalse);
      expect(c.selection, hasLength(2));
      expect(lastToast, 2);
    });

    test('selectAllFrom caps to max and reports first-N toast', () {
      int? cappedToast;
      final c = TpFileSelectionController(
        options: const TpFileSelectionOptions(
          allowMultiple: true,
          maxSelectionCount: 2,
        ),
        onSelectAllCapped: (n) => cappedToast = n,
      );

      c.selectAllFrom([
        const TpPickedEntry(path: '/1', kind: TpPickedKind.file),
        const TpPickedEntry(path: '/2', kind: TpPickedKind.file),
        const TpPickedEntry(path: '/3', kind: TpPickedKind.file),
      ]);

      expect(c.selection, hasLength(2));
      expect(c.selection.map((e) => e.path), ['/1', '/2']);
      expect(cappedToast, 2);
    });

    test('selectAllFrom does not report capped toast when under max', () {
      int? cappedToast;
      final c = TpFileSelectionController(
        options: const TpFileSelectionOptions(
          allowMultiple: true,
          maxSelectionCount: 5,
        ),
        onSelectAllCapped: (n) => cappedToast = n,
      );

      c.selectAllFrom([
        const TpPickedEntry(path: '/1', kind: TpPickedKind.file),
      ]);

      expect(c.selection, hasLength(1));
      expect(cappedToast, isNull);
    });

    test('shouldConfirmTabChange true when selection non-empty and different tab',
        () {
      final c = TpFileSelectionController(
        options: const TpFileSelectionOptions(),
      );
      c.trySelect(const TpPickedEntry(path: '/1', kind: TpPickedKind.file));

      expect(c.shouldConfirmTabChange(TpFileSelectionTab.gallery), isTrue);
      expect(c.activeTab, TpFileSelectionTab.filesystem);
    });

    test('shouldConfirmTabChange false when selection empty', () {
      final c = TpFileSelectionController(
        options: const TpFileSelectionOptions(),
      );

      expect(c.shouldConfirmTabChange(TpFileSelectionTab.gallery), isFalse);
      expect(c.activeTab, TpFileSelectionTab.gallery);
    });

    test('shouldConfirmTabChange false when same tab', () {
      final c = TpFileSelectionController(
        options: const TpFileSelectionOptions(),
      );
      c.trySelect(const TpPickedEntry(path: '/1', kind: TpPickedKind.file));

      expect(c.shouldConfirmTabChange(TpFileSelectionTab.filesystem), isFalse);
      expect(c.activeTab, TpFileSelectionTab.filesystem);
    });

    test('confirmTabChange clears then switches', () {
      final fsApi = _FakeTabApi();
      final galleryApi = _FakeTabApi();
      final c = TpFileSelectionController(
        options: const TpFileSelectionOptions(),
      );
      c.registerTabApi(TpFileSelectionTab.filesystem, fsApi);
      c.registerTabApi(TpFileSelectionTab.gallery, galleryApi);

      c.trySelect(const TpPickedEntry(path: '/1', kind: TpPickedKind.file));
      c.confirmTabChange(TpFileSelectionTab.gallery);

      expect(c.selection, isEmpty);
      expect(c.activeTab, TpFileSelectionTab.gallery);
      expect(fsApi.clearCalls, 1);
      expect(galleryApi.clearCalls, 1);
    });

    test('directory mode confirm builds entry from currentPath', () {
      final c = TpFileSelectionController(
        options: const TpFileSelectionOptions(
          selectionMode: TpSelectionMode.directories,
        ),
      );
      c.setCurrentPath('/home/user/docs');

      final result = c.confirmDirectorySelection();

      expect(
        result,
        [
          const TpPickedEntry(
            path: '/home/user/docs',
            kind: TpPickedKind.directory,
          ),
        ],
      );
    });

    test('clearSelection notifies registered tab APIs', () {
      final fsApi = _FakeTabApi();
      final galleryApi = _FakeTabApi();
      final c = TpFileSelectionController(
        options: const TpFileSelectionOptions(allowMultiple: true),
      );
      c.registerTabApi(TpFileSelectionTab.filesystem, fsApi);
      c.registerTabApi(TpFileSelectionTab.gallery, galleryApi);

      c.trySelect(const TpPickedEntry(path: '/1', kind: TpPickedKind.file));
      c.clearSelection();

      expect(c.selection, isEmpty);
      expect(fsApi.clearCalls, 1);
      expect(galleryApi.clearCalls, 1);
    });

    test('single-select replaces prior entry', () {
      final c = TpFileSelectionController(
        options: const TpFileSelectionOptions(allowMultiple: false),
      );

      c.trySelect(const TpPickedEntry(path: '/1', kind: TpPickedKind.file));
      c.trySelect(const TpPickedEntry(path: '/2', kind: TpPickedKind.file));

      expect(c.selection, hasLength(1));
      expect(c.selection.first.path, '/2');
    });
  });
}
