import 'package:flutter/material.dart';

import '../../theme/tp_text_styles.dart';
import '../../theme/tp_theme.dart';

/// Compact info icon that shows [message] in a tooltip on tap.
class TpInfoTipIcon extends StatelessWidget {
  const TpInfoTipIcon({
    required this.message,
    super.key,
  });

  final String message;

  @override
  Widget build(BuildContext context) {
    final trimmed = message.trim();
    if (trimmed.isEmpty) {
      return const SizedBox.shrink();
    }

    final scheme = Theme.of(context).colorScheme;
    final iconSize = context.tpIconSizes.sm;
    final tooltipTheme = Theme.of(context).tooltipTheme;
    final tipTextStyle = TpTextStyles.of(context).smRelaxed.copyWith(
      color: tooltipTheme.textStyle?.color ?? scheme.onInverseSurface,
    );

    return Tooltip(
      message: trimmed,
      textStyle: tipTextStyle,
      triggerMode: TooltipTriggerMode.tap,
      showDuration: const Duration(seconds: 12),
      waitDuration: Duration.zero,
      margin: const EdgeInsets.symmetric(horizontal: 12),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Icon(
        Icons.info_outline,
        size: iconSize,
        color: scheme.onSurfaceVariant,
      ),
    );
  }
}
