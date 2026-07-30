import 'package:flutter/material.dart';

import '../../theme/tp_text_styles.dart';
import '../../theme/tp_theme.dart';
import '../icon_button/tp_icon_button.dart';

/// One section in a [TpDialogNavShell] left nav.
class TpDialogNavEntry {
  const TpDialogNavEntry({
    required this.icon,
    required this.navLabel,
    required this.title,
    required this.subtitle,
    required this.bodyBuilder,
  });

  final IconData icon;
  final String Function(BuildContext) navLabel;
  final String Function(BuildContext) title;
  final String Function(BuildContext) subtitle;
  final WidgetBuilder bodyBuilder;
}

/// Dual-pane dialog host: side-by-side on wide, nav list → detail on narrow.
///
/// Owns SafeArea app bars on narrow. Do **not** wrap in [TpDialogPageShell].
class TpDialogNavShell extends StatefulWidget {
  const TpDialogNavShell({
    required this.navTitle,
    required this.entries,
    this.initialIndex = 0,
    this.mobileBreakpoint = 768,
    this.onClose,
    this.onSelectedIndexChanged,
    super.key,
  });

  final String Function(BuildContext) navTitle;
  final List<TpDialogNavEntry> entries;
  final int initialIndex;
  final double mobileBreakpoint;
  final VoidCallback? onClose;
  final ValueChanged<int>? onSelectedIndexChanged;

  @override
  State<TpDialogNavShell> createState() => _TpDialogNavShellState();
}

class _TpDialogNavShellState extends State<TpDialogNavShell> {
  static const double _navWidth = 220;

  late int _selectedIndex;
  final _navigatorKey = GlobalKey<NavigatorState>();

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initialIndex.clamp(0, widget.entries.length - 1);
  }

  bool _isNarrow(BuildContext context) =>
      MediaQuery.sizeOf(context).width < widget.mobileBreakpoint;

  void _close(BuildContext context) {
    if (widget.onClose != null) {
      widget.onClose!();
      return;
    }
    Navigator.of(context, rootNavigator: true).pop();
  }

  void _selectIndex(int index) {
    if (_selectedIndex == index) return;
    setState(() => _selectedIndex = index);
    widget.onSelectedIndexChanged?.call(index);
  }

  TpDialogNavEntry get _activeEntry => widget.entries[_selectedIndex];

  @override
  Widget build(BuildContext context) {
    if (_isNarrow(context)) {
      return _buildNarrow(context);
    }
    return _buildWide(context);
  }

  Widget _buildWide(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _NavPanel(
          width: _navWidth,
          navTitle: widget.navTitle(context),
          entries: widget.entries,
          selectedIndex: _selectedIndex,
          onSelect: _selectIndex,
        ),
        Expanded(
          child: _BodyPane(
            title: _activeEntry.title(context),
            subtitle: _activeEntry.subtitle(context),
            onClose: () => _close(context),
            child: _activeEntry.bodyBuilder(context),
          ),
        ),
      ],
    );
  }

  Widget _buildNarrow(BuildContext context) {
    final openDetailInitially = widget.initialIndex != 0;
    return Navigator(
      key: _navigatorKey,
      initialRoute: openDetailInitially ? _detailRoute : _navRoute,
      onGenerateRoute: (settings) {
        switch (settings.name) {
          case _detailRoute:
            return MaterialPageRoute<void>(
              builder: (detailContext) => _NarrowDetailPage(
                entry: _activeEntry,
                onBack: () => Navigator.of(detailContext).pop(),
                onClose: () => _close(context),
              ),
            );
          case _navRoute:
          default:
            return MaterialPageRoute<void>(
              builder: (navContext) => _NarrowNavPage(
                navTitle: widget.navTitle(navContext),
                entries: widget.entries,
                onClose: () => _close(context),
                onSelect: (index) {
                  _selectIndex(index);
                  Navigator.of(navContext).pushNamed(_detailRoute);
                },
              ),
            );
        }
      },
    );
  }
}

const String _navRoute = '/';
const String _detailRoute = '/detail';

class _NavPanel extends StatelessWidget {
  const _NavPanel({
    required this.width,
    required this.navTitle,
    required this.entries,
    required this.selectedIndex,
    required this.onSelect,
  });

  final double width;
  final String navTitle;
  final List<TpDialogNavEntry> entries;
  final int selectedIndex;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final styles = TpTextStyles.of(context);
    final spacing = context.tpSpacing;

    return Container(
      width: width,
      decoration: BoxDecoration(
        color: cs.surfaceContainerLow,
        border: Border(
          right: BorderSide(color: cs.outlineVariant.withValues(alpha: 0.5)),
        ),
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: spacing.lg, vertical: spacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(spacing.lg, spacing.lg, spacing.lg, spacing.md),
              child: Text(
                navTitle,
                style: styles.lgSemiboldSnugColored(cs.onSurface),
              ),
            ),
            Expanded(
              child: ListView(
                children: [
                  for (final (index, entry) in entries.indexed)
                    _NavTile(
                      label: entry.navLabel(context),
                      icon: entry.icon,
                      selected: index == selectedIndex,
                      onTap: () => onSelect(index),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NavTile extends StatelessWidget {
  const _NavTile({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final spacing = context.tpSpacing;
    final iconSizes = context.tpIconSizes;
    final textStyle = (Theme.of(context).textTheme.bodyMedium ?? const TextStyle())
        .copyWith(
          fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
          color: selected ? cs.onSecondaryContainer : cs.onSurface,
        );

    return Material(
      color: selected ? cs.secondaryContainer : Colors.transparent,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onTap,
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: spacing.md, vertical: spacing.sm),
          child: Row(
            children: [
              Icon(
                icon,
                size: iconSizes.md,
                color: selected ? cs.onSecondaryContainer : cs.onSurfaceVariant,
              ),
              SizedBox(width: spacing.sm),
              Expanded(child: Text(label, style: textStyle)),
            ],
          ),
        ),
      ),
    );
  }
}

class _BodyPane extends StatelessWidget {
  const _BodyPane({
    required this.title,
    required this.subtitle,
    required this.onClose,
    required this.child,
  });

  final String title;
  final String subtitle;
  final VoidCallback onClose;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final styles = TpTextStyles.of(context);
    final spacing = context.tpSpacing;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: EdgeInsets.fromLTRB(spacing.xl, spacing.lg, spacing.md, spacing.lg),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(color: cs.outlineVariant.withValues(alpha: 0.5)),
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: styles.lgSemiboldSnugColored(cs.onSurface),
                    ),
                    if (subtitle.isNotEmpty) ...[
                      SizedBox(height: spacing.xs),
                      Text(
                        subtitle,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: styles.mutedMd,
                      ),
                    ],
                  ],
                ),
              ),
              SizedBox(width: spacing.sm),
              TpIconButton(
                icon: Icons.close_rounded,
                tooltip: MaterialLocalizations.of(context).closeButtonTooltip,
                compact: true,
                color: cs.onSurfaceVariant,
                onTap: onClose,
              ),
            ],
          ),
        ),
        Expanded(
          child: Padding(
            padding: EdgeInsets.fromLTRB(spacing.xl, spacing.lg, spacing.xl, spacing.xl),
            child: child,
          ),
        ),
      ],
    );
  }
}

class _NarrowNavPage extends StatelessWidget {
  const _NarrowNavPage({
    required this.navTitle,
    required this.entries,
    required this.onClose,
    required this.onSelect,
  });

  final String navTitle;
  final List<TpDialogNavEntry> entries;
  final VoidCallback onClose;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final spacing = context.tpSpacing;
    final titleStyle = (textTheme.bodyLarge ?? const TextStyle()).copyWith(
      fontWeight: FontWeight.w600,
      height: 1.25,
      color: cs.onSurface,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SafeArea(
          bottom: false,
          child: Padding(
            padding: EdgeInsets.fromLTRB(spacing.lg, spacing.md, spacing.md, spacing.md),
            child: Row(
              children: [
                Expanded(child: Text(navTitle, style: titleStyle)),
                TpIconButton(
                  icon: Icons.close_rounded,
                  tooltip: MaterialLocalizations.of(context).cancelButtonLabel,
                  compact: true,
                  color: cs.onSurfaceVariant,
                  onTap: onClose,
                ),
              ],
            ),
          ),
        ),
        Expanded(
          child: SafeArea(
            top: false,
            child: ListView(
              padding: EdgeInsets.symmetric(horizontal: spacing.md),
              children: [
                for (final (index, entry) in entries.indexed)
                  _NavTile(
                    label: entry.navLabel(context),
                    icon: entry.icon,
                    selected: false,
                    onTap: () => onSelect(index),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _NarrowDetailPage extends StatelessWidget {
  const _NarrowDetailPage({
    required this.entry,
    required this.onBack,
    required this.onClose,
  });

  final TpDialogNavEntry entry;
  final VoidCallback onBack;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final styles = TpTextStyles.of(context);
    final spacing = context.tpSpacing;
    final titleStyle = (textTheme.bodyLarge ?? const TextStyle()).copyWith(
      fontWeight: FontWeight.w600,
      height: 1.25,
      color: cs.onSurface,
    );
    final subtitle = entry.subtitle(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SafeArea(
          bottom: false,
          child: Padding(
            padding: EdgeInsets.fromLTRB(spacing.sm, spacing.md, spacing.md, spacing.md),
            child: Row(
              children: [
                TpIconButton(
                  icon: Icons.arrow_back_rounded,
                  tooltip: MaterialLocalizations.of(context).backButtonTooltip,
                  compact: true,
                  color: cs.onSurfaceVariant,
                  onTap: onBack,
                ),
                SizedBox(width: spacing.xs),
                Expanded(
                  child: Text(
                    entry.title(context),
                    style: titleStyle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                TpIconButton(
                  icon: Icons.close_rounded,
                  tooltip: MaterialLocalizations.of(context).closeButtonTooltip,
                  compact: true,
                  color: cs.onSurfaceVariant,
                  onTap: onClose,
                ),
              ],
            ),
          ),
        ),
        Expanded(
          child: SafeArea(
            top: false,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (subtitle.isNotEmpty)
                  Padding(
                    padding: EdgeInsets.fromLTRB(spacing.lg, 0, spacing.lg, spacing.md),
                    child: Text(
                      subtitle,
                      style: styles.mutedMd,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(spacing.lg, 0, spacing.lg, spacing.lg),
                    child: entry.bodyBuilder(context),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
