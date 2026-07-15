import 'package:flutter/material.dart';

import '../../theme/tp_theme.dart';

/// Horizontal cluster of actions with consistent gaps (card / toolbar headers).
class TpActionRow extends StatelessWidget {
  const TpActionRow({super.key, required this.children, this.gap});

  final List<Widget> children;
  final double? gap;

  @override
  Widget build(BuildContext context) {
    final resolvedGap = gap ?? context.tpSpacing.sm;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < children.length; i++) ...[
          if (i > 0) SizedBox(width: resolvedGap),
          children[i],
        ],
      ],
    );
  }
}
