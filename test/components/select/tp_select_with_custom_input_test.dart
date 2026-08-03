import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
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

  testWidgets('uses icon buttons for custom cancel and confirm', (tester) async {
    await tester.binding.setSurfaceSize(const Size(360, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    String? confirmed;
    await tester.pumpWidget(
      wrap(
        SizedBox(
          width: 360,
          child: TpSelectWithCustomInput(
            value: '',
            items: const ['a', 'b'],
            hintText: 'Select model',
            cancelLabel: 'Cancel',
            confirmLabel: 'Confirm',
            onChanged: (value) => confirmed = value,
          ),
        ),
      ),
    );

    await tester.tap(find.byIcon(Icons.edit_outlined));
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.close), findsOneWidget);
    expect(find.byIcon(Icons.check), findsOneWidget);
    expect(find.text('Cancel'), findsNothing);
    expect(find.text('Confirm'), findsNothing);

    await tester.enterText(find.byType(TextField), 'custom-model');
    await tester.pump();
    await tester.tap(find.byIcon(Icons.check));
    await tester.pumpAndSettle();

    expect(confirmed, 'custom-model');
  });
}
