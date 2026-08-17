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
  testWidgets('renders four metric slots and a dash for missing values', (
    tester,
  ) async {
    await tester.pumpWidget(
      _wrap(
        TpCatalogMetadataRow(
          adoption: _metric('Installs', '128', Icons.download),
          rating: _metric('Rating', null, Icons.star),
          updated: _metric('Updated', 'Yesterday', Icons.update),
          published: _metric('Published', '2026-08-18', Icons.event),
        ),
      ),
    );

    expect(find.text('Installs'), findsOneWidget);
    expect(find.text('128'), findsOneWidget);
    expect(find.text('Rating'), findsOneWidget);
    expect(find.text('—'), findsOneWidget);
    expect(find.text('Updated'), findsOneWidget);
    expect(find.text('Yesterday'), findsOneWidget);
    expect(find.text('Published'), findsOneWidget);
    expect(find.text('2026-08-18'), findsOneWidget);
    expect(find.byIcon(Icons.download), findsOneWidget);
    expect(find.byIcon(Icons.star), findsOneWidget);
    expect(find.byIcon(Icons.update), findsOneWidget);
    expect(find.byIcon(Icons.event), findsOneWidget);
  });
}
