import 'package:flutter/material.dart';

import '../../theme/tp_theme.dart';
import '../icon_button/tp_icon_button.dart';

/// Simple page chrome for narrow [showTpDialog] page routes.
///
/// Draws a top SafeArea app bar (title + close + optional [trailing]) and a
/// bottom SafeArea body. Never used automatically by [showTpDialog]; callers
/// wrap non-[TpDialogNavShell] page content explicitly.
///
/// Do **not** wrap [TpDialogNavShell] — it owns its own nav/detail bars.
class TpDialogPageShell extends StatelessWidget {
  const TpDialogPageShell({
    required this.title,
    required this.child,
    this.onClose,
    this.trailing,
    super.key,
  });

  final String title;
  final Widget child;
  final VoidCallback? onClose;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final spacing = context.tpSpacing;
    final titleStyle = (textTheme.bodyLarge ?? const TextStyle()).copyWith(
      fontWeight: FontWeight.w600,
      height: 1.25,
      color: cs.onSurface,
    );
    final close =
        onClose ?? () => Navigator.of(context, rootNavigator: true).pop();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SafeArea(
          bottom: false,
          child: Padding(
            padding: EdgeInsets.fromLTRB(spacing.lg, spacing.md, spacing.md, spacing.md),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Text(title, style: titleStyle),
                ),
                if (trailing != null) ...[
                  trailing!,
                  SizedBox(width: spacing.xs),
                ],
                TpIconButton(
                  icon: Icons.close_rounded,
                  tooltip: MaterialLocalizations.of(context).cancelButtonLabel,
                  compact: true,
                  color: cs.onSurfaceVariant,
                  onTap: close,
                ),
              ],
            ),
          ),
        ),
        Expanded(
          child: SafeArea(
            top: false,
            child: child,
          ),
        ),
      ],
    );
  }
}
