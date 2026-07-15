# shared_ui

TeamPilot **Tp** design system — reusable Flutter UI primitives (`Tp*`) and theme tokens.

## Wiring (TeamPilot)

Wrap the app with `TpTheme` so components resolve spacing, typography, and control metrics from `TpThemeData`:

```dart
import 'package:shared_ui/shared_ui.dart';

MaterialApp(
  builder: (context, child) {
    return TpTheme(
      data: TpThemeData.fromColorScheme(
        Theme.of(context).colorScheme,
        scale: 1.0,
      ),
      child: child ?? const SizedBox.shrink(),
    );
  },
);
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
| **Select** | `TpSelect`, `TpSelectWithCustomInput`, search / filter helpers |
| **Dialog** | `TpDialog` |
| **Form** | `TpForm`, `TpFormField`, `TpFormFieldLayout`, `TpFormMap` |
| **Overlay** | `TpPopover`, `TpTooltip` |
| **Layout / chrome** | `TpCard`, `TpSeparator`, `TpSegmentedControl`, `TpEmptyState`, `TpHover` / `TpHoverRow` |
| **Theme** | `TpTheme`, `TpThemeData`, spacing / typography / control metric tokens, per-component themes |

## Layout

- `lib/src/components/` — `Tp*` widgets by category
- `lib/src/theme/` — `TpTheme` / `TpThemeData`, tokens, component themes
- `lib/shared_ui.dart` — public barrel export
