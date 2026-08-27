import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
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

  testWidgets('SelectionArea right-click opens the Tp action menu', (
    tester,
  ) async {
    await tester.pumpWidget(
      wrap(
        SelectionArea(
          contextMenuBuilder: buildTpSelectionAreaContextMenu,
          child: const Padding(
            padding: EdgeInsets.all(24),
            child: Text('the quick brown fox jumps over the lazy dog'),
          ),
        ),
      ),
    );

    // Select a word, then right-click inside the selection to surface the menu.
    final text = find.text('the quick brown fox jumps over the lazy dog');
    await tester.longPress(text);
    await tester.pumpAndSettle();

    final center = tester.getCenter(text);
    final gesture = await tester.startGesture(
      center,
      buttons: kSecondaryMouseButton,
    );
    await tester.pump();
    await gesture.up();
    await tester.pumpAndSettle();

    expect(isTpActionMenuOpen, isTrue);
    expect(find.byType(TpActionMenuItem), findsWidgets);

    dismissTpActionMenuIfOpen();
    await tester.pumpAndSettle();
    expect(isTpActionMenuOpen, isFalse);
  });

  testWidgets('TextField with Tp context menu opens the Tp action menu', (
    tester,
  ) async {
    final controller = TextEditingController(text: 'hello world');
    addTearDown(controller.dispose);

    await tester.pumpWidget(
      wrap(
        Padding(
          padding: const EdgeInsets.all(40),
          child: TextField(
            controller: controller,
            contextMenuBuilder: buildTpTextFieldContextMenu,
          ),
        ),
      ),
    );

    final field = find.byType(TextField);
    await tester.tap(field);
    await tester.pump();
    controller.selection = const TextSelection(baseOffset: 0, extentOffset: 5);
    await tester.pump();

    // Right-click inside the selected glyphs on desktop surfaces the menu.
    final topLeft = tester.getTopLeft(field);
    final size = tester.getSize(field);
    final gesture = await tester.startGesture(
      topLeft + Offset(30, size.height / 2),
      buttons: kSecondaryMouseButton,
    );
    await tester.pump();
    await gesture.up();
    await tester.pumpAndSettle();

    expect(isTpActionMenuOpen, isTrue);
    expect(find.byType(TpActionMenuItem), findsWidgets);
  });
}