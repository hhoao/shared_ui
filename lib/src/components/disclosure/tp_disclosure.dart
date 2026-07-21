import 'package:flutter/material.dart';

import '../../theme/tp_text_styles.dart';
import '../../theme/tp_theme.dart';
import '../preference/tp_preference_row.dart';

/// Collapsed-by-default panel for infrequently edited options.
///
/// Matches settings / member-config “Advanced” disclosures: preference title +
/// optional subtitle, chevron, lazy children. No [ExpansionTile] list chrome.
class TpDisclosure extends StatefulWidget {
  const TpDisclosure({
    super.key,
    required this.title,
    this.subtitle,
    required this.children,
    this.tilePadding,
    this.initiallyExpanded = false,
  });

  final String title;
  final String? subtitle;
  final List<Widget> children;
  final EdgeInsetsGeometry? tilePadding;
  final bool initiallyExpanded;

  @override
  State<TpDisclosure> createState() => _TpDisclosureState();
}

class _TpDisclosureState extends State<TpDisclosure>
    with SingleTickerProviderStateMixin {
  late var _expanded = widget.initiallyExpanded;
  late var _childrenBuilt = widget.initiallyExpanded;
  late final AnimationController _chevron;

  @override
  void initState() {
    super.initState();
    _chevron = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 180),
      value: _expanded ? 1 : 0,
    );
  }

  @override
  void dispose() {
    _chevron.dispose();
    super.dispose();
  }

  void _toggle() {
    final next = !_expanded;
    setState(() {
      _expanded = next;
      if (next) _childrenBuilt = true;
    });
    if (next) {
      _chevron.forward();
    } else {
      _chevron.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.children.isEmpty) return const SizedBox.shrink();

    final styles = TpTextStyles.of(context);
    final cs = Theme.of(context).colorScheme;
    final padding = widget.tilePadding ?? TpPreferenceRow.defaultPadding;
    final hasSub = TpPreferenceRow.hasSubtitle(widget.subtitle);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        MouseRegion(
          cursor: SystemMouseCursors.click,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: _toggle,
            child: Padding(
              padding: padding,
              child: Row(
                crossAxisAlignment: hasSub
                    ? CrossAxisAlignment.start
                    : CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.title,
                          style: styles.mdSemiboldTightSnug,
                        ),
                        if (hasSub)
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(
                              widget.subtitle!.trim(),
                              style: styles.mutedSm,
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Padding(
                    padding: EdgeInsets.only(top: hasSub ? 2 : 0),
                    child: RotationTransition(
                      turns: Tween<double>(begin: 0, end: 0.5).animate(
                        CurvedAnimation(
                          parent: _chevron,
                          curve: Curves.easeOutCubic,
                        ),
                      ),
                      child: Icon(
                        Icons.expand_more,
                        size: context.tpIconSizes.sm,
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        AnimatedSize(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOutCubic,
          alignment: Alignment.topCenter,
          child: !_expanded
              ? const SizedBox(width: double.infinity)
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: _childrenBuilt
                      ? widget.children
                      : const <Widget>[],
                ),
        ),
      ],
    );
  }
}
