import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:paybd/core/utils/numeric_input.dart';

void main() {
  test('digits are added and removed, up to the maximum length', () {
    final c = TextEditingController();
    for (final k in '0171234567'.split('')) {
      applyKey(c, k, maxLength: 11);
    }
    expect(c.text, '0171234567');
    expect(applyKey(c, '8', maxLength: 11), isTrue);
    expect(applyKey(c, '9', maxLength: 11), isFalse); // already 11
    expect(c.text, '01712345678');
    applyKey(c, 'back');
    expect(c.text, '0171234567');
    applyKey(c, 'clear');
    expect(c.text, '');
  });

  test('amounts: one dot, two decimals, no leading zero', () {
    final c = TextEditingController();
    applyKey(c, '0', decimal: true);
    applyKey(c, '5', decimal: true);
    expect(c.text, '5'); // not 05
    applyKey(c, '.', decimal: true);
    applyKey(c, '.', decimal: true);
    expect(c.text, '5.');
    applyKey(c, '2', decimal: true);
    applyKey(c, '5', decimal: true);
    expect(applyKey(c, '9', decimal: true), isFalse); // third decimal
    expect(c.text, '5.25');
  });

  test('a lone dot becomes 0.', () {
    final c = TextEditingController();
    applyKey(c, '.', decimal: true);
    expect(c.text, '0.');
  });

  test('the dot is ignored for non-decimal fields', () {
    final c = TextEditingController();
    expect(applyKey(c, '.'), isFalse);
  });
}
