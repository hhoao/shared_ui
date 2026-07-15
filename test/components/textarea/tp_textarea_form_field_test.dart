import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_ui/shared_ui.dart';

void main() {
  Widget wrap(Widget child) {
    return MaterialApp(
      home: Scaffold(
        body: TpTheme(
          data: TpThemeData.fallback(),
          child: child,
        ),
      ),
    );
  }

  testWidgets('validate fails when short and value maps after valid input', (
    tester,
  ) async {
    final formKey = GlobalKey<TpFormState>();

    await tester.pumpWidget(
      wrap(
        TpForm(
          key: formKey,
          child: Column(
            children: [
              TpTextareaFormField(
                id: 'bio',
                label: const Text('Bio'),
                validator: (v) =>
                    (v == null || v.trim().length < 5) ? 'too short' : null,
              ),
              Builder(
                builder: (context) {
                  return TextButton(
                    onPressed: () {
                      formKey.currentState!.saveAndValidate();
                    },
                    child: const Text('Submit'),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Submit'));
    await tester.pumpAndSettle();
    expect(find.text('too short'), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'hello world');
    await tester.pumpAndSettle();

    await tester.tap(find.text('Submit'));
    await tester.pumpAndSettle();
    expect(find.text('too short'), findsNothing);
    expect(formKey.currentState!.value['bio'], 'hello world');
  });

  testWidgets('setFieldValue and reset sync visible TextField text', (
    tester,
  ) async {
    final formKey = GlobalKey<TpFormState>();

    await tester.pumpWidget(
      wrap(
        TpForm(
          key: formKey,
          child: TpTextareaFormField(
            id: 'bio',
            initialValue: 'seed',
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      tester.widget<TextField>(find.byType(TextField)).controller!.text,
      'seed',
    );

    await tester.enterText(find.byType(TextField), 'typed');
    await tester.pumpAndSettle();
    expect(formKey.currentState!.value['bio'], 'typed');

    formKey.currentState!.setFieldValue('bio', 'from form');
    await tester.pumpAndSettle();
    expect(
      tester.widget<TextField>(find.byType(TextField)).controller!.text,
      'from form',
    );
    expect(find.text('from form'), findsOneWidget);

    formKey.currentState!.reset();
    await tester.pumpAndSettle();
    expect(
      tester.widget<TextField>(find.byType(TextField)).controller!.text,
      'seed',
    );
    expect(find.text('seed'), findsOneWidget);
  });
}
