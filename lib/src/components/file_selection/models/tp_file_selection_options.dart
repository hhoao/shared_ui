enum TpSelectionMode { files, directories, both }

enum TpFileSelectionTab { filesystem, gallery }

/// Presentation of the filesystem/gallery tab switcher.
enum TpFileSelectionTabStyle {
  /// [TpSegmentedControl] embedded under the app bar title row (default).
  segmentedControl,

  /// Material [TabBar] with the theme's indicator and divider.
  tabBar,
}

/// Overall page layout of the mobile file-selection page.
enum TpFileSelectionLayout {
  /// Filesystem/gallery tabs with inline search and chips (default).
  standard,

  /// Legacy look: storage tabs (phone storage / app folders / full-disk
  /// search) and a sectioned home with quick tiles and album cards.
  classic,
}

class TpFileSelectionOptions {
  const TpFileSelectionOptions({
    this.allowMultiple = false,
    this.allowedExtensions,
    this.title,
    this.maxSelectionCount,
    this.initialTab,
    this.initialPath,
    this.selectionMode = TpSelectionMode.files,
    this.showHiddenFiles = false,
    this.tabStyle = TpFileSelectionTabStyle.segmentedControl,
    this.layout = TpFileSelectionLayout.standard,
  });

  final bool allowMultiple;
  final List<String>? allowedExtensions;
  final String? title;
  final int? maxSelectionCount;
  final TpFileSelectionTab? initialTab;
  final String? initialPath;
  final TpSelectionMode selectionMode;
  final bool showHiddenFiles;
  final TpFileSelectionTabStyle tabStyle;
  final TpFileSelectionLayout layout;
}
