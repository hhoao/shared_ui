import 'package:flutter/foundation.dart';

/// Standard control size presets for buttons (theme default is [medium]).
enum TpControlSize { small, medium, large }

/// Resolved geometry for one [TpControlSize] (or the outline-input track).
@immutable
final class TpControlSizeMetrics {
  const TpControlSizeMetrics({
    required this.height,
    required this.minWidth,
    required this.horizontalPadding,
    required this.verticalPadding,
  });

  final double height;
  final double minWidth;
  final double horizontalPadding;
  final double verticalPadding;

  TpControlSizeMetrics scaleBy(double m) => TpControlSizeMetrics(
    height: height * m,
    minWidth: minWidth * m,
    horizontalPadding: horizontalPadding * m,
    verticalPadding: verticalPadding * m,
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TpControlSizeMetrics &&
          height == other.height &&
          minWidth == other.minWidth &&
          horizontalPadding == other.horizontalPadding &&
          verticalPadding == other.verticalPadding;

  @override
  int get hashCode =>
      Object.hash(height, minWidth, horizontalPadding, verticalPadding);
}

/// Shared control tokens: button S/M/L presets, outline-input track, radius.
@immutable
final class TpControlMetrics {
  const TpControlMetrics({
    required this.scale,
    required this.radius,
    required this.input,
    required this.small,
    required this.medium,
    required this.large,
  });

  final double scale;

  /// Corner radius for outline inputs and standard buttons (not stadium/pill).
  final double radius;

  /// Outline [TextField] content insets and height — separate from buttons.
  final TpControlSizeMetrics input;

  final TpControlSizeMetrics small;
  final TpControlSizeMetrics medium;
  final TpControlSizeMetrics large;

  /// Default painted height (medium button).
  double get height => medium.height;
  double get minWidth => medium.minWidth;
  double get horizontalPadding => medium.horizontalPadding;
  double get verticalPadding => medium.verticalPadding;

  static const double radiusBase = 8;
  static const double heightBase = 26;
  static const double minWidthBase = 64;
  static const double horizontalPaddingBase = 8;
  static const double verticalPaddingBase = 8;

  static const double inputHeightBase = 32;
  static const double inputHorizontalPaddingBase = 10;
  static const double inputVerticalPaddingBase = 8;

  static const TpControlSizeMetrics inputBase = TpControlSizeMetrics(
    height: inputHeightBase,
    minWidth: minWidthBase,
    horizontalPadding: inputHorizontalPaddingBase,
    verticalPadding: inputVerticalPaddingBase,
  );
  static const TpControlSizeMetrics smallBase = TpControlSizeMetrics(
    height: 20,
    minWidth: 48,
    horizontalPadding: 8,
    verticalPadding: 4,
  );
  static const TpControlSizeMetrics mediumBase = TpControlSizeMetrics(
    height: heightBase,
    minWidth: minWidthBase,
    horizontalPadding: horizontalPaddingBase,
    verticalPadding: verticalPaddingBase,
  );
  static const TpControlSizeMetrics largeBase = TpControlSizeMetrics(
    height: 36,
    minWidth: 80,
    horizontalPadding: 16,
    verticalPadding: 10,
  );

  factory TpControlMetrics.fromScale(double scale) => TpControlMetrics(
    scale: scale,
    radius: radiusBase * scale,
    input: inputBase.scaleBy(scale),
    small: smallBase.scaleBy(scale),
    medium: mediumBase.scaleBy(scale),
    large: largeBase.scaleBy(scale),
  );

  TpControlSizeMetrics metricsFor(TpControlSize size) => switch (size) {
    TpControlSize.small => small,
    TpControlSize.medium => medium,
    TpControlSize.large => large,
  };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TpControlMetrics &&
          scale == other.scale &&
          radius == other.radius &&
          input == other.input &&
          small == other.small &&
          medium == other.medium &&
          large == other.large;

  @override
  int get hashCode => Object.hash(scale, radius, input, small, medium, large);
}
