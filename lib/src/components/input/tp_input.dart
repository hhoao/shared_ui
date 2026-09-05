import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../theme/components/tp_input_theme.dart';
import '../../theme/tokens/tp_control_metrics.dart';
import '../../theme/tp_theme.dart';

TpControlSizeMetrics tpResolveInputMetrics({
  required TpControlMetrics control,
  required TpInputTheme inputTheme,
  TpControlSize? size,
  TpControlSizeMetrics? metrics,
}) {
  if (metrics != null) return metrics;
  if (size != null) return control.metricsFor(size);
  if (inputTheme.metrics != null) return inputTheme.metrics!;
  if (inputTheme.defaultSize != null) {
    return control.metricsFor(inputTheme.defaultSize!);
  }
  return control.input;
}

/// Single-line outline [TextField] chrome aligned with [TpInputTheme] /
/// textarea fill + border colors.
InputDecoration tpOutlineInputDecoration(
  BuildContext context, {
  InputDecoration? decoration,
  bool hasError = false,
  TpControlSize? size,
  TpControlSizeMetrics? metrics,
}) {
  final theme = Theme.of(context);
  final scheme = theme.colorScheme;
  final inputTheme = theme.inputDecorationTheme;
  final tp = TpTheme.of(context);
  final control = tp.control;
  final metricsTheme = tp.inputTheme;
  final resolvedMetrics = tpResolveInputMetrics(
    control: control,
    inputTheme: metricsTheme,
    size: size,
    metrics: metrics,
  );
  final useDefaultInputTrack =
      identical(resolvedMetrics, control.input) ||
      resolvedMetrics == control.input;
  final radius = BorderRadius.circular(control.radius);
  final base = decoration ?? const InputDecoration();
  final outline = scheme.outlineVariant;

  OutlineInputBorder outlineBorder(Color color, [double width = 1]) =>
      OutlineInputBorder(
        borderRadius: radius,
        borderSide: BorderSide(color: color, width: width),
      );

  OutlineInputBorder? themed(
    InputBorder? fromTheme,
    OutlineInputBorder fallback,
  ) {
    if (fromTheme is OutlineInputBorder) {
      return fromTheme.copyWith(borderRadius: radius);
    }
    return fallback;
  }

  final hintBase = theme.textTheme.bodyMedium ?? theme.textTheme.bodyLarge!;
  final hintStyle = tpWithResolvedFontSize(
    (base.hintStyle ?? inputTheme.hintStyle ?? hintBase).copyWith(
      color: scheme.onSurfaceVariant.withValues(alpha: metricsTheme.hintAlpha),
      height: 1.25,
      fontWeight: FontWeight.w400,
    ),
    sizeFrom: theme.textTheme.bodySmall ?? theme.textTheme.bodyMedium,
    typography: tp.typography,
  );

  // Per-widget size/metrics (or a theme-level TpInputTheme track) must win
  // over the fixed geometry baked into the Material inputDecorationTheme,
  // otherwise every input collapses back to the default 32px track.
  final trackConstraints = useDefaultInputTrack
      ? inputTheme.constraints
      : BoxConstraints.tightFor(height: resolvedMetrics.height);
  final trackPadding = useDefaultInputTrack
      ? inputTheme.contentPadding
      : EdgeInsets.symmetric(
          horizontal: resolvedMetrics.horizontalPadding,
          vertical: resolvedMetrics.verticalPadding,
        );

  return base.copyWith(
    filled: base.filled ?? true,
    fillColor:
        base.fillColor ?? inputTheme.fillColor ?? scheme.surfaceContainer,
    isDense: base.isDense ?? useDefaultInputTrack,
    constraints: base.constraints ?? trackConstraints,
    contentPadding: base.contentPadding ?? trackPadding,
    hintStyle: hintStyle,
    border: themed(inputTheme.border, outlineBorder(outline)),
    enabledBorder: themed(
      inputTheme.enabledBorder,
      outlineBorder(hasError ? scheme.error : outline),
    ),
    focusedBorder: themed(
      inputTheme.focusedBorder,
      outlineBorder(
        hasError ? scheme.error : scheme.primary,
        metricsTheme.focusedBorderWidth,
      ),
    ),
    errorBorder: themed(inputTheme.errorBorder, outlineBorder(scheme.error)),
    focusedErrorBorder: themed(
      inputTheme.focusedErrorBorder,
      outlineBorder(scheme.error, metricsTheme.focusedBorderWidth),
    ),
    disabledBorder: themed(
      inputTheme.disabledBorder,
      outlineBorder(
        outline.withValues(alpha: metricsTheme.disabledBorderAlpha),
      ),
    ),
  );
}

/// Single-line text input with outline chrome matching [TpTextarea] / theme.
class TpInput extends StatefulWidget {
  const TpInput({
    super.key,
    this.initialValue,
    this.controller,
    this.focusNode,
    this.decoration,
    this.size,
    this.metrics,
    this.onChanged,
    this.onEditingComplete,
    this.onSubmitted,
    this.style,
    this.strutStyle,
    this.textAlign = TextAlign.start,
    this.textDirection,
    this.showCursor,
    this.autofocus = false,
    this.enabled = true,
    this.readOnly = false,
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
    this.restorationId,
  }) : assert(
         initialValue == null || controller == null,
         'Cannot provide both initialValue and controller',
       );

  final String? initialValue;
  final TextEditingController? controller;
  final FocusNode? focusNode;
  final InputDecoration? decoration;
  final TpControlSize? size;
  final TpControlSizeMetrics? metrics;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onEditingComplete;
  final ValueChanged<String>? onSubmitted;
  final TextStyle? style;
  final StrutStyle? strutStyle;
  final TextAlign textAlign;
  final TextDirection? textDirection;
  final bool? showCursor;
  final bool autofocus;
  final bool enabled;
  final bool readOnly;
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
  final String? restorationId;

  @override
  State<TpInput> createState() => _TpInputState();
}

class _TpInputState extends State<TpInput> {
  TextEditingController? _ownedController;
  FocusNode? _ownedFocusNode;

  TextEditingController get _controller =>
      widget.controller ?? _ownedController!;

  FocusNode get _focusNode => widget.focusNode ?? _ownedFocusNode!;

  @override
  void initState() {
    super.initState();
    if (widget.controller == null) {
      _ownedController = TextEditingController(text: widget.initialValue);
    }
    if (widget.focusNode == null) {
      _ownedFocusNode = FocusNode();
    }
  }

  @override
  void didUpdateWidget(covariant TpInput oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.controller == null && oldWidget.controller != null) {
      _ownedController = TextEditingController(
        text: oldWidget.controller!.text,
      );
    } else if (widget.controller != null && oldWidget.controller == null) {
      _ownedController?.dispose();
      _ownedController = null;
    }

    if (widget.focusNode == null && oldWidget.focusNode != null) {
      _ownedFocusNode = FocusNode();
    } else if (widget.focusNode != null && oldWidget.focusNode == null) {
      _ownedFocusNode?.dispose();
      _ownedFocusNode = null;
    }
  }

  @override
  void dispose() {
    _ownedController?.dispose();
    _ownedFocusNode?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final style = widget.style ?? tpTextFieldStyle(theme.textTheme);

    return TextField(
      controller: _controller,
      focusNode: _focusNode,
      decoration: tpOutlineInputDecoration(
        context,
        decoration: widget.decoration,
        size: widget.size,
        metrics: widget.metrics,
      ),
      style: style,
      strutStyle: widget.strutStyle,
      textAlign: widget.textAlign,
      textDirection: widget.textDirection,
      showCursor: widget.showCursor,
      autofocus: widget.autofocus,
      enabled: widget.enabled,
      readOnly: widget.readOnly,
      obscureText: widget.obscureText,
      maxLines: 1,
      maxLength: widget.maxLength,
      maxLengthEnforcement: widget.maxLengthEnforcement,
      cursorWidth: widget.cursorWidth,
      cursorHeight: widget.cursorHeight,
      cursorRadius: widget.cursorRadius,
      cursorColor: widget.cursorColor,
      keyboardAppearance: widget.keyboardAppearance,
      keyboardType: widget.keyboardType,
      textInputAction: widget.textInputAction,
      inputFormatters: widget.inputFormatters,
      scrollPadding: widget.scrollPadding,
      enableInteractiveSelection: widget.enableInteractiveSelection,
      selectionControls: widget.selectionControls,
      onChanged: widget.onChanged,
      onEditingComplete: widget.onEditingComplete,
      onSubmitted: widget.onSubmitted,
      onTap: widget.onTap,
      onTapOutside: widget.onTapOutside,
      mouseCursor: widget.mouseCursor,
      restorationId: widget.restorationId,
    );
  }
}
