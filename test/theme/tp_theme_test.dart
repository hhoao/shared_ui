import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_ui/shared_ui.dart';

void main() {
  testWidgets('TpTheme exposes spacing and icon sizes', (tester) async {
    late BuildContext captured;
    await tester.pumpWidget(
      TpTheme(
        data: TpThemeData.fromColorScheme(
          ColorScheme.fromSeed(seedColor: const Color(0xFFD4A06A)),
          scale: 1.0,
        ),
        child: Builder(
          builder: (context) {
            captured = context;
            return const SizedBox();
          },
        ),
      ),
    );
    expect(captured.tpSpacing.md, 12);
    expect(captured.tpIconSizes.md, greaterThan(0));
    expect(TpTheme.of(captured).spacing.scale, 1.0);
  });
}
