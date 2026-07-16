import 'package:flutter/material.dart';

/// Resolves a right-click position for [showTpActionMenu] from the
/// widget that owns [context].
///
/// Always prefers [TapDownDetails.globalPosition]: it is in screen coordinates
/// and matches the pointer regardless of which descendant received the gesture.
/// Converting [TapDownDetails.localPosition] through [context]'s [RenderBox]
/// breaks when the caller only supplied [TapDownDetails.globalPosition] (local
/// defaults to zero) or when local coords belong to a nested hit target.
Offset contextMenuGlobalPosition(BuildContext context, TapDownDetails details) {
  // [context] is kept so call sites document which widget owns the menu.
  assert(context.mounted);
  return details.globalPosition;
}
