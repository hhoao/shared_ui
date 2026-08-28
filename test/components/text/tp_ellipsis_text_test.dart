import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_ui/shared_ui.dart';

Widget _wrap(Widget child) {
  final scheme = ColorScheme.fromSeed(seedColor: Colors.orange);
  return MaterialApp(
    theme: ThemeData(colorScheme: scheme, useMaterial3: true),
    home: Scaffold(body: child),
  );
}

void main() {
  const long = 'deepseek-v4-pro[1m]-very-long-model-name-that-must-overflow';

  testWidgets('long text ellipsizes and wraps in Tooltip with full text', (
    tester,
  ) async {
    await tester.pumpWidget(
      _wrap(
        SizedBox(
          width: 120,
          child: TpEllipsisText(long, style: const TextStyle(fontSize: 16)),
        ),
      ),
    );

    final tooltip = find.byType(Tooltip);
    expect(tooltip, findsOneWidget);
    expect(tester.widget<Tooltip>(tooltip).message, long);

    final text = tester.widget<Text>(find.byType(Text));
    expect(text.maxLines, 1);
    expect(text.overflow, TextOverflow.ellipsis);
  });

  testWidgets('short text renders plain Text and no Tooltip', (tester) async {
    await tester.pumpWidget(
      _wrap(
        SizedBox(
          width: 400,
          child: TpEllipsisText(
            'short-model',
            style: const TextStyle(fontSize: 16),
          ),
        ),
      ),
    );

    expect(find.byType(Tooltip), findsNothing);
    expect(find.text('short-model'), findsOneWidget);
  });

  testWidgets('unbounded maxLines never adds a Tooltip', (tester) async {
    await tester.pumpWidget(
      _wrap(
        SizedBox(
          width: 120,
          child: TpEllipsisText(
            long,
            maxLines: null,
            style: const TextStyle(fontSize: 16),
          ),
        ),
      ),
    );

    expect(find.byType(Tooltip), findsNothing);
  });
}
