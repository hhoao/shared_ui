import 'package:flutter/services.dart';

class TpTokenRange {
  const TpTokenRange({required this.start, required this.end});

  final int start;
  final int end;

  @override
  bool operator ==(Object other) =>
      other is TpTokenRange && other.start == start && other.end == end;

  @override
  int get hashCode => Object.hash(start, end);

  @override
  String toString() => 'TpTokenRange($start, $end)';
}

/// Legacy helper: ranges matched by [pattern]. Runtime compose tokens are
/// explicit ranges; this stays for pattern-driven callers and tests.
Iterable<TpTokenRange> tpTokenRanges(String text, RegExp pattern) sync* {
  for (final match in pattern.allMatches(text)) {
    yield TpTokenRange(start: match.start, end: match.end);
  }
}

TpTokenRange? tpTokenRangeStartingAt(
  Iterable<TpTokenRange> tokenRanges,
  int offset,
) {
  for (final token in tokenRanges) {
    if (token.start == offset && token.end > token.start) return token;
  }
  return null;
}

TpTokenRange? tpTokenRangeEndingAt(
  Iterable<TpTokenRange> tokenRanges,
  int offset,
) {
  for (final token in tokenRanges) {
    if (token.end == offset && token.end > token.start) return token;
  }
  return null;
}

TpTokenRange? tpTokenRangeForBackspace(
  Iterable<TpTokenRange> tokenRanges,
  int offset,
) {
  for (final token in tokenRanges) {
    if (offset > token.start && offset <= token.end) {
      return token;
    }
  }
  return null;
}

TpTokenRange? tpTokenRangeForDelete(
  Iterable<TpTokenRange> tokenRanges,
  int offset,
) {
  for (final token in tokenRanges) {
    if (offset >= token.start && offset < token.end) {
      return token;
    }
  }
  return null;
}

TextRange expandRangeToTpTokens({
  required int start,
  required int end,
  required Iterable<TpTokenRange> tokenRanges,
}) {
  var expandedStart = start;
  var expandedEnd = end;
  for (final token in tokenRanges) {
    if (token.end <= expandedStart || token.start >= expandedEnd) {
      continue;
    }
    if (token.start < expandedStart) expandedStart = token.start;
    if (token.end > expandedEnd) expandedEnd = token.end;
  }
  return TextRange(start: expandedStart, end: expandedEnd);
}

/// Selection [EditableText] should delete for a Backspace that hits a token.
///
/// Returns null when the key should fall through without adjusting selection
/// (plain character delete, or the selection already covers whole tokens).
TextSelection? tpTokenSelectionForBackspace(
  TextEditingValue value,
  Iterable<TpTokenRange> tokenRanges,
) {
  final ranges = tokenRanges.toList(growable: false);
  final selection = value.selection;
  if (!selection.isValid) return null;

  if (!selection.isCollapsed) {
    final expanded = expandRangeToTpTokens(
      start: selection.start,
      end: selection.end,
      tokenRanges: ranges,
    );
    if (expanded.start == selection.start && expanded.end == selection.end) {
      return null;
    }
    return TextSelection(
      baseOffset: expanded.start,
      extentOffset: expanded.end,
    );
  }

  final token = tpTokenRangeForBackspace(ranges, selection.extentOffset);
  if (token == null) return null;
  return TextSelection(baseOffset: token.start, extentOffset: token.end);
}

/// Selection [EditableText] should delete for a Delete that hits a token.
TextSelection? tpTokenSelectionForDelete(
  TextEditingValue value,
  Iterable<TpTokenRange> tokenRanges,
) {
  final ranges = tokenRanges.toList(growable: false);
  final selection = value.selection;
  if (!selection.isValid) return null;

  if (!selection.isCollapsed) {
    final expanded = expandRangeToTpTokens(
      start: selection.start,
      end: selection.end,
      tokenRanges: ranges,
    );
    if (expanded.start == selection.start && expanded.end == selection.end) {
      return null;
    }
    return TextSelection(
      baseOffset: expanded.start,
      extentOffset: expanded.end,
    );
  }

  final token = tpTokenRangeForDelete(ranges, selection.extentOffset);
  if (token == null) return null;
  return TextSelection(baseOffset: token.start, extentOffset: token.end);
}

TextEditingValue? applyTpTokenBackspace(
  TextEditingValue value,
  Iterable<TpTokenRange> tokenRanges,
) {
  final selected = tpTokenSelectionForBackspace(value, tokenRanges);
  if (selected == null) return null;
  return value.copyWith(
    text: value.text.replaceRange(selected.start, selected.end, ''),
    selection: TextSelection.collapsed(offset: selected.start),
    composing: TextRange.empty,
  );
}

TextEditingValue? applyTpTokenDelete(
  TextEditingValue value,
  Iterable<TpTokenRange> tokenRanges,
) {
  final selected = tpTokenSelectionForDelete(value, tokenRanges);
  if (selected == null) return null;
  return value.copyWith(
    text: value.text.replaceRange(selected.start, selected.end, ''),
    selection: TextSelection.collapsed(offset: selected.start),
    composing: TextRange.empty,
  );
}
