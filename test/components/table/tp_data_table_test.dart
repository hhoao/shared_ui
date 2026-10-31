import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_ui/shared_ui.dart';

final _columns = <TpTableColumn<String>>[
  TpTableColumn<String>(
    id: 'name',
    label: 'Name',
    locked: true,
    hideable: false,
    draggable: false,
    cellBuilder: (context, row) => Text(row),
  ),
  TpTableColumn<String>(
    id: 'value',
    label: 'Value',
    width: 100,
    sortValue: (row) => row.length,
    cellBuilder: (context, row) => Text('${row.length}'),
  ),
  TpTableColumn<String>(
    id: 'extra',
    label: 'Extra',
    width: 100,
    cellBuilder: (context, row) => const Text('extra'),
  ),
];

class _Host extends StatefulWidget {
  const _Host({this.rows = _Host._rows, this.height});

  static const _rows = ['alpha', 'four'];

  final List<String> rows;
  final double? height;

  @override
  State<_Host> createState() => _HostState();
}

class _HostState extends State<_Host> {
  TpTableState state = const TpTableState(
    sort: TpTableSort(columnId: 'value', ascending: false),
  );

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: TpTheme(
        data: TpThemeData.fromColorScheme(
          ColorScheme.fromSeed(seedColor: Colors.indigo),
          scale: 1,
        ),
        child: Scaffold(
          body: TpDataTable<String>(
            columns: _columns,
            rows: widget.rows,
            rowKey: (row) => row,
            height: widget.height,
            state: state,
            defaultSort: const TpTableSort(columnId: 'value', ascending: false),
            toolbar: TpTableColumnMenu<String>(
              columns: _columns,
              state: state,
              onChanged: (next) => setState(() => state = next),
              labels: const TpDataTableLabels(),
            ),
            labels: const TpDataTableLabels(
              sortAscending: 'Sort ascending localized',
              sortDescending: 'Sort descending localized',
            ),
            onStateChanged: (next) => setState(() => state = next),
          ),
        ),
      ),
    );
  }
}

void main() {
  test('layout fills the remaining width after a manual column width', () {
    final columns = [
      for (final id in ['a', 'b', 'c'])
        TpTableColumn<String>(
          id: id,
          label: id,
          width: 100,
          cellBuilder: (context, row) => Text(row),
        ),
    ];

    final fitted = TpTableLayout.resolve(
      columns: columns,
      availableWidth: 600,
      minTableWidth: 300,
      widthOverrides: const {'a': 100},
    );
    expect(fitted.totalWidth, 600);
    expect(fitted.widthOf('c'), 400);

    final notFitted = TpTableLayout.resolve(
      columns: columns,
      availableWidth: 600,
      minTableWidth: 300,
      widthOverrides: const {'a': 100},
      fit: false,
    );
    expect(notFitted.totalWidth, 300);

    final allManual = TpTableLayout.resolve(
      columns: columns,
      availableWidth: 600,
      minTableWidth: 300,
      widthOverrides: const {'a': 100, 'b': 100, 'c': 100},
    );
    expect(allManual.totalWidth, 600);
  });

  testWidgets('renders headers and rows', (tester) async {
    await tester.pumpWidget(const _Host());
    await tester.pumpAndSettle();

    expect(find.text('Name'), findsOneWidget);
    expect(find.text('Value'), findsOneWidget);
    expect(find.text('Extra'), findsOneWidget);
    expect(find.text('alpha'), findsOneWidget);
    expect(find.text('four'), findsOneWidget);
    expect(find.byKey(const ValueKey('resize-extra')), findsNothing);
  });

  testWidgets('uses rowKey for every rendered table row', (tester) async {
    await tester.pumpWidget(const _Host());
    await tester.pumpAndSettle();

    final keys = tester
        .widgetList<TpTableRow<String>>(find.byType(TpTableRow<String>))
        .map((row) => row.key)
        .toList(growable: false);
    expect(keys.where((key) => key == const ValueKey('alpha')), hasLength(2));
    expect(keys.where((key) => key == const ValueKey('four')), hasLength(2));
  });

  testWidgets('sortable header uses injected next-direction labels', (
    tester,
  ) async {
    await tester.pumpWidget(const _Host());
    await tester.pumpAndSettle();

    expect(find.byTooltip('Sort ascending localized'), findsOneWidget);
    await tester.tap(find.byTooltip('Sort ascending localized'));
    await tester.pumpAndSettle();
    expect(find.byTooltip('Sort descending localized'), findsOneWidget);
  });

  testWidgets(
    'clicking a sortable header cycles descending, ascending, default',
    (tester) async {
      await tester.pumpWidget(const _Host());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Value'));
      await tester.pumpAndSettle();
      expect(find.byIcon(Icons.arrow_upward), findsOneWidget);

      await tester.tap(find.text('Value'));
      await tester.pumpAndSettle();
      expect(find.byIcon(Icons.arrow_downward), findsOneWidget);
    },
  );

  testWidgets('dragging the header edge resizes the column', (tester) async {
    await tester.pumpWidget(const _Host());
    await tester.pumpAndSettle();

    await tester.drag(
      find.byKey(const ValueKey('resize-value')),
      const Offset(40, 0),
    );
    await tester.pumpAndSettle();

    final host = tester.state<_HostState>(find.byType(_Host));
    expect(host.state.widths['value'], 120);
    expect(host.state.widths['extra'], 80);
    expect(host.state.widths.containsKey('name'), isTrue);
  });

  testWidgets('double tapping the resize handle resets the width', (
    tester,
  ) async {
    await tester.pumpWidget(const _Host());
    await tester.pumpAndSettle();

    final handle = find.byKey(const ValueKey('resize-value'));
    await tester.drag(handle, const Offset(40, 0));
    await tester.pumpAndSettle();

    final host = tester.state<_HostState>(find.byType(_Host));
    expect(host.state.widths['value'], greaterThan(100));

    await tester.tap(handle);
    await tester.pump(const Duration(milliseconds: 50));
    await tester.tap(handle);
    await tester.pumpAndSettle();

    expect(host.state.widths.containsKey('value'), isFalse);
  });

  testWidgets('bounded height keeps the header and virtualizes rows', (
    tester,
  ) async {
    final rows = [for (var index = 0; index < 100; index++) 'row$index'];
    await tester.pumpWidget(_Host(rows: rows, height: 200));
    await tester.pumpAndSettle();

    expect(find.text('Name'), findsOneWidget);
    expect(find.text('row0'), findsOneWidget);
    expect(find.text('row99'), findsNothing);

    await tester.drag(find.byType(ListView).last, const Offset(0, -400));
    await tester.pumpAndSettle();

    expect(find.text('Name'), findsOneWidget);
    expect(find.text('row0'), findsNothing);
  });

  testWidgets('column menu hides and restores a column', (tester) async {
    await tester.pumpWidget(const _Host());
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.view_column_outlined));
    await tester.pumpAndSettle();
    await tester.tap(
      find.descendant(
        of: find.byType(TpActionMenuPanel),
        matching: find.text('Extra'),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.descendant(
        of: find.byType(TpTableHeader<String>),
        matching: find.text('Extra'),
      ),
      findsNothing,
    );

    await tester.tap(find.text('Reset to default'));
    await tester.pumpAndSettle();

    expect(
      find.descendant(
        of: find.byType(TpTableHeader<String>),
        matching: find.text('Extra'),
      ),
      findsOneWidget,
    );
  });

  testWidgets('empty rows render the empty slot', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: TpTheme(
          data: TpThemeData.fromColorScheme(
            ColorScheme.fromSeed(seedColor: Colors.indigo),
            scale: 1,
          ),
          child: Scaffold(
            body: TpDataTable<String>(
              columns: _columns,
              rows: const [],
              rowKey: _rowKey,
              state: const TpTableState(),
              emptyState: const Text('empty'),
              onStateChanged: _ignoreState,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('empty'), findsOneWidget);
  });
}

String _rowKey(String row) => row;

void _ignoreState(TpTableState state) {}
