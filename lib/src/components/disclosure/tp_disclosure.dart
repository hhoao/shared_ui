import 'package:flutter/material.dart';

import '../../theme/tp_text_styles.dart';
import '../preference/tp_preference_row.dart';

/// Collapsed-by-default panel for infrequently edited options.
///
/// Children are built lazily on first expand to avoid offscreen work.
class TpDisclosure extends StatefulWidget {
  const TpDisclosure({
    super.key,
    required this.title,
    this.subtitle,
    required this.children,
    this.tilePadding,
  });

  final String title;
  final String? subtitle;
  final List<Widget> children;
  final EdgeInsetsGeometry? tilePadding;

  @override
  State<TpDisclosure> createState() => _TpDisclosureState();
}

class _TpDisclosureState extends State<TpDisclosure> {
  var _childrenBuilt = false;

  @override
  Widget build(BuildContext context) {
    if (widget.children.isEmpty) return const SizedBox.shrink();

    final styles = TpTextStyles.of(context);
    return Material(
      color: Colors.transparent,
      child: ExpansionTile(
        initiallyExpanded: false,
        onExpansionChanged: (expanded) {
          if (expanded && !_childrenBuilt) {
            setState(() => _childrenBuilt = true);
          }
        },
        tilePadding: widget.tilePadding ?? TpPreferenceRow.defaultPadding,
        expandedAlignment: Alignment.centerLeft,
        childrenPadding: EdgeInsets.zero,
        collapsedShape: const RoundedRectangleBorder(side: BorderSide.none),
        shape: const RoundedRectangleBorder(side: BorderSide.none),
        title: Text(widget.title, style: styles.mdSemiboldTightSnug),
        subtitle: TpPreferenceRow.hasSubtitle(widget.subtitle)
            ? Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(widget.subtitle!, style: styles.mutedSm),
              )
            : null,
        children: _childrenBuilt ? widget.children : const [],
      ),
    );
  }
}
