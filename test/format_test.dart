import 'package:flutter_test/flutter_test.dart';
import 'package:paybd/core/utils/format.dart';
import 'package:paybd/core/utils/validators.dart';

void main() {
  group('formatTaka', () {
    test('formats paisa with Bangladeshi grouping', () {
      expect(formatTaka(1600300), '৳ 16,003.00');
      expect(formatTaka(160000000), '৳ 16,00,000.00');
      expect(formatTaka(5), '৳ 0.05');
    });
  });

  group('parseTakaToMinor', () {
    test('parses valid amounts', () {
      expect(parseTakaToMinor('125.5'), 12550);
      expect(parseTakaToMinor('500'), 50000);
      expect(parseTakaToMinor('0.05'), 5);
    });

    test('rejects invalid amounts', () {
      expect(parseTakaToMinor('abc'), isNull);
      expect(parseTakaToMinor('1.234'), isNull);
      expect(parseTakaToMinor(''), isNull);
    });
  });

  group('validators', () {
    test('BD phone numbers', () {
      expect(bdPhoneRegExp.hasMatch('01712345678'), isTrue);
      expect(bdPhoneRegExp.hasMatch('01212345678'), isFalse);
      expect(bdPhoneRegExp.hasMatch('1712345678'), isFalse);
    });

    test('weak PINs', () {
      expect(isWeakPin('11111'), isTrue);
      expect(isWeakPin('12345'), isTrue);
      expect(isWeakPin('54321'), isTrue);
      expect(isWeakPin('13579'), isFalse);
    });
  });
}
