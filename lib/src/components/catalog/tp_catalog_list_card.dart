import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../theme/tp_text_styles.dart';
import '../../theme/tp_theme.dart';
import 'tp_catalog_metadata_row.dart';

/// Compact tag pill used on [TpCatalogListCard] row 3.
class TpCatalogTagChip extends StatelessWidget {
  const TpCatalogTagChip({super.key, required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final styles = TpTextStyles.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(7),
      ),
      child: Text(
        label,
        style: styles.xsSemiboldColored(cs.onSurfaceVariant),
      ),
    );
  }
}

/// Four-row bordered discovery card shared by Skills / Plugins / MCP lists.
///
/// Height is fixed (see [listItemExtent]) so [ListView] can use `itemExtent`.
///
/// 1. leading + title + source
/// 2. description (always 2 lines)
/// 3. tags
/// 4. metrics + [actions] (actions right-aligned)
class TpCatalogListCard extends StatefulWidget {
  const TpCatalogListCard({
    super.key,
    required this.title,
    required this.source,
    required this.description,
    required this.emptyDescription,
    required this.adoption,
    required this.rating,
    required this.actions,
    this.leading,
    this.tags = const [],
    this.showTags = true,
    this.onTap,
    this.enabled = true,
  });

  final Widget? leading;
  final String title;
  final String source;
  final String description;
  final String emptyDescription;
  final List<Widget> tags;
  /// When false, the tags row (and its spacing) is omitted — use matching
  /// [listItemExtent] with `showTags: false`.
  final bool showTags;
  final TpCatalogMetricView adoption;
  final TpCatalogMetricView rating;
  final Widget actions;
  final VoidCallback? onTap;
  final bool enabled;

  static const double leadingSize = 36;
  static const double sourceMaxWidth = 120;
  static const double tagsRowHeight = 28;
  static const double footerRowHeight = 48;
  static const double outerVerticalPadding = 8;

  /// Scaled line height for a [TextStyle] under the ambient text scaler.
  static double lineExtent(BuildContext context, TextStyle style) {
    final size = style.fontSize ?? 14;
    final height = style.height ?? 1.0;
    return MediaQuery.textScalerOf(context).scale(size * height);
  }

  /// Full list-item height (outer margin included). Pass to [ListView.itemExtent].
  static double listItemExtent(
    BuildContext context, {
    bool showTags = true,
  }) {
    final spacing = context.tpSpacing;
    final styles = TpTextStyles.of(context);
    final titleRow = math.max(
      leadingSize,
      lineExtent(context, styles.mdSemibold),
    );
    final descriptionRow = 2 * lineExtent(context, styles.smRelaxed);
    final tagsBlock = showTags ? (spacing.sm + tagsRowHeight) : 0.0;
    return (outerVerticalPadding * 2) +
        (spacing.md * 2) +
        titleRow +
        spacing.sm +
        descriptionRow +
        tagsBlock +
        spacing.sm +
        footerRowHeight;
  }

  @override
  State<TpCatalogListCard> createState() => _TpCatalogListCardState();
}

class _TpCatalogListCardState extends State<TpCatalogListCard> {
  static const _radius = 14.0;
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final spacing = context.tpSpacing;
    final styles = TpTextStyles.of(context);
    final interactive = widget.enabled && widget.onTap != null;
    final description = widget.description.trim();
    final descriptionText = description.isEmpty
        ? widget.emptyDescription
        : description;
    final titleRowHeight = math.max(
      TpCatalogListCard.leadingSize,
      TpCatalogListCard.lineExtent(context, styles.mdSemibold),
    );
    final descriptionHeight =
        2 * TpCatalogListCard.lineExtent(context, styles.smRelaxed);

    return SizedBox(
      height: TpCatalogListCard.listItemExtent(
        context,
        showTags: widget.showTags,
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          vertical: TpCatalogListCard.outerVerticalPadding,
        ),
        child: MouseRegion(
          onEnter: (_) {
            if (!widget.enabled) return;
            setState(() => _hovered = true);
          },
          onExit: (_) => setState(() => _hovered = false),
          cursor: interactive
              ? SystemMouseCursors.click
              : SystemMouseCursors.basic,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: interactive ? widget.onTap : null,
            // Border-only hover — avoid AnimatedContainer + shadow (scroll cost).
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: cs.surfaceContainer,
                borderRadius: BorderRadius.circular(_radius),
                border: Border.all(
                  color: _hovered
                      ? cs.primary.withValues(alpha: 0.55)
                      : cs.outlineVariant,
                ),
              ),
              child: Padding(
                padding: EdgeInsets.all(spacing.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    SizedBox(
                      height: titleRowHeight,
                      child: Row(
                        children: [
                          if (widget.leading != null) ...[
                            SizedBox(
                              width: TpCatalogListCard.leadingSize,
                              height: TpCatalogListCard.leadingSize,
                              child: widget.leading,
                            ),
                            SizedBox(width: spacing.sm),
                          ],
                          Expanded(
                            child: Text(
                              widget.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: styles.mdSemiboldColored(cs.onSurface),
                            ),
                          ),
                          SizedBox(width: spacing.sm),
                          ConstrainedBox(
                            constraints: const BoxConstraints(
                              maxWidth: TpCatalogListCard.sourceMaxWidth,
                            ),
                            child: Text(
                              widget.source,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.end,
                              style: styles.xsColored(
                                cs.onSurface.withValues(alpha: 0.55),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: spacing.sm),
                    SizedBox(
                      height: descriptionHeight,
                      child: Align(
                        alignment: AlignmentDirectional.topStart,
                        child: Text(
                          descriptionText,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: styles.smRelaxedColored(
                            description.isEmpty
                                ? cs.onSurface.withValues(alpha: 0.45)
                                : cs.onSurface.withValues(alpha: 0.78),
                          ),
                        ),
                      ),
                    ),
                    if (widget.showTags) ...[
                      SizedBox(height: spacing.sm),
                      SizedBox(
                        height: TpCatalogListCard.tagsRowHeight,
                        child: widget.tags.isEmpty
                            ? const SizedBox.shrink()
                            : Align(
                                alignment: AlignmentDirectional.centerStart,
                                child: SingleChildScrollView(
                                  scrollDirection: Axis.horizontal,
                                  physics: const NeverScrollableScrollPhysics(),
                                  child: Row(
                                    children: [
                                      for (var i = 0;
                                          i < widget.tags.length;
                                          i++) ...[
                                        if (i > 0)
                                          SizedBox(width: spacing.xs),
                                        widget.tags[i],
                                      ],
                                    ],
                                  ),
                                ),
                              ),
                      ),
                    ],
                    SizedBox(height: spacing.sm),
                    SizedBox(
                      height: TpCatalogListCard.footerRowHeight,
                      child: Row(
                        children: [
                          Expanded(
                            child: Align(
                              alignment: AlignmentDirectional.centerStart,
                              child: TpCatalogMetadataRow(
                                adoption: widget.adoption,
                                rating: widget.rating,
                              ),
                            ),
                          ),
                          SizedBox(width: spacing.sm),
                          widget.actions,
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
