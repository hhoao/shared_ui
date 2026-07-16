part of 'tp_action_menu.dart';

Future<T?> _showActionMenuFromSpecs<T>({
  required BuildContext context,
  required Offset globalPosition,
  required List<TpActionMenuSpec> specs,
  double minWidth = TpActionMenuMetrics.minWidth,
  bool useRootNavigator = true,
  AnimationStyle? popUpAnimationStyle,
}) {
  return showTpActionMenuOverlay<T>(
    context: context,
    globalPosition: globalPosition,
    useRootNavigator: useRootNavigator,
    transitionDuration: _popUpTransitionDuration(popUpAnimationStyle),
    transitionCurve: _popUpTransitionCurve(popUpAnimationStyle),
    menuBuilder: (overlayContext, complete) {
      return DecoratedBox(
        decoration: TpActionMenuMetrics.panelDecoration(overlayContext),
        child: Padding(
          padding: TpActionMenuMetrics.panelPadding,
          child: TpActionMenuPanel(
            minWidth: minWidth,
            menuAnchorShell: true,
            children: specs.map((spec) {
              if (spec.isDivider) return const TpActionMenuDivider();
              return _specToMenuItem(
                context: overlayContext,
                spec: spec,
                onChosen: (value) => complete(value as T?),
              );
            }).toList(),
          ),
        ),
      );
    },
  );
}

Future<T?> showTpActionMenuFromSpecs<T>({
  required BuildContext context,
  required Offset globalPosition,
  required List<TpActionMenuSpec> specs,
  double minWidth = TpActionMenuMetrics.minWidth,
  bool useRootNavigator = true,
  AnimationStyle? popUpAnimationStyle,
}) {
  return _showActionMenuFromSpecs<T>(
    context: context,
    globalPosition: globalPosition,
    specs: specs,
    minWidth: minWidth,
    useRootNavigator: useRootNavigator,
    popUpAnimationStyle: popUpAnimationStyle,
  );
}

Future<T?> showTpActionMenuFromSpecsAtTap<T>({
  required BuildContext context,
  required TapDownDetails tapDetails,
  required List<TpActionMenuSpec> specs,
  double minWidth = TpActionMenuMetrics.minWidth,
  bool useRootNavigator = true,
  AnimationStyle? popUpAnimationStyle,
}) {
  return showTpActionMenuFromSpecs<T>(
    context: context,
    globalPosition: contextMenuGlobalPosition(context, tapDetails),
    specs: specs,
    minWidth: minWidth,
    useRootNavigator: useRootNavigator,
    popUpAnimationStyle: popUpAnimationStyle,
  );
}

Future<T?> _showActionMenuWithChildren<T>({
  required BuildContext context,
  required Offset globalPosition,
  required List<Widget> children,
  double minWidth = TpActionMenuMetrics.minWidth,
  bool useRootNavigator = true,
  AnimationStyle? popUpAnimationStyle,
}) {
  return showTpActionMenuOverlay<T>(
    context: context,
    globalPosition: globalPosition,
    useRootNavigator: useRootNavigator,
    transitionDuration: _popUpTransitionDuration(popUpAnimationStyle),
    transitionCurve: _popUpTransitionCurve(popUpAnimationStyle),
    menuBuilder: (overlayContext, complete) {
      return _ActionMenuOverlayScope<T>(
        onChosen: complete,
        child: DecoratedBox(
          decoration: TpActionMenuMetrics.panelDecoration(overlayContext),
          child: Padding(
            padding: TpActionMenuMetrics.panelPadding,
            child: TpActionMenuPanel(
              minWidth: minWidth,
              menuAnchorShell: true,
              children: children,
            ),
          ),
        ),
      );
    },
  );
}

/// Shows an action menu at [globalPosition] with pre-built row widgets.
Future<T?> showTpActionMenu<T>({
  required BuildContext context,
  required Offset globalPosition,
  required List<Widget> children,
  double minWidth = TpActionMenuMetrics.minWidth,
  int itemCount = 4,
  int dividerCount = 0,
  int? itemGapCount,
  bool useRootNavigator = true,
  AnimationStyle? popUpAnimationStyle,
}) {
  return _showActionMenuWithChildren<T>(
    context: context,
    globalPosition: globalPosition,
    children: children,
    minWidth: minWidth,
    useRootNavigator: useRootNavigator,
    popUpAnimationStyle: popUpAnimationStyle,
  );
}

Future<T?> showTpActionMenuAtTap<T>({
  required BuildContext context,
  required TapDownDetails tapDetails,
  required List<Widget> children,
  double minWidth = TpActionMenuMetrics.minWidth,
  int itemCount = 4,
  int dividerCount = 0,
  int? itemGapCount,
  bool useRootNavigator = true,
  AnimationStyle? popUpAnimationStyle,
}) {
  return showTpActionMenu<T>(
    context: context,
    globalPosition: contextMenuGlobalPosition(context, tapDetails),
    children: children,
    minWidth: minWidth,
    useRootNavigator: useRootNavigator,
    popUpAnimationStyle: popUpAnimationStyle,
  );
}
