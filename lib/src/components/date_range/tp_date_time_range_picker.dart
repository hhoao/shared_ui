import 'dart:async';

import 'package:flutter/material.dart';

import '../action_menu/tp_action_menu.dart';
import '../dialog/show_tp_dialog.dart';
import '../dialog/tp_dialog.dart';
import '../popover/tp_popover.dart';
import 'tp_date_time_range.dart';
import 'tp_date_time_range_panel.dart';

class TpDateTimeRangePicker extends StatefulWidget {
  const TpDateTimeRangePicker({
    required this.firstDate,
    required this.lastDate,
    required this.triggerBuilder,
    required this.labels,
    this.value,
    this.onChanged,
    this.maxDuration,
    this.presets = const [],
    this.selectedPresetId,
    this.onPresetSelected,
    this.panelWidth = 620,
    this.controller,
    super.key,
  });

  final DateTime firstDate;
  final DateTime lastDate;
  final Widget Function(BuildContext context, bool isOpen) triggerBuilder;
  final TpDateTimeRangePickerLabels labels;
  final TpDateTimeRange? value;
  final ValueChanged<TpDateTimeRange?>? onChanged;
  final Duration? maxDuration;
  final List<TpDateTimeRangePreset> presets;
  final String? selectedPresetId;
  final ValueChanged<String>? onPresetSelected;
  final double panelWidth;
  final TpPopoverController? controller;

  @override
  State<TpDateTimeRangePicker> createState() => _TpDateTimeRangePickerState();
}

class _TpDateTimeRangePickerState extends State<TpDateTimeRangePicker> {
  late final TpPopoverController _controller =
      widget.controller ?? TpPopoverController();
  late final bool _ownsController = widget.controller == null;

  late DateTime _draftStart;
  late DateTime _draftEnd;
  late bool _draftLiveEnd;
  TpDateTimeRangeField _activeField = TpDateTimeRangeField.start;
  String? _error;
  Timer? _liveTimer;

  TpDateTimeRange get _defaultValue {
    final now = DateTime.now();
    return TpDateTimeRange(
      start: now.subtract(const Duration(days: 30)),
      end: now,
    );
  }

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onControllerChanged);
    _resetDraft();
  }

  @override
  void dispose() {
    _liveTimer?.cancel();
    _controller.removeListener(_onControllerChanged);
    if (_ownsController) _controller.dispose();
    super.dispose();
  }

  /// Rebuilds the trigger so [TpDateTimeRangePicker.triggerBuilder] sees the
  /// live open state, and refreshes the panel from the reset draft on open.
  void _onControllerChanged() {
    if (mounted) setState(() {});
  }

  void _resetDraft() {
    final value = widget.value ?? _defaultValue;
    _draftStart = value.start;
    _draftEnd = value.end;
    _draftLiveEnd = value.liveEnd;
    _activeField = TpDateTimeRangeField.start;
    _error = null;
    _syncLiveTimer();
  }

  void _syncLiveTimer() {
    _liveTimer?.cancel();
    _liveTimer = null;
    if (!_draftLiveEnd) return;
    _liveTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() => _draftEnd = DateTime.now());
    });
  }

  void _open() {
    _resetDraft();
    _controller.show();
  }

  void _close() {
    _liveTimer?.cancel();
    _liveTimer = null;
    _controller.hide();
  }

  void _setActiveField(TpDateTimeRangeField field) {
    if (_draftLiveEnd && field == TpDateTimeRangeField.end) return;
    setState(() => _activeField = field);
  }

  void _setLiveEnd(bool live) {
    setState(() {
      _draftLiveEnd = live;
      if (live) {
        _draftEnd = DateTime.now();
        _activeField = TpDateTimeRangeField.start;
      }
      _error = null;
    });
    _syncLiveTimer();
  }

  void _setDate(DateTime day) {
    setState(() {
      final target = _activeField == TpDateTimeRangeField.start
          ? _draftStart
          : _draftEnd;
      final next = DateTime(
        day.year,
        day.month,
        day.day,
        target.hour,
        target.minute,
      );

      if (_activeField == TpDateTimeRangeField.start) {
        _draftStart = next;
        if (_draftStart.isAfter(_draftEnd)) {
          _draftEnd = DateTime(
            next.year,
            next.month,
            next.day,
            _draftEnd.hour,
            _draftEnd.minute,
          );
          if (_draftEnd.isBefore(_draftStart)) _draftEnd = _draftStart;
        }
        _activeField = TpDateTimeRangeField.end;
      } else if (next.isBefore(_draftStart)) {
        _draftStart = next;
        _activeField = TpDateTimeRangeField.end;
      } else {
        _draftEnd = next;
      }
      _error = null;
    });
  }

  void _setStart(DateTime value) {
    setState(() {
      _draftStart = value;
      _error = null;
    });
  }

  void _setEnd(DateTime value) {
    if (_draftLiveEnd) return;
    setState(() {
      _draftEnd = value;
      _error = null;
    });
  }

  String? _validate() {
    if (_draftStart.isAfter(_draftEnd)) return widget.labels.invalidOrder;
    final max = widget.maxDuration;
    if (max != null && _draftEnd.difference(_draftStart) > max) {
      return widget.labels.tooLong;
    }
    return null;
  }

  void _apply() {
    final error = _validate();
    if (error != null) {
      setState(() => _error = error);
      return;
    }
    widget.onChanged?.call(
      TpDateTimeRange(
        start: _draftStart,
        end: _draftEnd,
        liveEnd: _draftLiveEnd,
      ),
    );
    _close();
  }

  void _presetSelected(String id) {
    widget.onPresetSelected?.call(id);
    _close();
  }

  Widget _panel({VoidCallback? onCancel}) {
    return TpDateTimeRangePanel(
      start: _draftStart,
      end: _draftEnd,
      activeField: _activeField,
      liveEnd: _draftLiveEnd,
      presets: widget.presets,
      selectedPresetId: widget.selectedPresetId,
      labels: widget.labels,
      firstDate: widget.firstDate,
      lastDate: widget.lastDate,
      error: _error,
      onActiveFieldChanged: _setActiveField,
      onStartChanged: _setStart,
      onEndChanged: _setEnd,
      onDateChanged: _setDate,
      onLiveEndChanged: _setLiveEnd,
      onPresetSelected: _presetSelected,
      onApply: _apply,
      onCancel: onCancel ?? _close,
    );
  }

  Future<void> _openDialog() async {
    _resetDraft();
    String? dialogError;
    final result = await showTpDialog<TpDateTimeRange>(
      context: context,
      maxWidth: 680,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return TpDialog(
              maxWidth: 680,
              scrollable: true,
              child: TpDateTimeRangePanel(
                start: _draftStart,
                end: _draftEnd,
                activeField: _activeField,
                liveEnd: _draftLiveEnd,
                presets: widget.presets,
                selectedPresetId: widget.selectedPresetId,
                labels: widget.labels,
                firstDate: widget.firstDate,
                lastDate: widget.lastDate,
                error: dialogError,
                onActiveFieldChanged: (field) {
                  _setActiveField(field);
                  setDialogState(() {});
                },
                onStartChanged: (value) {
                  _setStart(value);
                  setDialogState(() {});
                },
                onEndChanged: (value) {
                  _setEnd(value);
                  setDialogState(() {});
                },
                onDateChanged: (date) {
                  _setDate(date);
                  setDialogState(() {});
                },
                onLiveEndChanged: (live) {
                  _setLiveEnd(live);
                  setDialogState(() {});
                },
                onPresetSelected: (id) {
                  widget.onPresetSelected?.call(id);
                  Navigator.of(dialogContext).pop();
                },
                onApply: () {
                  final error = _validate();
                  if (error != null) {
                    setDialogState(() => dialogError = error);
                    return;
                  }
                  Navigator.of(dialogContext).pop(
                    TpDateTimeRange(
                      start: _draftStart,
                      end: _draftEnd,
                      liveEnd: _draftLiveEnd,
                    ),
                  );
                },
                onCancel: () => Navigator.of(dialogContext).pop(),
              ),
            );
          },
        );
      },
    );
    _liveTimer?.cancel();
    _liveTimer = null;
    if (result != null) widget.onChanged?.call(result);
  }

  @override
  Widget build(BuildContext context) {
    final narrow = MediaQuery.sizeOf(context).width < 720;
    if (narrow) {
      return GestureDetector(
        onTap: _openDialog,
        behavior: HitTestBehavior.opaque,
        child: widget.triggerBuilder(context, false),
      );
    }

    final width = widget.panelWidth > MediaQuery.sizeOf(context).width - 32
        ? MediaQuery.sizeOf(context).width - 32
        : widget.panelWidth;

    return TpPopover(
      controller: _controller,
      panelWidth: width,
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 10),
      decoration: TpActionMenuMetrics.panelDecoration(context),
      anchor: const TpAnchor(
        childAlignment: Alignment.topLeft,
        overlayAlignment: Alignment.bottomLeft,
        offset: Offset(0, 4),
      ),
      popover: (_) => _panel(),
      child: GestureDetector(
        onTap: _open,
        behavior: HitTestBehavior.opaque,
        child: widget.triggerBuilder(context, _controller.isOpen),
      ),
    );
  }
}
