import 'dart:async';

/// shared_ui is a desktop-first design system.
///
/// We do NOT set `debugDefaultTargetPlatformOverride = TargetPlatform.linux`
/// here for the whole suite: flutter_test's `_verifyInvariants` requires every
/// foundation debug variable (including that override) to be null when each
/// test body returns, and `addTearDown` / `tearDown` / `setUpAll` callbacks
/// all run after that check, so a suite-wide override fails every test with
/// "The value of a foundation debug variable was changed by the test."
///
/// Instead, tests that must run on a specific platform set the override inline
/// and reset it in a `finally` within the same test body. The hover tests do
/// this via a local `testWidgets` shim that defaults every test to
/// `TargetPlatform.linux` (see `components/hover/tp_hover_test.dart` and
/// `components/hover/tp_hover_row_test.dart`); touch-specific tests override
/// to `TargetPlatform.android` inside the body.
Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  await testMain();
}
