import 'package:flutter/material.dart';

import '../../theme/tp_text_styles.dart';
import '../../theme/tp_theme.dart';

/// One localized metric displayed in a [TpCatalogMetadataRow].
@immutable
class TpCatalogMetricView {
  const TpCatalogMetricView({
    required this.icon,
    required this.label,
    required this.value,
    required this.missingValueTooltip,
  });

  final IconData icon;
  final String label;
  final String? value;
  final String missingValueTooltip;
}

/// Compact adoption + rating footer shared by public catalog cards.
class TpCatalogMetadataRow extends StatelessWidget {
  const TpCatalogMetadataRow({
    super.key,
    required this.adoption,
    required this.rating,
  });

  final TpCatalogMetricView adoption;
  final TpCatalogMetricView rating;

  @override
  Widget build(BuildContext context) {
    final spacing = context.tpSpacing;
    return Row(
      children: [
        Flexible(child: _TpCatalogMetricChip(metric: adoption)),
        SizedBox(width: spacing.md),
        Flexible(child: _TpCatalogMetricChip(metric: rating)),
      ],
    );
  }
}

class _TpCatalogMetricChip extends StatelessWidget {
  const _TpCatalogMetricChip({required this.metric});

  final TpCatalogMetricView metric;

  @override
  Widget build(BuildContext context) {
    final spacing = context.tpSpacing;
    final scheme = Theme.of(context).colorScheme;
    final textStyles = TpTextStyles.of(context);
    final isMissing = metric.value == null;
    final value = metric.value ?? '—';
    final semanticsLabel = isMissing
        ? '${metric.label} —'
        : '${metric.label} $value';
    final valueText = Text(
      value,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: textStyles.smMediumColored(scheme.onSurface),
    );

    final row = Semantics(
      label: semanticsLabel,
      child: ExcludeSemantics(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              metric.icon,
              size: context.tpIconSizes.sm,
              color: scheme.onSurface.withValues(alpha: 0.68),
            ),
            SizedBox(width: spacing.xs),
            Flexible(child: valueText),
          ],
        ),
      ),
    );

    if (!isMissing) return row;
    return Tooltip(message: metric.missingValueTooltip, child: row);
  }
}
