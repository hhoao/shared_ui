import 'package:flutter/foundation.dart';

import '../models/tp_file_selection_options.dart';
import '../models/tp_picked_entry.dart';
import 'tp_file_selection_tab_api.dart';

class TpFileSelectionController extends ChangeNotifier {
  TpFileSelectionController({
    required TpFileSelectionOptions options,
    this.onMaxSelectionReached,
    this.onSelectAllCapped,
  })  : _options = options,
        _activeTab = options.initialTab ?? TpFileSelectionTab.filesystem,
        _currentPath = options.initialPath ?? '';

  final void Function(int maxCount)? onMaxSelectionReached;
  final void Function(int count)? onSelectAllCapped;

  final TpFileSelectionOptions _options;
  final List<TpPickedEntry> _selection = [];
  final Map<TpFileSelectionTab, TpFileSelectionTabApi> _tabApis = {};

  String _currentPath;
  TpFileSelectionTab _activeTab;

  TpFileSelectionOptions get options => _options;
  List<TpPickedEntry> get selection => List.unmodifiable(_selection);
  String get currentPath => _currentPath;
  TpFileSelectionTab get activeTab => _activeTab;

  void setCurrentPath(String path) {
    if (_currentPath == path) {
      return;
    }
    _currentPath = path;
    notifyListeners();
  }

  void setActiveTab(TpFileSelectionTab tab) {
    if (_activeTab == tab) {
      return;
    }
    _activeTab = tab;
    notifyListeners();
  }

  void registerTabApi(TpFileSelectionTab tab, TpFileSelectionTabApi api) {
    _tabApis[tab] = api;
  }

  void unregisterTabApi(TpFileSelectionTab tab) {
    _tabApis.remove(tab);
  }

  bool trySelect(TpPickedEntry entry) {
    if (_selection.contains(entry)) {
      return true;
    }

    if (!_options.allowMultiple) {
      _selection
        ..clear()
        ..add(entry);
      notifyListeners();
      return true;
    }

    final max = _options.maxSelectionCount;
    if (max != null && _selection.length >= max) {
      onMaxSelectionReached?.call(max);
      return false;
    }

    _selection.add(entry);
    notifyListeners();
    return true;
  }

  void deselect(TpPickedEntry entry) {
    final removed = _selection.remove(entry);
    if (removed) {
      notifyListeners();
    }
  }

  void replaceSelection(List<TpPickedEntry> entries) {
    _selection
      ..clear()
      ..addAll(entries);
    notifyListeners();
  }

  void clearSelection() {
    if (_selection.isEmpty && _tabApis.isEmpty) {
      return;
    }
    _selection.clear();
    for (final api in _tabApis.values) {
      api.clearSelection();
    }
    notifyListeners();
  }

  void selectAllFrom(List<TpPickedEntry> candidates) {
    final max = _options.maxSelectionCount;
    if (max != null && candidates.length > max) {
      _selection
        ..clear()
        ..addAll(candidates.take(max));
      onSelectAllCapped?.call(max);
    } else {
      _selection
        ..clear()
        ..addAll(candidates);
    }
    notifyListeners();
  }

  bool shouldConfirmTabChange(TpFileSelectionTab target) {
    if (_selection.isEmpty || target == _activeTab) {
      setActiveTab(target);
      return false;
    }
    return true;
  }

  void confirmTabChange(TpFileSelectionTab target) {
    clearSelection();
    setActiveTab(target);
  }

  List<TpPickedEntry> confirmDirectorySelection() {
    return [
      TpPickedEntry(
        path: _currentPath,
        kind: TpPickedKind.directory,
      ),
    ];
  }
}
