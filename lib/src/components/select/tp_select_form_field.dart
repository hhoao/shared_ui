import 'package:flutter/material.dart';

import '../form/tp_form_field.dart';
import 'tp_select.dart';
import 'tp_select_decoration.dart';

/// [TpFormField] wrapping [TpSelect]; label / error / description come from
/// [TpFormFieldLayout], not from the trigger itself. While the field is in an
/// error state the trigger border turns red and the message renders below it.
class TpSelectFormField<T extends Object> extends TpFormField<T> {
  TpSelectFormField({
    super.key,
    super.id,
    super.initialValue,
    super.focusNode,
    super.label,
    super.error,
    super.description,
    super.validator,
    super.onSaved,
    super.onChanged,
    super.enabled,
    super.autovalidateMode,
    super.restorationId,
    super.layoutStyle,
    super.labelWidth,
    required this.items,
    this.itemLabel,
    this.itemBuilder,
    this.listItemBuilder,
    this.hintText,
    this.decoration,
    this.overlayHeight,
    this.searchable = true,
    this.searchMinItems = 8,
    this.onEmptyTap,
  }) : super(
          builder: (state) {
            return Focus(
              focusNode: state.focusNode,
              child: TpSelect<T>(
                items: items,
                initialItem: state.value,
                itemLabel: itemLabel,
                itemBuilder: itemBuilder,
                listItemBuilder: listItemBuilder,
                hintText: hintText,
                decoration: decoration,
                overlayHeight: overlayHeight,
                enabled: state.enabled,
                searchable: searchable,
                searchMinItems: searchMinItems,
                onEmptyTap: onEmptyTap,
                hasError: state.hasError,
                onChanged: state.didChange,
              ),
            );
          },
        );

  final List<T> items;
  final String Function(T item)? itemLabel;
  final Widget Function(BuildContext context, T item)? itemBuilder;
  final Widget Function(BuildContext context, T item)? listItemBuilder;
  final String? hintText;
  final TpSelectDecoration? decoration;
  final double? overlayHeight;
  final bool searchable;
  final int searchMinItems;
  final VoidCallback? onEmptyTap;

  @override
  TpFormFieldState<TpSelectFormField<T>, T> createState() =>
      TpFormFieldState<TpSelectFormField<T>, T>();
}
