import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_ui/shared_ui.dart';

Widget _wrap({
  required Widget child,
  bool open = true,
  TpSidebarCollapsible collapsible = TpSidebarCollapsible.icon,
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
          open: open,
          onOpenChange: (_) {},
          child: TpSidebar(
            collapsible: collapsible,
            child: child,
          ),
        ),
      ),
    ),
  );
}

Widget _sampleMenu({
  VoidCallback? onPressed,
  bool isActive = false,
  String? tooltip,
}) {
  return TpSidebarMenu(
    children: [
      TpSidebarMenuItem(
        children: [
          TpSidebarMenuButton(
            icon: const Icon(Icons.inbox),
            label: 'Tasks',
            isActive: isActive,
            onPressed: onPressed,
            tooltip: tooltip,
          ),
          const TpSidebarMenuBadge(label: '3'),
          TpSidebarMenuSub(
            children: [
              TpSidebarMenuSubItem(
                child: TpSidebarMenuSubButton(
                  label: 'Sub item',
                  onPressed: () {},
                ),
              ),
            ],
          ),
        ],
      ),
    ],
  );
}

void main() {
  testWidgets('expanded shows label, badge text, and MenuSub', (tester) async {
    await tester.pumpWidget(
      _wrap(child: _sampleMenu()),
    );
    await tester.pumpAndSettle();

    expect(find.text('Tasks'), findsOneWidget);
    expect(find.text('3'), findsOneWidget);
    expect(find.text('Sub item'), findsOneWidget);
    expect(find.byKey(const Key('tp-sidebar-badge-dot')), findsNothing);
  });

  testWidgets(
    'icon-collapsed hides label, badge text, MenuSub; shows badge dot',
    (tester) async {
      await tester.pumpWidget(
        _wrap(open: false, child: _sampleMenu()),
      );
      await tester.pumpAndSettle();

      expect(find.text('Tasks'), findsNothing);
      expect(find.text('3'), findsNothing);
      expect(find.text('Sub item'), findsNothing);
      expect(find.byKey(const Key('tp-sidebar-badge-dot')), findsOneWidget);
    },
  );

  testWidgets('MenuButton onPressed fires and isActive builds', (tester) async {
    var pressed = 0;
    await tester.pumpWidget(
      _wrap(
        child: _sampleMenu(
          isActive: true,
          onPressed: () => pressed++,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    await tester.tap(find.text('Tasks'));
    await tester.pump();
    expect(pressed, 1);
  });

  testWidgets('collapsed tooltip defaults to label', (tester) async {
    await tester.pumpWidget(
      _wrap(open: false, child: _sampleMenu()),
    );
    await tester.pumpAndSettle();

    final tip = find.byType(TpTooltip);
    final materialTip = find.byWidgetPredicate(
      (w) => w is Tooltip && w.message == 'Tasks',
    );
    expect(
      tip.evaluate().isNotEmpty || materialTip.evaluate().isNotEmpty,
      isTrue,
      reason: 'expected TpTooltip or Tooltip with label message',
    );

    if (tip.evaluate().isNotEmpty) {
      final widget = tester.widget<TpTooltip>(tip);
      expect(widget.message, 'Tasks');

      final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
      await gesture.addPointer(location: Offset.zero);
      addTearDown(gesture.removePointer);
      await tester.pump();
      await gesture.moveTo(tester.getCenter(find.byType(TpSidebarMenuButton)));
      await tester.pump(const Duration(milliseconds: 600));
      expect(find.text('Tasks'), findsWidgets);
    } else {
      expect(materialTip, findsOneWidget);
    }
  });
}
