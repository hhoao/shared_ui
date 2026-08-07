import 'dart:async';

/// shared_ui is a desktop-first design system.
///
/// We do NOT set `debugDefaultTargetPlatformOverride = TargetPlatform.linux`
/// here for the whole suite: flutter_test's `_verifyInvariants` requires every
/// foundation debug variable (including that override) to be null when each
/// test body returns, and `setUp` / `tearDown` / `addTearDown` callbacks all
/// run after that check, so a suite-wide override fails every test with
/// "The value of a foundation debug variable was changed by the test."
///
/// Instead, every shared_ui widget test imports the shared `testWidgets` shim
/// from `support/tp_test_widgets.dart`, which defaults each test to
/// `TargetPlatform.linux` (and clears the override in a `finally` within the
/// same test body). Touch-specific tests opt into `TargetPlatform.android`
/// inside the body.
Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  await testMain();
}
