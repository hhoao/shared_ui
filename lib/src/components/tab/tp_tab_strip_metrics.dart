/// Shared height / padding for [TpTabStrip] surfaces.
class TpTabStripMetrics {
  const TpTabStripMetrics({required this.height, this.horizontalPadding = 0});

  /// Strip / title-bar row height.
  final double height;

  /// Horizontal inset around the strip content.
  final double horizontalPadding;

  /// Center workbench / session strip.
  static const shell = TpTabStripMetrics(height: 40);

  /// Floating panel title tabs.
  static const compact = TpTabStripMetrics(height: 36);
}
