import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../theme/tp_theme.dart';
import '../input/tp_input.dart';
import '../popover/tp_popover.dart';
import '../select/tp_select_decoration.dart';
import '../select/tp_select_item_filter.dart';
import '../suggestion/tp_suggestion_list.dart';

/// Inline-filter autocomplete control (shadcn Combobox style).
class TpCombobox<T extends Object> extends StatefulWidget {
  const TpCombobox({
    super.key,
    required this.items,
    required this.onChanged,
    this.value,
    this.itemLabel,
    this.itemBuilder,
    this.placeholder,
    this.enabled = true,
    this.clearable = false,
    this.autoHighlight = true,
    this.controller,
    this.itemSearchText,
    this.filterPredicate,
    this.emptyText,
    this.overlayHeight,
    this.decoration,
  }) : assert(
         itemLabel != null || itemBuilder != null,
         'Provide itemLabel or itemBuilder',
       );

  final List<T> items;
  final ValueChanged<T?> onChanged;
  final T? value;
  final String Function(T item)? itemLabel;
  final Widget Function(BuildContext context, T item)? itemBuilder;
  final String? placeholder;
  final bool enabled;
  final bool clearable;
  final bool autoHighlight;
  final TpPopoverController? controller;
  final String Function(T item)? itemSearchText;
  final bool Function(T item, String query)? filterPredicate;
  final String? emptyText;
  final double? overlayHeight;
  final TpSelectDecoration? decoration;

  @override
  State<TpCombobox<T>> createState() => _TpComboboxState<T>();
}

class _TpComboboxState<T extends Object> extends State<TpCombobox<T>> {
  final GlobalKey _triggerKey = GlobalKey();
  late final TpPopoverController _popoverController;
  late final bool _ownsController;
  late final TextEditingController _textController;
  late final FocusNode _focusNode;
  bool _drafting = false;
  int _highlightedIndex = -1;
  double? _overlayWidth;

  @override
  void initState() {
    super.initState();
    _ownsController = widget.controller == null;
    _popoverController = widget.controller ?? TpPopoverController();
    _popoverController.addListener(_onPopoverChanged);
    _textController = TextEditingController(text: _displayTextForValue());
    _focusNode = FocusNode();
    _focusNode.addListener(_onFocusChanged);
    _focusNode.onKeyEvent = _handleKeyEvent;
  }

  @override
  void didUpdateWidget(TpCombobox<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_drafting && widget.value != oldWidget.value) {
      _textController.text = _displayTextForValue();
    }
  }

  @override
  void dispose() {
    _popoverController.removeListener(_onPopoverChanged);
    _focusNode.removeListener(_onFocusChanged);
    _focusNode.onKeyEvent = null;
    _textController.dispose();
    _focusNode.dispose();
    if (_ownsController) {
      _popoverController.dispose();
    }
    super.dispose();
  }

  String _labelFor(T item) {
    if (widget.itemLabel != null) {
      return widget.itemLabel!(item);
    }
    if (item is String) {
      return item;
    }
    return item.toString();
  }

  String _displayTextForValue() {
    final value = widget.value;
    if (value == null) {
      return '';
    }
    return _labelFor(value);
  }

  String _searchTextFor(T item) {
    if (widget.itemSearchText != null) {
      return widget.itemSearchText!(item);
    }
    if (widget.itemLabel != null) {
      return widget.itemLabel!(item);
    }
    if (item is String) {
      return item;
    }
    return item.toString();
  }

  bool _matchesSearch(T item, String query) {
    if (widget.filterPredicate != null) {
      return widget.filterPredicate!(item, query);
    }
    return tpSelectItemMatchesQuery(
      query: query,
      searchText: _searchTextFor(item),
    );
  }

  List<T> _filteredItemsFor(String query) {
    if (query.trim().isEmpty) {
      return widget.items;
    }
    return [
      for (final item in widget.items)
        if (_matchesSearch(item, query)) item,
    ];
  }

  List<T> get _filteredItems => _filteredItemsFor(_textController.text);

  void _resetHighlightForCurrentFilter() {
    final filtered = _filteredItems;
    _highlightedIndex =
        widget.autoHighlight && filtered.isNotEmpty ? 0 : -1;
  }

  void _onFocusChanged() {
    if (_focusNode.hasFocus) {
      _openPopover();
    }
  }

  void _onPopoverChanged() {
    if (!mounted) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (_popoverController.isOpen) {
        _syncOverlayWidth();
      } else {
        _onPopoverClosed();
      }
    });
  }

  void _onPopoverClosed() {
    if (_drafting) {
      _reconvergeDisplayText();
    }
    if (mounted) {
      setState(() => _highlightedIndex = -1);
    }
  }

  void _reconvergeDisplayText() {
    _drafting = false;
    final text = _displayTextForValue();
    if (_textController.text != text) {
      _textController.text = text;
    }
  }

  void _syncOverlayWidth() {
    if (!mounted || !_popoverController.isOpen) return;
    final box = _triggerKey.currentContext?.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _syncOverlayWidth());
      return;
    }
    final width = box.size.width;
    if (_overlayWidth == width) return;
    setState(() => _overlayWidth = width);
  }

  void _openPopover() {
    if (!widget.enabled) return;
    if (!_popoverController.isOpen) {
      _popoverController.show();
      _resetHighlightForCurrentFilter();
    }
  }

  void _onTextChanged(String text) {
    setState(() {
      _drafting = true;
      _resetHighlightForCurrentFilter();
    });
    if (!_popoverController.isOpen) {
      _popoverController.show();
    }
  }

  void _selectItem(T item) {
    setState(() {
      _drafting = false;
      _textController.text = _labelFor(item);
      _highlightedIndex = -1;
    });
    widget.onChanged(item);
    _popoverController.hide();
  }

  void _clear() {
    setState(() {
      _drafting = false;
      _textController.clear();
      _highlightedIndex = -1;
    });
    widget.onChanged(null);
    _popoverController.hide();
  }

  void _moveHighlight(int delta) {
    final count = _filteredItems.length;
    if (count == 0) return;
    setState(() {
      if (_highlightedIndex < 0) {
        _highlightedIndex = delta > 0 ? 0 : count - 1;
      } else {
        _highlightedIndex = (_highlightedIndex + delta).clamp(0, count - 1);
      }
    });
  }

  KeyEventResult _handleKeyEvent(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent) {
      return KeyEventResult.ignored;
    }
    if (!_popoverController.isOpen) {
      return KeyEventResult.ignored;
    }
    final key = event.logicalKey;
    if (key == LogicalKeyboardKey.arrowDown) {
      _moveHighlight(1);
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.arrowUp) {
      _moveHighlight(-1);
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.enter) {
      if (_highlightedIndex >= 0 &&
          _highlightedIndex < _filteredItems.length) {
        _selectItem(_filteredItems[_highlightedIndex]);
      }
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.escape) {
      _popoverController.hide();
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  Widget? _buildClearSuffix() {
    if (!widget.clearable) return null;
    final showClear =
        widget.value != null || _textController.text.isNotEmpty;
    if (!showClear) return null;
    return IconButton(
      icon: const Icon(Icons.clear),
      onPressed: widget.enabled ? _clear : null,
    );
  }

  @override
  Widget build(BuildContext context) {
    final deco =
        widget.decoration ??
        TpSelectDecorations.themed(
          context,
          suffixIconSize: context.tpIconSizes.md,
        );
    final maxHeight =
        widget.overlayHeight ??
        context.tpTheme.selectTheme.defaultOverlayHeight;
    final query = _textController.text;
    final filtered = _filteredItems;
    final showEmpty = query.trim().isNotEmpty && filtered.isEmpty;

    return ListenableBuilder(
      listenable: _popoverController,
      builder: (context, _) {
        return TpPopover(
          controller: _popoverController,
          panelWidth: _overlayWidth,
          overlayVisible: _overlayWidth != null,
          padding: deco.menuPadding,
          decoration: deco.menuDecoration(),
          anchor: const TpAnchor(
            childAlignment: Alignment.topCenter,
            overlayAlignment: Alignment.bottomCenter,
            offset: Offset(0, 4),
          ),
          popover: (popoverContext) {
            return ConstrainedBox(
              constraints: BoxConstraints(maxHeight: maxHeight),
              child: TpSuggestionList<T>(
                items: showEmpty ? const [] : filtered,
                highlightedIndex: _highlightedIndex,
                selectedItem: widget.value,
                itemLabel: widget.itemLabel,
                itemBuilder: widget.itemBuilder,
                emptyText: widget.emptyText ?? 'No results',
                onItemSelected: _selectItem,
              ),
            );
          },
          child: KeyedSubtree(
            key: _triggerKey,
            child: TpInput(
              controller: _textController,
              focusNode: _focusNode,
              enabled: widget.enabled,
              decoration: InputDecoration(
                hintText: widget.placeholder,
                suffixIcon: _buildClearSuffix(),
              ),
              onChanged: _onTextChanged,
              onTap: _openPopover,
            ),
          ),
        );
      },
    );
  }
}
