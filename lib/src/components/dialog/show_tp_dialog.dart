import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../theme/tp_theme.dart';
import 'tp_dialog.dart';
import 'tp_dialog_presentation.dart';

/// Default max width for [TpDialogPresentation.page] on wide viewports.
const double kTpDialogPageWideMaxWidth = 1160;

/// Default max height for [TpDialogPresentation.page] on wide viewports.
const double kTpDialogPageWideMaxHeight = 960;

/// Presents a modal dialog as a centered card or a full-bleed page on narrow.
///
/// When [presentation] is [TpDialogPresentation.page] and the viewport width is
/// below [mobileBreakpoint], uses [showGeneralDialog] with a zero-inset
/// fullscreen [Material] surface. The [builder] is mounted as-is — wrap simple
/// pages in [TpDialogPageShell]; dual-pane hosts use [TpDialogNavShell] alone.
///
/// Otherwise uses [showDialog]. For [TpDialogPresentation.card], [builder]
/// should return a [TpDialog] (or equivalent). For page on wide, the result is
/// wrapped in [TpDialog] with [maxWidth] / [maxHeight] defaults suited to
/// management dialogs ([kTpDialogPageWideMaxWidth] / [kTpDialogPageWideMaxHeight]).
Future<T?> showTpDialog<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  TpDialogPresentation presentation = TpDialogPresentation.card,
  double mobileBreakpoint = 768,
  bool barrierDismissible = true,

  /// Whether the Escape key pops the dialog. Defaults to [barrierDismissible]
  /// — the framework couples ESC with barrier dismissal on desktop — but can
  /// be set independently, e.g. `barrierDismissible: false,
  /// escapeDismissible: true` for a dialog that blocks tap-outside yet stays
  /// keyboard-dismissable. The pop passes a null result, like tapping outside.
  bool? escapeDismissible,
  bool useRootNavigator = true,
  RouteSettings? routeSettings,
  Color? barrierColor,

  /// Optional dialog/page surface. Prefer leaving null so surfaces resolve
  /// live from [ColorScheme] (page → [ColorScheme.surface], card [TpDialog]
  /// → surfaceContainer). A Theme-captured [Color] freezes at open and will
  /// not follow theme toggles.
  Color? backgroundColor,
  double? maxWidth,
  double? maxHeight,
}) {
  final isNarrow = MediaQuery.sizeOf(context).width < mobileBreakpoint;
  final escapeEnabled = escapeDismissible ?? barrierDismissible;

  if (presentation == TpDialogPresentation.page && isNarrow) {
    return showGeneralDialog<T>(
      context: context,
      barrierDismissible: barrierDismissible,
      barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
      barrierColor:
          barrierColor ??
          Theme.of(context).dialogTheme.barrierColor ??
          Colors.black.withValues(
            alpha: context.tpTheme.dialogTheme.barrierAlpha,
          ),
      useRootNavigator: useRootNavigator,
      routeSettings: routeSettings,
      pageBuilder: (dialogContext, animation, secondaryAnimation) {
        return Material(
          type: MaterialType.canvas,
          color: backgroundColor ?? Theme.of(dialogContext).colorScheme.surface,
          child: SizedBox.expand(child: builder(dialogContext)),
        );
      },
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        return FadeTransition(opacity: animation, child: child);
      },
    );
  }

  final NavigatorState navigator = Navigator.of(
    context,
    rootNavigator: useRootNavigator,
  );
  final CapturedThemes themes = InheritedTheme.capture(
    from: context,
    to: navigator.context,
  );

  Widget wrapForPresentation(BuildContext dialogContext) {
    final content = builder(dialogContext);
    if (presentation != TpDialogPresentation.page) {
      return content;
    }
    // Page canvases use [ColorScheme.surface] (live) so dual-pane hosts
    // can paint a quieter nav rail on top — same default as narrow
    // fullscreen Material. Card [TpDialog]s keep surfaceContainer.
    final pageSurface =
        backgroundColor ?? Theme.of(dialogContext).colorScheme.surface;
    return TpDialog(
      maxWidth: maxWidth ?? kTpDialogPageWideMaxWidth,
      maxHeight: maxHeight ?? kTpDialogPageWideMaxHeight,
      contentPadding: EdgeInsets.zero,
      backgroundColor: pageSurface,
      child: content,
    );
  }

  if (!escapeEnabled) {
    // Framework semantics only: Escape is coupled with the barrier, so plain
    // showDialog keeps exact legacy behavior.
    return showDialog<T>(
      context: context,
      barrierDismissible: barrierDismissible,
      barrierColor: barrierColor,
      useRootNavigator: useRootNavigator,
      routeSettings: routeSettings,
      builder: wrapForPresentation,
    );
  }

  // Escape enabled: push the DialogRoute directly so the Escape→pop handler
  // can be attached to the route's own focus scope node. That node is the
  // ancestor of every focusable widget inside the dialog (and receives key
  // events even when nothing in the dialog was focused), while sitting below
  // the framework's route-level DismissAction and above any nested Escape
  // claimants — so menus and popovers inside the dialog keep priority.

  return showRawDialog<T>(
    context: context,
    useRootNavigator: useRootNavigator,
    routeSettings: routeSettings,
    builder: (dialogContext) =>
        _RouteEscapeScope(child: wrapForPresentation(dialogContext)),
    routeBuilder: (routeContext, contentBuilder) {
      return DialogRoute<T>(
        context: routeContext,
        builder: contentBuilder,
        barrierColor:
            barrierColor ??
            Theme.of(context).dialogTheme.barrierColor ??
            Colors.black54,
        barrierDismissible: barrierDismissible,
        barrierLabel: MaterialLocalizations.of(
          context,
        ).modalBarrierDismissLabel,
        settings: routeSettings,
        themes: themes,
        traversalEdgeBehavior: TraversalEdgeBehavior.closedLoop,
      );
    },
  );
}

/// Mounts an Escape→pop handler on the enclosing route's focus scope node.
///
/// That node is the ancestor of every focusable widget inside the dialog and
/// receives key events even when nothing in the dialog was focused (the
/// framework gives the pushed route's scope focus), while sitting below the
/// framework's route-level DismissAction and above any nested Escape
/// claimants — so menus and popovers inside the dialog keep priority.
class _RouteEscapeScope extends StatefulWidget {
  const _RouteEscapeScope({required this.child});

  final Widget child;

  @override
  State<_RouteEscapeScope> createState() => _RouteEscapeScopeState();
}

class _RouteEscapeScopeState extends State<_RouteEscapeScope> {
  bool _popped = false;

  KeyEventResult _handleKey(FocusNode node, KeyEvent event) {
    if (event is KeyDownEvent &&
        event.logicalKey == LogicalKeyboardKey.escape &&
        !_popped) {
      final route = ModalRoute.of(context);
      if (route != null && route.isCurrent) {
        _popped = true;
        Navigator.of(context).pop();
        return KeyEventResult.handled;
      }
    }
    return KeyEventResult.ignored;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final scope = FocusScope.of(context);
    if (scope.onKeyEvent != _handleKey) {
      scope.onKeyEvent = _handleKey;
    }
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
