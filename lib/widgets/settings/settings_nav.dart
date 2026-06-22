import 'package:flutter/material.dart';
import 'package:shared_ui/theme/app_icon_sizes.dart';
import 'package:shared_ui/theme/app_text_styles.dart';

/// One row in a settings left nav.
class SettingsNavItem extends StatelessWidget {
  const SettingsNavItem({
    required this.title,
    required this.icon,
    required this.onTap,
    this.selected = false,
    super.key,
  });

  final String title;
  final IconData icon;
  final VoidCallback onTap;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final selectedFg = cs.onPrimaryContainer;
    final muted = cs.onSurfaceVariant;
    final normalFg = cs.onSurface.withValues(alpha: 0.88);

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: selected ? cs.primaryContainer : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: SizedBox(
            height: 48,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18),
              child: Row(
                children: [
                  Icon(
                    icon,
                    color: selected ? selectedFg : muted,
                    size: context.appIconSizes.md,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.of(context).body.copyWith(
                        fontWeight: FontWeight.w500,
                        color: selected ? selectedFg : normalFg,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class SettingsNavList extends StatelessWidget {
  const SettingsNavList({
    required this.children,
    super.key,
  });

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 28, 18, 24),
      children: children,
    );
  }
}
