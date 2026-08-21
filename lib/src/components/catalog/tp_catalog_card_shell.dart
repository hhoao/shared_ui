import 'package:flutter/material.dart';

import '../../theme/tp_text_styles.dart';
import '../../theme/tp_theme.dart';

/// Shared install-oriented frame for public catalog entries.
///
/// Owns border + hover chrome. Resource-specific details and actions are
/// supplied by the caller so this package remains independent of app models
/// and localization.
class TpCatalogCardShell extends StatefulWidget {
  const TpCatalogCardShell({
    super.key,
    required this.title,
    required this.source,
    required this.description,
    required this.metadata,
    required this.action,
    this.leading,
    this.body,
    this.onTap,
    this.enabled = true,
    this.selected = false,
    this.accentColor,
  });

  final String title;
  final String source;
  final String description;
  final Widget metadata;
  final Widget action;
  final Widget? leading;
  final Widget? body;

  /// Optional whole-card tap. Hover chrome still applies when null.
  final VoidCallback? onTap;
  final bool enabled;
  final bool selected;

  /// When set, hover border uses this accent (Team / Expert hubs).
  final Color? accentColor;

  @override
  State<TpCatalogCardShell> createState() => _TpCatalogCardShellState();
}

class _TpCatalogCardShellState extends State<TpCatalogCardShell> {
  static const _radius = 14.0;
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final spacing = context.tpSpacing;
    final scheme = Theme.of(context).colorScheme;
    final textStyles = TpTextStyles.of(context);
    final interactive = widget.enabled && widget.onTap != null;

    final borderColor = widget.selected
        ? scheme.primary.withValues(alpha: 0.65)
        : _hovered
        ? (widget.accentColor ?? scheme.primary).withValues(alpha: 0.55)
        : scheme.outlineVariant;

    final header = Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.leading != null) ...[
          Padding(
            padding: EdgeInsets.only(right: spacing.sm),
            child: widget.leading,
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
                  widget.title,
                  style: textStyles.mdSemiboldColored(scheme.onSurface),
                ),
              ),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 240),
                child: Text(
                  widget.source,
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

    final trimmedDescription = widget.description.trim();
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
      if (widget.body != null) ...[
        SizedBox(height: spacing.md),
        widget.body!,
      ],
    ];

    final footer = <Widget>[
      SizedBox(height: spacing.md),
      widget.metadata,
      SizedBox(height: spacing.md),
      Align(alignment: AlignmentDirectional.centerEnd, child: widget.action),
    ];

    final body = LayoutBuilder(
      builder: (context, constraints) {
        final children = [header, ...middleChildren, ...footer];
        if (!constraints.hasBoundedHeight) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: children,
          );
        }
        // Keep content top-aligned in fixed grid cells; clip instead of
        // stretching blank space through an Expanded filler.
        return ClipRect(
          child: SingleChildScrollView(
            physics: const NeverScrollableScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: children,
            ),
          ),
        );
      },
    );

    return MouseRegion(
      onEnter: (_) {
        if (!widget.enabled) return;
        setState(() => _hovered = true);
      },
      onExit: (_) => setState(() => _hovered = false),
      cursor: interactive ? SystemMouseCursors.click : SystemMouseCursors.basic,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: interactive ? widget.onTap : null,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          decoration: BoxDecoration(
            color: scheme.surfaceContainer,
            borderRadius: BorderRadius.circular(_radius),
            border: Border.all(color: borderColor),
            boxShadow: _hovered
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.10),
                      blurRadius: 14,
                      offset: const Offset(0, 6),
                    ),
                  ]
                : null,
          ),
          clipBehavior: Clip.antiAlias,
          padding: EdgeInsets.all(spacing.md),
          child: body,
        ),
      ),
    );
  }
}
