import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../theme/tp_text_styles.dart';
import '../hover/tp_hover.dart';
import 'calendar_date_utils.dart';

/// Inline month grid for selecting a single [DateTime].
///
/// Mirrors [TpRangeCalendar]'s chrome (header, weekday row, day cells) while
/// keeping a single selection: tapping the selected day again clears it.
class TpCalendar extends StatefulWidget {
  const TpCalendar({
    super.key,
    required this.firstDate,
    required this.lastDate,
    this.selected,
    this.onChanged,
    this.initialMonth,
    this.allowDeselection = true,
  });

  final DateTime firstDate;
  final DateTime lastDate;
  final DateTime? selected;
  final ValueChanged<DateTime?>? onChanged;
  final DateTime? initialMonth;

  /// Whether tapping the selected day again emits `null`.
  final bool allowDeselection;

  @override
  State<TpCalendar> createState() => _TpCalendarState();
}

class _TpCalendarState extends State<TpCalendar> {
  late DateTime _displayedMonth;
  DateTime? _selected;

  @override
  void initState() {
    super.initState();
    _selected = widget.selected?.calendarDay;
    _displayedMonth = _initialMonth();
  }

  @override
  void didUpdateWidget(TpCalendar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selected != widget.selected) {
      _selected = widget.selected?.calendarDay;
    }
  }

  DateTime _initialMonth() {
    return (widget.initialMonth ?? widget.selected ?? widget.lastDate)
        .calendarMonthStart;
  }

  bool _isDisabled(DateTime day) {
    return day.isBefore(widget.firstDate.calendarDay) ||
        day.isAfter(widget.lastDate.calendarDay);
  }

  void _selectDay(DateTime day) {
    if (_isDisabled(day)) return;

    final deselect = widget.allowDeselection &&
        _selected != null &&
        day.isSameCalendarDay(_selected!);
    setState(() {
      _selected = deselect ? null : day.calendarDay;
    });
    widget.onChanged?.call(deselect ? null : day.calendarDay);
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final styles = TpTextStyles.of(context);
    final locale = Localizations.localeOf(context);
    final firstWeekday = CalendarDateUtils.firstWeekdayForLocale(
      locale.languageCode,
    );
    final dates = CalendarDateUtils.buildMonthGrid(
      _displayedMonth,
      firstWeekday: firstWeekday,
    );
    final monthLabel = DateFormat.yMMMM(locale.toString()).format(
      _displayedMonth,
    );
    final weekdays = _weekdayLabels(context, firstWeekday);
    final today = DateTime.now().calendarDay;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _CalendarHeader(
          label: monthLabel,
          onPrevious: () => _goMonth(-1),
          onNext: () => _goMonth(1),
        ),
        const SizedBox(height: 8),
        Row(
          children: weekdays
              .map(
                (label) => Expanded(
                  child: Center(
                    child: Text(
                      label,
                      style: styles.xs.copyWith(
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                  ),
                ),
              )
              .toList(),
        ),
        const SizedBox(height: 4),
        GridView.count(
          crossAxisCount: 7,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 2,
          crossAxisSpacing: 2,
          children: [
            for (final date in dates)
              if (date == null)
                const SizedBox.shrink()
              else
                _DayCell(
                  date: date,
                  inMonth: date.month == _displayedMonth.month,
                  isToday: date.isSameCalendarDay(today),
                  isSelected: _selected != null &&
                      date.isSameCalendarDay(_selected!),
                  enabled: !_isDisabled(date),
                  onTap: () => _selectDay(date),
                ),
          ],
        ),
      ],
    );
  }

  void _goMonth(int delta) {
    setState(() {
      _displayedMonth = _displayedMonth.addCalendarMonths(delta);
    });
  }

  List<String> _weekdayLabels(BuildContext context, int firstWeekday) {
    final material = MaterialLocalizations.of(context);
    final labels = material.narrowWeekdays;
    final startIndex = firstWeekday == DateTime.monday ? 1 : 0;
    return List.generate(7, (i) => labels[(startIndex + i) % 7]);
  }
}

class _CalendarHeader extends StatelessWidget {
  const _CalendarHeader({
    required this.label,
    required this.onPrevious,
    required this.onNext,
  });

  final String label;
  final VoidCallback onPrevious;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final styles = TpTextStyles.of(context);

    return Row(
      children: [
        _NavButton(icon: Icons.chevron_left, onTap: onPrevious),
        Expanded(
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: styles.mdSemibold.copyWith(color: cs.onSurface),
          ),
        ),
        _NavButton(icon: Icons.chevron_right, onTap: onNext),
      ],
    );
  }
}

class _NavButton extends StatelessWidget {
  const _NavButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return TpHover(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      hoverColor: cs.onSurface.withValues(alpha: 0.06),
      child: Padding(
        padding: const EdgeInsets.all(4),
        child: Icon(icon, size: 18, color: cs.onSurfaceVariant),
      ),
    );
  }
}

class _DayCell extends StatelessWidget {
  const _DayCell({
    required this.date,
    required this.inMonth,
    required this.isToday,
    required this.isSelected,
    required this.enabled,
    required this.onTap,
  });

  final DateTime date;
  final bool inMonth;
  final bool isToday;
  final bool isSelected;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final styles = TpTextStyles.of(context);
    final selected = isSelected;

    final textColor = !enabled
        ? cs.onSurface.withValues(alpha: 0.25)
        : selected
        ? cs.onPrimary
        : inMonth
        ? cs.onSurface
        : cs.onSurfaceVariant.withValues(alpha: 0.55);

    Widget child = Container(
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: selected ? cs.primary : null,
        borderRadius: BorderRadius.circular(6),
        border: isToday && !selected
            ? Border.all(color: cs.primary.withValues(alpha: 0.65))
            : null,
      ),
      child: Text(
        '${date.day}',
        style: styles.xs.copyWith(
          color: textColor,
          fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
        ),
      ),
    );

    if (!enabled) return child;

    if (selected) {
      return GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: child,
      );
    }

    return TpHover(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      hoverColor: cs.onSurface.withValues(alpha: 0.06),
      child: child,
    );
  }
}
