import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_ui/shared_ui.dart';
import 'package:shared_ui/src/toast/engine/toastification.dart';

Widget _harness({required Widget child, TpToastTheme? toast}) {
  final scheme = ColorScheme.fromSeed(seedColor: Colors.indigo);
  return TpToastWrapper(
    config: const TpToastConfig(
      alignment: AlignmentDirectional.topEnd,
      itemWidth: 400,
      maxToastLimit: 1,
      animationDuration: Duration(milliseconds: 200),
    ),
    child: MaterialApp(
      theme: ThemeData(colorScheme: scheme),
      home: TpTheme(
        data: TpThemeData.fromColorScheme(scheme, scale: 1, toast: toast),
        child: child,
      ),
    ),
  );
}

void main() {
  tearDown(() {
    TpToast.dismiss();
  });

  testWidgets('show presents message and dismiss removes it', (tester) async {
    await tester.pumpWidget(
      _harness(
        child: Builder(
          builder: (context) {
            return TextButton(
              onPressed: () => TpToast.show(context, message: 'Hello toast'),
              child: const Text('go'),
            );
          },
        ),
      ),
    );
    await tester.tap(find.text('go'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 250));
    expect(find.text('Hello toast'), findsOneWidget);

    TpToast.dismiss();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 250));
    expect(find.text('Hello toast'), findsNothing);
  });

  testWidgets('empty message is a no-op', (tester) async {
    await tester.pumpWidget(
      _harness(
        child: Builder(
          builder: (context) {
            return TextButton(
              onPressed: () => TpToast.show(context, message: '   '),
              child: const Text('go'),
            );
          },
        ),
      ),
    );
    await tester.tap(find.text('go'));
    await tester.pumpAndSettle();
    expect(find.text('   '), findsNothing);
  });

  testWidgets('TpToastConfig itemWidth and marginBuilder are applied', (
    tester,
  ) async {
    const customMargin = EdgeInsets.all(42);
    late BuildContext capturedContext;

    await tester.pumpWidget(
      TpToastWrapper(
        config: TpToastConfig(
          itemWidth: 300,
          marginBuilder: (_, _) => customMargin,
        ),
        child: MaterialApp(
          home: Builder(
            builder: (context) {
              capturedContext = context;
              return const SizedBox();
            },
          ),
        ),
      ),
    );

    final provider = ToastificationConfigProvider.of(capturedContext);
    expect(provider.config.itemWidth, 300);
    expect(
      provider.config.marginBuilder(capturedContext, Alignment.topRight),
      customMargin,
    );
  });
}
