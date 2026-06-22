# shared_ui

Shared Flutter UI infrastructure extracted from Teampilot for use by **huji** and (future) **teampilot**.

## Contents

- `theme/` — AppTheme, typography, spacing, color presets
- `shell/` — WorkspacePageCardShell, surface layers
- `preferences/` — AppearanceCubit (theme, locale, zoom)
- `l10n/` — generic UI strings (window chrome, theme labels)
- `widgets/` — desktop chrome, dialogs, controls

## Usage

```yaml
dependencies:
  shared_ui:
    path: ../../shared_ui
```

```dart
import 'package:shared_ui/shared_ui.dart';
```
