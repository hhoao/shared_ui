import 'package:flutter/material.dart';

/// Top contentPadding — slightly taller than sides so ascenders clear the border.
const double kTpTextareaTopPadding = 16;

/// Bottom contentPadding before the resize-grip inset.
const double kTpTextareaBottomPadding = 12;

/// Horizontal contentPadding (each side). Matches shadcn `px-3`.
const double kTpTextareaHorizontalPadding = 12;

/// Extra bottom inset so the last line clears the resize grip.
const double kTpTextareaBottomInset = 10;

/// Default multiline [InputDecoration.contentPadding] for [TpTextarea].
const EdgeInsets kTpTextareaContentPadding = EdgeInsets.only(
  left: kTpTextareaHorizontalPadding,
  right: kTpTextareaHorizontalPadding,
  top: kTpTextareaTopPadding,
  bottom: kTpTextareaBottomPadding + kTpTextareaBottomInset,
);

/// Outline border width budget for outer height (1px idle; 1.5px when focused).
const double kTpTextareaBorderWidth = 1;

/// Hit-target size for the resize grip (visual paint stays smaller).
const double kTpTextareaResizeGripHitSize = 20;

/// Painted grip size.
const double kTpTextareaResizeGripVisualSize = 8;

/// Multiline textarea padding / chrome metrics.
@immutable
class TpTextareaTheme {
  const TpTextareaTheme({
    this.topPadding = kTpTextareaTopPadding,
    this.bottomPadding = kTpTextareaBottomPadding,
    this.horizontalPadding = kTpTextareaHorizontalPadding,
    this.bottomInset = kTpTextareaBottomInset,
    this.borderWidth = kTpTextareaBorderWidth,
    this.defaultMinHeight = 80,
    this.defaultMaxHeight = 500,
    this.hintAlpha = 0.55,
  });

  factory TpTextareaTheme.defaults() => const TpTextareaTheme();

  final double topPadding;
  final double bottomPadding;
  final double horizontalPadding;
  final double bottomInset;
  final double borderWidth;
  final double defaultMinHeight;
  final double defaultMaxHeight;
  final double hintAlpha;

  EdgeInsets get contentPadding => EdgeInsets.only(
    left: horizontalPadding,
    right: horizontalPadding,
    top: topPadding,
    bottom: bottomPadding + bottomInset,
  );

  double get verticalChrome =>
      topPadding + bottomPadding + bottomInset + borderWidth * 2;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TpTextareaTheme &&
          topPadding == other.topPadding &&
          bottomPadding == other.bottomPadding &&
          horizontalPadding == other.horizontalPadding &&
          bottomInset == other.bottomInset &&
          borderWidth == other.borderWidth &&
          defaultMinHeight == other.defaultMinHeight &&
          defaultMaxHeight == other.defaultMaxHeight &&
          hintAlpha == other.hintAlpha;

  @override
  int get hashCode => Object.hash(
    topPadding,
    bottomPadding,
    horizontalPadding,
    bottomInset,
    borderWidth,
    defaultMinHeight,
    defaultMaxHeight,
    hintAlpha,
  );
}

/// Total vertical chrome (padding + border) for the TpTextarea path.
double tpTextareaVerticalChrome({
  double topPadding = kTpTextareaTopPadding,
  double bottomPadding = kTpTextareaBottomPadding,
  double bottomInset = kTpTextareaBottomInset,
  double borderWidth = kTpTextareaBorderWidth,
}) =>
    topPadding + bottomPadding + bottomInset + borderWidth * 2;

/// Outer shell height for [lines] of [style], including TpTextarea chrome.
double tpTextareaHeightForLines(
  TextStyle style, {
  required int lines,
  double topPadding = kTpTextareaTopPadding,
  double bottomPadding = kTpTextareaBottomPadding,
  double bottomInset = kTpTextareaBottomInset,
  double borderWidth = kTpTextareaBorderWidth,
}) {
  assert(lines >= 1);
  final fontSize = style.fontSize ?? 14;
  final heightFactor = style.height ?? 20 / 14;
  final lineHeight = fontSize * heightFactor;
  return lines * lineHeight +
      tpTextareaVerticalChrome(
        topPadding: topPadding,
        bottomPadding: bottomPadding,
        bottomInset: bottomInset,
        borderWidth: borderWidth,
      );
}
