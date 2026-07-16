import 'package:flutter/material.dart';

import '../../theme/tp_text_styles.dart';
import 'tp_preference_row.dart';

/// Preference / settings block: title (+ subtitle) on top, [body] full-width below.
class TpPreferenceStack extends StatelessWidget {
  const TpPreferenceStack({
    super.key,
    required this.title,
    this.subtitle,
    this.titleLeading,
    this.titleTrailing,
    required this.body,
    this.helper,
    this.showDividerBelow = true,
    this.afterTitleBodyGap = 12.0,
    this.padding,
  });

  final String title;
  final String? subtitle;
  final Widget? titleLeading;
  final Widget? titleTrailing;
  final Widget body;
  final Widget? helper;
  final bool showDividerBelow;
  final double afterTitleBodyGap;
  final EdgeInsetsGeometry? padding;

  static const double _titleSubtitleGap = 4;
  static const double _titleOnlyBodyGap = 8;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final hasSub = TpPreferenceRow.hasSubtitle(subtitle);
    final subtitleStyle = TpTextStyles.of(context).mutedSm;
    final resolvedPadding = padding ?? TpPreferenceRow.defaultPadding;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: resolvedPadding,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (titleLeading != null || titleTrailing != null)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    if (titleLeading != null) ...[
                      titleLeading!,
                      const SizedBox(width: 10),
                    ],
                    Expanded(child: Text(title)),
                    if (titleTrailing != null) titleTrailing!,
                  ],
                )
              else
                Text(title),
              if (hasSub) ...[
                const SizedBox(height: _titleSubtitleGap),
                Text(subtitle!.trim(), style: subtitleStyle),
              ],
              SizedBox(
                height: hasSub ? afterTitleBodyGap : _titleOnlyBodyGap,
              ),
              body,
              if (helper != null) ...[const SizedBox(height: 10), helper!],
            ],
          ),
        ),
        if (showDividerBelow)
          Divider(
            height: 1,
            thickness: 1,
            color: cs.outlineVariant.withValues(alpha: 0.5),
          ),
      ],
    );
  }
}
