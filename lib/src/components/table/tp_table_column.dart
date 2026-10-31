import 'package:flutter/material.dart';

/// One column in a [TpDataTable].
///
/// [width] wins over [flex]. Flex columns share the remaining width after
/// fixed columns, never shrinking below [minWidth].
@immutable
class TpTableColumn<T> {
  const TpTableColumn({
    required this.id,
    required this.label,
    required this.cellBuilder,
    this.width,
    this.flex = 1,
    this.minWidth = 80,
    this.maxWidth = 640,
    this.alignment = Alignment.centerLeft,
    this.sortValue,
    this.hideable = true,
    this.locked = false,
    this.draggable = true,
    this.resizable = true,
    this.groupStart = false,
  });

  final String id;
  final String label;
  final Widget Function(BuildContext context, T row) cellBuilder;
  final double? width;
  final int flex;
  final double minWidth;
  final double maxWidth;
  final Alignment alignment;
  final Comparable? Function(T row)? sortValue;
  final bool hideable;
  final bool locked;
  final bool draggable;
  final bool resizable;
  final bool groupStart;
}

/// Resolved column widths for one table layout pass.
@immutable
class TpTableLayout {
  const TpTableLayout({required this.widths, required this.totalWidth});

  final Map<String, double> widths;
  final double totalWidth;

  double widthOf(String id) => widths[id] ?? 0;

  static TpTableLayout resolve<T>({
    required List<TpTableColumn<T>> columns,
    required double availableWidth,
    required double minTableWidth,
    Map<String, double> widthOverrides = const {},
    bool fit = true,
  }) {
    final target = availableWidth < minTableWidth
        ? minTableWidth
        : availableWidth;
    final fixedWidth = columns
        .where(
          (column) =>
              column.width != null || widthOverrides.containsKey(column.id),
        )
        .fold<double>(
          0,
          (sum, column) => sum + (widthOverrides[column.id] ?? column.width!),
        );
    final flexColumns = columns
        .where(
          (column) =>
              column.width == null && !widthOverrides.containsKey(column.id),
        )
        .toList(growable: false);
    final flexTotal = flexColumns.fold<int>(
      0,
      (sum, column) => sum + column.flex,
    );

    final widths = <String, double>{};
    for (final column in columns) {
      final override = widthOverrides[column.id];
      if (override != null) {
        widths[column.id] = override
            .clamp(column.minWidth, column.maxWidth)
            .toDouble();
        continue;
      }
      final fixed = column.width;
      if (fixed != null) {
        widths[column.id] = fixed
            .clamp(column.minWidth, column.maxWidth)
            .toDouble();
        continue;
      }
      final share = (target - fixedWidth) * column.flex / flexTotal;
      widths[column.id] = share
          .clamp(column.minWidth, column.maxWidth)
          .toDouble();
    }

    var total = widths.values.fold<double>(0, (sum, width) => sum + width);
    if (fit && total < target) {
      var remaining = target - total;
      for (
        var index = columns.length - 1;
        index >= 0 && remaining > 0;
        index--
      ) {
        final column = columns[index];
        if (widthOverrides.containsKey(column.id)) continue;
        final room = column.maxWidth - widths[column.id]!;
        if (room <= 0) continue;
        final add = room < remaining ? room : remaining;
        widths[column.id] = widths[column.id]! + add;
        remaining -= add;
      }
      total = widths.values.fold<double>(0, (sum, width) => sum + width);
    }

    if (fit && total > target) {
      var excess = total - target;
      // Shrink user-resized columns last: their explicit width wins until the
      // other columns reach their minimums.
      for (final overriddenPass in [false, true]) {
        if (excess <= 0) break;
        final candidates = columns
            .where(
              (column) =>
                  widthOverrides.containsKey(column.id) == overriddenPass &&
                  widths[column.id]! > column.minWidth,
            )
            .toList(growable: false);
        final capacity = candidates.fold<double>(
          0,
          (sum, column) => sum + (widths[column.id]! - column.minWidth),
        );
        if (capacity <= 0) continue;
        final take = excess < capacity ? excess : capacity;
        for (final column in candidates) {
          final room = widths[column.id]! - column.minWidth;
          widths[column.id] = widths[column.id]! - take * room / capacity;
        }
        excess -= take;
      }
    }

    final fittedTotal = widths.values.fold<double>(
      0,
      (sum, width) => sum + width,
    );
    return TpTableLayout(widths: widths, totalWidth: fittedTotal);
  }
}

EdgeInsetsDirectional tpTableCellPadding({
  required bool first,
  required bool last,
  required bool groupStart,
}) {
  final start = first ? 16.0 : (groupStart ? 40.0 : 24.0);
  final end = last ? 16.0 : 24.0;
  return EdgeInsetsDirectional.only(start: start, end: end);
}
