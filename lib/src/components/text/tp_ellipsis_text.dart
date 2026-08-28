import 'package:flutter/material.dart';

/// A label that ellipsizes at [maxLines] and, only when the text actually
/// overflows its bounds, reveals the full content in a platform-adaptive
/// [Tooltip] (hover on desktop, long-press on touch devices).
///
/// Prefer this over a raw `Text(overflow: TextOverflow.ellipsis)` wherever a
/// truncated label must stay discoverable (model names, preset names, …).
class TpEllipsisText extends StatelessWidget {
  const TpEllipsisText(
    this.text, {
    super.key,
    this.style,
    this.maxLines = 1,
    this.textAlign,
    this.textDirection,
    this.overflow = TextOverflow.ellipsis,
    this.softWrap = false,
  });

  final String text;
  final TextStyle? style;
  final int? maxLines;
  final TextAlign? textAlign;
  final TextDirection? textDirection;
  final TextOverflow overflow;
  final bool softWrap;

  bool _overflows(BuildContext context, double width) {
    final max = maxLines;
    if (max == null || max <= 0) return false;
    final effectiveStyle = style ?? DefaultTextStyle.of(context).style;
    final painter = TextPainter(
      text: TextSpan(text: text, style: effectiveStyle),
      textDirection: textDirection ?? Directionality.of(context),
      textAlign: textAlign ?? TextAlign.start,
      maxLines: max,
      textScaler: MediaQuery.textScalerOf(context),
    )..layout(maxWidth: width.isFinite ? width : double.infinity);
    return painter.didExceedMaxLines;
  }

  @override
  Widget build(BuildContext context) {
    final rendered = Text(
      text,
      style: style,
      maxLines: maxLines,
      overflow: overflow,
      textAlign: textAlign,
      softWrap: softWrap,
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        if (!_overflows(context, width)) return rendered;
        return Tooltip(message: text, child: rendered);
      },
    );
  }
}
