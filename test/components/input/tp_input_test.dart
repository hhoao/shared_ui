import 'package:flutter/material.dart';
import '../../support/tp_test_widgets.dart';
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

  testWidgets('metrics overrides default compact input height', (tester) async {
    const tall = TpControlSizeMetrics(
      height: 72,
      minWidth: 64,
      horizontalPadding: 16,
      verticalPadding: 24,
    );
    await tester.pumpWidget(
      wrap(const TpInput(metrics: tall)),
    );

    final field = tester.widget<TextField>(find.byType(TextField));
    expect(field.decoration?.constraints?.maxHeight, 72);
    expect(field.decoration?.isDense, isFalse);
    expect(
      field.decoration?.contentPadding,
      const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
    );
  });

  testWidgets('size uses button control track geometry', (tester) async {
    final control = TpControlMetrics.fromScale(1.0);
    await tester.pumpWidget(
      wrap(const TpInput(size: TpControlSize.large)),
    );

    final field = tester.widget<TextField>(find.byType(TextField));
    expect(
      field.decoration?.constraints?.maxHeight,
      control.large.height,
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
