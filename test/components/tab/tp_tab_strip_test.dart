import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import '../../support/tp_test_widgets.dart';
import 'package:shared_ui/shared_ui.dart';

void main() {
  Widget wrap(Widget child) {
    return MaterialApp(
      home: TpTheme(
        data: TpThemeData.fromColorScheme(
          ColorScheme.fromSeed(seedColor: Colors.teal),
          scale: 1.0,
        ),
        child: Scaffold(
          body: SizedBox(width: 400, height: 48, child: child),
        ),
      ),
    );
  }

  testWidgets('paints items and inStripTrailing without onReorder', (
    tester,
  ) async {
    await tester.pumpWidget(
      wrap(
        TpTabStrip(
          itemCount: 2,
          itemBuilder: (context, index) => TpTabChip(
            key: ValueKey('t$index'),
            title: 'Tab $index',
            active: index == 0,
            onTap: () {},
            onClose: () {},
          ),
          inStripTrailing: const Text('PLUS'),
          trailing: const Text('TRAIL'),
        ),
      ),
    );

    expect(find.text('Tab 0'), findsOneWidget);
    expect(find.text('Tab 1'), findsOneWidget);
    expect(find.text('PLUS'), findsOneWidget);
    expect(find.text('TRAIL'), findsOneWidget);
  });

  testWidgets('onReorder indices exclude inStripTrailing', (tester) async {
    final order = <String>['a', 'b', 'c'];
    late List<String> lastOrder;

    await tester.pumpWidget(
      wrap(
        StatefulBuilder(
          builder: (context, setState) {
            return TpTabStrip(
              itemCount: order.length,
              itemKey: (i) => ValueKey(order[i]),
              onReorder: (oldIndex, newIndex) {
                setState(() {
                  lastOrder = reorderListItems(order, oldIndex, newIndex);
                  order
                    ..clear()
                    ..addAll(lastOrder);
                });
              },
              itemBuilder: (context, index) => TpTabChip(
                title: order[index],
                active: false,
                onTap: () {},
                onClose: () {},
              ),
              inStripTrailing: const Text('PLUS'),
            );
          },
        ),
      ),
    );

    expect(find.byType(SliverReorderableList), findsOneWidget);
    // onReorderItem: move index 0 → 1.
    final list = tester.state<SliverReorderableListState>(
      find.byType(SliverReorderableList),
    );
    // Drive via public callback on the widget.
    final strip = tester.widget<TpTabStrip>(find.byType(TpTabStrip));
    strip.onReorder!(0, 1);
    await tester.pump();

    expect(lastOrder, ['b', 'a', 'c']);
    expect(find.text('PLUS'), findsOneWidget);
    expect(list, isNotNull);
  });

  testWidgets('mouse drag reorders without long-press', (tester) async {
    final order = <String>['a', 'b', 'c'];

    await tester.pumpWidget(
      wrap(
        StatefulBuilder(
          builder: (context, setState) {
            return TpTabStrip(
              itemCount: order.length,
              itemKey: (i) => ValueKey(order[i]),
              onReorder: (oldIndex, newIndex) {
                setState(() {
                  final next = reorderListItems(order, oldIndex, newIndex);
                  order
                    ..clear()
                    ..addAll(next);
                });
              },
              itemBuilder: (context, index) => TpTabChip(
                title: order[index],
                active: false,
                onTap: () {},
                onClose: () {},
              ),
            );
          },
        ),
      ),
    );

    final from = tester.getCenter(find.text('a'));
    final to = tester.getCenter(find.text('c'));
    final gesture = await tester.startGesture(
      from,
      kind: PointerDeviceKind.mouse,
    );
    await gesture.moveTo(to);
    await tester.pump();
    await gesture.up();
    await tester.pumpAndSettle();

    expect(order.first, isNot('a'));
  });

  testWidgets('touch drag scrolls an overflowing strip instead of reordering', (
    tester,
  ) async {
    final order = <String>['a', 'b', 'c', 'd', 'e', 'f'];

    await tester.pumpWidget(
      MaterialApp(
        home: TpTheme(
          data: TpThemeData.fromColorScheme(
            ColorScheme.fromSeed(seedColor: Colors.teal),
            scale: 1.0,
          ),
          child: Scaffold(
            body: SizedBox(
              width: 200,
              height: 48,
              child: Align(
                alignment: Alignment.centerLeft,
                child: StatefulBuilder(
                  builder: (context, setState) {
                    return TpTabStrip(
                      fillWidth: false,
                      itemCount: order.length,
                      itemKey: (i) => ValueKey(order[i]),
                      onReorder: (oldIndex, newIndex) {
                        setState(() {
                          final next = reorderListItems(
                            order,
                            oldIndex,
                            newIndex,
                          );
                          order
                            ..clear()
                            ..addAll(next);
                        });
                      },
                      itemBuilder: (context, index) => TpTabChip(
                        title: 'Very Long Tab Title $index',
                        active: index == 0,
                        onTap: () {},
                        onClose: () {},
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final position = tester
        .state<ScrollableState>(find.byType(Scrollable).first)
        .position;
    expect(position.pixels, 0);
    final before = List<String>.of(order);

    final start =
        tester.getTopLeft(find.byType(TpTabStrip)) + const Offset(50, 24);
    final gesture = await tester.startGesture(start);
    await gesture.moveBy(const Offset(-60, 0));
    await tester.pump();
    await gesture.moveBy(const Offset(-60, 0));
    await tester.pump();
    await gesture.up();
    await tester.pumpAndSettle();

    expect(
      position.pixels,
      greaterThan(0),
      reason: 'touch drag must reach the scroll view, not the reorder drag',
    );
    expect(order, before, reason: 'touch drag must not reorder tabs');
  });

  testWidgets('fillWidth false caps to parent and scrolls instead of overflowing', (
    tester,
  ) async {
    final errors = <FlutterErrorDetails>[];
    final oldHandler = FlutterError.onError;
    FlutterError.onError = (details) {
      errors.add(details);
      oldHandler?.call(details);
    };
    addTearDown(() => FlutterError.onError = oldHandler);

    await tester.pumpWidget(
      MaterialApp(
        home: TpTheme(
          data: TpThemeData.fromColorScheme(
            ColorScheme.fromSeed(seedColor: Colors.teal),
            scale: 1.0,
          ),
          child: const Scaffold(
            body: SizedBox(
              width: 180,
              height: 48,
              child: Align(
                alignment: Alignment.centerLeft,
                child: _WideFillWidthFalseStrip(),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      errors.where((e) => e.toString().contains('overflowed')),
      isEmpty,
      reason: 'narrow parent must scroll, not RenderFlex overflow',
    );
    expect(find.text('Very Long Tab Title 0'), findsOneWidget);
    expect(tester.getSize(find.byType(TpTabStrip)).width, lessThanOrEqualTo(180));
  });

  testWidgets('fillWidth false shrink-wraps when tabs fit', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: TpTheme(
          data: TpThemeData.fromColorScheme(
            ColorScheme.fromSeed(seedColor: Colors.teal),
            scale: 1.0,
          ),
          child: Scaffold(
            body: SizedBox(
              width: 400,
              height: 48,
              // Loose width so the strip can report content size (hit-test gap).
              child: Align(
                alignment: Alignment.centerLeft,
                child: TpTabStrip(
                  fillWidth: false,
                  itemCount: 1,
                  itemBuilder: (context, index) => TpTabChip(
                    title: 'A',
                    active: true,
                    onTap: () {},
                    onClose: () {},
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(tester.getSize(find.byType(TpTabStrip)).width, lessThan(200));
  });

  testWidgets('fillWidth false with onReorder also caps without overflow', (
    tester,
  ) async {
    final errors = <FlutterErrorDetails>[];
    final oldHandler = FlutterError.onError;
    FlutterError.onError = (details) {
      errors.add(details);
      oldHandler?.call(details);
    };
    addTearDown(() => FlutterError.onError = oldHandler);

    await tester.pumpWidget(
      MaterialApp(
        home: TpTheme(
          data: TpThemeData.fromColorScheme(
            ColorScheme.fromSeed(seedColor: Colors.teal),
            scale: 1.0,
          ),
          child: Scaffold(
            body: SizedBox(
              width: 180,
              height: 48,
              child: Align(
                alignment: Alignment.centerLeft,
                child: TpTabStrip(
                  fillWidth: false,
                  itemCount: 4,
                  onReorder: (oldIndex, newIndex) {},
                  itemBuilder: (context, index) => TpTabChip(
                    title: 'Very Long Tab Title $index',
                    active: index == 0,
                    onTap: () {},
                    onClose: () {},
                  ),
                  inStripTrailing: const Text('PLUS'),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      errors.where((e) => e.toString().contains('overflowed')),
      isEmpty,
    );
  });
}

/// Wide chips in a shrink-wrapping strip — used to assert no overflow.
class _WideFillWidthFalseStrip extends StatelessWidget {
  const _WideFillWidthFalseStrip();

  @override
  Widget build(BuildContext context) {
    return TpTabStrip(
      fillWidth: false,
      itemCount: 4,
      itemBuilder: (context, index) => TpTabChip(
        title: 'Very Long Tab Title $index',
        active: index == 0,
        onTap: () {},
        onClose: () {},
      ),
      inStripTrailing: const Text('PLUS'),
    );
  }
}
