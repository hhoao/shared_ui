import 'package:flutter/material.dart';

import '../../theme/tp_text_styles.dart';
import '../../theme/tp_theme.dart';

/// Compact status pill (configured / warning / neutral, …).
///
/// Hosts supply [label] (and optional [icon]) — no product copy in the package.
class TpStatusBadge extends StatelessWidget {
  const TpStatusBadge({
    super.key,
    required this.label,
    this.icon,
    this.tone = TpStatusBadgeTone.neutral,
    this.color,
  });

  final String label;
  final IconData? icon;
  final TpStatusBadgeTone tone;

  /// When set, overrides [tone] color resolution.
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final styles = TpTextStyles.of(context);
    final resolved =
        color ??
        switch (tone) {
          TpStatusBadgeTone.success => cs.tertiary,
          TpStatusBadgeTone.neutral => cs.onSurfaceVariant,
          TpStatusBadgeTone.warning => cs.error,
        };
    final icons = context.tpIconSizes;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: context.tpSpacing.sm - 1,
        vertical: 2,
      ),
      decoration: BoxDecoration(
        color: resolved.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: resolved.withValues(alpha: 0.35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: icons.sm * 0.75, color: resolved),
            SizedBox(width: context.tpSpacing.xxs * 2),
          ],
          Text(label, style: styles.xsColored(resolved)),
        ],
      ),
    );
  }
}

enum TpStatusBadgeTone { success, neutral, warning }
