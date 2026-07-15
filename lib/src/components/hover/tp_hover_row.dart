import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'tp_hover.dart';

export 'tp_hover.dart';

/// A full-width row with hover background and optional trailing actions that
/// appear on hover (always visible on Android where hover is unavailable).
class TpHoverRow extends StatefulWidget {
  const TpHoverRow({
    super.key,
    required this.child,
    this.trailing,
    this.trailingWidth,
    this.forceShowTrailing = false,
    this.showTrailingOnMobile = true,
    this.height,
    this.hoverColor,
    this.onTap,
    this.padding = const EdgeInsets.symmetric(horizontal: 2, vertical: 2),
    this.borderRadius = const BorderRadius.all(Radius.circular(8)),
    this.onHoverChanged,
  });

  final Widget child;
  final Widget? trailing;
  final double? trailingWidth;

  /// Keeps [trailing] mounted (e.g. while an overflow menu is open).
  final bool forceShowTrailing;

  /// When true, [trailing] stays visible on Android without hover.
  final bool showTrailingOnMobile;
  final double? height;
  final Color? hoverColor;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry padding;
  final BorderRadius borderRadius;
  final ValueChanged<bool>? onHoverChanged;

  @override
  State<TpHoverRow> createState() => _TpHoverRowState();
}

class _TpHoverRowState extends State<TpHoverRow> {
  var _hovered = false;

  bool get _showTrailing {
    if (widget.trailing == null) return false;
    if (widget.forceShowTrailing) return true;
    if (widget.showTrailingOnMobile &&
        defaultTargetPlatform == TargetPlatform.android) {
      return true;
    }
    return _hovered;
  }

  @override
  Widget build(BuildContext context) {
    return TpHover(
      hoverColor: widget.hoverColor,
      padding: widget.padding,
      borderRadius: widget.borderRadius,
      onTap: widget.onTap,
      onHoverChanged: (hovered) {
        setState(() => _hovered = hovered);
        widget.onHoverChanged?.call(hovered);
      },
      child: SizedBox(
        height: widget.height,
        width: double.infinity,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(child: widget.child),
            if (_showTrailing && widget.trailingWidth != null)
              SizedBox(width: widget.trailingWidth, child: widget.trailing!)
            else if (_showTrailing)
              widget.trailing!,
          ],
        ),
      ),
    );
  }
}
