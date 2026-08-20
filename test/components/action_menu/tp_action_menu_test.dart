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
}
