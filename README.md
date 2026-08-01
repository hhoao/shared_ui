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
| **Combobox** | `TpCombobox`, `TpSuggestionList` |
| **Dialog** | `TpDialog` |
| **Form** | `TpForm`, `TpFormField`, `TpFormFieldLayout`, `TpFormMap` |
| **Overlay** | `TpPopover`, `TpTooltip`, `TpActionMenu` / `TpActionMenuPanel`, `TpActionMenuShortcut` (Context Menu) |
| **Date range** | `TpDateRangePicker`, `TpRangeCalendar`, calendar date utils |
| **Toast** | `TpToast`, `TpToastWrapper`, `TpToastConfig`, `TpToastTheme`, `TpToastVariant`, `TpToastAction` |
| **Layout / chrome** | `TpCard`, `TpCardHeader`, `TpActionRow`, `TpSeparator`, `TpSegmentedControl`, `TpSegmentedPicker`, `TpEmptyState`, `TpHover` / `TpHoverRow` (click cursor, hover fill, optional press scale — prefer over bare `GestureDetector` for onTap UI), `TpSidebar*` (see below) |
| **Preference** | `TpPreferenceRow`, `TpPreferenceStack`, `TpSectionHeader`, `TpDisclosure`, `TpStatusBadge`, `TpCompactSelect` |
| **File selection** | `showTpFileSelection`, `TpFileSelectionDeps`, `TpFileSelectionOptions`, `TpPickedEntry`, port adapters (`TpFilesystemPort`, `TpGalleryPort`, …) |
| **Theme** | `TpTheme`, `TpThemeData`, `TpTextStyles`, `TpFontTheme`, `TpGlyphWarmup`, icon sizes (`sm`/`md`/`lg`/`hero`), spacing / typography / control metrics, per-component themes |

Toast engine sources live under `lib/src/toast/engine/` and are **not** barrel-exported.

## Combobox vs Select

- `TpSelect` — closed header + chevron; optional search inside the overlay.
- `TpCombobox` — editable input; typing filters suggestions (shadcn Combobox).

## Context Menu → TpActionMenu

| shadcn | Tp |
|--------|-----|
| ContextMenu + Trigger + Content | `TpActionMenu*` / `showTpActionMenu*` |
| ContextMenuItem | `TpActionMenuItem` / `TpActionMenuSpec.item` |
| ContextMenuSeparator | `TpActionMenuDivider` |
| Destructive | `destructive: true` |
| Checkbox / selected | `selected: true` (+ trailing check) |
| Shortcut | `TpActionMenuShortcut` or custom `trailing` |
| Submenu / Radio | Not yet — extend `TpActionMenu` when needed |

Use `showTpActionMenuFromSpecsAtTap` + `contextMenuGlobalPosition` for pointer-anchored menus.

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
- `lib/src/deferred/` — progressive mount / keep-alive primitives (if present)
- `lib/src/theme/` — `TpTheme` / `TpThemeData`, tokens, component themes
- `lib/src/toast/engine/` — private toast overlay engine (not public API)
- `lib/shared_ui.dart` — public barrel export
