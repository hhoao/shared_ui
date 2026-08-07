import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart' as ft;

/// Everything from `package:flutter_test/flutter_test.dart` except
/// [testWidgets], which is provided below so every widget test in this package
/// runs on the desktop platform by default.
export 'package:flutter_test/flutter_test.dart' hide testWidgets;

/// shared_ui is a desktop-first design system: run widget tests on a desktop
/// platform so [TpHover] and the other adaptive primitives render their desktop
/// (GestureDetector + hover + cursor) path by default.
///
/// A suite-wide `debugDefaultTargetPlatformOverride = TargetPlatform.linux` in
/// `flutter_test_config.dart` cannot be used: flutter_test's `_verifyInvariants`
/// requires every foundation debug variable to be null when each test body
/// returns, and `setUp` / `tearDown` / `addTearDown` callbacks all run after
/// that check, so a suite-wide override fails every test with "The value of a
/// foundation debug variable was changed by the test." This shim therefore sets
/// the override inside the test body and clears it in a `finally` within the
/// same body. Touch-specific tests opt into [testWidgetsTouch].
void testWidgets(String description, ft.WidgetTesterCallback callback) {
  ft.testWidgets(description, (tester) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.linux;
    try {
      await callback(tester);
    } finally {
      debugDefaultTargetPlatformOverride = null;
    }
  });
}

/// Like [testWidgets] but on a touch platform (`TargetPlatform.android`), for
/// shared_ui widgets whose behavior is genuinely touch-specific (e.g. the
/// sidebar mobile-drawer edge swipe). The override is cleared in a `finally`
/// within the same test body so flutter_test's debug-variable invariant holds.
void testWidgetsTouch(String description, ft.WidgetTesterCallback callback) {
  ft.testWidgets(description, (tester) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    try {
      await callback(tester);
    } finally {
      debugDefaultTargetPlatformOverride = null;
    }
  });
}
