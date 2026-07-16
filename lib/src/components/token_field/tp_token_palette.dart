import 'package:flutter/material.dart';

/// Background and foreground colors for one inline token chip.
typedef TpTokenPalette = ({Color background, Color foreground});

/// Resolves chip colors for a matched [token] string.
typedef TpTokenPaletteResolver =
    TpTokenPalette Function(String token, ColorScheme colorScheme);
