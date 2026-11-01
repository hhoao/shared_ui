// Portal positioning types adapted from AppFlowy UI / flutter_shadcn_ui.

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
class TpOverlayPositionDelegate extends SingleChildLayoutDelegate {
  const TpOverlayPositionDelegate({
    required this.targetPoint,
    required this.followerAlignment,
  });

  final Offset targetPoint;
  final Alignment followerAlignment;

  @override
  BoxConstraints getConstraintsForChild(BoxConstraints constraints) =>
      constraints.loosen();

  @override
  Offset getPositionForChild(Size size, Size childSize) => clampOverlayTopLeft(
    target: targetPoint - alignmentPointOnRect(childSize, followerAlignment),
    size: size,
    childSize: childSize,
  );

  @override
  bool shouldRelayout(TpOverlayPositionDelegate oldDelegate) =>
      targetPoint != oldDelegate.targetPoint ||
      followerAlignment != oldDelegate.followerAlignment;
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
