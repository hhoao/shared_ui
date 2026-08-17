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

/// Four-slot metadata row shared by public catalog cards.
class TpCatalogMetadataRow extends StatelessWidget {
  const TpCatalogMetadataRow({
    super.key,
    required this.adoption,
    required this.rating,
    required this.updated,
    required this.published,
  });

  final TpCatalogMetricView adoption;
  final TpCatalogMetricView rating;
  final TpCatalogMetricView updated;
  final TpCatalogMetricView published;

  @override
  Widget build(BuildContext context) {
    final spacing = context.tpSpacing;
    return Wrap(
      spacing: spacing.md,
      runSpacing: spacing.sm,
      children: [
        _TpCatalogMetricTile(metric: adoption),
        _TpCatalogMetricTile(metric: rating),
        _TpCatalogMetricTile(metric: updated),
        _TpCatalogMetricTile(metric: published),
      ],
    );
  }
}

class _TpCatalogMetricTile extends StatelessWidget {
  const _TpCatalogMetricTile({required this.metric});

  final TpCatalogMetricView metric;

  @override
  Widget build(BuildContext context) {
    final spacing = context.tpSpacing;
    final scheme = Theme.of(context).colorScheme;
    final textStyles = TpTextStyles.of(context);
    final isMissing = metric.value == null;
    final value = metric.value ?? '—';
    final valueText = Text(
      value,
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
      style: textStyles.smMediumColored(scheme.onSurface),
    );

    return ConstrainedBox(
      constraints: const BoxConstraints(minWidth: 88, maxWidth: 180),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            metric.icon,
            size: context.tpIconSizes.sm,
            color: scheme.onSurface.withValues(alpha: 0.68),
          ),
          SizedBox(width: spacing.xs),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  metric.label,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: textStyles.xsColored(
                    scheme.onSurface.withValues(alpha: 0.65),
                  ),
                ),
                isMissing
                    ? Tooltip(
                        message: metric.missingValueTooltip,
                        child: valueText,
                      )
                    : valueText,
              ],
            ),
          ),
        ],
      ),
    );
  }
}
