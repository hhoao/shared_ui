import 'package:flutter/material.dart';

import 'tp_info_tip_icon.dart';

/// Form field label with an optional info tip shown beside the text.
///
/// When [tip] is set, an info icon appears to the right of [text]; tap the icon
/// to read the tip.
class TpFormFieldLabel extends StatelessWidget {
  const TpFormFieldLabel({
    super.key,
    required this.text,
    this.tip,
    this.style,
  });

  final String text;
  final String? tip;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    final effectiveStyle = style ?? DefaultTextStyle.of(context).style;
    final trimmedTip = tip?.trim() ?? '';
    if (trimmedTip.isEmpty) {
      return Text(text, style: effectiveStyle);
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Flexible(
          child: Text(text, style: effectiveStyle),
        ),
        Padding(
          padding: const EdgeInsets.only(left: 4),
          child: TpInfoTipIcon(message: trimmedTip),
        ),
      ],
    );
  }
}
