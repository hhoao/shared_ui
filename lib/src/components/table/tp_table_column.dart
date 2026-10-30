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
    this.alignment = Alignment.centerLeft,
    this.sortValue,
    this.hideable = true,
    this.locked = false,
    this.draggable = true,
    this.groupStart = false,
  });

  final String id;
  final String label;
  final Widget Function(BuildContext context, T row) cellBuilder;
  final double? width;
  final int flex;
  final double minWidth;
  final Alignment alignment;
  final Comparable? Function(T row)? sortValue;
  final bool hideable;
  final bool locked;
  final bool draggable;
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
  }) {
    final target = availableWidth < minTableWidth
        ? minTableWidth
        : availableWidth;
    final fixedWidth = columns
        .where((column) => column.width != null)
        .fold<double>(0, (sum, column) => sum + column.width!);
    final flexColumns = columns
        .where((column) => column.width == null)
        .toList(growable: false);
    final flexTotal = flexColumns.fold<int>(
      0,
      (sum, column) => sum + column.flex,
    );

    final widths = <String, double>{};
    for (final column in columns) {
      final fixed = column.width;
      if (fixed != null) {
        widths[column.id] = fixed;
        continue;
      }
      final share = (target - fixedWidth) * column.flex / flexTotal;
      widths[column.id] = share < column.minWidth ? column.minWidth : share;
    }

    final total = widths.values.fold<double>(0, (sum, width) => sum + width);
    return TpTableLayout(widths: widths, totalWidth: total);
  }
}

EdgeInsets tpTableCellPadding({
  required bool first,
  required bool last,
  required bool groupStart,
}) {
  final left = first ? 16.0 : (groupStart ? 40.0 : 24.0);
  final right = last ? 16.0 : 24.0;
  return EdgeInsets.only(left: left, right: right);
}
