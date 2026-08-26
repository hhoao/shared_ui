import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_ui/shared_ui.dart';

Widget _wrap(Widget child) {
  final scheme = ColorScheme.fromSeed(seedColor: Colors.orange);
  return MaterialApp(
    theme: ThemeData(colorScheme: scheme, useMaterial3: true),
    home: TpTheme(
      data: TpThemeData.fromColorScheme(scheme, scale: 1.0),
      child: Scaffold(body: child),
    ),
  );
}

void main() {
  testWidgets('renders the initial value and reports selections', (
    tester,
  ) async {
    String? selected;
    await tester.pumpWidget(
      _wrap(
        TpSelectFormField<String>(
          id: 'pick',
          initialValue: 'alpha',
          items: const ['alpha', 'beta'],
          itemLabel: (item) => item,
          onChanged: (value) => selected = value,
        ),
      ),
    );

    expect(find.text('alpha'), findsOneWidget);

    await tester.tap(find.byType(TpSelect<String>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('beta').last);
    await tester.pumpAndSettle();

    expect(selected, 'beta');
    expect(find.text('beta'), findsOneWidget);
  });

  testWidgets('validates on form validate and clears after fixing', (
    tester,
  ) async {
    final formKey = GlobalKey<TpFormState>();
    Object? submitted;
    await tester.pumpWidget(
      _wrap(
        TpForm(
          key: formKey,
          child: Column(
            children: [
              TpSelectFormField<String>(
                id: 'pick',
                items: const ['alpha', 'beta'],
                hintText: 'pick one',
                itemLabel: (item) => item,
                validator: (value) =>
                    value == null || value.isEmpty ? 'Required' : null,
              ),
              TextButton(
                onPressed: () {
                  if (formKey.currentState!.validate()) {
                    submitted = formKey.currentState!.value['pick'];
                  }
                },
                child: const Text('submit'),
              ),
            ],
          ),
        ),
      ),
    );

    await tester.tap(find.text('submit'));
    await tester.pumpAndSettle();

    expect(find.text('Required'), findsOneWidget);
    expect(submitted, isNull);

    await tester.tap(find.byType(TpSelect<String>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('beta').last);
    await tester.pumpAndSettle();

    expect(find.text('Required'), findsNothing);

    await tester.tap(find.text('submit'));
    await tester.pumpAndSettle();

    expect(submitted, 'beta');
  });
}
