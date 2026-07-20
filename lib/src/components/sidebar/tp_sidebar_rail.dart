import 'package:flutter/material.dart';

import 'tp_sidebar_scope.dart';

/// Narrow inner-edge hit strip that toggles the sidebar (no drag-resize).
class TpSidebarRail extends StatelessWidget {
  const TpSidebarRail({super.key});

  static const double _width = 12;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final height = constraints.maxHeight.isFinite
            ? constraints.maxHeight
            : double.infinity;
        return Align(
          alignment: Alignment.centerRight,
          child: MouseRegion(
            cursor: SystemMouseCursors.click,
            child: GestureDetector(
              key: const Key('tp-sidebar-rail'),
              behavior: HitTestBehavior.opaque,
              onTap: TpSidebarScope.of(context).toggleSidebar,
              child: SizedBox(
                width: _width,
                height: height,
              ),
            ),
          ),
        );
      },
    );
  }
}
