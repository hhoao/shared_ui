import 'package:flutter/material.dart';

import '../../../../theme/tp_text_styles.dart';
import '../../../icon_button/tp_icon_button.dart';
import '../../../toast/tp_toast.dart';
import '../../../../toast/engine/toastification.dart';
import '../../controller/tp_file_selection_controller.dart';
import '../../controller/tp_file_selection_filters.dart';
import '../../models/tp_file_selection_options.dart';
import '../../models/tp_picked_entry.dart';
import '../../ports/tp_file_selection_deps.dart';
import '../tp_file_selection_strings.dart';
import '../widgets/tp_file_selection_bottom_bar.dart';
import '../widgets/tp_file_sort_sheet.dart';
import 'tp_classic_views.dart';

/// Legacy-style mobile file-selection page: 文件 / 相册 top tabs over the
/// storage home (quick tiles, folder browsing) and the gallery tab.
class TpFileSelectionClassicPage extends StatefulWidget {
  const TpFileSelectionClassicPage({
    super.key,
    required this.deps,
    required this.options,
  });

  final TpFileSelectionDeps deps;
  final TpFileSelectionOptions options;

  @override
  State<TpFileSelectionClassicPage> createState() =>
      _TpFileSelectionClassicPageState();
}

class _TpFileSelectionClassicPageState
    extends State<TpFileSelectionClassicPage>
    with SingleTickerProviderStateMixin {
  late final TpFileSelectionController _controller;
  TabController? _tabController;
  bool _isProgrammaticTabChange = false;
  int _currentTabIndex = 0;
  String _sortType = 'name';
  bool _sortAscending = true;

  final _storageTabKey = GlobalKey<TpClassicStorageTabState>();
  final _galleryTabKey = GlobalKey<TpClassicGalleryTabState>();

  TpFileSelectionStrings get _strings => widget.deps.strings;

  bool get _isDirectoryMode =>
      widget.options.selectionMode == TpSelectionMode.directories;

  @override
  void initState() {
    super.initState();
    _controller = TpFileSelectionController(
      options: widget.options,
      onMaxSelectionReached: _onMaxSelectionReached,
      onSelectAllCapped: _onSelectAllCapped,
    );

    final hasGalleryTab = !_isDirectoryMode && widget.deps.gallery != null;
    if (hasGalleryTab) {
      final initialIndex =
          widget.options.initialTab == TpFileSelectionTab.gallery ? 1 : 0;
      _currentTabIndex = initialIndex;
      _tabController = TabController(
        length: 2,
        vsync: this,
        initialIndex: initialIndex,
      )..addListener(_onTabChanged);
    }
  }

  @override
  void dispose() {
    _tabController?.removeListener(_onTabChanged);
    _tabController?.dispose();
    _controller.dispose();
    super.dispose();
  }

  void _onMaxSelectionReached(int maxCount) {
    _showToast(_strings.maxSelectionCountReached(maxCount));
  }

  void _onSelectAllCapped(int count) {
    _showToast(_strings.selectedFirstNItems(count));
  }

  void _showToast(String message) {
    if (!mounted) return;
    if (ToastificationConfigProvider.maybeOf(context) != null) {
      TpToast.show(
        context,
        message: message,
        variant: TpToastVariant.warning,
      );
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  void _onTabChanged() {
    final tabController = _tabController;
    if (tabController == null) return;
    if (_isProgrammaticTabChange) {
      _isProgrammaticTabChange = false;
      _currentTabIndex = tabController.index;
      return;
    }

    if (tabController.index != _currentTabIndex &&
        _controller.selection.isNotEmpty) {
      final targetIndex = tabController.index;
      _isProgrammaticTabChange = true;
      tabController.animateTo(_currentTabIndex);
      _showClearSelectionDialog(targetIndex);
      return;
    }

    setState(() => _currentTabIndex = tabController.index);
  }

  void _showClearSelectionDialog(int targetIndex) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(_strings.switchTabTitle),
        content: Text(_strings.switchTabClearSelectionMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(_strings.taskStatusCancelledShort),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              _controller.clearSelection();
              _isProgrammaticTabChange = true;
              _currentTabIndex = targetIndex;
              _tabController?.animateTo(targetIndex);
            },
            child: Text(_strings.actionConfirm),
          ),
        ],
      ),
    );
  }

  TpClassicViewApi? _apiForTabIndex(int index) {
    if (index == 0) return _storageTabKey.currentState;
    return _galleryTabKey.currentState;
  }

  TpClassicViewApi? get _activeApi =>
      _apiForTabIndex(_tabController?.index ?? 0);

  Future<void> _showSortSheet() async {
    await showTpFileSortSheet(
      context: context,
      strings: _strings,
      currentSortType: _sortType,
      currentAscending: _sortAscending,
      onSelected: (sortType, {required bool ascending}) {
        setState(() {
          _sortType = sortType;
          _sortAscending = ascending;
        });
        _activeApi?.applySorting(sortType, ascending: ascending);
      },
    );
  }

  Future<void> _toggleSelectAll() async {
    final api = _activeApi;
    if (api == null) return;

    final allSelected = _controller.selection.isNotEmpty &&
        _controller.selection.length >= api.selectableCount;
    if (allSelected) {
      _controller.clearSelection();
      return;
    }
    await api.selectAll();
  }

  void _closePage() {
    Navigator.of(context).pop<List<TpPickedEntry>?>(null);
  }

  void _confirmSelection() {
    final selection = _controller.selection;
    if (selection.isEmpty) return;
    Navigator.of(context).pop<List<TpPickedEntry>>(selection);
  }

  void _confirmDirectory() {
    final result = _controller.confirmDirectorySelection();
    Navigator.of(context).pop<List<TpPickedEntry>>(result);
  }

  void _clearSelection() {
    _controller.clearSelection();
  }

  String _pageTitle() {
    if (widget.options.title != null) {
      return widget.options.title!;
    }
    return switch (widget.options.selectionMode) {
      TpSelectionMode.files => _strings.selectFilesTitle,
      TpSelectionMode.directories => _strings.selectDirectoryTitle,
      TpSelectionMode.both => _strings.selectFilesAndDirectoriesTitle,
    };
  }

  String _selectionSummary() {
    final count = _controller.selection.length;
    if (count == 0) {
      return _strings.noItemsSelected;
    }
    return _strings.selectionSummaryItems(count);
  }

  /// Legacy empty-state prompt, e.g. 请选择视频文件.
  String _selectionPrompt() {
    return switch (widget.options.selectionMode) {
      TpSelectionMode.directories => _strings.selectDirectoryPrompt,
      TpSelectionMode.both => _strings.selectFilesOrDirectoriesPrompt,
      TpSelectionMode.files => switch (
          resolveGalleryMediaFilter(widget.options.allowedExtensions)) {
          TpGalleryMediaKind.video => _strings.selectionPromptForType(
              _strings.mediaTypeVideo,
            ),
          TpGalleryMediaKind.image =>
            _strings.selectionPromptForType(_strings.mediaTypeImage),
          TpGalleryMediaKind.all =>
            _strings.selectionPromptForType(_strings.mediaTypeAll),
        },
    };
  }

  @override
  Widget build(BuildContext context) {
    final styles = TpTextStyles.of(context);
    final cs = Theme.of(context).colorScheme;
    final tabController = _tabController;

    final hasTabs = tabController != null;
    // Legacy CommonAppBar: a single toolbar row — close left, centered tabs (in
    // place of the title) or title, sort right.
    return Scaffold(
      key: const Key('tp_file_selection_classic_page'),
      appBar: PreferredSize(
        key: const Key('tp_file_selection_classic_appbar'),
        preferredSize: const Size.fromHeight(kToolbarHeight),
        child: Container(
          // Legacy picker app bar background.
          color: const Color.fromARGB(255, 234, 237, 239),
          child: SafeArea(
            bottom: false,
            child: SizedBox(
              height: kToolbarHeight,
              child: Row(
                children: [
                  TpIconButton(
                    key: const Key('tp_file_selection_close'),
                    icon: Icons.close,
                    tooltip: _strings.taskStatusCancelledShort,
                    onTap: _closePage,
                  ),
                  Expanded(
                    child: hasTabs
                        ? Align(
                            alignment: Alignment.center,
                            child: Theme(
                              data: Theme.of(context).copyWith(
                                tabBarTheme: const TabBarThemeData(
                                  dividerColor: Colors.transparent,
                                ),
                              ),
                              child: TabBar(
                                key: const Key('tp_file_selection_classic_tabs'),
                                controller: tabController,
                                tabAlignment: TabAlignment.center,
                                isScrollable: true,
                                padding: EdgeInsets.zero,
                                indicator: UnderlineTabIndicator(
                                  borderSide: BorderSide(
                                    width: 2.0,
                                    color: cs.onSurface,
                                  ),
                                ),
                                labelColor: cs.onSurface,
                                unselectedLabelColor: cs.onSurfaceVariant,
                                labelStyle: const TextStyle(fontSize: 14),
                                indicatorSize: TabBarIndicatorSize.label,
                                tabs: [
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 8,
                                    ),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        const Icon(Icons.folder, size: 12),
                                        const SizedBox(width: 4),
                                        Text(_strings.tabFiles),
                                      ],
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 8,
                                    ),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        const Icon(Icons.photo_library, size: 12),
                                        const SizedBox(width: 4),
                                        Text(_strings.tabPhotoGallery),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          )
                        : Center(
                            child: Text(
                              _pageTitle(),
                              style: styles.mdSemibold,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                  ),
                  TpIconButton(
                    key: const Key('tp_file_selection_sort'),
                    icon: Icons.sort,
                    tooltip: _strings.sortOptionsTitle,
                    onTap: _showSortSheet,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: tabController == null
                ? _buildStorageTab()
                : IndexedStack(
                    index: _currentTabIndex.clamp(0, 1),
                    children: [
                      _buildStorageTab(),
                      TpClassicGalleryTab(
                        key: _galleryTabKey,
                        deps: widget.deps,
                        options: widget.options,
                        controller: _controller,
                      ),
                    ],
                  ),
          ),
          ListenableBuilder(
            listenable: _controller,
            builder: (context, _) {
              final api = _activeApi;
              final isAllSelected = api != null &&
                  _controller.selection.isNotEmpty &&
                  _controller.selection.length >= api.selectableCount;
              return Material(
                elevation: 4,
                color: cs.surface,
                child: SafeArea(
                  top: false,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                    child: _isDirectoryMode
                        ? TpFileSelectionBottomBar.directory(
                            strings: _strings,
                            currentPath: _controller.currentPath,
                            onConfirmDirectory: _confirmDirectory,
                          )
                        : TpFileSelectionBottomBar.file(
                            strings: _strings,
                            selectionCount: _controller.selection.length,
                            maxSelectionCount: widget.options.maxSelectionCount,
                            selectionSummary: _selectionSummary(),
                            confirmLabel: _controller.selection.isEmpty
                                ? _strings.selectAction
                                : _strings.actionConfirmWithCount(
                                    _controller.selection.length,
                                  ),
                            onClearSelection: _clearSelection,
                            onToggleSelectAll: _toggleSelectAll,
                            onConfirm: _confirmSelection,
                            classic: true,
                            isAllSelected: isAllSelected,
                            selectionPrompt: _selectionPrompt(),
                          ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildStorageTab() {
    return TpClassicStorageTab(
      key: _storageTabKey,
      deps: widget.deps,
      options: widget.options,
      controller: _controller,
      initialPath: widget.options.initialPath,
    );
  }
}
