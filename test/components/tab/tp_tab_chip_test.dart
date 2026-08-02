import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_ui/shared_ui.dart';

void main() {
  Widget wrap(Widget child) {
    return MaterialApp(
      home: TpTheme(
        data: TpThemeData.fromColorScheme(
          ColorScheme.fromSeed(seedColor: Colors.blue),
          scale: 1.0,
        ),
        child: Scaffold(body: child),
      ),
    );
  }

  Finder outerTpHover(WidgetTester tester) {
    return find.descendant(
      of: find.byType(TpTabChip),
      matching: find.byType(TpHover),
    ).first;
  }

  MouseRegion outerHoverRegion(WidgetTester tester) {
    return tester
        .widgetList<MouseRegion>(
          find.descendant(
            of: outerTpHover(tester),
            matching: find.byType(MouseRegion),
          ),
        )
        .first;
  }

  testWidgets('renders title and invokes onTap / onClose', (tester) async {
    var tapped = false;
    var closed = false;

    await tester.pumpWidget(
      wrap(
        TpTabChip(
          title: 'Session A',
          active: true,
          onTap: () => tapped = true,
          onClose: () => closed = true,
        ),
      ),
    );

    expect(find.text('Session A'), findsOneWidget);
    await tester.tap(find.text('Session A'));
    expect(tapped, isTrue);

    await tester.tap(find.byIcon(Icons.close));
    expect(closed, isTrue);
  });

  testWidgets('preview mutes and italicizes title', (tester) async {
    await tester.pumpWidget(
      wrap(
        TpTabChip(
          title: 'Draft',
          active: false,
          preview: true,
          onTap: () {},
          onClose: () {},
        ),
      ),
    );

    final text = tester.widget<Text>(find.text('Draft'));
    expect(text.style?.fontStyle, FontStyle.italic);
    expect(text.style?.color?.a, lessThan(1.0));
  });

  testWidgets('outer interactive surface uses click cursor', (tester) async {
    await tester.pumpWidget(
      wrap(
        TpTabChip(
          title: 'Tab',
          active: false,
          onTap: () {},
          onClose: () {},
        ),
      ),
    );

    expect(outerHoverRegion(tester).cursor, SystemMouseCursors.click);
  });

  testWidgets('onSecondaryTapDown fires with details', (tester) async {
    TapDownDetails? details;
    await tester.pumpWidget(
      wrap(
        TpTabChip(
          title: 'Tab',
          active: false,
          onTap: () {},
          onClose: () {},
          onSecondaryTapDown: (d) => details = d,
        ),
      ),
    );

    await tester.tap(
      outerTpHover(tester),
      buttons: kSecondaryButton,
    );
    await tester.pump();
    expect(details, isNotNull);
  });

  testWidgets('forceShowChrome keeps close icon visible and hittable', (
    tester,
  ) async {
    var closed = false;
    await tester.pumpWidget(
      wrap(
        TpTabChip(
          title: 'Tab',
          active: false,
          forceShowChrome: true,
          onTap: () {},
          onClose: () => closed = true,
        ),
      ),
    );

    final opacity = tester.widget<AnimatedOpacity>(
      find.ancestor(
        of: find.byIcon(Icons.close),
        matching: find.byType(AnimatedOpacity),
      ),
    );
    expect(opacity.opacity, 1.0);

    await tester.tap(find.byIcon(Icons.close));
    expect(closed, isTrue);
  });
}
