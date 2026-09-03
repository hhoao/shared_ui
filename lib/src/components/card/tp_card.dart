import 'package:flutter/material.dart';

import '../../theme/tp_theme.dart';

/// Shadow preset for [TpCard].
enum TpCardElevation {
  none,
  /// Settings groups / compact tiles (blur 4, offset y 2).
  low,
  /// Prominent action cards (blur 8, offset y 2).
  medium,
}

/// Generic padded surface container.
class TpCard extends StatelessWidget {
  const TpCard({
    super.key,
    required this.child,
    this.padding,
    this.color,
    this.borderRadius,
    this.clipBehavior = Clip.antiAlias,
    this.outlined = false,
    this.borderAlpha = 0.5,
    this.elevation = TpCardElevation.none,
  });

  /// Bordered clip panel with no fill — preference / settings shells on desktop.
  const TpCard.outlined({
    super.key,
    required this.child,
    this.padding = EdgeInsets.zero,
    this.borderRadius = 14,
    this.clipBehavior = Clip.antiAlias,
    this.borderAlpha = 0.5,
  })  : color = Colors.transparent,
        outlined = true,
        elevation = TpCardElevation.none;

  /// Mobile settings-style group: surface fill + soft shadow, no border.
  const TpCard.elevated({
    super.key,
    required this.child,
    this.padding = EdgeInsets.zero,
    this.borderRadius = 18,
    this.color,
    this.clipBehavior = Clip.antiAlias,
    this.elevation = TpCardElevation.low,
  })  : outlined = false,
        borderAlpha = 0.5;

  /// Compact interactive tile: surface fill, border, light shadow.
  const TpCard.tiled({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(12),
    this.borderRadius = 12,
    this.color,
    this.clipBehavior = Clip.antiAlias,
    this.borderAlpha = 1.0,
    this.elevation = TpCardElevation.low,
  }) : outlined = true;

  final Widget child;
  final EdgeInsetsGeometry? padding;
  final Color? color;
  final double? borderRadius;
  final Clip clipBehavior;

  /// When true, draws an [outlineVariant] border (see [TpCard.outlined]).
  final bool outlined;
  final double borderAlpha;
  final TpCardElevation elevation;

  static List<BoxShadow> shadowsFor(
    ColorScheme scheme,
    TpCardElevation level,
  ) {
    if (scheme.brightness == Brightness.light) {
      return switch (level) {
        TpCardElevation.none => const [],
        TpCardElevation.low => [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
        TpCardElevation.medium => [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      };
    }
    final alpha = 0.28;
    final shadowColor = scheme.shadow.withValues(alpha: alpha);
    return switch (level) {
      TpCardElevation.none => const [],
      TpCardElevation.low => [
        BoxShadow(
          color: shadowColor,
          blurRadius: 4,
          offset: const Offset(0, 2),
        ),
      ],
      TpCardElevation.medium => [
        BoxShadow(
          color: shadowColor,
          blurRadius: 8,
          offset: const Offset(0, 2),
        ),
      ],
    };
  }

  /// Compact tile shadow — matches legacy mobile tool cards (blur 4, y 1).
  static List<BoxShadow> tileShadows(ColorScheme scheme) {
    if (scheme.brightness == Brightness.light) {
      return [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.12),
          blurRadius: 4,
          offset: const Offset(0, 1),
        ),
      ];
    }
    final alpha = 0.28;
    return [
      BoxShadow(
        color: scheme.shadow.withValues(alpha: alpha),
        blurRadius: 4,
        offset: const Offset(0, 1),
      ),
    ];
  }

  Color _resolveBorderColor(ColorScheme scheme) {
    if (outlined && elevation != TpCardElevation.none) {
      return scheme.brightness == Brightness.light
          ? const Color(0xFFE0E0E0) // legacy grey[300]
          : scheme.outlineVariant.withValues(alpha: borderAlpha);
    }
    return scheme.outlineVariant.withValues(alpha: borderAlpha);
  }

  Color _resolveFillColor(ColorScheme scheme) {
    if (color != null) return color!;
    if (outlined && elevation == TpCardElevation.none) {
      return Colors.transparent;
    }
    if (outlined && elevation != TpCardElevation.none) {
      return scheme.brightness == Brightness.light
          ? Colors.white
          : scheme.surface;
    }
    if (elevation != TpCardElevation.none) {
      return scheme.surface;
    }
    return scheme.surfaceContainer;
  }

  List<BoxShadow> _resolveShadows(ColorScheme scheme) {
    if (elevation == TpCardElevation.none) return const [];
    if (outlined && elevation == TpCardElevation.low) {
      return tileShadows(scheme);
    }
    return shadowsFor(scheme, elevation);
  }

  @override
  Widget build(BuildContext context) {
    final tp = TpTheme.of(context);
    final scheme = Theme.of(context).colorScheme;
    final cardTheme = tp.cardTheme;
    final radius = borderRadius ?? cardTheme.borderRadius ?? tp.control.radius;
    final resolvedPadding = outlined && padding == null
        ? EdgeInsets.zero
        : (padding ?? cardTheme.padding ?? EdgeInsets.all(tp.spacing.md));
    final fill = _resolveFillColor(scheme);
    final shadows = _resolveShadows(scheme);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: fill,
        borderRadius: BorderRadius.circular(radius),
        border: outlined
            ? Border.all(color: _resolveBorderColor(scheme))
            : null,
        boxShadow: shadows,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        clipBehavior: clipBehavior,
        child: Padding(
          padding: resolvedPadding,
          child: child,
        ),
      ),
    );
  }
}
