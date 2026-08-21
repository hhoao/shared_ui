import 'package:flutter/material.dart';

import '../../theme/tp_theme.dart';
import '../card/tp_card_header.dart';
import 'tp_catalog_source_warning.dart';

/// Shared discovery section chrome: title + filter trailing, optional search.
///
/// Matches the MCP discovery header pattern so Skills / Plugins / MCP share
/// one filter layout.
class TpCatalogDiscoveryHeader extends StatelessWidget {
  const TpCatalogDiscoveryHeader({
    super.key,
    required this.title,
    this.filters = const [],
    this.failures = const [],
    this.onRefresh,
    this.refreshing = false,
    this.refreshTooltip,
    this.searchController,
    this.searchHint,
    this.onSearchChanged,
    this.onSearchSubmitted,
    this.showSearch = true,
    this.belowSearch,
  });

  final String title;

  /// Filter controls shown in the header trailing row (before warning/refresh).
  final List<Widget> filters;

  final List<TpCatalogFailureView> failures;
  final VoidCallback? onRefresh;
  final bool refreshing;
  final String? refreshTooltip;

  final TextEditingController? searchController;
  final String? searchHint;
  final ValueChanged<String>? onSearchChanged;
  final ValueChanged<String>? onSearchSubmitted;
  final bool showSearch;

  /// Optional banner under the search field (e.g. syncing status).
  final Widget? belowSearch;

  @override
  Widget build(BuildContext context) {
    final spacing = context.tpSpacing;
    final trailing = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < filters.length; i++) ...[
          if (i > 0) SizedBox(width: spacing.sm),
          filters[i],
        ],
        if (filters.isNotEmpty) SizedBox(width: spacing.sm),
        TpCatalogSourceWarning(failures: failures),
        if (onRefresh != null)
          IconButton(
            tooltip: refreshTooltip,
            onPressed: refreshing ? null : onRefresh,
            icon: refreshing
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Icon(Icons.refresh, size: context.tpIconSizes.md),
          ),
      ],
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TpCardHeader(title: title, trailing: trailing),
        if (showSearch && searchController != null) ...[
          SizedBox(height: spacing.md),
          TextField(
            controller: searchController,
            onChanged: onSearchChanged,
            onSubmitted: onSearchSubmitted ?? onSearchChanged,
            decoration: InputDecoration(
              hintText: searchHint,
              prefixIcon: Icon(Icons.search, size: context.tpIconSizes.md),
              isDense: true,
              floatingLabelBehavior: FloatingLabelBehavior.never,
            ),
          ),
        ],
        if (belowSearch != null) ...[
          SizedBox(height: spacing.sm),
          belowSearch!,
        ],
      ],
    );
  }
}
