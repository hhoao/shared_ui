import 'package:flutter/material.dart';

import '../../theme/tp_theme.dart';

/// Flat muted-icon empty state for lists and library panes.
class TpEmptyState extends StatelessWidget {
  const TpEmptyState({
    required this.icon,
    required this.title,
    this.hint,
    this.actionLabel,
    this.onAction,
    this.centered = false,
    super.key,
  });

  final IconData icon;
  final String title;
  final String? hint;
  final String? actionLabel;
  final VoidCallback? onAction;
  final bool centered;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final spacing = context.tpSpacing;
    final textBase = cs.onSurface;
    final content = Padding(
      padding: EdgeInsets.symmetric(vertical: spacing.xl),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: context.tpIconSizes.hero,
            color: textBase.withValues(alpha: 0.35),
          ),
          SizedBox(height: spacing.md),
          Text(
            title,
            style: (textTheme.bodyMedium ?? const TextStyle()).copyWith(
              color: textBase,
              fontWeight: FontWeight.w600,
            ),
          ),
          if (hint != null && hint!.isNotEmpty) ...[
            SizedBox(height: spacing.xs + spacing.xxs),
            Text(
              hint!,
              textAlign: TextAlign.center,
              style: (textTheme.bodySmall ?? const TextStyle()).copyWith(
                color: textBase.withValues(alpha: 0.55),
              ),
            ),
          ],
          if (actionLabel != null && onAction != null) ...[
            SizedBox(height: spacing.sm + spacing.xxs),
            TextButton(onPressed: onAction, child: Text(actionLabel!)),
          ],
        ],
      ),
    );

    if (centered) {
      return Center(child: content);
    }
    return content;
  }
}
