import 'package:flutter/material.dart';

import '../../theme/tp_theme.dart';

/// How [TpFormFieldLayout] places [label] relative to the control.
enum TpFormFieldLayoutStyle {
  /// Label above the control (default).
  stacked,

  /// Label and control on one row (IDEA-style form rows).
  inline,
}

/// Label / control / description / error layout for [TpFormField].
class TpFormFieldLayout extends StatelessWidget {
  const TpFormFieldLayout({
    super.key,
    this.child,
    this.label,
    this.error,
    this.description,
    this.style = TpFormFieldLayoutStyle.stacked,
    this.labelWidth = 140,
  });

  final Widget? child;
  final Widget? label;
  final Widget? error;
  final Widget? description;
  final TpFormFieldLayoutStyle style;

  /// Fixed label column width when [style] is [TpFormFieldLayoutStyle.inline].
  final double labelWidth;

  @override
  Widget build(BuildContext context) {
    final spacing = context.tpSpacing;
    final textTheme = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    final body = textTheme.bodyMedium ?? const TextStyle();
    final labelStyle = body.copyWith(
      fontWeight: FontWeight.w500,
      color: scheme.onSurface,
    );
    final descriptionStyle = body.copyWith(color: scheme.onSurfaceVariant);
    final errorStyle = body.copyWith(
      fontWeight: FontWeight.w500,
      color: scheme.error,
    );
    final gap = spacing.sm;
    final inlineGap = spacing.md;

    final labeledControl = style == TpFormFieldLayoutStyle.inline
        ? _inlineRow(labelStyle, inlineGap)
        : _stackedColumn(labelStyle, gap);

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        labeledControl,
        if (description != null)
          Padding(
            padding: EdgeInsets.only(
              top: gap,
              left: style == TpFormFieldLayoutStyle.inline
                  ? labelWidth + inlineGap
                  : 0,
            ),
            child: DefaultTextStyle(
              style: descriptionStyle,
              child: description!,
            ),
          ),
        if (error != null)
          Padding(
            padding: EdgeInsets.only(
              top: gap,
              left: style == TpFormFieldLayoutStyle.inline
                  ? labelWidth + inlineGap
                  : 0,
            ),
            child: DefaultTextStyle(
              style: errorStyle,
              child: error!,
            ),
          ),
      ],
    );
  }

  Widget _stackedColumn(TextStyle labelStyle, double gap) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label != null)
          Padding(
            padding: EdgeInsets.only(bottom: gap),
            child: DefaultTextStyle(style: labelStyle, child: label!),
          ),
        if (child != null) child!,
      ],
    );
  }

  Widget _inlineRow(TextStyle labelStyle, double inlineGap) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label != null)
          SizedBox(
            width: labelWidth,
            child: Padding(
              padding: EdgeInsets.only(right: inlineGap),
              child: DefaultTextStyle(
                style: labelStyle,
                textAlign: TextAlign.left,
                child: label!,
              ),
            ),
          )
        else
          SizedBox(width: labelWidth + inlineGap),
        if (child != null)
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [child!],
            ),
          ),
      ],
    );
  }
}
