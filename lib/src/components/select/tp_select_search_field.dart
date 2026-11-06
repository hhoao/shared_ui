import 'package:flutter/material.dart';

import '../icon_button/tp_icon_button.dart';
import '../input/tp_search_pill.dart';

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
    final hasQuery = widget.controller.text.isNotEmpty;

    return TextField(
      controller: widget.controller,
      focusNode: widget.focusNode,
      decoration: tpSearchPillDecoration(
        context,
        hintText: widget.hintText,
        suffixIcon: hasQuery
            ? TpIconButton(
                icon: Icons.clear,
                compact: true,
                size: TpIconButton.kCompactSize,
                onTap: _clear,
              )
            : null,
      ),
      onChanged: widget.onChanged,
      textInputAction: TextInputAction.search,
    );
  }
}
