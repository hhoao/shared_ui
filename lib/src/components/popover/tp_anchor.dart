// Portal positioning types adapted from AppFlowy UI / flutter_shadcn_ui.

import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Base type for [TpPortal] overlay positioning.
sealed class TpAnchorBase {
  const TpAnchorBase();
}

/// Automatically positions the overlay relative to the anchor widget.
@immutable
class TpAnchorAuto extends TpAnchorBase {
  const TpAnchorAuto({
    this.offset = Offset.zero,
    this.followTargetOnResize = true,
    this.followerAnchor = Alignment.bottomCenter,
    this.targetAnchor = Alignment.bottomCenter,
  });

  final Offset offset;
  final bool followTargetOnResize;
  final Alignment followerAnchor;
  final Alignment targetAnchor;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is TpAnchorAuto &&
        other.offset == offset &&
        other.followTargetOnResize == followTargetOnResize &&
        other.followerAnchor == followerAnchor &&
        other.targetAnchor == targetAnchor;
  }

  @override
  int get hashCode =>
      Object.hash(offset, followTargetOnResize, followerAnchor, targetAnchor);
}

/// Positions the overlay with explicit alignments on anchor and follower.
@immutable
class TpAnchor extends TpAnchorBase {
  const TpAnchor({
    this.childAlignment = Alignment.topLeft,
    this.overlayAlignment = Alignment.bottomLeft,
    this.offset = Offset.zero,
  });

  final Alignment childAlignment;
  final Alignment overlayAlignment;
  final Offset offset;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is TpAnchor &&
        other.childAlignment == childAlignment &&
        other.overlayAlignment == overlayAlignment &&
        other.offset == offset;
  }

  @override
  int get hashCode => Object.hash(childAlignment, overlayAlignment, offset);
}

/// Extra hit-test padding on the overlay so the pointer can cross [TpAnchor.offset]
/// without leaving the [TapRegion] (avoids spurious [TapRegion.onTapOutside]).
EdgeInsets tapRegionBridgeInsetsForAnchor(TpAnchorBase anchor) {
  if (anchor is! TpAnchor) return EdgeInsets.zero;
  final offset = anchor.offset;
  final child = anchor.childAlignment;
  final target = anchor.overlayAlignment;

  var top = 0.0;
  var bottom = 0.0;
  var left = 0.0;
  var right = 0.0;

  if (child.y < target.y) {
    if (offset.dy > 0) top = offset.dy;
    if (offset.dy < 0) bottom = -offset.dy;
  } else if (child.y > target.y) {
    if (offset.dy > 0) bottom = offset.dy;
    if (offset.dy < 0) top = -offset.dy;
  }

  if (child.x < target.x) {
    if (offset.dx > 0) left = offset.dx;
    if (offset.dx < 0) right = -offset.dx;
  } else if (child.x > target.x) {
    if (offset.dx > 0) right = offset.dx;
    if (offset.dx < 0) left = -offset.dx;
  }

  return EdgeInsets.fromLTRB(left, top, right, bottom);
}

/// Point on a rectangle for an [Alignment] (-1..1 → edges/center).
Offset alignmentPointOnRect(Size size, Alignment alignment) {
  return Offset(
    (1 + alignment.x) / 2 * size.width,
    (1 + alignment.y) / 2 * size.height,
  );
}

/// Clamps an overlay's top-left into the overlay ancestor's bounds.
///
/// An overlay that does not fit below [target] is flipped above it, matching
/// [showMenu] / [RelativeRect] behaviour.
Offset clampOverlayTopLeft({
  required Offset target,
  required Size size,
  required Size childSize,
}) {
  var x = target.dx;
  var y = target.dy;
  if (x + childSize.width > size.width) {
    x = size.width - childSize.width;
  }
  if (y + childSize.height > size.height) {
    y = target.dy - childSize.height;
  }
  x = x.clamp(0.0, (size.width - childSize.width).clamp(0.0, size.width));
  y = y.clamp(0.0, (size.height - childSize.height).clamp(0.0, size.height));
  return Offset(x, y);
}

/// Pins [followerAlignment] of the overlay to [targetPoint].
///
/// [targetPoint] is resolved during build, while the follower point is
/// resolved inside [getPositionForChild] from the size the overlay actually
/// laid out with. Measuring the overlay before layout would freeze the
/// position on the previous frame's height, so a bottom-aligned panel that
/// grows (a refresh error line appearing, for example) would be flipped above
/// the anchor and jump upward.
///
/// When the panel does not fit on the primary side it flips to
/// [flipTargetPoint] — the mirrored point on the anchor's opposite edge, so a
/// menu flipped above its trigger ends at the trigger's *top* edge instead of
/// its bottom edge (which would cover the trigger). With [capHeightToAnchorSide]
/// the panel is additionally capped to the roomier side, so a menu tall enough
/// to fit on neither side scrolls instead of spilling over the trigger.
class TpOverlayPositionDelegate extends SingleChildLayoutDelegate {
  const TpOverlayPositionDelegate({
    required this.targetPoint,
    required this.followerAlignment,
    Offset? flipTargetPoint,
    Alignment? flipFollowerAlignment,
    this.capHeightToAnchorSide = false,
  }) : flipTargetPoint = flipTargetPoint ?? targetPoint,
       flipFollowerAlignment = flipFollowerAlignment ?? followerAlignment;

  final Offset targetPoint;
  final Alignment followerAlignment;

  /// Primary placement mirrored to the anchor's opposite side.
  final Offset flipTargetPoint;
  final Alignment flipFollowerAlignment;

  /// Caps the panel height to the larger of the two sides around the anchor.
  /// Only for content that scrolls; a fixed-size child would overflow instead.
  final bool capHeightToAnchorSide;

  static Offset _topLeft(Offset target, Alignment follower, Size childSize) =>
      target - alignmentPointOnRect(childSize, follower);

  static bool _fitsVertically(Offset topLeft, Size container, Size childSize) =>
      topLeft.dy >= 0 && topLeft.dy + childSize.height <= container.height;

  /// Tallest panel that stays inside [containerHeight] when pinned to [target]
  /// with [follower].
  static double _maxHeightFor(
    Offset target,
    Alignment follower,
    double containerHeight,
  ) {
    final topFraction = (follower.y + 1) / 2;
    final roomBelow = topFraction >= 1
        ? double.infinity
        : (containerHeight - target.dy) / (1 - topFraction);
    final roomAbove = topFraction <= 0
        ? double.infinity
        : target.dy / topFraction;
    return math.min(roomBelow, roomAbove);
  }

  static Offset _clampHorizontally(
    Offset topLeft,
    Size container,
    Size childSize,
  ) {
    final maxX = (container.width - childSize.width).clamp(
      0.0,
      container.width,
    );
    return Offset(topLeft.dx.clamp(0.0, maxX), topLeft.dy);
  }

  static Offset _clampInside(Offset topLeft, Size container, Size childSize) {
    final maxX = (container.width - childSize.width).clamp(
      0.0,
      container.width,
    );
    final maxY = (container.height - childSize.height).clamp(
      0.0,
      container.height,
    );
    return Offset(topLeft.dx.clamp(0.0, maxX), topLeft.dy.clamp(0.0, maxY));
  }

  @override
  BoxConstraints getConstraintsForChild(BoxConstraints constraints) {
    final loose = constraints.loosen();
    if (!capHeightToAnchorSide || !constraints.maxHeight.isFinite) {
      return loose;
    }
    final capped = math.max(
      _maxHeightFor(targetPoint, followerAlignment, constraints.maxHeight),
      _maxHeightFor(
        flipTargetPoint,
        flipFollowerAlignment,
        constraints.maxHeight,
      ),
    );
    if (!capped.isFinite || capped >= loose.maxHeight) return loose;
    return loose.copyWith(maxHeight: math.max(0, capped));
  }

  @override
  Offset getPositionForChild(Size size, Size childSize) {
    final primary = _topLeft(targetPoint, followerAlignment, childSize);
    if (_fitsVertically(primary, size, childSize)) {
      return _clampHorizontally(primary, size, childSize);
    }
    final flipped = _topLeft(flipTargetPoint, flipFollowerAlignment, childSize);
    if (_fitsVertically(flipped, size, childSize)) {
      return _clampHorizontally(flipped, size, childSize);
    }
    // Neither side has enough room: keep the panel on the roomier side and
    // clamp it inside the viewport.
    final roomPrimary = size.height - targetPoint.dy;
    final roomFlipped = flipTargetPoint.dy;
    return _clampInside(
      roomFlipped > roomPrimary ? flipped : primary,
      size,
      childSize,
    );
  }

  @override
  bool shouldRelayout(TpOverlayPositionDelegate oldDelegate) =>
      targetPoint != oldDelegate.targetPoint ||
      followerAlignment != oldDelegate.followerAlignment ||
      flipTargetPoint != oldDelegate.flipTargetPoint ||
      flipFollowerAlignment != oldDelegate.flipFollowerAlignment ||
      capHeightToAnchorSide != oldDelegate.capHeightToAnchorSide;
}

/// Positions the overlay at a fixed global offset (screen coordinates).
///
/// Used for right-click menus: the menu's top-left is placed at [offset],
/// matching legacy [showMenu] / [RelativeRect] behavior (not tooltip centering).
@immutable
class TpGlobalAnchor extends TpAnchorBase {
  const TpGlobalAnchor(this.offset);

  final Offset offset;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is TpGlobalAnchor && other.offset == offset;
  }

  @override
  int get hashCode => offset.hashCode;
}

/// Positions a context-menu panel with its top-left at [target] (overlay-local).
class ContextMenuOverlayPositionDelegate extends SingleChildLayoutDelegate {
  const ContextMenuOverlayPositionDelegate({required this.target});

  final Offset target;

  @override
  BoxConstraints getConstraintsForChild(BoxConstraints constraints) =>
      constraints.loosen();

  @override
  Offset getPositionForChild(Size size, Size childSize) =>
      clampOverlayTopLeft(target: target, size: size, childSize: childSize);

  @override
  bool shouldRelayout(ContextMenuOverlayPositionDelegate oldDelegate) {
    return target != oldDelegate.target;
  }
}
