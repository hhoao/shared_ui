# shared_ui

TeamPilot **Tp** design system — reusable Flutter UI primitives (`Tp*`) and theme tokens.

## Theme

Wrap the app with `TpTheme`. Prefer `TpTextStyles.of(context)` for semantic text,
`context.tpFonts` for families, and `TpGlyphWarmup` for boot glyph shaping:

```dart
import 'package:shared_ui/shared_ui.dart';

MaterialApp(
  theme: ThemeData(
    extensions: [
      TpFontTheme(
        uiFontFamily: 'Noto Sans SC',
        monoFontFamily: 'JetBrains Mono',
        monoFontFamilyFallback: const ['monospace'],
      ),
    ],
  ),
  builder: (context, child) {
    return TpTheme(
      data: TpThemeData.fromColorScheme(
        Theme.of(context).colorScheme,
        scale: 1.0, // layout spacing
        iconScale: iconMultiplier,
        controlScale: textMultiplier, // buttons/inputs track text size
      ),
      child: child ?? const SizedBox.shrink(),
    );
  },
);

// Boot warmup (host supplies glyphs charset):
final styles = TpGlyphWarmup.dedupeByShapeKey([
  ...TpTextStyles(theme).stylesForWarmup(),
  ...hostExtras,
]);
TpGlyphWarmup.shapeAll(styles: styles, glyphs: warmupGlyphs);
```

In `pubspec.yaml`:

```yaml
dependencies:
  shared_ui:
    path: packages/shared_ui
```

```dart
import 'package:shared_ui/shared_ui.dart';
```

## Component categories

| Category | Examples |
|----------|----------|
| **Button** | `TpButton`, `TpIconButton` |
| **Input** | `TpInput`, `TpInputFormField`, `TpTextarea`, `TpTextareaFormField` |
| **Token field** | `TpTokenTextField`, `TpTokenChipMirror`, palette typedefs / edit helpers (`applyTpTokenBackspace`, …) |
| **Select** | `TpSelect`, `TpSelectWithCustomInput`, search / filter helpers |
| **Dialog** | `TpDialog` |
| **Form** | `TpForm`, `TpFormField`, `TpFormFieldLayout`, `TpFormMap` |
| **Overlay** | `TpPopover`, `TpTooltip`, `TpActionMenu` / `TpActionMenuPanel` |
| **Date range** | `TpDateRangePicker`, `TpRangeCalendar`, calendar date utils |
| **Toast** | `TpToast`, `TpToastWrapper`, `TpToastConfig`, `TpToastTheme`, `TpToastVariant`, `TpToastAction` |
| **Layout / chrome** | `TpCard`, `TpCardHeader`, `TpActionRow`, `TpSeparator`, `TpSegmentedControl`, `TpSegmentedPicker`, `TpEmptyState`, `TpHover` / `TpHoverRow` (click cursor, hover fill, optional press scale — prefer over bare `GestureDetector` for onTap UI), `TpSidebar*` (see below) |
| **Preference** | `TpPreferenceRow`, `TpPreferenceStack`, `TpSectionHeader`, `TpDisclosure`, `TpStatusBadge`, `TpCompactSelect` |
| **Theme** | `TpTheme`, `TpThemeData`, `TpTextStyles`, `TpFontTheme`, `TpGlyphWarmup`, icon sizes (`sm`/`md`/`lg`/`hero`), spacing / typography / control metrics, per-component themes |

Toast engine sources live under `lib/src/toast/engine/` and are **not** barrel-exported.

## Sidebar

Composable shell chrome aligned with [shadcn Sidebar](https://ui.shadcn.com/docs/components/base/sidebar). The **host** owns `Row(sidebar, inset)`; `TpSidebarProvider` wraps the shell (title bar + content) so triggers and keyboard shortcuts resolve `TpSidebarScope`. On mobile, `TpSidebar` reserves ~0 in-flow width and presents the panel as an `OverlayPortal` drawer.

| shadcn | Tp |
|--------|-----|
| `SidebarProvider` | `TpSidebarProvider` |
| `Sidebar` | `TpSidebar` |
| `SidebarInset` | `TpSidebarInset` |
| `SidebarTrigger` | `TpSidebarTrigger` |
| `SidebarRail` | `TpSidebarRail` |
| `SidebarHeader` / `Footer` / `Content` | `TpSidebarHeader` / `Footer` / `Content` |
| `SidebarGroup*` | `TpSidebarGroup*` |
| `SidebarMenu*` | `TpSidebarMenu*` |
| `useSidebar` | `TpSidebarScope.of` |

`TpSidebarRail` needs a **bounded-height** parent (it sizes its hit strip from `LayoutBuilder` constraints). Prefer a `Stack` overlay on the sidebar panel rather than placing it in an unbounded `Column` child.

## Layout

- `lib/src/components/` — `Tp*` widgets by category
- `lib/src/theme/` — `TpTheme` / `TpThemeData`, tokens, component themes
- `lib/src/toast/engine/` — private toast overlay engine (not public API)
- `lib/shared_ui.dart` — public barrel export
