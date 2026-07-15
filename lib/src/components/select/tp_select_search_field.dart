import 'package:flutter/material.dart';

import '../../theme/tp_theme.dart';
import '../icon_button/tp_icon_button.dart';

/// Compact search input for searchable [TpSelect] overlays (shadcn Combobox style).
class TpSelectSearchField extends StatefulWidget {
  const TpSelectSearchField({
    super.key,
    required this.controller,
    required this.focusNode,
    required this.hintText,
    required this.onChanged,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final String hintText;
  final ValueChanged<String> onChanged;

  @override
  State<TpSelectSearchField> createState() => _TpSelectSearchFieldState();
}

class _TpSelectSearchFieldState extends State<TpSelectSearchField> {
  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onTextChanged);
  }

  @override
  void didUpdateWidget(TpSelectSearchField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_onTextChanged);
      widget.controller.addListener(_onTextChanged);
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onTextChanged);
    super.dispose();
  }

  void _onTextChanged() {
    if (mounted) setState(() {});
  }

  void _clear() {
    widget.controller.clear();
    widget.onChanged('');
    widget.focusNode.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final spacing = context.tpSpacing;
    final hasQuery = widget.controller.text.isNotEmpty;

    return TextField(
      controller: widget.controller,
      focusNode: widget.focusNode,
      decoration: InputDecoration(
        hintText: widget.hintText,
        isDense: true,
        filled: true,
        fillColor: cs.surfaceContainer,
        contentPadding: EdgeInsets.symmetric(
          horizontal: spacing.md - 2,
          vertical: spacing.sm,
        ),
        prefixIcon: Icon(
          Icons.search_rounded,
          size: context.tpIconSizes.md,
          color: cs.onSurfaceVariant,
        ),
        suffixIcon: hasQuery
            ? TpIconButton(
                icon: Icons.clear,
                compact: true,
                size: TpIconButton.kCompactSize,
                onTap: _clear,
              )
            : null,
        floatingLabelBehavior: FloatingLabelBehavior.never,
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: BorderSide(
            color: cs.outlineVariant.withValues(alpha: 0.7),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: BorderSide(color: cs.primary),
        ),
      ),
      onChanged: widget.onChanged,
      textInputAction: TextInputAction.search,
    );
  }
}
