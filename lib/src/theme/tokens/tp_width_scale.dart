import 'package:flutter/widgets.dart';

import 'tp_breakpoints.dart';

/// Piecewise width → value scale across [TpBreakpoint] stops.
///
/// Pass **any non-empty subset** of `sm` / `md` / `lg` / `xl` / `xxl`. Missing
/// stops are skipped; we lerp only between the anchors you set. Below the
/// first provided stop holds that value; at/above the last holds that value.
///
/// Resolve from a **surface / pane** width (e.g. floating panel), not only the
/// full window — a narrow float stays on the smallest provided tier.
///
/// ```dart
/// // Two anchors — md/lg/xl auto-lerp between sm and xxl:
/// TpScaledEdgeInsets(sm: EdgeInsets.all(8), xxl: EdgeInsets.all(28))
///
/// // One anchor — constant at every width:
/// TpScaledDouble(lg: 20)
/// ```
abstract final class TpWidthScale {
  /// Builds ordered `(width, value)` pairs from optional named anchors.
  ///
  /// At least one of [sm]/[md]/[lg]/[xl]/[xxl] must be non-null.
  static List<(double, T)> anchors<T>({
    T? sm,
    T? md,
    T? lg,
    T? xl,
    T? xxl,
  }) {
    final out = <(double, T)>[];
    void add(TpBreakpoint bp, T? value) {
      if (value == null) return;
      out.add((TpBreakpoints.of(bp), value));
    }

    add(TpBreakpoint.sm, sm);
    add(TpBreakpoint.md, md);
    add(TpBreakpoint.lg, lg);
    add(TpBreakpoint.xl, xl);
    add(TpBreakpoint.xxl, xxl);
    assert(
      out.isNotEmpty,
      'TpWidthScale requires at least one of sm/md/lg/xl/xxl.',
    );
    return out;
  }

  /// Piecewise lerp across [pairs] sorted by ascending width.
  static T resolveFromAnchors<T>({
    required double width,
    required List<(double, T)> pairs,
    required T Function(T a, T b, double t) lerp,
  }) {
    assert(pairs.isNotEmpty);
    if (width <= pairs.first.$1) return pairs.first.$2;
    if (width >= pairs.last.$1) return pairs.last.$2;
    for (var i = 0; i < pairs.length - 1; i++) {
      final (loW, loV) = pairs[i];
      final (hiW, hiV) = pairs[i + 1];
      if (width <= hiW) {
        final t = ((width - loW) / (hiW - loW)).clamp(0.0, 1.0);
        return lerp(loV, hiV, t);
      }
    }
    return pairs.last.$2;
  }

  /// Scales a double; omit unused breakpoint named args.
  static double of(
    double width, {
    double? sm,
    double? md,
    double? lg,
    double? xl,
    double? xxl,
  }) {
    return resolveFromAnchors<double>(
      width: width,
      pairs: anchors(sm: sm, md: md, lg: lg, xl: xl, xxl: xxl),
      lerp: (a, b, t) => a + (b - a) * t,
    );
  }

  /// Scales [EdgeInsets]; omit unused breakpoint named args.
  static EdgeInsets edgeInsets(
    double width, {
    EdgeInsets? sm,
    EdgeInsets? md,
    EdgeInsets? lg,
    EdgeInsets? xl,
    EdgeInsets? xxl,
  }) {
    return resolveFromAnchors<EdgeInsets>(
      width: width,
      pairs: anchors(sm: sm, md: md, lg: lg, xl: xl, xxl: xxl),
      lerp: (a, b, t) => EdgeInsets.lerp(a, b, t)!,
    );
  }
}

/// Sparse [EdgeInsets] anchors aligned with [TpBreakpoint].
///
/// Provide one or more of [sm]/[md]/[lg]/[xl]/[xxl]; omitted tiers lerp
/// between neighbors (see [TpWidthScale]).
class TpScaledEdgeInsets {
  const TpScaledEdgeInsets({
    this.sm,
    this.md,
    this.lg,
    this.xl,
    this.xxl,
  }) : assert(
          sm != null || md != null || lg != null || xl != null || xxl != null,
          'TpScaledEdgeInsets requires at least one of sm/md/lg/xl/xxl.',
        );

  final EdgeInsets? sm;
  final EdgeInsets? md;
  final EdgeInsets? lg;
  final EdgeInsets? xl;
  final EdgeInsets? xxl;

  EdgeInsets forWidth(double width) => TpWidthScale.edgeInsets(
        width,
        sm: sm,
        md: md,
        lg: lg,
        xl: xl,
        xxl: xxl,
      );
}

/// Sparse double anchors aligned with [TpBreakpoint].
///
/// Provide one or more of [sm]/[md]/[lg]/[xl]/[xxl]; omitted tiers lerp
/// between neighbors (see [TpWidthScale]).
class TpScaledDouble {
  const TpScaledDouble({
    this.sm,
    this.md,
    this.lg,
    this.xl,
    this.xxl,
  }) : assert(
          sm != null || md != null || lg != null || xl != null || xxl != null,
          'TpScaledDouble requires at least one of sm/md/lg/xl/xxl.',
        );

  final double? sm;
  final double? md;
  final double? lg;
  final double? xl;
  final double? xxl;

  double forWidth(double width) => TpWidthScale.of(
        width,
        sm: sm,
        md: md,
        lg: lg,
        xl: xl,
        xxl: xxl,
      );
}

/// Provides a width-resolved [T] to descendants via [TpWidthValueScope].
///
/// Measures this host's max width with [LayoutBuilder], then calls [resolve].
class TpWidthValueHost<T> extends StatelessWidget {
  const TpWidthValueHost({
    required this.resolve,
    required this.child,
    this.fallback,
    super.key,
  });

  /// Maps surface width → typed insets / metrics bundle.
  final T Function(double width) resolve;

  /// Used by [TpWidthValueScope.maybeOf] when no host is above.
  final T? fallback;

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        return TpWidthValueScope<T>(
          width: width,
          value: resolve(width),
          fallback: fallback,
          child: child,
        );
      },
    );
  }
}

/// Inherited width-resolved value from the nearest [TpWidthValueHost].
class TpWidthValueScope<T> extends InheritedWidget {
  const TpWidthValueScope({
    required this.width,
    required this.value,
    required super.child,
    this.fallback,
    super.key,
  });

  final double width;
  final T value;
  final T? fallback;

  static TpWidthValueScope<T>? maybeScopeOf<T>(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<TpWidthValueScope<T>>();
  }

  static T? maybeOf<T>(BuildContext context) {
    final scope = maybeScopeOf<T>(context);
    return scope?.value ?? scope?.fallback;
  }

  static T of<T>(BuildContext context) {
    final scope = maybeScopeOf<T>(context);
    final value = scope?.value ?? scope?.fallback;
    assert(
      value != null,
      'TpWidthValueScope<$T> not found. Wrap with TpWidthValueHost<$T>.',
    );
    return value as T;
  }

  static double? maybeWidthOf<T>(BuildContext context) =>
      maybeScopeOf<T>(context)?.width;

  @override
  bool updateShouldNotify(TpWidthValueScope<T> oldWidget) =>
      width != oldWidget.width || value != oldWidget.value;
}
