import 'package:flutter/material.dart';

import '../../theme/tp_text_styles.dart';

/// Small uppercase-style section label inside a preference card / panel.
class TpSectionHeader extends StatelessWidget {
  const TpSectionHeader({
    super.key,
    required this.title,
    this.padding = const EdgeInsets.fromLTRB(20, 20, 20, 8),
  });

  final String title;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final styles = TpTextStyles.of(context);
    return Padding(
      padding: padding,
      child: Text(title, style: styles.xsTrackColored(cs.onSurfaceVariant)),
    );
  }
}
