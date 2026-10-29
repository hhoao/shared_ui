import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../theme/tp_text_styles.dart';
import '../../theme/tokens/tp_control_metrics.dart';
import '../button/tp_button.dart';
import '../time_picker/tp_time_picker.dart';
import 'tp_calendar.dart';
import 'tp_date_time_range.dart';

class TpDateTimeRangePanel extends StatelessWidget {
  const TpDateTimeRangePanel({
    required this.start,
    required this.end,
    required this.activeField,
    required this.liveEnd,
    required this.presets,
    required this.selectedPresetId,
    required this.labels,
    required this.firstDate,
    required this.lastDate,
    required this.onActiveFieldChanged,
    required this.onStartChanged,
    required this.onEndChanged,
    required this.onDateChanged,
    required this.onLiveEndChanged,
    required this.onPresetSelected,
    required this.onApply,
    required this.onCancel,
    this.error,
    super.key,
  });

  final DateTime start;
  final DateTime end;
  final TpDateTimeRangeField activeField;
  final bool liveEnd;
  final List<TpDateTimeRangePreset> presets;
  final String? selectedPresetId;
  final TpDateTimeRangePickerLabels labels;
  final DateTime firstDate;
  final DateTime lastDate;
  final ValueChanged<TpDateTimeRangeField> onActiveFieldChanged;
  final ValueChanged<DateTime> onStartChanged;
  final ValueChanged<DateTime> onEndChanged;
  final ValueChanged<DateTime> onDateChanged;
  final ValueChanged<bool> onLiveEndChanged;
  final ValueChanged<String> onPresetSelected;
  final VoidCallback onApply;
  final VoidCallback onCancel;
  final String? error;

  @override
  Widget build(BuildContext context) {
    final styles = TpTextStyles.of(context);
    final cs = Theme.of(context).colorScheme;

    final fields = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          labels.hint,
          style: styles.xs.copyWith(
            color: cs.onSurface.withValues(alpha: 0.56),
          ),
        ),
        const SizedBox(height: 8),
        _FieldCard(
          label: labels.start,
          date: start,
          active: activeField == TpDateTimeRangeField.start,
          enabled: true,
          onTap: () => onActiveFieldChanged(TpDateTimeRangeField.start),
          onTimeChanged: (time) => onStartChanged(
            DateTime(start.year, start.month, start.day, time.hour, time.minute),
          ),
        ),
        const SizedBox(height: 8),
        _FieldCard(
          label: labels.end,
          date: end,
          active: activeField == TpDateTimeRangeField.end,
          enabled: !liveEnd,
          onTap: () => onActiveFieldChanged(TpDateTimeRangeField.end),
          onTimeChanged: (time) => onEndChanged(
            DateTime(end.year, end.month, end.day, time.hour, time.minute),
          ),
        ),
        const SizedBox(height: 4),
        InkWell(
          onTap: () => onLiveEndChanged(!liveEnd),
          child: Row(
            children: [
              IgnorePointer(
                child: Checkbox(
                  value: liveEnd,
                  onChanged: (_) {},
                ),
              ),
              Expanded(
                child: Text(
                  labels.liveEnd,
                  style: styles.xs.copyWith(
                    color: cs.onSurface.withValues(alpha: 0.72),
                  ),
                ),
              ),
            ],
          ),
        ),
        if (error != null) ...[
          const SizedBox(height: 4),
          Text(error!, style: styles.xs.copyWith(color: cs.error)),
        ],
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: TpButton(
                variant: TpButtonVariant.outline,
                size: TpControlSize.small,
                onPressed: onCancel,
                child: Text(labels.cancel),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: TpButton(
                size: TpControlSize.small,
                onPressed: onApply,
                child: Text(labels.confirm),
              ),
            ),
          ],
        ),
      ],
    );

    final calendar = Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: cs.surfaceContainerLow,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: cs.outlineVariant),
      ),
      child: TpCalendar(
        key: ValueKey(activeField),
        firstDate: firstDate,
        lastDate: lastDate,
        selected: activeField == TpDateTimeRangeField.start ? start : end,
        initialMonth: activeField == TpDateTimeRangeField.start ? start : end,
        allowDeselection: false,
        onChanged: (date) {
          if (date != null) onDateChanged(date);
        },
      ),
    );

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (presets.isNotEmpty) ...[
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (final preset in presets)
                TpButton(
                  variant: selectedPresetId == preset.id
                      ? TpButtonVariant.primary
                      : TpButtonVariant.outline,
                  size: TpControlSize.small,
                  onPressed: () => onPresetSelected(preset.id),
                  child: Text(preset.label),
                ),
            ],
          ),
          const SizedBox(height: 10),
        ],
        LayoutBuilder(
          builder: (context, constraints) {
            final narrow = constraints.maxWidth < 560;
            if (narrow) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  fields,
                  const SizedBox(height: 10),
                  calendar,
                ],
              );
            }
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(flex: 5, child: fields),
                const SizedBox(width: 12),
                Expanded(flex: 6, child: calendar),
              ],
            );
          },
        ),
      ],
    );
  }
}

class _FieldCard extends StatelessWidget {
  const _FieldCard({
    required this.label,
    required this.date,
    required this.active,
    required this.enabled,
    required this.onTap,
    required this.onTimeChanged,
  });

  final String label;
  final DateTime date;
  final bool active;
  final bool enabled;
  final VoidCallback onTap;
  final ValueChanged<TimeOfDay> onTimeChanged;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final styles = TpTextStyles.of(context);

    return Opacity(
      opacity: enabled ? 1 : 0.5,
      child: GestureDetector(
        onTap: enabled ? onTap : null,
        behavior: HitTestBehavior.opaque,
        child: Container(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
          decoration: BoxDecoration(
            color: enabled ? cs.surface : cs.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: active ? cs.primary : cs.outlineVariant,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                label,
                style: styles.xs.copyWith(
                  color: cs.onSurface.withValues(alpha: 0.56),
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      DateFormat('yyyy/MM/dd').format(date),
                      style: styles.sm,
                    ),
                  ),
                  TpTimePicker(
                    initialValue: TimeOfDay.fromDateTime(date),
                    enabled: enabled,
                    onChanged: onTimeChanged,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
