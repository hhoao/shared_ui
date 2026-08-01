import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_ui/shared_ui.dart';

Widget _wrap({required Widget child}) {
  final scheme = ColorScheme.fromSeed(seedColor: Colors.indigo);
  return MaterialApp(
    theme: ThemeData(
      colorScheme: scheme,
      useMaterial3: true,
      dialogTheme: buildTpDialogTheme(
        colorScheme: scheme,
        textTheme: ThemeData.light().textTheme,
      ),
    ),
    home: TpTheme(
      data: TpThemeData.fromColorScheme(scheme, scale: 1.0),
      child: child,
    ),
  );
}

Future<void> _pumpSized(WidgetTester tester, Size size, Widget child) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(_wrap(child: child));
}

void main() {
  testWidgets('page+narrow uses fullscreen surface with PageShell', (
    tester,
  ) async {
    await _pumpSized(
      tester,
      const Size(400, 800),
      Builder(
        builder: (context) => Scaffold(
          body: TextButton(
            onPressed: () {
              showTpDialog<void>(
                context: context,
                presentation: TpDialogPresentation.page,
                mobileBreakpoint: 768,
                builder: (ctx) => TpDialogPageShell(
                  title: 'Automations',
                  child: const Text('page-body'),
                ),
              );
            },
            child: const Text('open'),
          ),
        ),
      ),
    );

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    expect(find.byType(Dialog), findsNothing);
    expect(find.text('Automations'), findsOneWidget);
    expect(find.text('page-body'), findsOneWidget);

    final shellRect = tester.getRect(find.byType(TpDialogPageShell));
    expect(shellRect.width, closeTo(400, 0.5));
    expect(shellRect.height, closeTo(800, 0.5));

    await tester.tap(find.byIcon(Icons.chevron_left_rounded));
    await tester.pumpAndSettle();
    expect(find.text('Automations'), findsNothing);
  });

  testWidgets('page+wide uses constrained card, not full-bleed', (
    tester,
  ) async {
    await _pumpSized(
      tester,
      const Size(1200, 800),
      Builder(
        builder: (context) => Scaffold(
          body: TextButton(
            onPressed: () {
              showTpDialog<void>(
                context: context,
                presentation: TpDialogPresentation.page,
                mobileBreakpoint: 768,
                builder: (ctx) => TpDialogPageShell(
                  title: 'Settings',
                  child: const Text('wide-body'),
                ),
              );
            },
            child: const Text('open'),
          ),
        ),
      ),
    );

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    expect(find.byType(Dialog), findsOneWidget);
    expect(find.byType(TpDialog), findsOneWidget);
    expect(find.byType(TpDialogHeader), findsOneWidget);
    expect(find.byType(TpDialogMobileNavBar), findsNothing);
    expect(find.byIcon(Icons.close_rounded), findsOneWidget);

    final shellRect = tester.getRect(find.byType(TpDialogPageShell));
    expect(shellRect.width, lessThan(1200));
    expect(shellRect.width, closeTo(kTpDialogPageWideMaxWidth, 48));

    final scheme = Theme.of(
      tester.element(find.byType(TpDialog)),
    ).colorScheme;
    final dialog = tester.widget<Dialog>(find.byType(Dialog));
    expect(dialog.backgroundColor, scheme.surface);
  });

  testWidgets('narrow PageShell uses mobile nav, not desktop header', (
    tester,
  ) async {
    await _pumpSized(
      tester,
      const Size(400, 800),
      Builder(
        builder: (context) => Scaffold(
          body: TextButton(
            onPressed: () {
              showTpDialog<void>(
                context: context,
                presentation: TpDialogPresentation.page,
                mobileBreakpoint: 768,
                builder: (ctx) => const TpDialogPageShell(
                  title: 'Narrow',
                  child: Text('body'),
                ),
              );
            },
            child: const Text('open'),
          ),
        ),
      ),
    );

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    expect(find.byType(TpDialogMobileNavBar), findsOneWidget);
    expect(find.byType(TpDialogHeader), findsNothing);
    expect(find.byIcon(Icons.chevron_left_rounded), findsOneWidget);
  });

  testWidgets('wide fillBody:false shrink-wraps intrinsic child', (
    tester,
  ) async {
    await _pumpSized(
      tester,
      const Size(1200, 900),
      Builder(
        builder: (context) => Scaffold(
          body: TextButton(
            onPressed: () {
              showTpDialog<void>(
                context: context,
                presentation: TpDialogPresentation.page,
                mobileBreakpoint: 768,
                maxWidth: 720,
                maxHeight: 800,
                builder: (ctx) => TpDialogPageShell(
                  title: 'Short',
                  fillBody: false,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      SizedBox(height: 80, child: Text('short')),
                    ],
                  ),
                ),
              );
            },
            child: const Text('open'),
          ),
        ),
      ),
    );

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    expect(find.byType(TpDialogHeader), findsOneWidget);
    final shellRect = tester.getRect(find.byType(TpDialogPageShell));
    expect(shellRect.height, lessThan(400));
  });

  testWidgets('wide fillBody:true allows host Expanded without assert', (
    tester,
  ) async {
    await _pumpSized(
      tester,
      const Size(1200, 900),
      Builder(
        builder: (context) => Scaffold(
          body: TextButton(
            onPressed: () {
              showTpDialog<void>(
                context: context,
                presentation: TpDialogPresentation.page,
                mobileBreakpoint: 768,
                maxHeight: 600,
                builder: (ctx) => const TpDialogPageShell(
                  title: 'Fill',
                  fillBody: true,
                  child: Column(
                    children: [
                      Expanded(child: Text('fill')),
                      Text('footer'),
                    ],
                  ),
                ),
              );
            },
            child: const Text('open'),
          ),
        ),
      ),
    );

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    expect(find.text('fill'), findsOneWidget);
    expect(find.text('footer'), findsOneWidget);
    final shellRect = tester.getRect(find.byType(TpDialogPageShell));
    expect(shellRect.height, greaterThan(400));
  });

  testWidgets('wide header is inset from dialog edge', (tester) async {
    await _pumpSized(
      tester,
      const Size(1200, 800),
      Builder(
        builder: (context) => Scaffold(
          body: TextButton(
            onPressed: () {
              showTpDialog<void>(
                context: context,
                presentation: TpDialogPresentation.page,
                mobileBreakpoint: 768,
                builder: (ctx) => const TpDialogPageShell(
                  title: 'Inset Title',
                  child: Text('body'),
                ),
              );
            },
            child: const Text('open'),
          ),
        ),
      ),
    );

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    final dialogLeft = tester.getRect(find.byType(Dialog)).left;
    final titleLeft = tester.getRect(find.text('Inset Title')).left;
    expect(titleLeft - dialogLeft, greaterThanOrEqualTo(24));
  });

  testWidgets('card+narrow still shows centered TpDialog', (tester) async {
    await _pumpSized(
      tester,
      const Size(400, 800),
      Builder(
        builder: (context) => Scaffold(
          body: TextButton(
            onPressed: () {
              showTpDialog<void>(
                context: context,
                presentation: TpDialogPresentation.card,
                mobileBreakpoint: 768,
                builder: (ctx) => TpDialog(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      TpDialogHeader(title: 'Confirm'),
                      Text('card-body'),
                    ],
                  ),
                ),
              );
            },
            child: const Text('open'),
          ),
        ),
      ),
    );

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    expect(find.byType(TpDialog), findsOneWidget);
    expect(find.byType(Dialog), findsOneWidget);
    expect(find.text('Confirm'), findsOneWidget);
    expect(find.text('card-body'), findsOneWidget);

    final dialogRect = tester.getRect(find.byType(Dialog));
    expect(dialogRect.width, lessThanOrEqualTo(400));
  });
}
