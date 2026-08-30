import 'package:flutter/material.dart';
import '../../support/tp_test_widgets.dart';
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

  testWidgets('shows label text only when tip is absent', (tester) async {
    await tester.pumpWidget(
      wrap(
        const TpFormFieldLabel(text: 'Endpoint'),
      ),
    );

    expect(find.text('Endpoint'), findsOneWidget);
    expect(find.byIcon(Icons.info_outline), findsNothing);
    expect(find.byType(Tooltip), findsNothing);
  });

  testWidgets('shows info icon and tooltip when tip is set', (tester) async {
    await tester.pumpWidget(
      wrap(
        const TpFormFieldLabel(
          text: 'Response path',
          tip: 'Optional JSONPath into the response body.',
        ),
      ),
    );

    expect(find.text('Response path'), findsOneWidget);
    expect(find.byIcon(Icons.info_outline), findsOneWidget);

    final tooltip = tester.widget<Tooltip>(find.byType(Tooltip));
    expect(
      tooltip.message,
      'Optional JSONPath into the response body.',
    );
    expect(tooltip.textStyle?.fontSize, isNotNull);
  });
}
