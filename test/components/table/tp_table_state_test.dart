import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_ui/shared_ui.dart';

TpTableColumn<String> _column(
  String id, {
  bool locked = false,
  bool hideable = true,
}) {
  return TpTableColumn<String>(
    id: id,
    label: id,
    locked: locked,
    hideable: hideable,
    cellBuilder: (context, row) => Text(row),
  );
}

void main() {
  test('locked columns stay first and stored order wins', () {
    final columns = [
      _column('group', locked: true),
      _column('total'),
      _column('input'),
    ];

    final ordered = orderedTableColumns(
      columns,
      const TpTableState(order: ['input', 'total']),
    );

    expect(ordered.map((column) => column.id), ['group', 'input', 'total']);
  });

  test('new columns insert before the next known column', () {
    final columns = [
      _column('group', locked: true),
      _column('total'),
      _column('input'),
      _column('share'),
    ];

    final ordered = orderedTableColumns(
      columns,
      const TpTableState(order: ['group', 'share']),
    );

    expect(ordered.map((column) => column.id), [
      'group',
      'total',
      'input',
      'share',
    ]);
  });

  test('hidden columns are removed but locked stays', () {
    final columns = [
      _column('group', locked: true),
      _column('total'),
      _column('input'),
    ];

    final visible = visibleTableColumns(
      columns,
      const TpTableState(hidden: {'group', 'input'}),
    );

    expect(visible.map((column) => column.id), ['group', 'total']);
  });

  test('reorderTableColumnIds moves to the target slot', () {
    expect(
      reorderTableColumnIds(['group', 'total', 'input'], 'total', 'input'),
      ['group', 'input', 'total'],
    );
  });

  test('json round trip and malformed input', () {
    const state = TpTableState(
      order: ['group', 'total'],
      hidden: {'input'},
      sort: TpTableSort(columnId: 'total', ascending: false),
    );

    final restored = TpTableState.fromJson(state.toJson());
    expect(restored.order, state.order);
    expect(restored.hidden, state.hidden);
    expect(restored.sort, state.sort);

    final malformed = TpTableState.fromJson({
      'order': 'bad',
      'hidden': 3,
      'sort': [],
    });
    expect(malformed.order, isEmpty);
    expect(malformed.hidden, isEmpty);
    expect(malformed.sort, isNull);
  });

  test('equivalent states compare and hash equally', () {
    const state = TpTableState(
      order: ['group', 'total'],
      hidden: {'input'},
      sort: TpTableSort(columnId: 'total', ascending: true),
    );
    final other = TpTableState(
      order: List<String>.of(state.order),
      hidden: Set<String>.of(state.hidden),
      sort: const TpTableSort(columnId: 'total', ascending: true),
    );

    expect(other, state);
    expect(other.hashCode, state.hashCode);
  });

  test('differing order, hidden, or sort makes states unequal', () {
    const state = TpTableState(
      order: ['group', 'total'],
      hidden: {'input'},
      sort: TpTableSort(columnId: 'total', ascending: true),
    );

    expect(state, isNot(const TpTableState(
      order: ['total', 'group'],
      hidden: {'input'},
      sort: TpTableSort(columnId: 'total', ascending: true),
    )));
    expect(state, isNot(const TpTableState(
      order: ['group', 'total'],
      hidden: {'share'},
      sort: TpTableSort(columnId: 'total', ascending: true),
    )));
    expect(state, isNot(const TpTableState(
      order: ['group', 'total'],
      hidden: {'input'},
      sort: TpTableSort(columnId: 'total', ascending: false),
    )));
  });
}
