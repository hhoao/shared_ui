import 'package:flutter/material.dart';

/// Localized, presentation-ready details for one failed catalog source.
@immutable
class TpCatalogFailureView {
  const TpCatalogFailureView({
    required this.sourceLabel,
    required this.message,
  });

  final String sourceLabel;
  final String message;
}

/// Warning affordance for partial catalog-source failures.
class TpCatalogSourceWarning extends StatelessWidget {
  TpCatalogSourceWarning({
    super.key,
    required List<TpCatalogFailureView> failures,
  }) : failures = List.unmodifiable(failures);

  final List<TpCatalogFailureView> failures;

  @override
  Widget build(BuildContext context) {
    if (failures.isEmpty) return const SizedBox.shrink();

    final message = failures
        .map((failure) => '${failure.sourceLabel}: ${failure.message}')
        .join('\n');
    final scheme = Theme.of(context).colorScheme;

    return Tooltip(
      message: message,
      preferBelow: false,
      child: Semantics(
        label: message,
        child: SizedBox(
          width: 32,
          height: 32,
          child: Center(
            child: Icon(
              Icons.warning_amber_rounded,
              size: 18,
              color: scheme.error,
            ),
          ),
        ),
      ),
    );
  }
}
