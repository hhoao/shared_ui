import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../popover/tp_anchor.dart';
import '../popover/tp_portal.dart';
import 'tp_token_chip_mirror.dart';
import 'tp_token_edit.dart';
import 'tp_token_palette.dart';

/// Multiline text field that renders [tokenPattern] matches as inline chips.
///
/// When the text has no token matches, this is a normal opaque [TextField] (no
/// mirror). With matches, the editable layer uses transparent glyphs and a
/// [TpTokenChipMirror] underneath paints colored tokens + background pills
/// aligned to layout metrics. Skipping the mirror widget when unused avoids a
/// second text layout on common paths (empty landing compose, plain typing).
/// The Stack always keeps a stable editor slot so mirror mount/unmount does
/// not remount [EditableText].
///
/// Callers must supply [tokenPattern] and [resolveTokenPalette]; the package
/// does not ship product-specific compose token defaults.
class TpTokenTextField extends StatefulWidget {
  const TpTokenTextField({
    required this.controller,
    required this.focusNode,
    required this.hint,
    required this.enabled,
    required this.onChanged,
    required this.textStyle,
    required this.hintStyle,
    required this.cursorColor,
    required this.tokenPattern,
    required this.resolveTokenPalette,
    this.minLines = 3,
    this.maxLines = 6,
    this.expands = false,
    this.overlayVisible = false,
    this.overlayAnchor = Offset.zero,
    this.overlayBuilder,
    this.onKeyEvent,
    this.fieldKey,
    this.selectionColor,
    super.key,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final String hint;
  final bool enabled;
  final ValueChanged<String> onChanged;
  final TextStyle textStyle;
  final TextStyle hintStyle;
  final Color cursorColor;
  final Color? selectionColor;
  final RegExp tokenPattern;
  final TpTokenPaletteResolver resolveTokenPalette;
  final int minLines;
  final int maxLines;

  /// When true, fill the parent (e.g. [TpTextareaShell]) instead of sizing
  /// from [minLines]/[maxLines]. Avoids untappable blank gaps below the field.
  final bool expands;
  final bool overlayVisible;
  final Offset overlayAnchor;
  final WidgetBuilder? overlayBuilder;
  final FocusOnKeyEventCallback? onKeyEvent;
  final GlobalKey? fieldKey;

  @override
  State<TpTokenTextField> createState() => _TpTokenTextFieldState();
}

class _TpTokenTextFieldState extends State<TpTokenTextField> {
  FocusOnKeyEventCallback? _chainedKeyHandler;
  final _scrollController = ScrollController();
  final _internalFieldKey = GlobalKey();
  /// Keeps [TextField]/[EditableText] identity when the mirror slot toggles.
  final _editorKey = GlobalKey();

  GlobalKey get _effectiveFieldKey => widget.fieldKey ?? _internalFieldKey;

  @override
  void initState() {
    super.initState();
    _attachKeyHandler(widget.focusNode);
    widget.controller.addListener(_handleControllerChanged);
  }

  @override
  void didUpdateWidget(covariant TpTokenTextField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.focusNode != widget.focusNode) {
      _detachKeyHandler(oldWidget.focusNode);
      _attachKeyHandler(widget.focusNode);
    }
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_handleControllerChanged);
      widget.controller.addListener(_handleControllerChanged);
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_handleControllerChanged);
    _detachKeyHandler(widget.focusNode);
    _scrollController.dispose();
    super.dispose();
  }

  void _handleControllerChanged() {
    if (mounted) setState(() {});
  }

  void _attachKeyHandler(FocusNode node) {
    _chainedKeyHandler = node.onKeyEvent;
    node.onKeyEvent = _handleKeyWithChain;
  }

  void _detachKeyHandler(FocusNode node) {
    if (node.onKeyEvent == _handleKeyWithChain) {
      node.onKeyEvent = _chainedKeyHandler;
    }
    _chainedKeyHandler = null;
  }

  KeyEventResult _handleKeyWithChain(FocusNode node, KeyEvent event) {
    final result = _handleKey(node, event);
    if (result != KeyEventResult.ignored) {
      return result;
    }
    final extra = widget.onKeyEvent?.call(node, event);
    if (extra != null && extra != KeyEventResult.ignored) {
      return extra;
    }
    return _chainedKeyHandler?.call(node, event) ?? KeyEventResult.ignored;
  }

  KeyEventResult _handleKey(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent) {
      return KeyEventResult.ignored;
    }

    if (event.logicalKey == LogicalKeyboardKey.backspace) {
      final updated = applyTpTokenBackspace(
        widget.controller.value,
        widget.tokenPattern,
      );
      if (updated != null) {
        widget.controller.value = updated;
        widget.onChanged(updated.text);
        setState(() {});
        return KeyEventResult.handled;
      }
    }
    if (event.logicalKey == LogicalKeyboardKey.delete) {
      final updated = applyTpTokenDelete(
        widget.controller.value,
        widget.tokenPattern,
      );
      if (updated != null) {
        widget.controller.value = updated;
        widget.onChanged(updated.text);
        setState(() {});
        return KeyEventResult.handled;
      }
    }

    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    final selectionColor =
        widget.selectionColor ??
        Theme.of(context).colorScheme.primary.withValues(alpha: 0.25);

    // Avoid LayoutBuilder here: nesting under ide/MultiPane LayoutBuilders
    // forces TextField BUILD during parent layout (landing first-open jank).
    final editor = widget.expands
        ? SizedBox.expand(child: _buildEditorStack(selectionColor))
        : _buildEditorStack(selectionColor);

    if (widget.overlayBuilder == null) {
      return editor;
    }

    return TpPortal(
      visible: widget.overlayVisible,
      anchor: TpGlobalAnchor(widget.overlayAnchor),
      portalBuilder: (context) {
        final box =
            _effectiveFieldKey.currentContext?.findRenderObject() as RenderBox?;
        final width = (box != null && box.hasSize) ? box.size.width : 320.0;
        return SizedBox(
          width: width,
          child: widget.overlayBuilder!(context),
        );
      },
      child: editor,
    );
  }

  Widget _buildEditorStack(Color selectionColor) {
    final text = widget.controller.text;
    final showChipMirror = widget.tokenPattern.hasMatch(text);

    // Always keep two Stack slots so toggling the mirror never shifts the
    // TextField from index 1 → 0 (that remounts EditableText and can kill IME).
    final Widget mirrorSlot = showChipMirror
        ? IgnorePointer(
            child: ListenableBuilder(
              listenable: _scrollController,
              builder: (context, _) {
                final scrollOffset = _scrollController.hasClients
                    ? _scrollController.offset
                    : 0.0;
                return TpTokenChipMirror(
                  text: text,
                  baseStyle: widget.textStyle,
                  minLines: widget.expands ? 1 : widget.minLines,
                  maxLines: widget.expands ? 100 : widget.maxLines,
                  expands: widget.expands,
                  scrollOffset: scrollOffset,
                  tokenPattern: widget.tokenPattern,
                  resolvePalette: widget.resolveTokenPalette,
                );
              },
            ),
          )
        : const SizedBox.shrink();

    final field = KeyedSubtree(
      key: _editorKey,
      child: TextSelectionTheme(
        data: TextSelectionThemeData(
          selectionColor: selectionColor,
          cursorColor: widget.cursorColor,
        ),
        child: TextField(
          controller: widget.controller,
          focusNode: widget.focusNode,
          scrollController: _scrollController,
          expands: widget.expands,
          minLines: widget.expands ? null : widget.minLines,
          maxLines: widget.expands ? null : widget.maxLines,
          enabled: widget.enabled,
          onChanged: (value) {
            setState(() {});
            widget.onChanged(value);
          },
          // Opaque when solo; transparent when mirror paints visible glyphs.
          style: showChipMirror
              ? widget.textStyle.copyWith(color: Colors.transparent)
              : widget.textStyle,
          cursorColor: widget.cursorColor,
          textAlignVertical: widget.expands ? TextAlignVertical.top : null,
          decoration: InputDecoration(
            filled: false,
            hoverColor: Colors.transparent,
            hintText: widget.hint,
            hintStyle: widget.hintStyle,
            border: InputBorder.none,
            enabledBorder: InputBorder.none,
            focusedBorder: InputBorder.none,
            disabledBorder: InputBorder.none,
            contentPadding: EdgeInsets.zero,
            isDense: true,
          ),
        ),
      ),
    );

    return Stack(
      key: _effectiveFieldKey,
      alignment: Alignment.topLeft,
      children: [
        if (widget.expands)
          Positioned.fill(child: mirrorSlot)
        else
          mirrorSlot,
        if (widget.expands) Positioned.fill(child: field) else field,
      ],
    );
  }
}
