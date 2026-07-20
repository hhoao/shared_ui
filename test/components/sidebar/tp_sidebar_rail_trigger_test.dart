import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_ui/shared_ui.dart';

Widget _wrap({
  required Widget child,
  bool defaultOpen = true,
  Size size = const Size(1200, 800),
}) {
  final scheme = ColorScheme.fromSeed(seedColor: Colors.teal);
  return MediaQuery(
    data: MediaQueryData(size: size),
    child: MaterialApp(
      theme: ThemeData(colorScheme: scheme, useMaterial3: true),
      home: TpTheme(
        data: TpThemeData.fromColorScheme(scheme, scale: 1.0),
        child: TpSidebarProvider(
          defaultOpen: defaultOpen,
          child: Builder(
            builder: (context) {
              final open = TpSidebarScope.of(context).open;
              return Column(
                children: [
                  Text(open ? 'open' : 'closed'),
                  child,
                ],
              );
            },
          ),
        ),
      ),
    ),
  );
}

void main() {
  testWidgets('Trigger tap flips open via TpSidebarProvider', (tester) async {
    await tester.pumpWidget(
      _wrap(child: const TpSidebarTrigger()),
    );
    expect(find.text('open'), findsOneWidget);

    await tester.tap(find.byType(TpSidebarTrigger));
    await tester.pump();
    expect(find.text('closed'), findsOneWidget);

    await tester.tap(find.byType(TpSidebarTrigger));
    await tester.pump();
    expect(find.text('open'), findsOneWidget);
  });

  testWidgets('Rail tap flips open via TpSidebarProvider', (tester) async {
    await tester.pumpWidget(
      _wrap(
        child: const SizedBox(
          width: 256,
          height: 200,
          child: TpSidebarRail(),
        ),
      ),
    );
    expect(find.text('open'), findsOneWidget);

    await tester.tap(find.byKey(const Key('tp-sidebar-rail')));
    await tester.pump();
    expect(find.text('closed'), findsOneWidget);

    await tester.tap(find.byKey(const Key('tp-sidebar-rail')));
    await tester.pump();
    expect(find.text('open'), findsOneWidget);
  });

  testWidgets('Inset applies theme-driven radius decoration', (tester) async {
    final scheme = ColorScheme.fromSeed(seedColor: Colors.teal);
    final themeData = TpThemeData.fromColorScheme(scheme, scale: 1.0);
    final insetRadius = themeData.sidebarTheme.insetRadius;

    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(size: Size(1200, 800)),
        child: MaterialApp(
          theme: ThemeData(colorScheme: scheme, useMaterial3: true),
          home: TpTheme(
            data: themeData,
            child: const TpSidebarInset(
              child: Text('content'),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('content'), findsOneWidget);
    expect(find.byKey(const Key('tp-sidebar-inset')), findsOneWidget);

    final clipRRect = tester.widget<ClipRRect>(
      find.ancestor(
        of: find.text('content'),
        matching: find.byType(ClipRRect),
      ),
    );
    expect(clipRRect.borderRadius, BorderRadius.circular(insetRadius));

    final decorated = tester.widget<DecoratedBox>(
      find.descendant(
        of: find.byKey(const Key('tp-sidebar-inset')),
        matching: find.byType(DecoratedBox),
      ),
    );
    final decoration = decorated.decoration as BoxDecoration;
    expect(decoration.borderRadius, BorderRadius.circular(insetRadius));
    expect(
      decoration.color,
      themeData.sidebarTheme.insetBackgroundColor ?? scheme.surface,
    );
  });
}
