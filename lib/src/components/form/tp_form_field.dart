import 'package:flutter/widgets.dart';

import 'tp_form.dart';
import 'tp_form_field_layout.dart';

/// Transforms a field value before it is stored in [TpFormState.value].
typedef TpFormToValueTransformer<T> = dynamic Function(T value);

/// Transforms a stored form value into the field's expected type.
typedef TpFormFromValueTransformer<T> = T Function(dynamic value);

/// Form field that registers with [TpForm] and lays out label / error / description.
///
/// Put a plain control in [builder] (e.g. [TextField]), not a nested [FormField].
class TpFormField<T> extends FormField<T> {
  TpFormField({
    super.key,
    required Widget Function(TpFormFieldState<TpFormField<T>, T> state)
    builder,
    super.onSaved,
    super.validator,
    super.initialValue,
    super.enabled,
    super.autovalidateMode,
    super.restorationId,
    super.forceErrorText,
    super.onReset,
    this.readOnly = false,
    this.id,
    this.focusNode,
    this.label,
    this.error,
    this.description,
    this.onChanged,
    this.toValueTransformer,
    this.fromValueTransformer,
    this.layoutStyle = TpFormFieldLayoutStyle.stacked,
    this.labelWidth = 140,
  }) : super(
         builder: (fieldState) {
           final state = fieldState as TpFormFieldState<TpFormField<T>, T>;
           final hasError = state.hasError;
           final effectiveError = hasError
               ? error?.call(state.errorText!) ?? Text(state.errorText!)
               : null;

           return TpFormFieldLayout(
             label: label,
             error: effectiveError,
             description: description,
             style: layoutStyle,
             labelWidth: labelWidth,
             child: builder(state),
           );
         },
       );

  /// Optional id used as the key in [TpFormState.value].
  final String? id;

  final FocusNode? focusNode;
  final Widget? label;
  final Widget Function(String error)? error;
  final Widget? description;
  final ValueChanged<T?>? onChanged;
  final TpFormToValueTransformer<T?>? toValueTransformer;
  final TpFormFromValueTransformer<T?>? fromValueTransformer;
  final bool readOnly;

  /// Label placement relative to the control.
  final TpFormFieldLayoutStyle layoutStyle;

  /// Label column width when [layoutStyle] is [TpFormFieldLayoutStyle.inline].
  final double labelWidth;

  @override
  TpFormFieldState<TpFormField<T>, T> createState() =>
      TpFormFieldState<TpFormField<T>, T>();
}

/// State for [TpFormField], including focus and parent [TpForm] registration.
class TpFormFieldState<F extends TpFormField<T>, T>
    extends FormFieldState<T> {
  final String _internalId = UniqueKey().toString();
  FocusNode? _focusNode;
  TpFormState? _parentForm;
  String? _forceErrorText;

  FocusNode get focusNode => widget.focusNode ?? _focusNode!;

  String? get forceErrorText => widget.forceErrorText ?? _forceErrorText;

  @override
  String? get errorText => forceErrorText ?? super.errorText;

  @override
  bool get hasError => forceErrorText != null || super.hasError;

  void setError(String? error) {
    setState(() => _forceErrorText = error);
  }

  @override
  F get widget => super.widget as F;

  T? get initialValue {
    if (widget.initialValue != null) return widget.initialValue;
    if (widget.id == null || _parentForm == null) return null;
    final value = _parentForm!.getFieldValue(widget.id!);
    if (widget.fromValueTransformer != null) {
      return widget.fromValueTransformer!(value);
    }
    return value as T?;
  }

  bool get enabled => widget.enabled && (_parentForm?.enabled ?? true);

  String get effectiveId => widget.id ?? _internalId;

  @override
  void initState() {
    super.initState();
    if (widget.focusNode == null) {
      _focusNode = FocusNode(canRequestFocus: !widget.readOnly);
    }
    _parentForm = TpForm.maybeOf(context);
    _parentForm?.registerField(effectiveId, this);
  }

  @override
  void didUpdateWidget(covariant TpFormField<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.id != oldWidget.id) {
      _parentForm?.unregisterField(oldWidget.id ?? _internalId, this);
      _parentForm?.registerField(effectiveId, this);
    }
    if (oldWidget.focusNode != null && widget.focusNode == null) {
      _focusNode ??= FocusNode(canRequestFocus: !widget.readOnly);
    }
    if (widget.readOnly != oldWidget.readOnly) {
      _focusNode?.canRequestFocus = !widget.readOnly;
    }
  }

  @override
  void didChange(T? value) {
    _parentForm?.setFieldValue<T>(effectiveId, value, notifyField: false);
    super.didChange(value);
    widget.onChanged?.call(value);
  }

  @override
  void reset() {
    super.reset();
    didChange(initialValue);
  }

  @override
  void dispose() {
    _parentForm?.unregisterField(effectiveId, this);
    _focusNode?.dispose();
    super.dispose();
  }

  void focus() {
    FocusScope.of(context).requestFocus(focusNode);
  }

  void ensureVisible() {
    Scrollable.ensureVisible(context);
  }

  @override
  void setValue(T? value, {bool populateForm = true}) {
    super.setValue(value);
    if (populateForm) {
      _parentForm?.setFieldValue<T>(effectiveId, value, notifyField: false);
    }
  }

  void registerToValueTransformer(Map<String, Function> map) {
    final fun = widget.toValueTransformer;
    if (fun != null) map[effectiveId] = fun;
  }

  void registerFromValueTransformer(Map<String, Function> map) {
    final fun = widget.fromValueTransformer;
    if (fun != null) map[effectiveId] = fun;
  }
}
