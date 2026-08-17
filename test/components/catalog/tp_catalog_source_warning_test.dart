import 'package:flutter/material.dart';
import 'package:shared_ui/shared_ui.dart';

import '../../support/tp_test_widgets.dart';

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
  testWidgets('renders nothing when there are no failures', (tester) async {
    await tester.pumpWidget(
      _wrap(TpCatalogSourceWarning(failures: <TpCatalogFailureView>[])),
    );

    expect(find.byIcon(Icons.warning_amber_rounded), findsNothing);
    expect(find.byType(Tooltip), findsNothing);
  });

  testWidgets('shows one warning tooltip line for every failed source', (
    tester,
  ) async {
    await tester.pumpWidget(
      _wrap(
        TpCatalogSourceWarning(
          failures: const [
            TpCatalogFailureView(
              sourceLabel: 'SkillsMP',
              message: 'Request timed out',
            ),
            TpCatalogFailureView(
              sourceLabel: 'skills.sh',
              message: 'Service unavailable',
            ),
          ],
        ),
      ),
    );

    expect(find.byIcon(Icons.warning_amber_rounded), findsOneWidget);
    final tooltip = tester.widget<Tooltip>(find.byType(Tooltip));
    expect(
      tooltip.message,
      'SkillsMP: Request timed out\nskills.sh: Service unavailable',
    );
  });
}
