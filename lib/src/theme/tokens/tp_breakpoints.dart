/// Tailwind-aligned viewport width tokens and predicates.
///
/// Mobile first (`up`): `width >= token` — like `@media (min-width: …)`.
/// Desktop first (`down`): `width < token` — like `<sm` / `max-sm`.
/// Only (`only`): half-open band `[token, next)`; `xxl` is `width >= 1536`.
enum TpBreakpoint { sm, md, lg, xl, xxl }

abstract final class TpBreakpoints {
  static const double sm = 640;
  static const double md = 768;
  static const double lg = 1024;
  static const double xl = 1280;
  static const double xxl = 1536;

  static double of(TpBreakpoint breakpoint) => switch (breakpoint) {
        TpBreakpoint.sm => sm,
        TpBreakpoint.md => md,
        TpBreakpoint.lg => lg,
        TpBreakpoint.xl => xl,
        TpBreakpoint.xxl => xxl,
      };

  static bool up(double width, TpBreakpoint breakpoint) =>
      width >= of(breakpoint);

  static bool down(double width, TpBreakpoint breakpoint) =>
      width < of(breakpoint);

  static bool only(double width, TpBreakpoint breakpoint) {
    final start = of(breakpoint);
    if (breakpoint == TpBreakpoint.xxl) return width >= start;
    final end = of(TpBreakpoint.values[breakpoint.index + 1]);
    return width >= start && width < end;
  }
}
