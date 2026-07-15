import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_ui/shared_ui.dart';

void main() {
  ThemeData themeWithOutlineInput() {
    final base = ThemeData.light();
    final control = TpControlMetrics.fromScale(1.0);
    return base.copyWith(
      inputDecorationTheme: buildTpOutlineInputDecorationTheme(
        colorScheme: base.colorScheme,
        textTheme: base.textTheme,
        control: control,
      ),
    );
  }

  Widget wrap(Widget child, {ThemeData? theme}) {
    final resolved = theme ?? themeWithOutlineInput();
    return MaterialApp(
      theme: resolved,
      home: Scaffold(
        body: TpTheme(
          data: TpThemeData.fromColorScheme(resolved.colorScheme, scale: 1.0),
          child: child,
        ),
      ),
    );
  }

  testWidgets('shows hint and accepts text', (tester) async {
    await tester.pumpWidget(
      wrap(const TpInput(decoration: InputDecoration(hintText: 'Name'))),
    );

    expect(find.text('Name'), findsOneWidget);
    await tester.enterText(find.byType(TextField), 'hello');
    expect(find.text('hello'), findsOneWidget);
  });

  testWidgets('fill matches outline input chrome', (tester) async {
    final theme = themeWithOutlineInput();
    await tester.pumpWidget(wrap(const TpInput(), theme: theme));

    final field = tester.widget<TextField>(find.byType(TextField));
    expect(
      field.decoration?.fillColor,
      theme.colorScheme.surfaceContainer,
    );
  });

  testWidgets('TpInputFormField syncs text with form', (tester) async {
    await tester.pumpWidget(
      wrap(
        TpForm(
          child: TpInputFormField(
            id: 'title',
            decoration: const InputDecoration(hintText: 'Title'),
          ),
        ),
      ),
    );

    expect(find.text('Title'), findsOneWidget);
    await tester.enterText(find.byType(TextField), 'draft');
    expect(find.text('draft'), findsOneWidget);
  });
}
