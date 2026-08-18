import 'package:flutter/material.dart';

import '../../theme/tp_text_styles.dart';
import '../../theme/tp_theme.dart';
import '../card/tp_card.dart';

/// Shared install-oriented frame for public catalog entries.
///
/// The shell owns only layout. Resource-specific details and actions are
/// supplied by the caller so this package remains independent of app models
/// and localization.
class TpCatalogCardShell extends StatelessWidget {
  const TpCatalogCardShell({
    super.key,
    required this.title,
    required this.source,
    required this.description,
    required this.metadata,
    required this.action,
    this.leading,
    this.body,
  });

  final String title;
  final String source;
  final String description;
  final Widget metadata;
  final Widget action;
  final Widget? leading;
  final Widget? body;

  @override
  Widget build(BuildContext context) {
    final spacing = context.tpSpacing;
    final scheme = Theme.of(context).colorScheme;
    final textStyles = TpTextStyles.of(context);

    final header = Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (leading != null) ...[
          Padding(
            padding: EdgeInsets.only(right: spacing.sm),
            child: leading,
          ),
        ],
        Expanded(
          child: Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.start,
            spacing: spacing.sm,
            runSpacing: spacing.xs,
            children: [
              ConstrainedBox(
                constraints: const BoxConstraints(minWidth: 120),
                child: Text(
                  title,
                  style: textStyles.mdSemiboldColored(scheme.onSurface),
                ),
              ),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 240),
                child: Text(
                  source,
                  style: textStyles.smColored(
                    scheme.onSurface.withValues(alpha: 0.65),
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ],
    );

    final trimmedDescription = description.trim();
    final middleChildren = <Widget>[
      if (trimmedDescription.isNotEmpty) ...[
        SizedBox(height: spacing.sm),
        Text(
          trimmedDescription,
          style: textStyles.smRelaxedColored(
            scheme.onSurface.withValues(alpha: 0.78),
          ),
          maxLines: 3,
          overflow: TextOverflow.ellipsis,
        ),
      ],
      if (body != null) ...[SizedBox(height: spacing.md), body!],
    ];

    final footer = <Widget>[
      SizedBox(height: spacing.md),
      metadata,
      SizedBox(height: spacing.md),
      Align(alignment: AlignmentDirectional.centerEnd, child: action),
    ];

    return TpCard(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final children = [header, ...middleChildren, ...footer];
          if (!constraints.hasBoundedHeight) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: children,
            );
          }
          // Header + metadata + action can exceed a short grid cell (the
          // landing picker used to give discovery cards 186px). Keep the
          // column in an Expanded ListView so the shell never overflows.
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: ListView(
                  padding: EdgeInsets.zero,
                  physics: const NeverScrollableScrollPhysics(),
                  children: children,
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
