import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../support/tp_test_widgets.dart';
import 'package:shared_ui/shared_ui.dart';

void main() {
  Widget wrap(Widget child) {
    return MaterialApp(
      home: TpTheme(
        data: TpThemeData.fromColorScheme(
          ColorScheme.fromSeed(seedColor: Colors.orange),
          scale: 1.0,
        ),
        child: Scaffold(body: child),
      ),
    );
  }

  testWidgets('TpActionMenuItem invokes onTap', (tester) async {
    var tapped = false;
    await tester.pumpWidget(
      wrap(
        TpActionMenuPanel(
          children: [
            TpActionMenuItem(
              icon: Icons.check,
              label: 'Do it',
              onTap: () => tapped = true,
            ),
          ],
        ),
      ),
    );
    await tester.tap(find.text('Do it'));
    await tester.pump();
    expect(tapped, isTrue);
  });

  testWidgets('Escape dismisses open action menu', (tester) async {
    await tester.pumpWidget(
      wrap(
        Builder(
          builder: (context) {
            return Center(
              child: ElevatedButton(
                onPressed: () {
                  showTpActionMenuFromSpecs<String>(
                    context: context,
                    globalPosition: const Offset(80, 80),
                    specs: [
                      TpActionMenuSpec.item(
                        value: 'a',
                        label: 'Item A',
                        icon: Icons.check,
                      ),
                    ],
                  );
                },
                child: const Text('open'),
              ),
            );
          },
        ),
      ),
    );

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    expect(find.text('Item A'), findsOneWidget);
    expect(isTpActionMenuOpen, isTrue);

    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();
    expect(find.text('Item A'), findsNothing);
    expect(isTpActionMenuOpen, isFalse);
  });

  testWidgets('dismiss before first frame does not orphan the overlay entry', (
    tester,
  ) async {
    await tester.pumpWidget(
      wrap(
        Builder(
          builder: (context) {
            return Center(
              child: ElevatedButton(
                onPressed: () {
                  // Same-frame insert → dismiss: a second menu opening while the
                  // first entry has not built yet must remove the first entry
                  // (regression: removeEntry gated on entry.mounted left an
                  // orphan that never dismissed).
                  showTpActionMenuFromSpecs<String>(
                    context: context,
                    globalPosition: const Offset(80, 80),
                    specs: [
                      TpActionMenuSpec.item(
                        value: 'a',
                        label: 'Item A',
                        icon: Icons.check,
                      ),
                    ],
                  );
                  dismissTpActionMenuIfOpen();
                },
                child: const Text('open'),
              ),
            );
          },
        ),
      ),
    );

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    expect(find.text('Item A'), findsNothing);
    expect(isTpActionMenuOpen, isFalse);
  });

  testWidgets(
    'second menu in same frame replaces the first (nested deadline fire)',
    (tester) async {
      await tester.pumpWidget(
        wrap(
          Builder(
            builder: (context) {
              return Center(
                child: ElevatedButton(
                  onPressed: () {
                    // Two nested onSecondaryTapDown recognizers can both fire when
                    // the button is held past kPressTimeout; the second overlay
                    // call must close the first and leave exactly one menu.
                    showTpActionMenuFromSpecs<String>(
                      context: context,
                      globalPosition: const Offset(80, 80),
                      specs: [
                        TpActionMenuSpec.item(
                          value: 'a',
                          label: 'Item A',
                          icon: Icons.check,
                        ),
                      ],
                    );
                    showTpActionMenuFromSpecs<String>(
                      context: context,
                      globalPosition: const Offset(200, 80),
                      specs: [
                        TpActionMenuSpec.item(
                          value: 'b',
                          label: 'Item B',
                          icon: Icons.check,
                        ),
                      ],
                    );
                  },
                  child: const Text('open'),
                ),
              );
            },
          ),
        ),
      );

      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      expect(find.text('Item A'), findsNothing);
      expect(find.text('Item B'), findsOneWidget);
      expect(isTpActionMenuOpen, isTrue);
    },
  );

  group('submenu', () {
    List<TpActionMenuSpec> specs({required bool withSubmenu}) => [
      TpActionMenuSpec.item(value: 'plain', label: 'Plain', icon: Icons.star),
      if (withSubmenu)
        TpActionMenuSpec.submenu(
          value: 'branch',
          label: 'Branch',
          icon: Icons.folder,
          children: [
            TpActionMenuSpec.item(
              value: 'leaf',
              label: 'Leaf',
              icon: Icons.eco,
            ),
          ],
        ),
    ];

    Widget wrapWithButton(
      List<TpActionMenuSpec> specs, {
      void Function(Object?)? onSelected,
    }) => wrap(
      TpActionMenuButton(specs: specs, onSelected: onSelected ?? (_) {}),
    );

    Future<void> pumpHost(
      WidgetTester tester,
      List<TpActionMenuSpec> specs, {
      void Function(Object?)? onSelected,
    }) async {
      await tester.pumpWidget(wrapWithButton(specs, onSelected: onSelected));
      await tester.tap(find.byIcon(Icons.more_horiz));
      await tester.pumpAndSettle();
    }

    testWidgets('tap opens submenu and shows child', (tester) async {
      var onOpened = 0;
      await pumpHost(tester, [
        TpActionMenuSpec.submenu(
          value: 'branch',
          label: 'Branch',
          icon: Icons.folder,
          onOpen: () => onOpened++,
          children: [
            TpActionMenuSpec.item(
              value: 'leaf',
              label: 'Leaf',
              icon: Icons.eco,
            ),
          ],
        ),
      ]);
      await tester.tap(find.text('Branch'));
      await tester.pumpAndSettle();
      expect(find.text('Leaf'), findsOneWidget);
      expect(onOpened, 1);
    });

    testWidgets('selecting a leaf fires onSelect and closes everything', (
      tester,
    ) async {
      final picked = <Object?>[];
      await pumpHost(tester, specs(withSubmenu: true), onSelected: picked.add);
      await tester.tap(find.text('Branch'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Leaf'));
      await tester.pumpAndSettle();
      expect(picked, ['leaf']);
      expect(find.text('Leaf'), findsNothing);
      expect(find.text('Plain'), findsNothing);
    });

    testWidgets('opening a sibling submenu closes the previously open branch', (
      tester,
    ) async {
      TpActionMenuSpec branch(String label) => TpActionMenuSpec.submenu(
        value: label,
        label: label,
        icon: Icons.folder,
        children: [
          TpActionMenuSpec.item(
            value: '$label-child',
            label: '$label-child',
            icon: Icons.eco,
          ),
        ],
      );
      await pumpHost(tester, [branch('A'), branch('B')]);
      await tester.tap(find.text('A'));
      await tester.pumpAndSettle();
      expect(find.text('A-child'), findsOneWidget);
      await tester.tap(find.text('B'));
      await tester.pumpAndSettle();
      expect(find.text('A-child'), findsNothing);
      expect(find.text('B-child'), findsOneWidget);
    });

    testWidgets('hover intent opens after delay', (tester) async {
      final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
      await gesture.addPointer(location: Offset.zero);
      addTearDown(gesture.removePointer);
      await pumpHost(tester, specs(withSubmenu: true));
      await tester.tap(find.text('Branch'));
      await tester.pumpAndSettle();
      // close again to test hover path from scratch
      await tester.tap(find.text('Branch'));
      await tester.pumpAndSettle();
      await gesture.moveTo(tester.getCenter(find.text('Branch')));
      await tester.pump(const Duration(milliseconds: 40));
      expect(find.text('Leaf'), findsNothing);
      await tester.pump(const Duration(milliseconds: 200));
      await tester.pumpAndSettle();
      expect(find.text('Leaf'), findsOneWidget);
    });
  });
}
