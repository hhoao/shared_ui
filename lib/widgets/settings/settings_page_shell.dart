import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:shared_ui/widgets/settings/settings_nav.dart';
import 'package:shared_ui/widgets/settings/workspace_hub_title_bar.dart';

/// Teampilot-style settings layout: left nav + title bar + scrollable body.
class SettingsPageShell extends StatefulWidget {
  const SettingsPageShell({
    required this.sections,
    super.key,
  });

  final List<SettingsPageSection> sections;

  @override
  State<SettingsPageShell> createState() => _SettingsPageShellState();
}

class SettingsPageSection {
  const SettingsPageSection({
    required this.icon,
    required this.navLabel,
    required this.title,
    required this.subtitle,
    required this.body,
  });

  final IconData icon;
  final String navLabel;
  final String title;
  final String subtitle;
  final Widget body;
}

class _SettingsPageShellState extends State<SettingsPageShell> {
  int _selected = 0;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final active = widget.sections[_selected];

    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          width: 220,
          decoration: BoxDecoration(
            border: Border(
              right: BorderSide(color: cs.outlineVariant.withValues(alpha: 0.6)),
            ),
          ),
          child: SettingsNavList(
            children: [
              for (final (index, section) in widget.sections.indexed)
                SettingsNavItem(
                  title: section.navLabel,
                  icon: section.icon,
                  selected: index == _selected,
                  onTap: () => setState(() => _selected = index),
                ),
            ],
          ),
        ),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              WorkspaceHubTitleBar(
                compact: true,
                title: active.title,
                subtitle: active.subtitle,
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
                  child: active.body
                      .animate(key: ValueKey(_selected))
                      .fadeIn(duration: 180.ms, curve: Curves.easeOut),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
