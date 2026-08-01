import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../theme/tp_text_styles.dart';
import '../../theme/tp_theme.dart';
import '../hover/tp_hover.dart';

/// Presentation-only tab chip for [TpTabStrip] hosts.
///
/// No domain types — hosts pass [title], [leading], [working], and menu hooks.
class TpTabChip extends StatefulWidget {
  const TpTabChip({
    required this.title,
    required this.active,
    required this.onTap,
    required this.onClose,
    this.leading,
    this.working = false,
    this.preview = false,
    this.accentColor,
    this.maxWidth = 200,
    this.tooltip,
    this.onSecondaryTapDown,
    this.onLongPress,
    this.actions,
    this.forceShowChrome = false,
    super.key,
  });

  final String title;
  final bool active;
  final VoidCallback onTap;
  final VoidCallback onClose;
  final Widget? leading;
  final bool working;
  final bool preview;
  final Color? accentColor;
  final double maxWidth;
  final String? tooltip;
  final GestureTapDownCallback? onSecondaryTapDown;
  final VoidCallback? onLongPress;
  final Widget? actions;

  /// Keep close / leading chrome visible (e.g. while a host menu is open).
  final bool forceShowChrome;

  @override
  State<TpTabChip> createState() => _TpTabChipState();
}

class _TpTabChipState extends State<TpTabChip> {
  var _hovered = false;

  /// Touch platforms have no hover; keep chrome visible on Android.
  bool get _showChrome =>
      widget.active ||
      _hovered ||
      widget.forceShowChrome ||
      defaultTargetPlatform == TargetPlatform.android;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final styles = TpTextStyles.of(context);
    final active = widget.active;
    final Color fg = active ? cs.onSurface : cs.onSurfaceVariant;
    final Color accent = widget.accentColor ?? cs.primary;
    final double barAlpha = active ? 1.0 : (_hovered ? 0.7 : 0.4);
    final Color barColor = accent.withValues(alpha: barAlpha);
    final double iconAlpha = active ? 1.0 : (_hovered ? 0.9 : 0.8);
    final Color iconColor = accent.withValues(alpha: iconAlpha);
    final titleStyle = styles.smColored(
      widget.preview ? fg.withValues(alpha: 0.72) : fg,
    );

    return Tooltip(
      message: widget.tooltip ?? widget.title,
      waitDuration: const Duration(milliseconds: 500),
      child: MouseRegion(
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: widget.onTap,
          onSecondaryTapDown: widget.onSecondaryTapDown,
          onLongPress: widget.onLongPress,
          child: Material(
            color: active
                ? cs.surfaceContainerHigh
                : _hovered
                ? cs.onSurface.withValues(alpha: 0.05)
                : Colors.transparent,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
              side: BorderSide(
                color: active
                    ? cs.outlineVariant.withValues(alpha: 0.7)
                    : Colors.transparent,
              ),
            ),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: widget.onTap,
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: widget.maxWidth),
                child: Padding(
                  padding: const EdgeInsets.only(
                    left: 10,
                    right: 6,
                    top: 6,
                    bottom: 6,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      SizedBox(
                        width: 3,
                        height: context.tpIconSizes.md,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            color: barColor,
                            borderRadius: BorderRadius.circular(1.5),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      if (widget.working)
                        SizedBox(
                          width: context.tpIconSizes.sm,
                          height: context.tpIconSizes.sm,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: iconColor,
                          ),
                        )
                      else if (widget.leading != null)
                        _TpTabChromeSlot(
                          visible: _showChrome,
                          child: IconTheme(
                            data: IconThemeData(
                              color: iconColor,
                              size: context.tpIconSizes.md,
                            ),
                            child: widget.leading!,
                          ),
                        ),
                      const SizedBox(width: 12),
                      Flexible(
                        child: Text(
                          widget.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: widget.preview
                              ? titleStyle.copyWith(
                                  fontStyle: FontStyle.italic,
                                )
                              : titleStyle,
                        ),
                      ),
                      if (widget.actions != null)
                        _TpTabChromeSlot(
                          visible: _showChrome,
                          child: widget.actions!,
                        ),
                      _TpTabChromeSlot(
                        visible: _showChrome,
                        child: _TpTabCloseButton(
                          active: active,
                          onTap: widget.onClose,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _TpTabChromeSlot extends StatelessWidget {
  const _TpTabChromeSlot({required this.visible, required this.child});

  final bool visible;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      ignoring: !visible,
      child: AnimatedOpacity(
        opacity: visible ? 1 : 0,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOut,
        child: child,
      ),
    );
  }
}

class _TpTabCloseButton extends StatelessWidget {
  const _TpTabCloseButton({required this.onTap, required this.active});

  final VoidCallback onTap;
  final bool active;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tint = active ? cs.onSurface : cs.onSurfaceVariant;
    final hoverAlpha = active ? 0.14 : 0.08;

    return TpHover(
      borderRadius: BorderRadius.circular(5),
      padding: const EdgeInsets.all(2),
      hoverColor: cs.onSurface.withValues(alpha: hoverAlpha),
      onTap: onTap,
      child: Icon(
        Icons.close,
        size: context.tpIconSizes.md,
        color: tint,
      ),
    );
  }
}
