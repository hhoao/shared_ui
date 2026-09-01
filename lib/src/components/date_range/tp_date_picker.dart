import 'package:flutter/material.dart';

import '../action_menu/tp_action_menu.dart';
import '../popover/tp_popover.dart';
import 'tp_calendar.dart';

/// Popover single-day picker using [TpPopover] + [TpCalendar].
class TpDatePicker extends StatefulWidget {
  const TpDatePicker({
    super.key,
    required this.firstDate,
    required this.lastDate,
    required this.triggerBuilder,
    this.selected,
    this.onChanged,
    this.closeOnSelection = true,
    this.panelWidth = 280,
    this.controller,
    this.header,
  });

  final DateTime firstDate;
  final DateTime lastDate;
  final DateTime? selected;
  final ValueChanged<DateTime?>? onChanged;
  final bool closeOnSelection;
  final double panelWidth;

  /// Receives open state so the trigger can reflect popover visibility.
  final Widget Function(BuildContext context, bool isOpen) triggerBuilder;

  final TpPopoverController? controller;

  /// Optional widget rendered above the calendar.
  final Widget? header;

  @override
  State<TpDatePicker> createState() => _TpDatePickerState();
}

class _TpDatePickerState extends State<TpDatePicker> {
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

  void _handleDateChanged(DateTime? date) {
    widget.onChanged?.call(date);
    if (widget.closeOnSelection && date != null) {
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
      popover: (_) => Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (widget.header != null) ...[
            widget.header!,
            const SizedBox(height: 8),
          ],
          TpCalendar(
            firstDate: widget.firstDate,
            lastDate: widget.lastDate,
            selected: widget.selected,
            initialMonth: widget.selected ?? widget.lastDate,
            onChanged: _handleDateChanged,
          ),
        ],
      ),
      child: GestureDetector(
        onTap: _controller.toggle,
        behavior: HitTestBehavior.opaque,
        child: widget.triggerBuilder(context, _controller.isOpen),
      ),
    );
  }
}
