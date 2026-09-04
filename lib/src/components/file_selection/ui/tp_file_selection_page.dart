import 'package:flutter/material.dart';

import '../../button/tp_button.dart';
import '../../dialog/tp_dialog.dart';
import '../../icon_button/tp_icon_button.dart';
import '../../segmented_control/tp_segmented_control.dart';
import '../../toast/tp_toast.dart';
import '../../../toast/engine/toastification.dart';
import '../../../theme/tp_text_styles.dart';
import '../controller/tp_file_selection_controller.dart';
import '../controller/tp_file_selection_tab_api.dart';
import '../models/tp_file_selection_options.dart';
import '../models/tp_picked_entry.dart';
import '../ports/tp_file_selection_deps.dart';
import 'tp_file_selection_strings.dart';
import 'tp_filesystem_tab.dart';
import 'tp_gallery_tab.dart';
import 'widgets/tp_file_sort_sheet.dart';
import 'widgets/tp_file_selection_bottom_bar.dart';

/// Mobile file-selection page: app bar, filesystem/gallery tabs, bottom bar.
class TpFileSelectionPage extends StatefulWidget {
  const TpFileSelectionPage({
    super.key,
    required this.deps,
    required this.options,
  });

  final TpFileSelectionDeps deps;
  final TpFileSelectionOptions options;

  @override
  State<TpFileSelectionPage> createState() => _TpFileSelectionPageState();
}

class _TpFileSelectionPageState extends State<TpFileSelectionPage>
    with SingleTickerProviderStateMixin {
  late final TpFileSelectionController _controller;
  TabController? _tabController;
  bool _isProgrammaticTabChange = false;
  String _sortType = 'name';
  bool _sortAscending = true;

  TpFileSelectionStrings get _strings => widget.deps.strings;

  bool get _showGalleryTab =>
      widget.deps.gallery != null &&
      widget.options.selectionMode != TpSelectionMode.directories;

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

    if (_showGalleryTab) {
      final initialIndex = _controller.activeTab == TpFileSelectionTab.gallery
          ? 1
          : 0;
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
    if (tabController == null || _isProgrammaticTabChange) {
      _isProgrammaticTabChange = false;
      return;
    }

    final target = tabController.index == 0
        ? TpFileSelectionTab.filesystem
        : TpFileSelectionTab.gallery;

    if (_controller.shouldConfirmTabChange(target)) {
      final previousIndex = target == TpFileSelectionTab.filesystem ? 1 : 0;
      _isProgrammaticTabChange = true;
      tabController.index = previousIndex;
      setState(() {});
      _showTabChangeDialog(target);
      return;
    }

    setState(() {});
  }

  Future<void> _showTabChangeDialog(TpFileSelectionTab target) async {
    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return TpDialog(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TpDialogHeader(title: _strings.switchTabTitle),
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  _strings.switchTabClearSelectionMessage,
                  style: TpTextStyles.of(dialogContext).sm,
                ),
              ),
              TpDialogActions(
                children: [
                  TpButton(
                    variant: TpButtonVariant.outline,
                    onPressed: () => Navigator.pop(dialogContext),
                    child: Text(_strings.taskStatusCancelledShort),
                  ),
                  TpButton(
                    onPressed: () {
                      Navigator.pop(dialogContext);
                      _controller.confirmTabChange(target);
                      _switchToTab(target);
                    },
                    child: Text(_strings.actionConfirm),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  void _switchToTab(TpFileSelectionTab tab) {
    final tabController = _tabController;
    if (tabController == null) return;
    final index = tab == TpFileSelectionTab.filesystem ? 0 : 1;
    if (tabController.index == index) {
      setState(() {});
      return;
    }
    _isProgrammaticTabChange = true;
    tabController.index = index;
    setState(() {});
  }

  void _onSegmentedTabToggle(int? index) {
    if (index == null) return;
    final tabController = _tabController;
    if (tabController == null || tabController.index == index) return;
    tabController.index = index;
  }

  /// Horizontal icon + label tab used by the [TpFileSelectionTabStyle.tabBar]
  /// presentation.
  Widget _buildTabLabel(IconData icon, String label) {
    return Tab(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 12),
          const SizedBox(width: 4),
          Text(label),
        ],
      ),
    );
  }

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
        _filesystemTabKey.currentState
            ?.applySorting(sortType, ascending: ascending);
      },
    );
  }

  final _filesystemTabKey = GlobalKey<TpFilesystemTabState>();

  void _handlePathNotFound(String path) {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return TpDialog(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TpDialogHeader(title: _strings.pathNotFound(path)),
              TpDialogActions(
                children: [
                  TpButton(
                    key: const Key('tp_file_selection_path_not_found_confirm'),
                    onPressed: () {
                      Navigator.pop(dialogContext);
                      Navigator.pop(context);
                    },
                    child: Text(_strings.actionConfirm),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
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

  Future<void> _toggleSelectAll() async {
    final api = _activeTabApi;
    if (api == null) return;

    final allSelected = _controller.selection.isNotEmpty &&
        _controller.selection.length >= api.selectableCount;
    if (allSelected) {
      _controller.clearSelection();
      return;
    }
    await api.selectAll();
  }

  TpFileSelectionTabApi? get _activeTabApi {
    // Registered on controller — delegate via tab state keys.
    if (_controller.activeTab == TpFileSelectionTab.gallery) {
      return _galleryTabKey.currentState;
    }
    return _filesystemTabKey.currentState;
  }

  final _galleryTabKey = GlobalKey<TpGalleryTabState>();

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

  bool get _showSortAction =>
      !_isDirectoryMode && (_tabController?.index ?? 0) == 0;

  @override
  Widget build(BuildContext context) {
    final styles = TpTextStyles.of(context);
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      key: const Key('tp_file_selection_page'),
      appBar: AppBar(
        automaticallyImplyLeading: false,
        titleSpacing: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                TpIconButton(
                  key: const Key('tp_file_selection_close'),
                  icon: Icons.close,
                  tooltip: _strings.taskStatusCancelledShort,
                  onTap: _closePage,
                ),
                Expanded(
                  child: Text(
                    _pageTitle(),
                    style: styles.mdSemibold,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (_showSortAction)
                  TpIconButton(
                    key: const Key('tp_file_selection_sort'),
                    icon: Icons.sort,
                    tooltip: _strings.sortOptionsTitle,
                    onTap: _showSortSheet,
                  )
                else
                  const SizedBox(width: 32),
              ],
            ),
            if (_showGalleryTab && _tabController != null)
              widget.options.tabStyle == TpFileSelectionTabStyle.tabBar
                  ? TabBar(
                      key: const Key('tp_file_selection_tab_bar'),
                      controller: _tabController!,
                      tabs: [
                        _buildTabLabel(
                          Icons.folder,
                          _strings.tabFiles,
                        ),
                        _buildTabLabel(
                          Icons.photo_library,
                          _strings.tabPhotoGallery,
                        ),
                      ],
                    )
                  : Padding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                      child: Center(
                        child: TpSegmentedControl(
                          key: ValueKey(_tabController!.index),
                          totalSwitches: 2,
                          initialLabelIndex: _tabController!.index,
                          labels: [
                            _strings.tabFiles,
                            _strings.tabPhotoGallery,
                          ],
                          icons: const [Icons.folder_outlined, Icons.photo_library_outlined],
                          onToggle: _onSegmentedTabToggle,
                        ),
                      ),
                    ),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: _showGalleryTab && _tabController != null
                ? IndexedStack(
                    index: _tabController!.index,
                    children: [
                      TpFilesystemTab(
                        key: _filesystemTabKey,
                        deps: widget.deps,
                        options: widget.options,
                        controller: _controller,
                        onPathNotFound: _handlePathNotFound,
                      ),
                      TpGalleryTab(
                        key: _galleryTabKey,
                        deps: widget.deps,
                        options: widget.options,
                        controller: _controller,
                      ),
                    ],
                  )
                : TpFilesystemTab(
                    key: _filesystemTabKey,
                    deps: widget.deps,
                    options: widget.options,
                    controller: _controller,
                    onPathNotFound: _handlePathNotFound,
                  ),
          ),
          ListenableBuilder(
            listenable: _controller,
            builder: (context, _) {
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
                                ? _strings.actionConfirm
                                : _strings.actionConfirmWithCount(
                                    _controller.selection.length,
                                  ),
                            onClearSelection: _clearSelection,
                            onToggleSelectAll: _toggleSelectAll,
                            onConfirm: _confirmSelection,
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
}
