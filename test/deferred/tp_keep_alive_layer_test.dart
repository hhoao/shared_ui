import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_ui/shared_ui.dart';

void main() {
  testWidgets('TpKeepAliveLayer skips child layout when inactive', (
    tester,
  ) async {
    var layouts = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 100,
            height: 100,
            child: TpKeepAliveLayer(
              active: false,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  layouts++;
                  return const SizedBox.expand();
                },
              ),
            ),
          ),
        ),
      ),
    );

    expect(layouts, 0);
  });

  testWidgets('TpKeepAliveLayer lays out child when active', (tester) async {
    var layouts = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 100,
            height: 100,
            child: TpKeepAliveLayer(
              active: true,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  layouts++;
                  return const SizedBox.expand();
                },
              ),
            ),
          ),
        ),
      ),
    );

    expect(layouts, greaterThan(0));
  });

  testWidgets('TpKeepAliveLayer layouts when becoming active', (tester) async {
    var layouts = 0;
    var active = false;

    await tester.pumpWidget(
      MaterialApp(
        home: StatefulBuilder(
          builder: (context, setState) {
            return Scaffold(
              body: Column(
                children: [
                  TextButton(
                    onPressed: () => setState(() => active = true),
                    child: const Text('activate'),
                  ),
                  SizedBox(
                    width: 100,
                    height: 100,
                    child: TpKeepAliveLayer(
                      active: active,
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          layouts++;
                          return const SizedBox.expand();
                        },
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );

    expect(layouts, 0);
    await tester.tap(find.text('activate'));
    await tester.pump();
    expect(layouts, greaterThan(0));
  });
}
