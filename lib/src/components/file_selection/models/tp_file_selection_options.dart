enum TpSelectionMode { files, directories, both }

enum TpFileSelectionTab { filesystem, gallery }

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
  });

  final bool allowMultiple;
  final List<String>? allowedExtensions;
  final String? title;
  final int? maxSelectionCount;
  final TpFileSelectionTab? initialTab;
  final String? initialPath;
  final TpSelectionMode selectionMode;
  final bool showHiddenFiles;
}
