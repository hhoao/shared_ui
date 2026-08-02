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
| **Dialog** | `TpDialog`, `showTpDialog`, `TpDialogPresentation`, `TpDialogPageShell`, `TpDialogNavShell` |
| **Form** | `TpForm`, `TpFormField`, `TpFormFieldLayout`, `TpFormMap` |
| **Overlay** | `TpPopover`, `TpTooltip`, `TpActionMenu` / `TpActionMenuPanel` |
| **Date range** | `TpDateRangePicker`, `TpRangeCalendar`, calendar date utils |
| **Toast** | `TpToast`, `TpToastWrapper`, `TpToastConfig`, `TpToastTheme`, `TpToastVariant`, `TpToastAction` |
| **Layout / chrome** | `TpCard`, `TpCardHeader`, `TpActionRow`, `TpSeparator`, `TpSegmentedControl`, `TpSegmentedPicker`, `TpEmptyState`, `TpHover` / `TpHoverRow` (click cursor when interactive, animated hover fill; optional idle `backgroundColor`, `enabled`, `onLongPress`, `onSecondaryTapDown`, `pressScale` — prefer over bare `MouseRegion`+`GestureDetector` for onTap chrome; selected idle fill = pass `backgroundColor`, not a `selected` API on `TpHover`), `TpSidebar` |
| **Deferred / keep-alive** | `TpDeferredMountShell`, `TpDeferredMountAfter`, `TpDeferredForegroundMount`, `TpKeepAliveLayer` — host progressive paint guide (TeamPilot: `docs/PERFORMANCE.md`) |
| **Preference** | `TpPreferenceRow`, `TpPreferenceStack`, `TpSectionHeader`, `TpDisclosure`, `TpStatusBadge`, `TpCompactSelect` |
| **File selection** | `showTpFileSelection`, `TpFileSelectionDeps`, `TpFileSelectionOptions`, `TpPickedEntry`, port adapters (`TpFilesystemPort`, `TpGalleryPort`, …) |
| **Theme** | `TpTheme`, `TpThemeData`, `TpTextStyles`, `TpFontTheme`, `TpGlyphWarmup`, icon sizes (`sm`/`md`/`lg`/`hero`), spacing / typography / control metrics, per-component themes |

Toast engine sources live under `lib/src/toast/engine/` and are **not** barrel-exported.

## Breakpoints

`TpBreakpoints` / `TpBreakpoint` provide Tailwind-aligned viewport width tokens (`sm` 640, `md` 768, `lg` 1024, `xl` 1280, `xxl` 1536) and predicates: `up` (mobile first, `width >= token`), `down` (`width < token`), `only` (half-open band `[token, next)`; `xxl` is `width >= 1536`).

Shell hosts may still pass product-specific breakpoint widths (e.g. TeamPilot workspace shell `840` on `TpSidebarProvider` / dialogs). Do not replace those with `TpBreakpoints.md` blindly — use `TpBreakpoints` for component-level responsive layout inside a host-provided pane width.

## TpSidebar

Composable workspace sidebar: wrap the shell in `TpSidebarProvider`, place `TpSidebar`
beside `TpSidebarInset` (or use `TpSidebarMenu` / `TpSidebarTrigger` inside).

- **State:** `TpSidebarProvider` owns desktop `open` + `width` and mobile `openMobile`.
  Read or mutate via `TpSidebarScope.of(context)` / `maybeOf`.
- **Mobile drawer:** below `mobileBreakpoint` (default `768`), the sidebar becomes a hidden
  overlay drawer opened by `TpSidebarTrigger` or edge drag. Close with
  `TpSidebarScope.maybeOf(context)?.setOpenMobile(false)` after navigation.
- **Overlay ownership:** when several `TpSidebar`s share one provider (kept-alive home +
  workspace tabs), only the foreground instance sets `overlayActive: true`. Losing
  ownership (`true` → `false`) closes shared `openMobile`; already-inactive hosts never
  mutate that flag.
- **Mobile drawer width** (`TpSidebarTheme`):
  - `widthMobileFraction` — fraction of viewport width (default `0.8`).
  - `widthMobileOverride` — optional fixed px; wins over fraction when set.
  - `resolveMobileDrawerWidth(screenWidth)` — shared resolver for left drawer and host
    right overlays (`widthMobileOverride ?? screenWidth * widthMobileFraction`).
  - `widthMobile` — legacy fixed default (`288`); not used by `resolveMobileDrawerWidth`.
- **Hosts:** TeamPilot relies on fraction (`widthMobileOverride: null`). huji can pin
  `widthMobileOverride: 288` until it opts into fraction.
- **Breakpoint:** package default `768`; TeamPilot passes `840`
  (`WorkspacePanePolicy.narrowBreakpointWidth`) on `TpSidebarProvider`, `showTpDialog`,
  and `TpDialogNavShell`.

```dart
TpSidebarProvider(
  mobileBreakpoint: 840,
  child: Row(
    children: [
      TpSidebar(child: /* menu */),
      Expanded(child: TpSidebarInset(child: /* main */)),
    ],
  ),
);
```

## Dialogs (`showTpDialog`)

`showTpDialog` presents modal content as a centered card or a full-bleed page on narrow
viewports. Use `TpDialogPresentation.card` (default) for short confirms; use `.page` for
large management surfaces.

- **`TpDialogPresentation.card`** — `showDialog` + caller returns `TpDialog` (or equivalent).
- **`TpDialogPresentation.page`** — below `mobileBreakpoint`, `showGeneralDialog` mounts a
  zero-inset fullscreen `Material` surface; on wide, wraps content in a constrained `TpDialog`.
- **Chrome ownership:** `showTpDialog` does **not** add an app bar. Callers choose:
  - **`TpDialogPageShell`** — simple pages on **narrow and wide**: mobile nav on narrow;
    `TpDialogHeader` + theme content padding on wide. Pass the same `mobileBreakpoint` as
    `showTpDialog`. Use `fillBody: true` when the child uses vertical `Expanded` (lists /
    pinned footers); default shrink-wrap requires an intrinsic-height child
    (`Column(min)`). Do not use an outer `SingleChildScrollView` on wide — it expands
    to `maxHeight`. Scroll on narrow Expanded body, or use `fillBody: true` with an
    inner scroll region.
  - **`TpDialogNavShell`** — dual-pane nav + detail; owns narrow nav/detail bars.
    **Never** wrap `TpDialogNavShell` in `TpDialogPageShell`.

```dart
// Simple page (settings list, editor form, …)
showTpDialog<void>(
  context: context,
  presentation: TpDialogPresentation.page,
  mobileBreakpoint: 840,
  builder: (ctx) => TpDialogPageShell(
    title: 'Automations',
    mobileBreakpoint: 840,
    fillBody: true, // list / Expanded child
    child: AutomationsBody(),
  ),
);

// Dual-pane settings (nav list → detail on narrow)
showTpDialog<void>(
  context: context,
  presentation: TpDialogPresentation.page,
  mobileBreakpoint: 840,
  builder: (ctx) => TpDialogNavShell(
    mobileBreakpoint: 840,
    navTitle: (ctx) => 'Settings',
    entries: [/* TpDialogNavEntry … */],
  ),
);
```

## File selection (`showTpFileSelection`)

Cross-platform file / directory / media picker UI. Host apps wire platform I/O through
**port adapters**; `shared_ui` has **no** hard dependency on `photo_manager`,
`permission_handler`, or `file_picker`.

```dart
final result = await showTpFileSelection(
  context: context,
  deps: TpFileSelectionDeps(
    filesystem: myFilesystemAdapter,
    permission: myPermissionAdapter,
    gallery: myGalleryAdapter, // optional — gallery tab
    desktop: myDesktopPickerAdapter, // optional — native desktop dialog
    preview: myPreviewAdapter, // optional — image/video preview
    strings: myStrings, // app l10n mapped into TpFileSelectionStrings
    isDesktop: () => Platform.isLinux || Platform.isMacOS || Platform.isWindows,
  ),
  options: const TpFileSelectionOptions(
    allowMultiple: true,
    selectionMode: TpSelectionMode.files,
    allowedExtensions: ['pdf', 'png'],
  ),
);
// null = user cancelled; non-null list = confirmed selection
```

**Return type:** `Future<List<TpPickedEntry>?>`. Each `TpPickedEntry` carries `path`,
`kind` (`TpPickedKind.file` / `directory`), and optional `displayName` / `mimeType`.

**`TpFileSelectionDeps` ports**

| Port | Required | Role |
|------|----------|------|
| `TpFilesystemPort` (`filesystem`) | yes | Browse roots, list directories, optional full-disk search (`searchFiles`) |
| `TpPermissionPort` (`permission`) | yes | Storage / gallery permission prompts (`ensureStorageAccess`, `ensureGalleryAccess`) |
| `TpFileSelectionStrings` (`strings`) | yes | All user-visible labels — map from app ARB / l10n |
| `bool Function()` (`isDesktop`) | yes | Desktop vs mobile routing |
| `TpGalleryPort` (`gallery`) | optional | Photo / video gallery tab; omit to hide gallery |
| `TpDesktopPickerPort` (`desktop`) | optional | Native OS picker on desktop; when set and `isDesktop()` is true, `showTpFileSelection` short-circuits to `pickFiles` / `pickDirectory` without pushing the full-page UI |
| `TpMediaPreviewPort` (`preview`) | optional | In-tab image / video preview; omit to disable preview actions |

**Desktop routing:** when `isDesktop()` returns true and `desktop` is non-null, the entry
point delegates to the native picker and never mounts `TpFileSelectionPage`. Mobile (or
desktop without `desktop`) opens the full filesystem / gallery page via `Navigator.push`.

**Tests:** `TpFileSelectionStrings.english()` supplies English placeholders; port fakes
live in `test/components/file_selection/fake_file_selection_ports.dart`.

Sources: `lib/src/components/file_selection/` (ports, models, `show_tp_file_selection.dart`,
`TpFileSelectionPage`, tabs).

## Layout

- `lib/src/components/` — `Tp*` widgets by category (including `file_selection/`)
- `lib/src/deferred/` — progressive mount / keep-alive primitives
- `lib/src/theme/` — `TpTheme` / `TpThemeData`, tokens, component themes
- `lib/src/toast/engine/` — private toast overlay engine (not public API)
- `lib/shared_ui.dart` — public barrel export
