import 'package:flutter/material.dart';

import '../../theme/components/tp_dialog_theme.dart';
import '../../theme/tp_theme.dart';
import '../icon_button/tp_icon_button.dart';

/// Shared shell for centered modal dialogs.
///
/// Wraps a bare [Dialog] with content padding plus width/height constraints.
/// Shape, inset padding, surface tint, and barrier color come from the global
/// `dialogTheme`; only the elevated card background is overridden here.
///
/// Pair with [TpDialogHeader] for the title row + close affordance.
class TpDialog extends StatelessWidget {
  const TpDialog({
    super.key,
    required this.child,
    this.maxWidth = 640,
    this.maxHeight,
    this.contentPadding,
    this.scrollable = false,
    this.backgroundColor,
    this.showBorder = false,
  });

  /// The dialog body. Typically a [Column] starting with a [TpDialogHeader].
  final Widget child;

  /// Maximum content width before the dialog stops growing horizontally.
  final double maxWidth;

  /// Optional maximum height; when set, overflowing content clips unless the
  /// child scrolls (via [scrollable] or [TpDialogPinnedLayout]).
  final double? maxHeight;

  /// Inner padding around [child]. Defaults to [TpDialogTheme.contentPadding].
  final EdgeInsets? contentPadding;

  /// When true, wraps the entire [child] in a [SingleChildScrollView].
  /// Prefer [TpDialogPinnedLayout] when only the middle should scroll while
  /// title/actions stay pinned.
  final bool scrollable;

  /// Overrides the dialog surface. Defaults to [ColorScheme.surfaceContainer].
  final Color? backgroundColor;

  /// Draws an [outlineVariant] border around the dialog shell.
  final bool showBorder;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final dialogTheme = context.tpTheme.dialogTheme;
    final padding = contentPadding ?? dialogTheme.contentPadding;
    final body = scrollable
        ? SingleChildScrollView(padding: padding, child: child)
        : Padding(padding: padding, child: child);

    return Dialog(
      backgroundColor: backgroundColor ?? cs.surfaceContainer,
      shape: showBorder
          ? dialogTheme.shape().copyWith(
              side: BorderSide(color: cs.outlineVariant.withValues(alpha: 0.7)),
            )
          : null,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: maxWidth,
          maxHeight: maxHeight ?? double.infinity,
        ),
        child: body,
      ),
    );
  }
}

/// Column layout for [TpDialog]: pinned [header]/[footer], scrollable [body].
///
/// Shrinks to content when short; when the dialog hits [TpDialog.maxHeight],
/// only [body] scrolls — title and actions stay visible.
class TpDialogPinnedLayout extends StatelessWidget {
  const TpDialogPinnedLayout({
    super.key,
    required this.header,
    required this.body,
    this.footer,
    this.bodyTopSpacing,
  });

  final Widget header;
  final Widget body;
  final Widget? footer;

  /// Gap between [header] and the scrollable [body].
  /// Defaults to [TpSpacing.lg].
  final double? bodyTopSpacing;

  @override
  Widget build(BuildContext context) {
    final top = bodyTopSpacing ?? context.tpSpacing.lg;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        header,
        Flexible(
          fit: FlexFit.loose,
          child: SingleChildScrollView(
            padding: EdgeInsets.only(top: top),
            child: body,
          ),
        ),
        if (footer != null) footer!,
      ],
    );
  }
}

/// Section divider that spans the full [TpDialog] width inside content padding.
///
/// [horizontalInset] should match [TpDialog.contentPadding]'s horizontal insets
/// when callers override the default content padding.
class TpDialogDivider extends StatelessWidget {
  const TpDialogDivider({super.key, this.horizontalInset});

  final double? horizontalInset;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final inset =
        horizontalInset ?? context.tpTheme.dialogTheme.contentHorizontalInset;
    return LayoutBuilder(
      builder: (context, constraints) {
        final fullWidth = constraints.maxWidth + inset * 2;
        return SizedBox(
          height: 1,
          child: OverflowBox(
            maxWidth: fullWidth,
            minWidth: fullWidth,
            alignment: Alignment.center,
            child: Divider(
              height: 1,
              thickness: 1,
              color: cs.outlineVariant.withValues(alpha: 0.5),
            ),
          ),
        );
      },
    );
  }
}

/// End-aligned action row for [TpDialog] footers (replaces [AlertDialog.actions]).
class TpDialogActions extends StatelessWidget {
  const TpDialogActions({
    super.key,
    required this.children,
    this.showDividerAbove = true,
    this.horizontalInset,
  });

  final List<Widget> children;

  /// When true (default), draws a full-width [TpDialogDivider] above the row.
  final bool showDividerAbove;

  /// Horizontal bleed for [TpDialogDivider]; match [TpDialog.contentPadding].
  final double? horizontalInset;

  @override
  Widget build(BuildContext context) {
    final spacing = context.tpSpacing;
    final inset =
        horizontalInset ?? context.tpTheme.dialogTheme.contentHorizontalInset;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (showDividerAbove) ...[
          SizedBox(height: spacing.lg),
          TpDialogDivider(horizontalInset: inset),
        ],
        Padding(
          padding: EdgeInsets.only(
            top: showDividerAbove ? spacing.lg : spacing.xl,
          ),
          child: OverflowBar(
            alignment: MainAxisAlignment.end,
            spacing: spacing.sm,
            children: children,
          ),
        ),
      ],
    );
  }
}

/// Dialog title with a top-right close button.
///
/// [titleAlignment] controls horizontal title placement. Defaults to
/// [Alignment.topLeft]; use [Alignment.center] when the title should sit in the
/// middle of the header (close button stays top-right).
class TpDialogHeader extends StatelessWidget {
  const TpDialogHeader({
    super.key,
    required this.title,
    this.onClose,
    this.titleAlignment = Alignment.topLeft,
    this.showDividerBelow = true,
    this.horizontalInset,
    this.trailing,
    this.closeTooltip,
  });

  final String title;

  /// Defaults to popping the enclosing [Navigator].
  final VoidCallback? onClose;

  /// Title alignment within the header row. [Alignment.center] centers the label;
  /// [Alignment.topLeft] left-aligns it (default).
  final Alignment titleAlignment;

  /// When true (default), draws a full-width [TpDialogDivider] below the title.
  final bool showDividerBelow;

  /// Horizontal bleed for [TpDialogDivider]; match [TpDialog.contentPadding].
  final double? horizontalInset;

  /// Optional actions between the title and the close button.
  final Widget? trailing;

  /// Close-button tooltip. Defaults to [MaterialLocalizations.cancelButtonLabel].
  final String? closeTooltip;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final spacing = context.tpSpacing;
    final inset =
        horizontalInset ?? context.tpTheme.dialogTheme.contentHorizontalInset;
    final centered = titleAlignment == Alignment.center;
    final tooltip =
        closeTooltip ?? MaterialLocalizations.of(context).cancelButtonLabel;
    // bodyLarge + semibold + snug matches former AppTextStyles.lgSemiboldSnug.
    final titleStyle = (textTheme.bodyLarge ?? const TextStyle()).copyWith(
      fontWeight: FontWeight.w600,
      height: 1.25,
      color: cs.onSurface,
    );
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Text(
                title,
                textAlign: centered ? TextAlign.center : TextAlign.start,
                style: titleStyle,
              ),
            ),
            if (trailing != null) ...[
              trailing!,
              SizedBox(width: spacing.xs),
            ],
            TpIconButton(
              icon: Icons.close_rounded,
              tooltip: tooltip,
              compact: true,
              color: cs.onSurfaceVariant,
              onTap: onClose ?? () => Navigator.of(context).pop(),
            ),
          ],
        ),
        if (showDividerBelow) ...[
          SizedBox(height: spacing.lg),
          TpDialogDivider(horizontalInset: inset),
        ],
      ],
    );
  }
}

/// Single-line text prompt dialog with correct [TextEditingController] lifecycle.
///
/// Returns the entered text on confirm, or `null` on cancel/close.
Future<String?> showTpTextPromptDialog(
  BuildContext context, {
  required String title,
  String initialText = '',
  String? hintText,
  String? labelText,
  required String confirmLabel,
  String? cancelLabel,
  double maxWidth = 480,
}) {
  return showDialog<String>(
    context: context,
    builder: (ctx) => TpTextPromptDialog(
      title: title,
      initialText: initialText,
      hintText: hintText,
      labelText: labelText,
      confirmLabel: confirmLabel,
      cancelLabel: cancelLabel,
      maxWidth: maxWidth,
    ),
  );
}

class TpTextPromptDialog extends StatefulWidget {
  const TpTextPromptDialog({
    super.key,
    required this.title,
    this.initialText = '',
    this.hintText,
    this.labelText,
    required this.confirmLabel,
    this.cancelLabel,
    this.maxWidth = 480,
  });

  final String title;
  final String initialText;
  final String? hintText;
  final String? labelText;
  final String confirmLabel;

  /// Defaults to [MaterialLocalizations.cancelButtonLabel].
  final String? cancelLabel;
  final double maxWidth;

  @override
  State<TpTextPromptDialog> createState() => _TpTextPromptDialogState();
}

class _TpTextPromptDialogState extends State<TpTextPromptDialog> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialText);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() => Navigator.of(context).pop(_controller.text);

  @override
  Widget build(BuildContext context) {
    final cancel =
        widget.cancelLabel ??
        MaterialLocalizations.of(context).cancelButtonLabel;
    return TpDialog(
      maxWidth: widget.maxWidth,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TpDialogHeader(
            title: widget.title,
            onClose: () => Navigator.of(context).pop(),
          ),
          SizedBox(height: context.tpSpacing.lg),
          TextField(
            controller: _controller,
            autofocus: true,
            decoration: InputDecoration(
              hintText: widget.hintText,
              labelText: widget.labelText,
            ),
            onSubmitted: (_) => _submit(),
          ),
          TpDialogActions(
            children: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text(cancel),
              ),
              FilledButton(
                onPressed: _submit,
                child: Text(widget.confirmLabel),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
