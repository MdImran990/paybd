import 'package:flutter_test/flutter_test.dart';
import 'package:paybd/core/i18n/app_language.dart';
import 'package:paybd/core/i18n/tr.dart';

void main() {
  tearDown(() => appLang = 'en');

  test('English text is unchanged', () {
    appLang = 'en';
    expect(tr('Send Money'), 'Send Money');
  });

  test('Bangla exact translations', () {
    appLang = 'bn';
    expect(tr('Send Money'), 'সেন্ড মানি');
    expect(tr('Cancel'), 'বাতিল');
  });

  test('unknown text stays English', () {
    appLang = 'bn';
    expect(tr('Totally unknown text'), 'Totally unknown text');
  });

  test('digits become Bangla digits, IDs stay', () {
    appLang = 'bn';
    expect(tr('৳ 16,003.00'), '৳ ১৬,০০৩.০০');
    expect(tr('TX1001'), 'TX1001');
    expect(tr('5'), '৫');
  });

  test('sentences with values', () {
    appLang = 'bn';
    expect(tr('Wrong PIN. 4 attempts left.'), 'ভুল পিন। আর ৪ বার চেষ্টা করা যাবে।');
    expect(tr('Sent to 01712345678'), '০১৭১২৩৪৫৬৭৮ নম্বরে পাঠানো হয়েছে');
  });

  test('dates', () {
    appLang = 'bn';
    expect(tr('04 Oct 2026, 12:41 PM'), '০৪ অক্টোবর ২০২৬, ১২:৪১ পিএম');
  });

  test('paragraph made of known sentences', () {
    appLang = 'bn';
    expect(
      tr('No. This is a demo build. Balances and transactions are for testing only. '
          'Real money services will be added after the required approvals.'),
      'না। এটি একটি ডেমো সংস্করণ। ব্যালেন্স ও লেনদেন শুধু পরীক্ষার জন্য। প্রয়োজনীয় অনুমোদনের পর আসল টাকার সেবা যুক্ত করা হবে।',
    );
  });
}
