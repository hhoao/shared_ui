import 'package:flutter/material.dart';

import '../icon_button/tp_icon_button.dart';
import 'tp_sidebar_scope.dart';

/// Toolbar control that toggles the sidebar via [TpSidebarScope.toggleSidebar].
class TpSidebarTrigger extends StatelessWidget {
  const TpSidebarTrigger({
    super.key,
    this.icon,
    this.tooltip,
    this.size = TpIconButton.kDefaultSize,
    this.selected = false,
  });

  final Widget? icon;
  final String? tooltip;
  final double size;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    if (icon != null) {
      return TpIconButton(
        iconWidget: icon,
        onTap: TpSidebarScope.of(context).toggleSidebar,
        tooltip: tooltip,
        size: size,
        selected: selected,
      );
    }
    return TpIconButton(
      icon: selected ? Icons.menu_open : Icons.menu,
      onTap: TpSidebarScope.of(context).toggleSidebar,
      tooltip: tooltip,
      size: size,
      selected: selected,
    );
  }
}
