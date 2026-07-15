import 'package:flutter/foundation.dart';

/// Default metrics for [TpSelect] overlays and chrome.
@immutable
class TpSelectTheme {
  const TpSelectTheme({
    this.defaultOverlayHeight = 260,
    this.triggerBorderRadius = 6,
    this.menuBorderRadius = 10,
    this.listItemBorderRadius = 6,
    this.searchMinItems = 8,
  });

  factory TpSelectTheme.defaults() => const TpSelectTheme();

  final double defaultOverlayHeight;
  final double triggerBorderRadius;
  final double menuBorderRadius;
  final double listItemBorderRadius;
  final int searchMinItems;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TpSelectTheme &&
          defaultOverlayHeight == other.defaultOverlayHeight &&
          triggerBorderRadius == other.triggerBorderRadius &&
          menuBorderRadius == other.menuBorderRadius &&
          listItemBorderRadius == other.listItemBorderRadius &&
          searchMinItems == other.searchMinItems;

  @override
  int get hashCode => Object.hash(
    defaultOverlayHeight,
    triggerBorderRadius,
    menuBorderRadius,
    listItemBorderRadius,
    searchMinItems,
  );
}
