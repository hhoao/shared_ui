import 'dart:async';

import 'package:flutter/material.dart';

import 'tp_action_menu.dart';

/// Built-in [TpActionMenu]-backed context menu for an [EditableText] field.
///
/// Pass as [TextField.contextMenuBuilder] (or the shared `contextMenuBuilder`
/// of [TpInput]/[TpTextArea]/[TpTokenTextField]) so right-click / selection
/// actions render as the Tp action menu instead of the platform Material
/// toolbar.
Widget buildTpTextFieldContextMenu(
  BuildContext context,
  EditableTextState editableTextState,
) {
  return _TpTextSelectionContextMenu(
    items: editableTextState.contextMenuButtonItems,
    anchor: editableTextState.contextMenuAnchors.primaryAnchor,
    hideToolbar: editableTextState.hideToolbar,
  );
}

/// Built-in [TpActionMenu]-backed context menu for a [SelectionArea].
///
/// Pass as [SelectionArea.contextMenuBuilder] (SelectableRegion) so selected
/// text actions render as the Tp action menu instead of the platform toolbar.
Widget buildTpSelectionAreaContextMenu(
  BuildContext context,
  SelectableRegionState selectableRegionState,
) {
  return _TpTextSelectionContextMenu(
    items: selectableRegionState.contextMenuButtonItems,
    anchor: selectableRegionState.contextMenuAnchors.primaryAnchor,
    hideToolbar: selectableRegionState.hideToolbar,
  );
}

/// Opens the Tp action menu over the selection context items after the frame
/// in which the platform toolbar would otherwise open. The built-in toolbar is
/// intentionally not inserted — this widget is its replacement.
class _TpTextSelectionContextMenu extends StatefulWidget {
  const _TpTextSelectionContextMenu({
    required this.items,
    required this.anchor,
    required this.hideToolbar,
  });

  final List<ContextMenuButtonItem> items;
  final Offset anchor;
  final VoidCallback hideToolbar;

  @override
  State<_TpTextSelectionContextMenu> createState() =>
      _TpTextSelectionContextMenuState();
}

class _TpTextSelectionContextMenuState
    extends State<_TpTextSelectionContextMenu> {
  var _opened = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _opened) return;
      _opened = true;
      unawaited(_openMenu());
    });
  }

  Future<void> _openMenu() async {
    final items = widget.items;
    if (items.isEmpty) {
      widget.hideToolbar();
      return;
    }

    final specs = <TpActionMenuSpec>[
      for (final item in items)
        TpActionMenuSpec.item(
          icon: _contextMenuIconFor(item.type),
          label: item.label ?? _contextMenuFallbackLabel(context, item.type),
          onAction: () => item.onPressed?.call(),
        ),
    ];

    await showTpActionMenuFromSpecs<void>(
      context: context,
      globalPosition: widget.anchor,
      specs: specs,
    );
    if (!mounted) return;
    widget.hideToolbar();
  }

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}

IconData _contextMenuIconFor(ContextMenuButtonType type) {
  return switch (type) {
    ContextMenuButtonType.copy => Icons.content_copy,
    ContextMenuButtonType.cut => Icons.content_cut,
    ContextMenuButtonType.paste => Icons.content_paste,
    ContextMenuButtonType.selectAll => Icons.select_all,
    ContextMenuButtonType.delete => Icons.delete_outline,
    ContextMenuButtonType.lookUp => Icons.menu_book_outlined,
    ContextMenuButtonType.searchWeb => Icons.search,
    ContextMenuButtonType.share => Icons.share_outlined,
    ContextMenuButtonType.liveTextInput => Icons.text_fields,
    ContextMenuButtonType.custom => Icons.more_horiz,
  };
}

String _contextMenuFallbackLabel(BuildContext context, ContextMenuButtonType type) {
  final mloc = MaterialLocalizations.of(context);
  return switch (type) {
    ContextMenuButtonType.copy => mloc.copyButtonLabel,
    ContextMenuButtonType.cut => mloc.cutButtonLabel,
    ContextMenuButtonType.paste => mloc.pasteButtonLabel,
    ContextMenuButtonType.selectAll => mloc.selectAllButtonLabel,
    ContextMenuButtonType.delete => mloc.deleteButtonTooltip,
    _ => type.name,
  };
}