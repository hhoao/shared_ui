import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_ui/shared_ui.dart';

final _columns = <TpTableColumn<String>>[
  TpTableColumn<String>(
    id: 'name',
    label: 'Name',
    width: 120,
    locked: true,
    hideable: false,
    draggable: false,
    cellBuilder: (context, row) => Text(row),
  ),
  TpTableColumn<String>(
    id: 'value',
    label: 'Value',
    width: 120,
    cellBuilder: (context, row) => const Text('value'),
  ),
  TpTableColumn<String>(
    id: 'extra',
    label: 'Extra',
    width: 120,
    cellBuilder: (context, row) => const Text('extra'),
  ),
];

class _Host extends StatefulWidget {
  const _Host();

  @override
  State<_Host> createState() => _HostState();
}

class _HostState extends State<_Host> {
  TpTableState state = const TpTableState();

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
            rows: const ['row'],
            rowKey: (row) => row,
            state: state,
            onStateChanged: (next) => setState(() => state = next),
          ),
        ),
      ),
    );
  }
}

Positioned _insertionIndicator(WidgetTester tester) {
  return tester
      .widgetList<Positioned>(find.byType(Positioned))
      .singleWhere((positioned) => positioned.width == 2);
}

void main() {
  testWidgets('hovering a draggable header shows its drag handle', (
    tester,
  ) async {
    await tester.pumpWidget(const _Host());
    await tester.pumpAndSettle();

    final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await mouse.addPointer(location: tester.getCenter(find.text('Value')));
    await tester.pump();

    expect(find.byIcon(Icons.drag_indicator), findsOneWidget);
    await mouse.removePointer();
  });

  testWidgets('hovering a locked header shows no drag handle', (tester) async {
    await tester.pumpWidget(const _Host());
    await tester.pumpAndSettle();

    final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await mouse.addPointer(location: tester.getCenter(find.text('Name')));
    await tester.pump();

    expect(find.byIcon(Icons.drag_indicator), findsNothing);
    await mouse.removePointer();
  });

  testWidgets('dropping a header on a locked header keeps the order', (
    tester,
  ) async {
    await tester.pumpWidget(const _Host());
    await tester.pumpAndSettle();

    final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await mouse.addPointer(location: tester.getCenter(find.text('Value')));
    await tester.pump();

    final handle = find.byIcon(Icons.drag_indicator);
    final gesture = await tester.startGesture(
      tester.getCenter(handle),
      kind: PointerDeviceKind.mouse,
    );
    await gesture.moveTo(tester.getCenter(find.text('Name')));
    await tester.pump();
    await gesture.up();
    await tester.pumpAndSettle();

    final hostState = tester.state<_HostState>(find.byType(_Host));
    expect(hostState.state.order, isEmpty);
  });

  testWidgets('rightward drag renders the insertion indicator on the right', (
    tester,
  ) async {
    await tester.pumpWidget(const _Host());
    await tester.pumpAndSettle();

    final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await mouse.addPointer(location: tester.getCenter(find.text('Value')));
    await tester.pump();
    final gesture = await tester.startGesture(
      tester.getCenter(find.byIcon(Icons.drag_indicator)),
      kind: PointerDeviceKind.mouse,
    );
    await gesture.moveTo(tester.getCenter(find.text('Extra')));
    await tester.pump();

    final indicator = _insertionIndicator(tester);
    expect(indicator.left, isNull);
    expect(indicator.right, 0);

    await gesture.up();
    await mouse.removePointer();
  });

  testWidgets('leftward drag renders the insertion indicator on the left', (
    tester,
  ) async {
    await tester.pumpWidget(const _Host());
    await tester.pumpAndSettle();

    final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await mouse.addPointer(location: tester.getCenter(find.text('Extra')));
    await tester.pump();
    final gesture = await tester.startGesture(
      tester.getCenter(find.byIcon(Icons.drag_indicator)),
      kind: PointerDeviceKind.mouse,
    );
    await gesture.moveTo(tester.getCenter(find.text('Value')));
    await tester.pump();

    final indicator = _insertionIndicator(tester);
    expect(indicator.left, 0);
    expect(indicator.right, isNull);

    await gesture.up();
    await mouse.removePointer();
  });

  testWidgets('dragging a header onto another reorders columns', (
    tester,
  ) async {
    await tester.pumpWidget(const _Host());
    await tester.pumpAndSettle();

    final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await mouse.addPointer(location: tester.getCenter(find.text('Value')));
    await tester.pump();

    final handle = find.byIcon(Icons.drag_indicator);
    final gesture = await tester.startGesture(
      tester.getCenter(handle),
      kind: PointerDeviceKind.mouse,
    );
    await gesture.moveTo(tester.getCenter(find.text('Extra')));
    await tester.pump();

    // The hover pointer leaving the Value cell must not hide the handle while
    // the drag is in flight.
    await mouse.moveTo(tester.getCenter(find.text('Name')));
    await tester.pump();
    expect(find.byIcon(Icons.drag_indicator), findsOneWidget);

    await gesture.up();
    await tester.pumpAndSettle();

    final hostState = tester.state<_HostState>(find.byType(_Host));
    expect(hostState.state.order, ['name', 'extra', 'value']);
  });
}
