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
  testWidgets('renders catalog content and optional slots', (tester) async {
    await tester.pumpWidget(
      _wrap(
        TpCatalogCardShell(
          title: 'Release helper',
          source: 'TeamPilot Registry',
          description: 'Automates release notes.',
          leading: const Icon(Icons.extension),
          body: const Text('Extra catalog details'),
          metadata: const Text('Metadata'),
          action: const Text('Install'),
        ),
      ),
    );

    expect(find.text('Release helper'), findsOneWidget);
    expect(find.text('TeamPilot Registry'), findsOneWidget);
    expect(find.text('Automates release notes.'), findsOneWidget);
    expect(find.text('Extra catalog details'), findsOneWidget);
    expect(find.text('Metadata'), findsOneWidget);
    expect(find.text('Install'), findsOneWidget);
    expect(find.byIcon(Icons.extension), findsOneWidget);
  });

  testWidgets('sort control renders the selected localized label', (
    tester,
  ) async {
    await tester.pumpWidget(
      _wrap(
        TpCatalogSortControl<String>(
          items: const ['adoption', 'rating'],
          initialItem: 'adoption',
          itemLabel: (item) => item == 'adoption' ? 'Installs' : 'Rating',
          onChanged: (_) {},
        ),
      ),
    );

    expect(find.text('Installs'), findsOneWidget);
    expect(find.byType(TpSelect<String>), findsOneWidget);
  });

  testWidgets('wraps the header on a narrow card', (tester) async {
    await tester.pumpWidget(
      _wrap(
        SizedBox(
          width: 150,
          child: TpCatalogCardShell(
            title: 'A very long catalog entry name',
            source: 'A source with a long name',
            description: 'A description that can wrap on a narrow screen.',
            metadata: const SizedBox(),
            action: const SizedBox(),
          ),
        ),
      ),
    );

    expect(tester.takeException(), isNull);
  });

  testWidgets('truncates a long description inside a short grid cell', (
    tester,
  ) async {
    await tester.pumpWidget(
      _wrap(
        SizedBox(
          width: 266,
          height: 274,
          child: TpCatalogCardShell(
            title: 'Reviewer',
            source: 'TeamPilot built-in',
            description:
                'A long builtin persona description that used to overflow '
                'fixed catalog grid cells because the shell laid out the full '
                'paragraph without a line limit. Extra sentences keep coming '
                'so the card body would exceed the 300px main axis extent.',
            metadata: const SizedBox(height: 48, width: double.infinity),
            action: const SizedBox(height: 36, width: 80),
          ),
        ),
      ),
    );

    expect(tester.takeException(), isNull);
  });

  testWidgets('draws an outlined border at rest', (tester) async {
    await tester.pumpWidget(
      _wrap(
        const TpCatalogCardShell(
          title: 'Bordered',
          source: 'src',
          description: 'desc',
          metadata: SizedBox(),
          action: SizedBox(),
        ),
      ),
    );

    final container = tester.widget<AnimatedContainer>(
      find.byType(AnimatedContainer),
    );
    final decoration = container.decoration! as BoxDecoration;
    expect(decoration.border, isA<Border>());
    expect((decoration.border! as Border).top.width, greaterThan(0));
  });

  testWidgets('does not overflow a 160px-tall landing-picker cell', (
    tester,
  ) async {
    await tester.pumpWidget(
      _wrap(
        SizedBox(
          width: 266,
          height: 160,
          child: TpCatalogCardShell(
            title: 'Research Squad',
            source: 'o/r/squad',
            description: 'deep research',
            metadata: const SizedBox(height: 72, width: double.infinity),
            action: const SizedBox(height: 40, width: 80),
            body: const SizedBox(height: 40, width: double.infinity),
          ),
        ),
      ),
    );

    expect(tester.takeException(), isNull);
  });
}
