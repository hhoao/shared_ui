import 'package:flutter/material.dart';

import '../action_menu/tp_action_menu.dart';
import '../popover/tp_popover.dart';
import 'tp_range_calendar.dart';

/// Popover date-range picker using [TpPopover] + [TpRangeCalendar].
class TpDateRangePicker extends StatefulWidget {
  const TpDateRangePicker({
    super.key,
    required this.firstDate,
    required this.lastDate,
    required this.triggerBuilder,
    this.value,
    this.onChanged,
    this.closeOnCompleteSelection = true,
    this.panelWidth = 280,
    this.controller,
  });

  final DateTime firstDate;
  final DateTime lastDate;
  final DateTimeRange? value;
  final ValueChanged<DateTimeRange?>? onChanged;
  final bool closeOnCompleteSelection;
  final double panelWidth;

  /// Receives open state so the trigger can reflect popover visibility.
  final Widget Function(BuildContext context, bool isOpen) triggerBuilder;

  final TpPopoverController? controller;

  @override
  State<TpDateRangePicker> createState() => _TpDateRangePickerState();
}

class _TpDateRangePickerState extends State<TpDateRangePicker> {
  late final TpPopoverController _controller;
  late final bool _ownsController;

  @override
  void initState() {
    super.initState();
    _ownsController = widget.controller == null;
    _controller = widget.controller ?? TpPopoverController();
    _controller.addListener(_onControllerChanged);
  }

  @override
  void dispose() {
    _controller.removeListener(_onControllerChanged);
    if (_ownsController) {
      _controller.dispose();
    }
    super.dispose();
  }

  void _onControllerChanged() {
    if (mounted) setState(() {});
  }

  void _handleRangeChanged(DateTimeRange? range) {
    widget.onChanged?.call(range);
    if (widget.closeOnCompleteSelection &&
        range != null &&
        !range.start.isAfter(range.end)) {
      _controller.hide();
    }
  }

  @override
  Widget build(BuildContext context) {
    final decoration = TpActionMenuMetrics.panelDecoration(context);

    return TpPopover(
      controller: _controller,
      panelWidth: widget.panelWidth,
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
      decoration: decoration,
      anchor: const TpAnchor(
        childAlignment: Alignment.topRight,
        overlayAlignment: Alignment.bottomRight,
        offset: Offset(0, 4),
      ),
      popover: (_) => TpRangeCalendar(
        firstDate: widget.firstDate,
        lastDate: widget.lastDate,
        value: widget.value,
        initialMonth: widget.value?.start ?? widget.lastDate,
        onChanged: _handleRangeChanged,
      ),
      child: GestureDetector(
        onTap: _controller.toggle,
        behavior: HitTestBehavior.opaque,
        child: widget.triggerBuilder(context, _controller.isOpen),
      ),
    );
  }
}
