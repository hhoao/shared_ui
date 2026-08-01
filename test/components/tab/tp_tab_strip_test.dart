import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
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

    // Drive reorder via the strip's ReorderableListView callback path:
    // find the list and invoke onReorder directly for stable unit coverage.
    final list = tester.widget<ReorderableListView>(
      find.byType(ReorderableListView),
    );
    list.onReorder!(0, 2);
    await tester.pump();

    expect(lastOrder, ['b', 'a', 'c']);
    expect(find.text('PLUS'), findsOneWidget);
  });
}
