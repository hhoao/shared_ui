import 'package:flutter/material.dart';

import '../../theme/tp_text_styles.dart';
import '../../theme/tp_theme.dart';

/// Title + optional trailing actions for card / management headers.
class TpCardHeader extends StatelessWidget {
  const TpCardHeader({
    super.key,
    required this.title,
    this.trailing,
    this.crossAxisAlignment = CrossAxisAlignment.center,
  });

  final String title;
  final Widget? trailing;
  final CrossAxisAlignment crossAxisAlignment;

  @override
  Widget build(BuildContext context) {
    final textBase = Theme.of(context).colorScheme.onSurface;
    final spacing = context.tpSpacing;
    final titleText = Text(
      title,
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
      style: TpTextStyles.of(context).mdSemiboldTightSnugColored(textBase),
    );

    if (trailing == null) return titleText;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: crossAxisAlignment,
      children: [
        Flexible(
          fit: FlexFit.loose,
          child: Padding(
            padding: EdgeInsets.only(right: spacing.md),
            child: titleText,
          ),
        ),
        Flexible(
          fit: FlexFit.loose,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            reverse: true,
            child: trailing!,
          ),
        ),
      ],
    );
  }
}
