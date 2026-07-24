import 'package:flutter/services.dart';

class TpTokenRange {
  const TpTokenRange({required this.start, required this.end});

  final int start;
  final int end;
}

Iterable<TpTokenRange> tpTokenRanges(String text, RegExp pattern) sync* {
  for (final match in pattern.allMatches(text)) {
    yield TpTokenRange(start: match.start, end: match.end);
  }
}

TpTokenRange? tpTokenRangeForBackspace(
  String text,
  int offset,
  RegExp pattern,
) {
  for (final token in tpTokenRanges(text, pattern)) {
    if (offset > token.start && offset <= token.end) {
      return token;
    }
  }
  return null;
}

TpTokenRange? tpTokenRangeForDelete(
  String text,
  int offset,
  RegExp pattern,
) {
  for (final token in tpTokenRanges(text, pattern)) {
    if (offset >= token.start && offset < token.end) {
      return token;
    }
  }
  return null;
}

TextRange expandRangeToTpTokens({
  required String text,
  required int start,
  required int end,
  required RegExp pattern,
}) {
  var expandedStart = start;
  var expandedEnd = end;
  for (final token in tpTokenRanges(text, pattern)) {
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
  RegExp pattern,
) {
  final selection = value.selection;
  if (!selection.isValid) return null;

  if (!selection.isCollapsed) {
    final expanded = expandRangeToTpTokens(
      text: value.text,
      start: selection.start,
      end: selection.end,
      pattern: pattern,
    );
    if (expanded.start == selection.start && expanded.end == selection.end) {
      return null;
    }
    return TextSelection(
      baseOffset: expanded.start,
      extentOffset: expanded.end,
    );
  }

  final token = tpTokenRangeForBackspace(
    value.text,
    selection.extentOffset,
    pattern,
  );
  if (token == null) return null;
  return TextSelection(baseOffset: token.start, extentOffset: token.end);
}

/// Selection [EditableText] should delete for a Delete that hits a token.
TextSelection? tpTokenSelectionForDelete(
  TextEditingValue value,
  RegExp pattern,
) {
  final selection = value.selection;
  if (!selection.isValid) return null;

  if (!selection.isCollapsed) {
    final expanded = expandRangeToTpTokens(
      text: value.text,
      start: selection.start,
      end: selection.end,
      pattern: pattern,
    );
    if (expanded.start == selection.start && expanded.end == selection.end) {
      return null;
    }
    return TextSelection(
      baseOffset: expanded.start,
      extentOffset: expanded.end,
    );
  }

  final token = tpTokenRangeForDelete(
    value.text,
    selection.extentOffset,
    pattern,
  );
  if (token == null) return null;
  return TextSelection(baseOffset: token.start, extentOffset: token.end);
}

TextEditingValue? applyTpTokenBackspace(
  TextEditingValue value,
  RegExp pattern,
) {
  final selected = tpTokenSelectionForBackspace(value, pattern);
  if (selected == null) return null;
  return value.copyWith(
    text: value.text.replaceRange(selected.start, selected.end, ''),
    selection: TextSelection.collapsed(offset: selected.start),
    composing: TextRange.empty,
  );
}

TextEditingValue? applyTpTokenDelete(
  TextEditingValue value,
  RegExp pattern,
) {
  final selected = tpTokenSelectionForDelete(value, pattern);
  if (selected == null) return null;
  return value.copyWith(
    text: value.text.replaceRange(selected.start, selected.end, ''),
    selection: TextSelection.collapsed(offset: selected.start),
    composing: TextRange.empty,
  );
}
