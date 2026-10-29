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
  const _Host({this.rows = const ['alpha', 'four']});

  final List<String> rows;

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
            state: state,
            defaultSort: const TpTableSort(
              columnId: 'value',
              ascending: false,
            ),
            toolbar: TpTableColumnMenu<String>(
              columns: _columns,
              state: state,
              onChanged: (next) => setState(() => state = next),
              labels: const TpDataTableLabels(),
            ),
            onStateChanged: (next) => setState(() => state = next),
          ),
        ),
      ),
    );
  }
}

void main() {
  testWidgets('renders headers and rows', (tester) async {
    await tester.pumpWidget(const _Host());
    await tester.pumpAndSettle();

    expect(find.text('Name'), findsOneWidget);
    expect(find.text('Value'), findsOneWidget);
    expect(find.text('Extra'), findsOneWidget);
    expect(find.text('alpha'), findsOneWidget);
    expect(find.text('four'), findsOneWidget);
  });

  testWidgets('clicking a sortable header cycles descending, ascending, default', (
    tester,
  ) async {
    await tester.pumpWidget(const _Host());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Value'));
    await tester.pumpAndSettle();
    expect(find.byIcon(Icons.arrow_upward), findsOneWidget);

    await tester.tap(find.text('Value'));
    await tester.pumpAndSettle();
    expect(find.byIcon(Icons.arrow_downward), findsOneWidget);
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
