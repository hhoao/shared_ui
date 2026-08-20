import 'dart:async';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../popover/tp_anchor.dart';

/// Closes the currently open floating context menu, if any.
VoidCallback? _activeFloatingContextMenuCloser;

/// Whether a [showTpActionMenuOverlay] panel is currently on screen.
bool get isTpActionMenuOpen => _activeFloatingContextMenuCloser != null;

/// Dismisses the open action menu, if any. Returns whether a menu was closed.
bool dismissTpActionMenuIfOpen() {
  final closer = _activeFloatingContextMenuCloser;
  if (closer == null) return false;
  closer();
  return true;
}

/// Shows a context menu overlay that only hit-tests the menu panel itself.
///
/// Pointer events outside the panel pass through to widgets below (e.g. terminal),
/// so the user can right-click repeatedly at the same spot to reopen the menu.
Future<T?> showTpActionMenuOverlay<T>({
  required BuildContext context,
  required Offset globalPosition,
  required bool useRootNavigator,
  required Duration transitionDuration,
  required Curve transitionCurve,
  required Widget Function(
    BuildContext overlayContext,
    void Function(T? value) complete,
  )
  menuBuilder,
}) {
  _activeFloatingContextMenuCloser?.call();

  final overlayState = Overlay.of(context, rootOverlay: useRootNavigator);
  final overlayBox = overlayState.context.findRenderObject()! as RenderBox;
  final localTarget = overlayBox.globalToLocal(globalPosition);
  final completer = Completer<T?>();
  final menuKey = GlobalKey();
  late OverlayEntry entry;
  var entryInserted = false;
  var entryRemoved = false;

  void removeEntry() {
    // Do not gate on `entry.mounted`: a same-frame insert → dismiss (e.g. two
    // nested onSecondaryTapDown handlers both hit the kPressTimeout deadline)
    // removes the entry before its widget has built, when `mounted` is still
    // false. Guard on whether we inserted instead, so the entry cannot orphan.
    if (!entryInserted || entryRemoved) return;
    entryRemoved = true;
    entry.remove();
  }

  void complete(T? value) {
    if (!completer.isCompleted) completer.complete(value);
    removeEntry();
  }

  void dismiss() => complete(null);

  late final VoidCallback thisCloser = dismiss;
  _activeFloatingContextMenuCloser = thisCloser;

  late final PointerRoute outsidePointerRoute;
  outsidePointerRoute = (PointerEvent event) {
    if (event is! PointerDownEvent) return;
    if (event.buttons != kPrimaryMouseButton) return;
    final menuBox = menuKey.currentContext?.findRenderObject() as RenderBox?;
    if (menuBox == null || !menuBox.hasSize) return;
    final origin = menuBox.localToGlobal(Offset.zero);
    final rect = origin & menuBox.size;
    if (!rect.contains(event.position)) {
      dismiss();
    }
  };

  bool escapeHandler(KeyEvent event) {
    if (event is! KeyDownEvent) return false;
    if (event.logicalKey != LogicalKeyboardKey.escape) return false;
    dismiss();
    return true;
  }

  entry = OverlayEntry(
    builder: (overlayContext) {
      return _FloatingContextMenuLayer(
        menuBoundsKey: menuKey,
        localTarget: localTarget,
        transitionDuration: transitionDuration,
        transitionCurve: transitionCurve,
        onSecondaryPointerDown: dismiss,
        onDismiss: dismiss,
        child: menuBuilder(overlayContext, complete),
      );
    },
  );

  GestureBinding.instance.pointerRouter.addGlobalRoute(outsidePointerRoute);
  HardwareKeyboard.instance.addHandler(escapeHandler);
  overlayState.insert(entry);
  entryInserted = true;

  return completer.future.whenComplete(() {
    HardwareKeyboard.instance.removeHandler(escapeHandler);
    GestureBinding.instance.pointerRouter.removeGlobalRoute(
      outsidePointerRoute,
    );
    removeEntry();
    if (identical(_activeFloatingContextMenuCloser, thisCloser)) {
      _activeFloatingContextMenuCloser = null;
    }
  });
}

class _FloatingContextMenuLayer extends StatefulWidget {
  const _FloatingContextMenuLayer({
    required this.menuBoundsKey,
    required this.localTarget,
    required this.transitionDuration,
    required this.transitionCurve,
    required this.onSecondaryPointerDown,
    required this.onDismiss,
    required this.child,
  });

  final GlobalKey menuBoundsKey;
  final Offset localTarget;
  final Duration transitionDuration;
  final Curve transitionCurve;
  final VoidCallback onSecondaryPointerDown;
  final VoidCallback onDismiss;
  final Widget child;

  @override
  State<_FloatingContextMenuLayer> createState() =>
      _FloatingContextMenuLayerState();
}

class _FloatingContextMenuLayerState extends State<_FloatingContextMenuLayer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fade;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.transitionDuration,
    );
    final curved = CurvedAnimation(
      parent: _controller,
      curve: widget.transitionCurve,
      reverseCurve: Curves.easeInCubic,
    );
    _fade = curved;
    _scale = Tween<double>(begin: 0.97, end: 1).animate(curved);
    if (widget.transitionDuration == Duration.zero) {
      _controller.value = 1.0;
    } else {
      _controller.forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Widget panel = Listener(
      onPointerDown: (event) {
        if (event.buttons == kSecondaryMouseButton) {
          widget.onSecondaryPointerDown();
        }
      },
      child: widget.child,
    );

    panel = CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.escape): widget.onDismiss,
      },
      child: Focus(autofocus: true, child: panel),
    );

    if (widget.transitionDuration != Duration.zero) {
      panel = FadeTransition(
        opacity: _fade,
        child: ScaleTransition(
          scale: _scale,
          alignment: Alignment.topLeft,
          child: panel,
        ),
      );
    }

    return CustomSingleChildLayout(
      delegate: ContextMenuOverlayPositionDelegate(target: widget.localTarget),
      child: KeyedSubtree(key: widget.menuBoundsKey, child: panel),
    );
  }
}
