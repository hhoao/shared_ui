import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../form/tp_form_field.dart';
import 'tp_input.dart';

/// [TpFormField] wrapping [TpInput]; label / error / description come from
/// [TpFormFieldLayout], not from [InputDecoration.labelText].
class TpInputFormField extends TpFormField<String> {
  TpInputFormField({
    super.key,
    super.id,
    String? initialValue,
    this.controller,
    super.focusNode,
    super.label,
    super.error,
    super.description,
    super.validator,
    super.onChanged,
    super.onSaved,
    super.enabled,
    super.readOnly,
    super.autovalidateMode,
    super.restorationId,
    super.forceErrorText,
    super.onReset,
    super.toValueTransformer,
    super.fromValueTransformer,
    super.layoutStyle,
    super.labelWidth,
    this.decoration,
    this.style,
    this.strutStyle,
    this.textAlign = TextAlign.start,
    this.textDirection,
    this.showCursor,
    this.autofocus = false,
    this.obscureText = false,
    this.maxLength,
    this.maxLengthEnforcement,
    this.cursorWidth = 2.0,
    this.cursorHeight,
    this.cursorRadius,
    this.cursorColor,
    this.keyboardAppearance,
    this.keyboardType,
    this.textInputAction,
    this.inputFormatters,
    this.scrollPadding = const EdgeInsets.all(20),
    this.enableInteractiveSelection,
    this.selectionControls,
    this.onTap,
    this.onTapOutside,
    this.mouseCursor,
    this.onEditingComplete,
    this.onSubmitted,
  }) : assert(
         initialValue == null || controller == null,
         'Cannot provide both initialValue and controller',
       ),
       super(
         initialValue: controller != null ? controller.text : initialValue,
         builder: (state) {
           state as TpInputFormFieldState;
           final baseDecoration = decoration ?? const InputDecoration();
           return TpInput(
             focusNode: state.focusNode,
             enabled: state.enabled,
             readOnly: readOnly,
             controller: state.controller,
             onEditingComplete: onEditingComplete,
             onSubmitted: onSubmitted,
             decoration: baseDecoration.copyWith(
               errorText: state.hasError ? '' : null,
               errorStyle: const TextStyle(height: 0, fontSize: 0),
             ),
             style: style,
             strutStyle: strutStyle,
             textAlign: textAlign,
             textDirection: textDirection,
             showCursor: showCursor,
             autofocus: autofocus,
             obscureText: obscureText,
             maxLength: maxLength,
             maxLengthEnforcement: maxLengthEnforcement,
             cursorWidth: cursorWidth,
             cursorHeight: cursorHeight,
             cursorRadius: cursorRadius,
             cursorColor: cursorColor,
             keyboardAppearance: keyboardAppearance,
             keyboardType: keyboardType,
             textInputAction: textInputAction,
             inputFormatters: inputFormatters,
             scrollPadding: scrollPadding,
             enableInteractiveSelection: enableInteractiveSelection,
             selectionControls: selectionControls,
             onTap: onTap,
             onTapOutside: onTapOutside,
             mouseCursor: mouseCursor,
             restorationId: restorationId,
           );
         },
       );

  final TextEditingController? controller;
  final InputDecoration? decoration;
  final TextStyle? style;
  final StrutStyle? strutStyle;
  final TextAlign textAlign;
  final TextDirection? textDirection;
  final bool? showCursor;
  final bool autofocus;
  final bool obscureText;
  final int? maxLength;
  final MaxLengthEnforcement? maxLengthEnforcement;
  final double cursorWidth;
  final double? cursorHeight;
  final Radius? cursorRadius;
  final Color? cursorColor;
  final Brightness? keyboardAppearance;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final List<TextInputFormatter>? inputFormatters;
  final EdgeInsets scrollPadding;
  final bool? enableInteractiveSelection;
  final TextSelectionControls? selectionControls;
  final GestureTapCallback? onTap;
  final TapRegionCallback? onTapOutside;
  final MouseCursor? mouseCursor;
  final VoidCallback? onEditingComplete;
  final ValueChanged<String>? onSubmitted;

  @override
  TpFormFieldState<TpInputFormField, String> createState() =>
      TpInputFormFieldState();
}

class TpInputFormFieldState extends TpFormFieldState<TpInputFormField, String> {
  TextEditingController? _controller;

  TextEditingController get controller => widget.controller ?? _controller!;

  @override
  void initState() {
    super.initState();
    if (widget.controller == null) {
      _controller = TextEditingController(text: value);
    }
    controller.addListener(_onControllerChanged);
  }

  @override
  void didUpdateWidget(covariant TpInputFormField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      (oldWidget.controller ?? _controller)?.removeListener(
        _onControllerChanged,
      );
      if (oldWidget.controller == null && widget.controller != null) {
        _controller?.dispose();
        _controller = null;
      } else if (oldWidget.controller != null && widget.controller == null) {
        _controller = TextEditingController(text: value);
      }
      controller.addListener(_onControllerChanged);
    }
  }

  @override
  void didChange(String? value) {
    super.didChange(value);
    if (controller.text != value) {
      controller.text = value ?? '';
    }
  }

  @override
  void reset() {
    super.reset();
    controller.text = initialValue ?? '';
  }

  @override
  void dispose() {
    controller.removeListener(_onControllerChanged);
    _controller?.dispose();
    super.dispose();
  }

  void _onControllerChanged() {
    if (controller.text != value) {
      didChange(controller.text);
    }
  }
}
