import 'package:flutter/foundation.dart';

/// Minimal control-facing typography tokens derived from [scale].
@immutable
final class TpTypography {
  const TpTypography({required this.scale});

  /// Raw UI scale multiplier (1.0 = design baseline).
  final double scale;

  double get bodySize => 14 * scale;
  double get labelSize => 12 * scale;
  double get titleSize => 16 * scale;

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is TpTypography && scale == other.scale;

  @override
  int get hashCode => scale.hashCode;
}
