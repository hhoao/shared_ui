import 'package:flutter/foundation.dart';

import 'tp_table_column.dart';

@immutable
class TpTableSort {
  const TpTableSort({required this.columnId, required this.ascending});

  final String columnId;
  final bool ascending;

  @override
  bool operator ==(Object other) {
    return other is TpTableSort &&
        other.columnId == columnId &&
        other.ascending == ascending;
  }

  @override
  int get hashCode => Object.hash(columnId, ascending);
}

@immutable
class TpTableState {
  const TpTableState({
    this.order = const [],
    this.hidden = const {},
    this.sort,
  });

  final List<String> order;
  final Set<String> hidden;
  final TpTableSort? sort;

  @override
  bool operator ==(Object other) {
    return other is TpTableState &&
        listEquals(other.order, order) &&
        setEquals(other.hidden, hidden) &&
        other.sort == sort;
  }

  @override
  int get hashCode {
    return Object.hash(
      Object.hashAll(order),
      Object.hashAllUnordered(hidden),
      sort,
    );
  }

  TpTableState copyWith({
    List<String>? order,
    Set<String>? hidden,
    TpTableSort? sort,
    bool clearSort = false,
  }) {
    return TpTableState(
      order: order ?? this.order,
      hidden: hidden ?? this.hidden,
      sort: clearSort ? null : (sort ?? this.sort),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'order': order,
      'hidden': hidden.toList(growable: false),
      if (sort != null)
        'sort': {
          'column': sort!.columnId,
          'ascending': sort!.ascending,
        },
    };
  }

  factory TpTableState.fromJson(Map<String, dynamic> json) {
    final order = <String>[];
    final rawOrder = json['order'];
    if (rawOrder is List) {
      for (final value in rawOrder) {
        if (value is String && value.isNotEmpty && !order.contains(value)) {
          order.add(value);
        }
      }
    }

    final hidden = <String>{};
    final rawHidden = json['hidden'];
    if (rawHidden is List) {
      for (final value in rawHidden) {
        if (value is String && value.isNotEmpty) hidden.add(value);
      }
    }

    TpTableSort? sort;
    final rawSort = json['sort'];
    if (rawSort is Map) {
      final column = rawSort['column'];
      final ascending = rawSort['ascending'];
      if (column is String && column.isNotEmpty && ascending is bool) {
        sort = TpTableSort(columnId: column, ascending: ascending);
      }
    }

    return TpTableState(order: order, hidden: hidden, sort: sort);
  }
}

/// All columns in display order: locked first, then persisted order, then any
/// columns missing from the persisted order at their default position.
List<TpTableColumn<T>> orderedTableColumns<T>(
  List<TpTableColumn<T>> columns,
  TpTableState state,
) {
  final byId = {for (final column in columns) column.id: column};
  final ordered = <TpTableColumn<T>>[];
  final seen = <String>{};

  for (final column in columns.where((column) => column.locked)) {
    if (seen.add(column.id)) ordered.add(column);
  }

  for (final id in state.order) {
    final column = byId[id];
    if (column == null || column.locked || !seen.add(column.id)) continue;
    ordered.add(column);
  }

  for (var index = 0; index < columns.length; index++) {
    final column = columns[index];
    if (column.locked || seen.contains(column.id)) continue;

    var insertAt = ordered.length;
    for (var nextIndex = index + 1; nextIndex < columns.length; nextIndex++) {
      final next = columns[nextIndex];
      final at = ordered.indexWhere((item) => item.id == next.id);
      if (at >= 0) {
        insertAt = at;
        break;
      }
    }
    ordered.insert(insertAt, column);
    seen.add(column.id);
  }

  return ordered;
}

List<TpTableColumn<T>> visibleTableColumns<T>(
  List<TpTableColumn<T>> columns,
  TpTableState state,
) {
  return orderedTableColumns(columns, state)
      .where((column) => column.locked || !state.hidden.contains(column.id))
      .toList(growable: false);
}

/// Moves [draggedId] into [targetId]'s slot.
///
/// For `['a','b','c']`, dragging `a` onto `c` yields `['b','c','a']`;
/// dragging `c` onto `a` yields `['c','a','b']`.
List<String> reorderTableColumnIds(
  List<String> ids,
  String draggedId,
  String targetId,
) {
  final next = List<String>.of(ids);
  final from = next.indexOf(draggedId);
  final to = next.indexOf(targetId);
  if (from < 0 || to < 0 || from == to) return next;
  next.removeAt(from);
  next.insert(to.clamp(0, next.length), draggedId);
  return next;
}
