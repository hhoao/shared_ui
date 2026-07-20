import 'dart:io' show Platform;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

/// Mounts [child] after [delayFrames] post-frame callbacks so heavy subtrees
/// can paint in a later frame than their parent shell.
///
/// When [awaitIdle] is true, the final mount is scheduled at [Priority.idle]
/// so it does not share a busy frame with shell rebuilds (e.g. compose fields).
///
/// Under `FLUTTER_TEST`, mounts [child] immediately.
class TpDeferredMountShell extends StatefulWidget {
  const TpDeferredMountShell({
    required this.child,
    this.placeholder,
    this.delayFrames = 1,
    this.awaitIdle = false,
    super.key,
  });

  final Widget child;
  final Widget? placeholder;

  /// Number of frames to wait after the first build before showing [child].
  final int delayFrames;

  /// After [delayFrames], mount on an idle scheduler task instead of the next
  /// post-frame callback.
  final bool awaitIdle;

  @override
  State<TpDeferredMountShell> createState() => _TpDeferredMountShellState();
}

class _TpDeferredMountShellState extends State<TpDeferredMountShell> {
  var _showChild = false;

  static bool get _inTest {
    try {
      return Platform.environment.containsKey('FLUTTER_TEST');
    } on Object {
      return false;
    }
  }

  @override
  void initState() {
    super.initState();
    if (_inTest) {
      _showChild = true;
      return;
    }
    if (widget.delayFrames <= 0) {
      if (widget.awaitIdle) {
        _scheduleIdleMount();
      } else {
        _showChild = true;
      }
      return;
    }
    _scheduleShow(widget.delayFrames);
  }

  void _revealChild() {
    if (!mounted || _showChild) return;
    setState(() => _showChild = true);
  }

  void _scheduleIdleMount() {
    SchedulerBinding.instance.scheduleTask(_revealChild, Priority.idle);
  }

  void _scheduleShow(int framesRemaining) {
    SchedulerBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (framesRemaining <= 1) {
        if (widget.awaitIdle) {
          _scheduleIdleMount();
        } else {
          _revealChild();
        }
        return;
      }
      _scheduleShow(framesRemaining - 1);
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_showChild) return widget.child;
    return widget.placeholder ?? const SizedBox.shrink();
  }
}

/// Mounts [child] after [delay] elapses so animated pane switches can finish
/// before a heavy subtree builds.
///
/// Under `FLUTTER_TEST`, mounts [child] immediately.
class TpDeferredMountAfter extends StatefulWidget {
  const TpDeferredMountAfter({
    required this.child,
    required this.delay,
    this.placeholder,
    super.key,
  });

  final Widget child;
  final Duration delay;
  final Widget? placeholder;

  @override
  State<TpDeferredMountAfter> createState() => _TpDeferredMountAfterState();
}

class _TpDeferredMountAfterState extends State<TpDeferredMountAfter> {
  var _showChild = false;

  static bool get _inTest {
    try {
      return Platform.environment.containsKey('FLUTTER_TEST');
    } on Object {
      return false;
    }
  }

  @override
  void initState() {
    super.initState();
    _scheduleShow();
  }

  @override
  void didUpdateWidget(covariant TpDeferredMountAfter oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.delay != oldWidget.delay && !_showChild) {
      _scheduleShow();
    }
  }

  void _scheduleShow() {
    if (_inTest || widget.delay <= Duration.zero) {
      _showChild = true;
      return;
    }
    Future<void>.delayed(widget.delay, () {
      if (!mounted) return;
      setState(() => _showChild = true);
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_showChild) return widget.child;
    return widget.placeholder ?? const SizedBox.shrink();
  }
}
