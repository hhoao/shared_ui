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

TpCatalogMetricView _metric(String label, String? value, IconData icon) {
  return TpCatalogMetricView(
    icon: icon,
    label: label,
    value: value,
    missingValueTooltip: 'No data for $label',
  );
}

void main() {
  testWidgets('renders compact adoption and rating without label text', (
    tester,
  ) async {
    await tester.pumpWidget(
      _wrap(
        TpCatalogMetadataRow(
          adoption: _metric('Installs', '128', Icons.download),
          rating: _metric('Rating', null, Icons.star),
        ),
      ),
    );

    expect(find.text('128'), findsOneWidget);
    expect(find.text('—'), findsOneWidget);
    expect(find.text('Installs'), findsNothing);
    expect(find.text('Rating'), findsNothing);
    expect(find.byIcon(Icons.download), findsOneWidget);
    expect(find.byIcon(Icons.star), findsOneWidget);
  });
}
