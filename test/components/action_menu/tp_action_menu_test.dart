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
}
