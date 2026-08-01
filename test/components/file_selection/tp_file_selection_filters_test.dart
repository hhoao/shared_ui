import 'package:flutter_test/flutter_test.dart';
import 'package:shared_ui/shared_ui.dart';

TpFsEntry _entry({
  required String name,
  TpFsEntryKind kind = TpFsEntryKind.file,
  DateTime? modifiedAt,
  int? sizeBytes,
}) {
  return TpFsEntry(
    path: '/tmp/$name',
    name: name,
    kind: kind,
    modifiedAt: modifiedAt,
    sizeBytes: sizeBytes,
  );
}

void main() {
  group('filterFsEntries', () {
    final entries = [
      _entry(name: 'photo.JPG'),
      _entry(name: 'clip.MP4'),
      _entry(name: 'notes.txt'),
      _entry(name: '.hidden', kind: TpFsEntryKind.file),
      _entry(name: 'Projects', kind: TpFsEntryKind.directory),
      _entry(name: '.config', kind: TpFsEntryKind.directory),
    ];

    test('extension filter is case-insensitive with or without leading dot', () {
      final withDot = filterFsEntries(
        entries,
        allowedExtensions: const ['.jpg', 'mp4'],
      );
      expect(withDot.map((e) => e.name), ['photo.JPG', 'clip.MP4', 'Projects']);

      final withoutDot = filterFsEntries(
        entries,
        allowedExtensions: const ['JPG', '.Mp4'],
      );
      expect(withoutDot.map((e) => e.name), ['photo.JPG', 'clip.MP4', 'Projects']);
    });

    test('null or empty allowedExtensions keeps all non-hidden entries', () {
      expect(
        filterFsEntries(entries).map((e) => e.name),
        ['photo.JPG', 'clip.MP4', 'notes.txt', 'Projects'],
      );
      expect(
        filterFsEntries(entries, allowedExtensions: const []).map((e) => e.name),
        ['photo.JPG', 'clip.MP4', 'notes.txt', 'Projects'],
      );
    });

    test('hides dot-prefixed names when showHiddenFiles is false', () {
      expect(
        filterFsEntries(entries, showHiddenFiles: false).map((e) => e.name),
        ['photo.JPG', 'clip.MP4', 'notes.txt', 'Projects'],
      );
    });

    test('shows dot-prefixed names when showHiddenFiles is true', () {
      expect(
        filterFsEntries(entries, showHiddenFiles: true).map((e) => e.name),
        [
          'photo.JPG',
          'clip.MP4',
          'notes.txt',
          '.hidden',
          'Projects',
          '.config',
        ],
      );
    });

    test('query filters by case-insensitive name substring', () {
      expect(
        filterFsEntries(entries, query: 'oto').map((e) => e.name),
        ['photo.JPG'],
      );
      expect(
        filterFsEntries(entries, query: 'PRO').map((e) => e.name),
        ['Projects'],
      );
      expect(
        filterFsEntries(entries, query: '   ').map((e) => e.name),
        ['photo.JPG', 'clip.MP4', 'notes.txt', 'Projects'],
      );
    });
  });

  group('sortFsEntries', () {
    final t1 = DateTime(2024, 1, 1);
    final t2 = DateTime(2024, 6, 1);
    final entries = [
      _entry(name: 'b.txt', modifiedAt: t2, sizeBytes: 200),
      _entry(name: 'A.png', modifiedAt: t1, sizeBytes: 100),
      _entry(name: 'folder', kind: TpFsEntryKind.directory),
      _entry(name: 'c.MP4', modifiedAt: t2, sizeBytes: 50),
    ];

    test('sorts by name ascending and descending', () {
      expect(
        sortFsEntries(entries, sortType: 'name').map((e) => e.name),
        ['folder', 'A.png', 'b.txt', 'c.MP4'],
      );
      expect(
        sortFsEntries(entries, sortType: 'name', ascending: false)
            .map((e) => e.name),
        ['folder', 'c.MP4', 'b.txt', 'A.png'],
      );
    });

    test('sorts by date ascending and descending', () {
      expect(
        sortFsEntries(entries, sortType: 'date').map((e) => e.name),
        ['folder', 'A.png', 'b.txt', 'c.MP4'],
      );
      expect(
        sortFsEntries(entries, sortType: 'date', ascending: false)
            .map((e) => e.name),
        ['folder', 'b.txt', 'c.MP4', 'A.png'],
      );
    });

    test('sorts by size ascending and descending', () {
      expect(
        sortFsEntries(entries, sortType: 'size').map((e) => e.name),
        ['folder', 'c.MP4', 'A.png', 'b.txt'],
      );
      expect(
        sortFsEntries(entries, sortType: 'size', ascending: false)
            .map((e) => e.name),
        ['folder', 'b.txt', 'A.png', 'c.MP4'],
      );
    });

    test('sorts by type ascending and descending', () {
      expect(
        sortFsEntries(entries, sortType: 'type').map((e) => e.name),
        ['folder', 'c.MP4', 'A.png', 'b.txt'],
      );
      expect(
        sortFsEntries(entries, sortType: 'type', ascending: false)
            .map((e) => e.name),
        ['folder', 'b.txt', 'A.png', 'c.MP4'],
      );
    });
  });

  group('resolveGalleryMediaFilter', () {
    test('returns all when extensions are null or empty', () {
      expect(resolveGalleryMediaFilter(null), TpGalleryMediaKind.all);
      expect(resolveGalleryMediaFilter(const []), TpGalleryMediaKind.all);
    });

    test('returns image when only image extensions are allowed', () {
      expect(
        resolveGalleryMediaFilter(const ['jpg', '.PNG', 'webp']),
        TpGalleryMediaKind.image,
      );
    });

    test('returns video when only video extensions are allowed', () {
      expect(
        resolveGalleryMediaFilter(const ['.mp4', 'MOV']),
        TpGalleryMediaKind.video,
      );
    });

    test('returns all when both image and video extensions are allowed', () {
      expect(
        resolveGalleryMediaFilter(const ['jpg', 'mp4']),
        TpGalleryMediaKind.all,
      );
    });

    test('returns all when extensions are neither image nor video', () {
      expect(
        resolveGalleryMediaFilter(const ['txt', 'pdf']),
        TpGalleryMediaKind.all,
      );
    });
  });
}
