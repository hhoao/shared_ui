import 'package:flutter_test/flutter_test.dart';
import 'package:shared_ui/shared_ui.dart';

void main() {
  group('tpSelectItemMatchesQuery', () {
    test('matches empty query against any item', () {
      expect(
        tpSelectItemMatchesQuery(query: '  ', searchText: 'Alpha'),
        isTrue,
      );
    });

    test('matches case-insensitive substring', () {
      expect(
        tpSelectItemMatchesQuery(query: 'BeT', searchText: 'Beta Model'),
        isTrue,
      );
      expect(
        tpSelectItemMatchesQuery(query: 'zzz', searchText: 'Beta Model'),
        isFalse,
      );
    });

    test('uses custom predicate when provided', () {
      expect(
        tpSelectItemMatchesQuery(
          query: 'abc',
          searchText: 'ignored',
          predicate: (_, q) => q == 'abc',
        ),
        isTrue,
      );
    });
  });
}
