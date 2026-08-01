import 'package:flutter/material.dart';

import '../../theme/tp_theme.dart';
import 'tp_dialog.dart';
import 'tp_dialog_mobile_nav_bar.dart';

/// Chrome for simple [showTpDialog] page Dialogs on **narrow and wide**.
///
/// Narrow: system-style mobile nav bar + Expanded SafeArea body.
/// Wide: [TpDialogHeader] + theme content padding; shrink-wraps unless
/// [fillBody] is true.
///
/// Never used automatically by [showTpDialog]; callers wrap non-[TpDialogNavShell]
/// page content explicitly. Do **not** wrap [TpDialogNavShell].
///
/// [mobileBreakpoint] must match the paired [showTpDialog] call.
///
/// When [fillBody] is false on wide, [child] must report an intrinsic height
/// (`Column(mainAxisSize: min)`). Do not use an outer [SingleChildScrollView] on
/// wide — it expands to [TpDialog.maxHeight]. Scroll on narrow (Expanded body) or
/// use [fillBody] true with an inner scroll region instead.
class TpDialogPageShell extends StatelessWidget {
  const TpDialogPageShell({
    required this.title,
    required this.child,
    this.onClose,
    this.trailing,
    this.mobileBreakpoint = 768,
    this.fillBody = false,
    this.titleAlignment = Alignment.topLeft,
    super.key,
  });

  final String title;
  final Widget child;
  final VoidCallback? onClose;
  final Widget? trailing;

  /// Must match the paired [showTpDialog] `mobileBreakpoint`.
  final double mobileBreakpoint;

  /// Wide only: expand body under header. Narrow always expands (ignored).
  /// Required `true` when [child] uses vertical [Expanded].
  final bool fillBody;

  /// Wide header only; narrow keeps centered mobile title.
  final Alignment titleAlignment;

  static const double _headerBodyGap = 20;

  @override
  Widget build(BuildContext context) {
    final close = onClose ?? () => Navigator.of(context).pop();
    final isNarrow = MediaQuery.sizeOf(context).width < mobileBreakpoint;

    if (isNarrow) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TpDialogMobileNavBar(
            title: title,
            onLeading: close,
            leadingTooltip: MaterialLocalizations.of(context).cancelButtonLabel,
            trailing: trailing,
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

    final dialogTheme = context.tpTheme.dialogTheme;
    final padding = dialogTheme.contentPadding;
    final h = dialogTheme.contentHorizontalInset;
    final vTop = padding.top;
    final vBottom = padding.bottom;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: fillBody ? MainAxisSize.max : MainAxisSize.min,
      children: [
        Padding(
          padding: EdgeInsets.fromLTRB(h, vTop, h, 0),
          child: TpDialogHeader(
            title: title,
            onClose: close,
            titleAlignment: titleAlignment,
            showDividerBelow: false,
            trailing: trailing,
            horizontalInset: 0,
          ),
        ),
        if (!fillBody)
          Padding(
            padding: EdgeInsets.fromLTRB(h, _headerBodyGap, h, vBottom),
            child: child,
          )
        else
          Expanded(
            child: Padding(
              padding: EdgeInsets.fromLTRB(h, 0, h, vBottom),
              child: child,
            ),
          ),
      ],
    );
  }
}
