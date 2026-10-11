import 'package:flutter/widgets.dart';

/// Applies one key of the on-screen keypad to a text field's controller.
/// Keys: '0'-'9', '.', 'back', 'clear'. Returns true when the text changed.
bool applyKey(
  TextEditingController c,
  String key, {
  int maxLength = 20,
  bool decimal = false,
  int maxInt = 5,
  int maxDecimals = 2,
}) {
  var t = c.text;
  switch (key) {
    case 'back':
      if (t.isEmpty) return false;
      t = t.substring(0, t.length - 1);
    case 'clear':
      if (t.isEmpty) return false;
      t = '';
    case '.':
      if (!decimal || t.contains('.')) return false;
      t = t.isEmpty ? '0.' : '$t.';
    default:
      if (!RegExp(r'^\d$').hasMatch(key)) return false;
      if (decimal) {
        final dot = t.indexOf('.');
        if (dot == -1) {
          if (t.length >= maxInt) return false;
          if (t == '0') t = ''; // no leading zero (05)
          t += key;
        } else {
          if (t.length - dot - 1 >= maxDecimals) return false;
          t += key;
        }
      } else {
        if (t.length >= maxLength) return false;
        t += key;
      }
  }
  c.value = TextEditingValue(
    text: t,
    selection: TextSelection.collapsed(offset: t.length),
  );
  return true;
}
