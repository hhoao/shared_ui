import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../theme/tp_text_styles.dart';
import '../../theme/tp_theme.dart';
import '../icon_button/tp_icon_button.dart';
import '../popover/tp_popover.dart';
import 'tp_action_menu_overlay.dart';
import 'tp_context_menu_position.dart';

part 'tp_action_menu_show.dart';

/// Popover-backed menu controller (replaces [MenuAnchor]'s [MenuController]).
class TpActionMenuController {
  TpActionMenuController(this._inner);

  final TpPopoverController _inner;

  bool get isOpen => _inner.isOpen;

  void open() => _inner.show();

  void close() => _inner.hide();
}

Duration _popUpTransitionDuration(AnimationStyle? style) {
  return style?.duration ?? const Duration(milliseconds: 160);
}

Curve _popUpTransitionCurve(AnimationStyle? style) {
  return style?.curve ?? Curves.easeOutCubic;
}

/// AppFlowy-inspired action menu: rounded panel, icon rows, hover highlight,
/// optional dividers. Overlay uses [TpPopover] (portal, ~160ms scale/fade).
abstract final class TpActionMenuMetrics {
  static const double minWidth = 160;

  /// Legacy [MenuAnchor] allowed the panel to grow up to min × 2.
  static double maxWidthFor(double minWidth) => minWidth * 2;

  static BoxConstraints panelConstraints({
    double minWidth = TpActionMenuMetrics.minWidth,
    double? maxWidth,
  }) {
    return BoxConstraints(
      minWidth: minWidth,
      maxWidth: maxWidth ?? maxWidthFor(minWidth),
    );
  }

  static const double itemHeight = 34;
  static const int searchThreshold = 10;
  static const double itemHorizontalMargin = 6;
  static const double itemPaddingLeft = 6;
  static const double itemPaddingRight = 6;
  static double iconSize(BuildContext context) => context.tpIconSizes.md;
  static const double iconGap = 10;
  static const double panelPaddingTop = 12;
  static const double panelPaddingHorizontal = 8;
  static const double panelPaddingBottom = 12;
  static const double dividerVerticalPadding = 8;
  static const double itemGap = 4;
  static const BorderRadius panelRadius = BorderRadius.all(Radius.circular(8));

  static EdgeInsets get panelPadding => const EdgeInsets.fromLTRB(
    panelPaddingHorizontal,
    panelPaddingTop,
    panelPaddingHorizontal,
    panelPaddingBottom,
  );

  static BoxDecoration panelDecoration(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return BoxDecoration(
      color: cs.surfaceContainer,
      borderRadius: panelRadius,
      border: Border.all(color: cs.outlineVariant),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: isDark ? 0.42 : 0.1),
          blurRadius: 20,
          offset: const Offset(0, 8),
        ),
      ],
    );
  }
}

bool _tpActionMenuChildUsesItemGap(Widget child) =>
    child is! TpActionMenuDivider;

List<Widget> _interleaveTpActionMenuItemGap(List<Widget> children) {
  if (children.length < 2) return children;
  final spaced = <Widget>[];
  for (var i = 0; i < children.length; i++) {
    spaced.add(children[i]);
    if (i < children.length - 1 &&
        _tpActionMenuChildUsesItemGap(children[i]) &&
        _tpActionMenuChildUsesItemGap(children[i + 1])) {
      spaced.add(const SizedBox(height: TpActionMenuMetrics.itemGap));
    }
  }
  return spaced;
}

/// Panel container (background, padding, min width).
class TpActionMenuPanel extends StatelessWidget {
  const TpActionMenuPanel({
    super.key,
    required this.children,
    this.minWidth = TpActionMenuMetrics.minWidth,
    this.maxWidth,
    this.menuAnchorShell = false,
  });

  final List<Widget> children;
  final double minWidth;
  final double? maxWidth;

  /// When true, border and shadow come from the popover [decoration].
  final bool menuAnchorShell;

  @override
  Widget build(BuildContext context) {
    final content = IntrinsicWidth(
      child: ConstrainedBox(
        constraints: TpActionMenuMetrics.panelConstraints(
          minWidth: minWidth,
          maxWidth: maxWidth,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: _interleaveTpActionMenuItemGap(children),
        ),
      ),
    );
    // Popover shell ([TpPopover]) already applies [panelPadding].
    if (menuAnchorShell) return content;
    return DecoratedBox(
      decoration: TpActionMenuMetrics.panelDecoration(context),
      child: Padding(padding: TpActionMenuMetrics.panelPadding, child: content),
    );
  }
}

/// Horizontal rule between action groups.
class TpActionMenuDivider extends StatelessWidget {
  const TpActionMenuDivider({super.key});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(
        vertical: TpActionMenuMetrics.dividerVerticalPadding,
      ),
      child: Divider(height: 1, thickness: 1, color: cs.outlineVariant),
    );
  }
}

/// Single menu row with instant hover (no route animation).
class TpActionMenuItem extends StatefulWidget {
  const TpActionMenuItem({
    super.key,
    this.icon,
    this.iconWidget,
    required this.label,
    this.subtitle,
    this.subtitleSuffix,
    this.trailing,
    this.onTap,
    this.destructive = false,
    this.enabled = true,
    this.highlighted = false,
    this.menuController,
    this.tooltip,
  });

  final IconData? icon;
  final Widget? iconWidget;
  final String label;
  final Widget? subtitle;

  /// Muted suffix on the same line as [label] (e.g. machine name).
  final String? subtitleSuffix;
  final Widget? trailing;
  final VoidCallback? onTap;
  final bool destructive;
  final bool enabled;
  final bool highlighted;
  final TpActionMenuController? menuController;
  final String? tooltip;

  @override
  State<TpActionMenuItem> createState() => _TpActionMenuItemState();
}

class _TpActionMenuItemState extends State<TpActionMenuItem> {
  var _hovered = false;

  void _handleTap() {
    if (!widget.enabled || widget.onTap == null) return;
    widget.onTap!();
    widget.menuController?.close();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final styles = TpTextStyles.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final hoverFill = isDark
        ? Colors.white.withValues(alpha: 0.08)
        : Colors.black.withValues(alpha: 0.05);

    // Match theme bodyMedium color/weight (not dropdownFieldTextStyle's w500).
    final baseFg = widget.destructive
        ? cs.error
        : (styles.md.color ?? cs.onSurface);
    final fg = baseFg.withValues(alpha: widget.enabled ? 1 : 0.35);
    final labelStyle = styles.mdSnugColored(fg);
    final suffixStyle = styles.mdSnugColored(
      fg.withValues(alpha: widget.enabled ? 0.45 : 0.35),
    );

    Widget row = Shortcuts(
      shortcuts: const {
        SingleActivator(LogicalKeyboardKey.enter): ActivateIntent(),
        SingleActivator(LogicalKeyboardKey.space): ActivateIntent(),
      },
      child: Actions(
        actions: {
          ActivateIntent: CallbackAction<ActivateIntent>(
            onInvoke: (_) {
              widget.onTap?.call();
              return null;
            },
          ),
        },
        child: Focus(
          child: MouseRegion(
            onEnter: (_) => setState(() => _hovered = true),
            onExit: (_) => setState(() => _hovered = false),
            cursor: widget.enabled && widget.onTap != null
                ? SystemMouseCursors.click
                : SystemMouseCursors.basic,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: widget.enabled ? _handleTap : null,
              child: Container(
                constraints: const BoxConstraints(
                  minHeight: TpActionMenuMetrics.itemHeight,
                ),
                margin: const EdgeInsets.symmetric(
                  horizontal: TpActionMenuMetrics.itemHorizontalMargin,
                ),
                padding: const EdgeInsets.only(
                  left: TpActionMenuMetrics.itemPaddingLeft,
                  right: TpActionMenuMetrics.itemPaddingRight,
                ),
                decoration: BoxDecoration(
                  color:
                      (_hovered || widget.highlighted) &&
                          widget.enabled &&
                          widget.onTap != null
                      ? hoverFill
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.max,
                  children: [
                    if (widget.icon != null || widget.iconWidget != null) ...[
                      SizedBox(
                        width: TpActionMenuMetrics.iconSize(context),
                        height: TpActionMenuMetrics.iconSize(context),
                        child: Center(
                          child:
                              widget.iconWidget ??
                              Icon(
                                widget.icon,
                                size: TpActionMenuMetrics.iconSize(context),
                                color: fg,
                              ),
                        ),
                      ),
                      SizedBox(width: TpActionMenuMetrics.iconGap),
                    ],
                    Flexible(
                      fit: FlexFit.loose,
                      child: widget.subtitleSuffix != null
                          ? Row(
                              children: [
                                Flexible(
                                  child: Text(
                                    widget.label,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    softWrap: false,
                                    style: labelStyle,
                                  ),
                                ),
                                SizedBox(width: context.tpSpacing.lg),
                                Text(
                                  widget.subtitleSuffix!,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  softWrap: false,
                                  style: suffixStyle,
                                ),
                              ],
                            )
                          : Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  widget.label,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  softWrap: false,
                                  style: labelStyle,
                                ),
                                if (widget.subtitle != null) widget.subtitle!,
                              ],
                            ),
                    ),
                    if (widget.trailing != null) ...[
                      const SizedBox(width: 8),
                      widget.trailing!,
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );

    if (widget.tooltip != null && widget.tooltip!.isNotEmpty) {
      row = Tooltip(message: widget.tooltip!, child: row);
    }

    return row;
  }
}

/// Popover anchor for custom panel content (notifications, hover menus, etc.).
class TpActionMenuAnchor extends StatefulWidget {
  const TpActionMenuAnchor({
    super.key,
    required this.child,
    required this.popoverBuilder,
    this.controller,
    this.anchor,
    this.onOpen,
    this.onClose,
    this.minWidth,
    this.maxWidth,
    this.fixedPanelWidth,
    this.padding,
    this.closeOnTapOutside = true,
  });

  final Widget child;
  final Widget Function(BuildContext context, TpActionMenuController controller)
  popoverBuilder;
  final TpPopoverController? controller;
  final TpAnchorBase? anchor;
  final VoidCallback? onOpen;
  final VoidCallback? onClose;
  final double? minWidth;
  final double? maxWidth;

  /// When set, the popover panel is exactly this wide (e.g. notification dropdown).
  final double? fixedPanelWidth;
  final EdgeInsetsGeometry? padding;
  final bool closeOnTapOutside;

  @override
  State<TpActionMenuAnchor> createState() => _TpActionMenuAnchorState();
}

class _TpActionMenuAnchorState extends State<TpActionMenuAnchor> {
  TpPopoverController? _ownedController;

  TpPopoverController get _popoverController =>
      widget.controller ?? _ownedController!;

  @override
  void initState() {
    super.initState();
    _ownedController = widget.controller == null ? TpPopoverController() : null;
    _popoverController.addListener(_onPopoverChanged);
  }

  @override
  void didUpdateWidget(covariant TpActionMenuAnchor oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      (oldWidget.controller ?? _ownedController)?.removeListener(
        _onPopoverChanged,
      );
      if (oldWidget.controller == null && widget.controller != null) {
        _ownedController?.dispose();
        _ownedController = null;
      }
      if (widget.controller == null && _ownedController == null) {
        _ownedController = TpPopoverController();
      }
      _popoverController.addListener(_onPopoverChanged);
    }
  }

  @override
  void dispose() {
    _popoverController.removeListener(_onPopoverChanged);
    _ownedController?.dispose();
    super.dispose();
  }

  void _onPopoverChanged() {
    if (_popoverController.isOpen) {
      widget.onOpen?.call();
    } else {
      widget.onClose?.call();
    }
  }

  TpActionMenuController get _menuController =>
      TpActionMenuController(_popoverController);

  @override
  Widget build(BuildContext context) {
    final panelMin = widget.minWidth ?? TpActionMenuMetrics.minWidth;
    return TpPopover(
      controller: _popoverController,
      closeOnTapOutside: widget.closeOnTapOutside,
      anchor:
          widget.anchor ??
          const TpAnchor(
            childAlignment: Alignment.topLeft,
            overlayAlignment: Alignment.bottomLeft,
            offset: Offset(0, 4),
          ),
      decoration: TpActionMenuMetrics.panelDecoration(context),
      panelWidth: widget.fixedPanelWidth,
      padding: widget.padding ?? TpActionMenuMetrics.panelPadding,
      popover: (ctx) {
        final panel = widget.popoverBuilder(ctx, _menuController);
        if (widget.fixedPanelWidth != null) return panel;
        return IntrinsicWidth(
          child: ConstrainedBox(
            constraints: TpActionMenuMetrics.panelConstraints(
              minWidth: panelMin,
              maxWidth: widget.maxWidth,
            ),
            child: panel,
          ),
        );
      },
      child: widget.child,
    );
  }
}

/// Icon button that opens an [TpPopover] action menu.
class TpActionMenuIconAnchor extends StatefulWidget {
  const TpActionMenuIconAnchor({
    super.key,
    this.icon,
    this.triggerBuilder,
    required this.buildMenuChildren,
    this.onOpen,
    this.onClose,
    this.size = TpIconButton.kDefaultSize,
    this.minWidth = TpActionMenuMetrics.minWidth,
    this.anchor,
  }) : assert(icon != null || triggerBuilder != null);

  final Widget? icon;
  final Widget Function(
    BuildContext context,
    TpActionMenuController controller,
  )?
  triggerBuilder;
  final List<Widget> Function(
    BuildContext context,
    TpActionMenuController controller,
  )
  buildMenuChildren;
  final VoidCallback? onOpen;
  final VoidCallback? onClose;
  final double size;
  final double minWidth;
  final TpAnchorBase? anchor;

  @override
  State<TpActionMenuIconAnchor> createState() => _TpActionMenuIconAnchorState();
}

class _TpActionMenuIconAnchorState extends State<TpActionMenuIconAnchor> {
  final _popoverController = TpPopoverController();

  @override
  void initState() {
    super.initState();
    _popoverController.addListener(_onPopoverChanged);
  }

  @override
  void dispose() {
    _popoverController.removeListener(_onPopoverChanged);
    _popoverController.dispose();
    super.dispose();
  }

  void _onPopoverChanged() {
    if (_popoverController.isOpen) {
      widget.onOpen?.call();
    } else {
      widget.onClose?.call();
    }
  }

  TpActionMenuController get _menuController =>
      TpActionMenuController(_popoverController);

  @override
  Widget build(BuildContext context) {
    final menuController = _menuController;
    return TpPopover(
      controller: _popoverController,
      anchor:
          widget.anchor ??
          const TpAnchor(
            childAlignment: Alignment.topLeft,
            overlayAlignment: Alignment.bottomLeft,
            offset: Offset(0, 4),
          ),
      decoration: TpActionMenuMetrics.panelDecoration(context),
      padding: TpActionMenuMetrics.panelPadding,
      popover: (ctx) => TpActionMenuPanel(
        minWidth: widget.minWidth,
        menuAnchorShell: true,
        children: widget.buildMenuChildren(ctx, menuController),
      ),
      child: widget.triggerBuilder != null
          ? widget.triggerBuilder!(context, menuController)
          : TpIconButton(
              iconWidget: widget.icon,
              size: widget.size,
              onTap: _popoverController.toggle,
            ),
    );
  }
}

int tpActionMenuSpecGapCount(List<TpActionMenuSpec> specs) {
  var gaps = 0;
  var previousWasItem = false;
  for (final spec in specs) {
    if (spec.isDivider) {
      previousWasItem = false;
      continue;
    }
    if (previousWasItem) gaps++;
    previousWasItem = true;
  }
  return gaps;
}

double estimateTpActionMenuHeight({
  required int itemCount,
  int dividerCount = 0,
  int itemGapCount = 0,
}) {
  final gaps = itemGapCount > 0
      ? itemGapCount
      : (itemCount > 1 ? itemCount - 1 : 0);
  return TpActionMenuMetrics.panelPaddingTop +
      TpActionMenuMetrics.panelPaddingBottom +
      itemCount * TpActionMenuMetrics.itemHeight +
      gaps * TpActionMenuMetrics.itemGap +
      dividerCount * (TpActionMenuMetrics.dividerVerticalPadding * 2 + 1);
}

/// Tracks which sibling submenu is open within one panel level.
/// A fresh coordinator is created per [buildTpActionMenuChildren] invocation,
/// giving each panel level its own mutually-exclusive open slot.
class TpActionMenuSubmenuCoordinator extends ChangeNotifier {
  Object? _openId;
  FocusNode? _handedOffCapture;

  Object? get openId => _openId;

  void open(Object id) {
    if (_openId == id) return;
    _openId = id;
    notifyListeners();
  }

  void close(Object id) {
    if (_openId != id) return;
    _openId = null;
    notifyListeners();
  }

  void stashHandedOffCapture(FocusNode? node) {
    _handedOffCapture = node;
  }

  FocusNode? takeHandedOffCapture() {
    final node = _handedOffCapture;
    _handedOffCapture = null;
    return node;
  }
}

class TpActionMenuSpec {
  const TpActionMenuSpec.divider()
    : isDivider = true,
      value = null,
      icon = null,
      iconWidget = null,
      label = null,
      subtitle = null,
      subtitleSuffix = null,
      trailing = null,
      destructive = false,
      enabled = true,
      selected = false,
      onAction = null,
      tooltip = null,
      children = null,
      searchable = false,
      onOpen = null,
      scrollChildren = null,
      maxHeight = null;

  const TpActionMenuSpec.item({
    this.value,
    this.icon,
    this.iconWidget,
    required this.label,
    this.subtitle,
    this.subtitleSuffix,
    this.trailing,
    this.destructive = false,
    this.enabled = true,
    this.selected = false,
    this.onAction,
    this.tooltip,
  }) : isDivider = false,
       children = null,
       searchable = false,
       onOpen = null,
       scrollChildren = null,
       maxHeight = null;

  const TpActionMenuSpec.submenu({
    this.value,
    this.icon,
    this.iconWidget,
    required this.label,
    this.subtitle,
    this.selected = false,
    this.enabled = true,
    this.searchable = false,
    required this.children,
    this.onOpen,
  }) : isDivider = false,
       subtitleSuffix = null,
       trailing = null,
       destructive = false,
       onAction = null,
       tooltip = null,
       scrollChildren = null,
       maxHeight = null;

  /// A group of rows rendered as a fixed-height scrollable block within a menu.
  const TpActionMenuSpec.scroll({
    required List<TpActionMenuSpec> children,
    this.maxHeight,
  }) : isDivider = false,
       value = null,
       icon = null,
       iconWidget = null,
       label = null,
       subtitle = null,
       subtitleSuffix = null,
       trailing = null,
       destructive = false,
       enabled = true,
       selected = false,
       onAction = null,
       tooltip = null,
       children = null,
       searchable = false,
       onOpen = null,
       scrollChildren = children;

  final bool isDivider;
  final Object? value;
  final IconData? icon;
  final Widget? iconWidget;
  final String? label;
  final Widget? subtitle;
  final String? subtitleSuffix;
  final Widget? trailing;
  final bool destructive;
  final bool enabled;
  final bool selected;
  final VoidCallback? onAction;
  final String? tooltip;

  /// Non-null for [TpActionMenuSpec.submenu].
  final List<TpActionMenuSpec>? children;
  final bool searchable;
  final VoidCallback? onOpen;

  /// Non-null for [TpActionMenuSpec.scroll].
  final List<TpActionMenuSpec>? scrollChildren;
  final double? maxHeight;

  bool get isSubmenu => !isDivider && children != null;
  bool get isScrollBlock => !isDivider && scrollChildren != null;
}

int tpActionMenuSpecItemCount(List<TpActionMenuSpec> specs) =>
    specs.where((s) => !s.isDivider).length;

int tpActionMenuSpecDividerCount(List<TpActionMenuSpec> specs) =>
    specs.where((s) => s.isDivider).length;

List<Widget> buildTpActionMenuChildren({
  required BuildContext context,
  required List<TpActionMenuSpec> specs,
  required TpActionMenuController menuController,
  required ValueChanged<Object?> onSelect,
}) {
  final coordinator = TpActionMenuSubmenuCoordinator();
  return [
    for (var i = 0; i < specs.length; i++)
      if (specs[i].isDivider)
        const TpActionMenuDivider()
      else if (specs[i].isScrollBlock)
        _TpActionMenuScrollBlock(
          spec: specs[i],
          menuController: menuController,
          onSelect: onSelect,
        )
      else if (specs[i].isSubmenu)
        TpActionMenuSubmenuItem(
          id: i,
          spec: specs[i],
          coordinator: coordinator,
          rootMenuController: menuController,
          onSelect: onSelect,
        )
      else
        _specToMenuItem(
          context: context,
          spec: specs[i],
          menuController: menuController,
          onSelect: onSelect,
        ),
  ];
}

/// A group of rows confined to a fixed max-height and scrolled when long
/// (used e.g. for a capped presets list so the rest of the menu stays short).
class _TpActionMenuScrollBlock extends StatelessWidget {
  const _TpActionMenuScrollBlock({
    required this.spec,
    required this.menuController,
    required this.onSelect,
  });

  final TpActionMenuSpec spec;
  final TpActionMenuController menuController;
  final ValueChanged<Object?> onSelect;

  @override
  Widget build(BuildContext context) {
    final maxHeight =
        spec.maxHeight ?? MediaQuery.sizeOf(context).height * 0.5;
    return ConstrainedBox(
      constraints: BoxConstraints(maxHeight: maxHeight),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: buildTpActionMenuChildren(
            context: context,
            specs: spec.scrollChildren!,
            menuController: menuController,
            onSelect: onSelect,
          ),
        ),
      ),
    );
  }
}

class _TpActionMenuSubmenuPanel extends StatefulWidget {
  const _TpActionMenuSubmenuPanel({
    required this.children,
    required this.searchable,
    required this.rootMenuController,
    required this.onSelect,
    required this.onDismiss,
    required this.panelScope,
    this.autofocusFirstRow = false,
  });

  final List<TpActionMenuSpec> children;
  final bool searchable;
  final TpActionMenuController rootMenuController;
  final ValueChanged<Object?> onSelect;
  final VoidCallback onDismiss;
  final FocusScopeNode panelScope;
  final bool autofocusFirstRow;

  @override
  State<_TpActionMenuSubmenuPanel> createState() =>
      _TpActionMenuSubmenuPanelState();
}

class _TpActionMenuSubmenuPanelState extends State<_TpActionMenuSubmenuPanel> {
  final _searchFocus = FocusNode(debugLabel: 'tp-submenu-search');
  String _query = '';

  bool get _showsSearchField =>
      widget.searchable &&
      widget.children.length > TpActionMenuMetrics.searchThreshold;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (_showsSearchField) {
        if (widget.autofocusFirstRow) _searchFocus.requestFocus();
        return;
      }
      final scope = widget.panelScope;
      if (widget.autofocusFirstRow) {
        final descendants = scope.traversalDescendants.toList(growable: false);
        if (descendants.isNotEmpty) {
          descendants.first.requestFocus();
          return;
        }
      }
      scope.requestFocus();
    });
  }

  @override
  void dispose() {
    _searchFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final needle = _query.trim().toLowerCase();
    final visible = needle.isEmpty
        ? widget.children
        : widget.children
              .where((s) => (s.label ?? '').toLowerCase().contains(needle))
              .toList(growable: false);
    final showSearch =
        widget.searchable &&
        widget.children.length > TpActionMenuMetrics.searchThreshold;
    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.escape): widget.onDismiss,
        if (!_showsSearchField)
          const SingleActivator(LogicalKeyboardKey.arrowLeft): widget.onDismiss,
      },
      child: FocusScope(
        node: widget.panelScope,
        child: IntrinsicWidth(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.sizeOf(context).height * 0.6,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (showSearch) ...[
                  Padding(
                    padding: const EdgeInsets.fromLTRB(6, 0, 6, 4),
                    child: TextField(
                      focusNode: _searchFocus,
                      autofocus: true,
                      onChanged: (v) => setState(() => _query = v),
                      style: TpTextStyles.of(context).md,
                      decoration: InputDecoration(
                        isDense: true,
                        prefixIcon: Icon(
                          Icons.search,
                          size: TpActionMenuMetrics.iconSize(context),
                        ),
                        border: const OutlineInputBorder(),
                      ),
                    ),
                  ),
                  const TpActionMenuDivider(),
                ],
                Flexible(
                  child: SingleChildScrollView(
                    child: FocusTraversalGroup(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: visible.isEmpty
                            ? [const SizedBox(height: 4)]
                            : buildTpActionMenuChildren(
                                context: context,
                                specs: visible,
                                menuController: widget.rootMenuController,
                                onSelect: widget.onSelect,
                              ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class TpActionMenuSubmenuItem extends StatefulWidget {
  const TpActionMenuSubmenuItem({
    super.key,
    required this.id,
    required this.spec,
    required this.coordinator,
    required this.rootMenuController,
    required this.onSelect,
  });

  final int id;
  final TpActionMenuSpec spec;
  final TpActionMenuSubmenuCoordinator coordinator;
  final TpActionMenuController rootMenuController;
  final ValueChanged<Object?> onSelect;

  @override
  State<TpActionMenuSubmenuItem> createState() =>
      _TpActionMenuSubmenuItemState();
}

class _TpActionMenuSubmenuItemState extends State<TpActionMenuSubmenuItem> {
  final _popover = TpPopoverController();
  final _rowFocus = FocusNode(debugLabel: 'tp-submenu-row');
  final _panelScope = FocusScopeNode(debugLabel: 'tp-submenu-panel-scope');
  Timer? _hoverTimer;
  bool _focusPanelNextFrame = false;
  FocusNode? _capturedFocus;

  static const _hoverIntentDelay = Duration(milliseconds: 150);

  @override
  void initState() {
    super.initState();
    widget.coordinator.addListener(_syncWithCoordinator);
    _popover.addListener(_onPopoverStateChanged);
  }

  void _onPopoverStateChanged() {
    if (mounted) setState(() {});
  }

  @override
  void didUpdateWidget(covariant TpActionMenuSubmenuItem oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.coordinator != widget.coordinator) {
      oldWidget.coordinator.removeListener(_syncWithCoordinator);
      widget.coordinator.addListener(_syncWithCoordinator);
    }
  }

  @override
  void dispose() {
    _hoverTimer?.cancel();
    _popover.removeListener(_onPopoverStateChanged);
    widget.coordinator.removeListener(_syncWithCoordinator);
    _capturedFocus = null;
    _rowFocus.dispose();
    _panelScope.dispose();
    super.dispose();
  }

  void _syncWithCoordinator() {
    if (widget.coordinator.openId != widget.id && _popover.isOpen) {
      _focusPanelNextFrame = false;
      widget.coordinator.stashHandedOffCapture(_capturedFocus);
      _capturedFocus = null;
      _popover.hide();
    }
  }

  bool get _isOpen => _popover.isOpen;

  void _openNow({bool focusPanel = false}) {
    if (_isOpen) return;
    setState(() => _focusPanelNextFrame = focusPanel);
    widget.coordinator.open(widget.id);
    widget.spec.onOpen?.call();
    _capturedFocus =
        widget.coordinator.takeHandedOffCapture() ?? _liveCaptureCandidate();
    _popover.show();
  }

  FocusNode? _liveCaptureCandidate() {
    final current = FocusManager.instance.primaryFocus;
    if (current == null || current == FocusManager.instance.rootScope) {
      return null;
    }
    for (
      FocusNode? scope = _rowFocus.enclosingScope;
      scope != null;
      scope = scope.enclosingScope
    ) {
      if (identical(scope, current)) {
        return null;
      }
    }
    return current;
  }

  bool _focusIsOwnedByOpenPanel(FocusNode current) {
    if (identical(current, FocusManager.instance.rootScope)) return true;
    return identical(current, _panelScope) ||
        identical(current, _rowFocus) ||
        current.ancestors.contains(_panelScope);
  }

  bool _restoreCapturedFocusIfOwned() {
    final captured = _capturedFocus;
    _capturedFocus = null;
    if (captured == null ||
        !captured.canRequestFocus ||
        captured.context == null) {
      return false;
    }
    final current = FocusManager.instance.primaryFocus;
    if (current != null && !_focusIsOwnedByOpenPanel(current)) {
      return false;
    }
    captured.requestFocus();
    return true;
  }

  void _openViaKeyboard() {
    _openNow(focusPanel: true);
  }

  void _dismissViaKeyboard() {
    _focusPanelNextFrame = false;
    if (!_restoreCapturedFocusIfOwned()) {
      _rowFocus.requestFocus();
    }
    widget.coordinator.close(widget.id);
  }

  void _toggle() {
    if (_isOpen) {
      _focusPanelNextFrame = false;
      _restoreCapturedFocusIfOwned();
      widget.coordinator.close(widget.id);
    } else {
      _openNow();
    }
  }

  static Widget _submenuTrailing(BuildContext context, TpActionMenuSpec spec) {
    final chevron = Icon(
      Icons.chevron_right_rounded,
      size: TpActionMenuMetrics.iconSize(context),
      color: TpTextStyles.of(context).md.color?.withValues(alpha: 0.45),
    );
    if (!spec.selected) return chevron;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          Icons.check,
          size: TpActionMenuMetrics.iconSize(context),
          color:
              (TpTextStyles.of(context).md.color ??
                      Theme.of(context).colorScheme.onSurface)
                  .withValues(alpha: 0.7),
        ),
        const SizedBox(width: 4),
        chevron,
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final spec = widget.spec;
    return TpPopover(
      controller: _popover,
      padding: TpActionMenuMetrics.panelPadding,
      decoration: TpActionMenuMetrics.panelDecoration(context),
      anchor: const TpAnchor(
        childAlignment: Alignment.topLeft,
        overlayAlignment: Alignment.centerRight,
        offset: Offset(-4, 0),
      ),
      popover: (ctx) => _TpActionMenuSubmenuPanel(
        children: spec.children!,
        searchable: spec.searchable,
        rootMenuController: widget.rootMenuController,
        onSelect: widget.onSelect,
        onDismiss: _dismissViaKeyboard,
        panelScope: _panelScope,
        autofocusFirstRow: _focusPanelNextFrame,
      ),
      child: CallbackShortcuts(
        bindings: {
          const SingleActivator(LogicalKeyboardKey.arrowRight): spec.enabled
              ? _openViaKeyboard
              : () {},
        },
        child: Focus(
          focusNode: _rowFocus,
          child: MouseRegion(
            onEnter: (_) {
              if (!spec.enabled) return;
              _hoverTimer?.cancel();
              _hoverTimer = Timer(_hoverIntentDelay, _openNow);
            },
            onExit: (_) => _hoverTimer?.cancel(),
            child: TpActionMenuItem(
              icon: spec.icon,
              iconWidget: spec.iconWidget,
              label: spec.label ?? '',
              subtitle: spec.subtitle,
              enabled: spec.enabled,
              highlighted: _popover.isOpen,
              onTap: spec.enabled ? _toggle : null,
              trailing: _submenuTrailing(context, spec),
            ),
          ),
        ),
      ),
    );
  }
}

Widget _specToMenuItem({
  required BuildContext context,
  required TpActionMenuSpec spec,
  TpActionMenuController? menuController,
  ValueChanged<Object?>? onSelect,
  void Function(Object? value)? onChosen,
}) {
  final trailing = spec.selected
      ? Icon(
          Icons.check,
          size: context.tpIconSizes.md,
          color:
              (TpTextStyles.of(context).md.color ??
                      Theme.of(context).colorScheme.onSurface)
                  .withValues(alpha: 0.7),
        )
      : spec.trailing;

  VoidCallback? onTap;
  if (spec.enabled) {
    onTap = () {
      spec.onAction?.call();
      onChosen?.call(spec.value);
      onSelect?.call(spec.value);
      menuController?.close();
    };
  }

  return TpActionMenuItem(
    icon: spec.icon,
    iconWidget: spec.iconWidget,
    label: spec.label ?? '',
    subtitle: spec.subtitle,
    subtitleSuffix: spec.subtitleSuffix,
    trailing: trailing,
    destructive: spec.destructive,
    enabled: spec.enabled,
    tooltip: spec.tooltip,
    menuController: menuController,
    onTap: onTap,
  );
}

class TpActionMenuButton extends StatelessWidget {
  const TpActionMenuButton({
    super.key,
    required this.specs,
    required this.onSelected,
    this.icon,
    this.triggerBuilder,
    this.onOpen,
    this.onClose,
    this.size = TpIconButton.kDefaultSize,
    this.minWidth = TpActionMenuMetrics.minWidth,
    this.tooltip,
  });

  final List<TpActionMenuSpec> specs;
  final ValueChanged<Object?> onSelected;
  final Widget? icon;
  final Widget Function(
    BuildContext context,
    TpActionMenuController controller,
  )?
  triggerBuilder;
  final VoidCallback? onOpen;
  final VoidCallback? onClose;
  final double size;
  final double minWidth;
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    final anchor = TpActionMenuIconAnchor(
      icon: triggerBuilder == null
          ? (icon ?? Icon(Icons.more_horiz, size: context.tpIconSizes.md))
          : null,
      triggerBuilder: triggerBuilder,
      size: size,
      minWidth: minWidth,
      onOpen: onOpen,
      onClose: onClose,
      buildMenuChildren: (context, controller) => buildTpActionMenuChildren(
        context: context,
        specs: specs,
        menuController: controller,
        onSelect: onSelected,
      ),
    );
    if (tooltip == null || tooltip!.isEmpty) return anchor;
    return Tooltip(message: tooltip!, child: anchor);
  }
}

class _ActionMenuOverlayScope<T> extends InheritedWidget {
  const _ActionMenuOverlayScope({required this.onChosen, required super.child});

  final void Function(T? value) onChosen;

  static _ActionMenuOverlayScope<T>? maybeOf<T>(BuildContext context) {
    return context
        .dependOnInheritedWidgetOfExactType<_ActionMenuOverlayScope<T>>();
  }

  @override
  bool updateShouldNotify(_ActionMenuOverlayScope<T> oldWidget) => false;
}

class TpActionMenuPopupItem<T> extends StatelessWidget {
  const TpActionMenuPopupItem({
    super.key,
    required this.value,
    this.icon,
    this.iconWidget,
    required this.label,
    this.destructive = false,
    this.enabled = true,
    this.tooltip,
  }) : assert(icon != null || iconWidget != null);

  final T value;
  final IconData? icon;
  final Widget? iconWidget;
  final String label;
  final bool destructive;
  final bool enabled;
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    final scope = _ActionMenuOverlayScope.maybeOf<T>(context);
    return TpActionMenuItem(
      icon: icon,
      iconWidget: iconWidget,
      label: label,
      destructive: destructive,
      enabled: enabled,
      tooltip: tooltip,
      onTap: enabled ? () => scope?.onChosen(value) : null,
    );
  }
}
