import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app_language.dart';
import 'bn_strings.dart';

/// Translates an English UI string. Returns it unchanged when the app is in English
/// or when no translation exists (nothing breaks if a string is missing).
String tr(String s) {
  if (appLang != 'bn') return s;
  return localizeDigits(translateBn(s));
}

const _bnMonths = {
  'Jan': 'জানু', 'Feb': 'ফেব্রু', 'Mar': 'মার্চ', 'Apr': 'এপ্রিল',
  'May': 'মে', 'Jun': 'জুন', 'Jul': 'জুলাই', 'Aug': 'আগস্ট',
  'Sep': 'সেপ্টেম্বর', 'Oct': 'অক্টোবর', 'Nov': 'নভেম্বর', 'Dec': 'ডিসেম্বর',
};

/// 0-9 -> ০-৯, except inside IDs like TX1001 (digits right after a letter).
String localizeDigits(String s) => s.replaceAllMapped(
      RegExp(r'(?<![A-Za-z\d])\d+'),
      (m) => String.fromCharCodes(
        m[0]!.codeUnits.map((c) => 0x09E6 + (c - 0x30)),
      ),
    );

String translateBn(String s) {
  final core = s.trim();
  if (core.isEmpty) return s;
  final start = s.indexOf(core);
  final prefix = s.substring(0, start);
  final suffix = s.substring(start + core.length);
  return '$prefix${_core(core)}$suffix';
}

String _t(String s) => translateBn(s);

final _rules = <(RegExp, String Function(Match m))>[
  (
    RegExp(r'^(\d{2}) (Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec) (\d{4}), (\d{2}):(\d{2}) (AM|PM)$'),
    (m) =>
        '${m[1]} ${_bnMonths[m[2]]} ${m[3]}, ${m[4]}:${m[5]} ${m[6] == 'AM' ? 'এএম' : 'পিএম'}',
  ),
  (RegExp(r'^(\d+) transactions?$'), (m) => '${m[1]} টি লেনদেন'),
  (RegExp(r'^Sent to (.+)$'), (m) => '${m[1]} নম্বরে পাঠানো হয়েছে'),
  (RegExp(r'^Received from (.+)$'), (m) => '${m[1]} থেকে পাওয়া'),
  (RegExp(r'^Added from (.+)$'), (m) => '${_t(m[1]!)} থেকে যোগ করা হয়েছে'),
  (RegExp(r'^Cash out to agent (.+)$'), (m) => 'এজেন্ট ${m[1]}-এ ক্যাশ আউট'),
  (RegExp(r'^Recharge (\d+) \((.+)\)$'), (m) => 'রিচার্জ ${m[1]} (${_t(m[2]!)})'),
  (RegExp(r'^Recharge (.+)$'), (m) => 'রিচার্জ ${m[1]}'),
  (RegExp(r'^Donation: (.+)$'), (m) => 'অনুদান: ${_t(m[1]!)}'),
  (RegExp(r'^Education fee (.+)$'), (m) => 'শিক্ষা ফি ${m[1]}'),
  (RegExp(r'^(.+) fee (\S+)$'), (m) => '${_t(m[1]!)} ফি ${m[2]}'),
  (RegExp(r'^Bill (.+)$'), (m) => 'বিল ${m[1]}'),
  (RegExp(r'^(.+) bill (\S+)$'), (m) => '${_t(m[1]!)} বিল ${m[2]}'),
  (RegExp(r'^Saved (.+) of (.+)$'), (m) => '${m[1]} জমা, লক্ষ্য ${m[2]}'),
  (RegExp(r'^Saved to (.+)$'), (m) => '${m[1]} লক্ষ্যে সঞ্চয়'),
  (RegExp(r'^Withdrawn from (.+)$'), (m) => '${m[1]} থেকে উত্তোলন'),
  (RegExp(r'^(৳ [\d,.]+) of (৳ [\d,.]+)$'), (m) => '${m[1]} / ${m[2]}'),
  (RegExp(r'^Available balance: (.+)$'), (m) => 'উপলব্ধ ব্যালেন্স: ${m[1]}'),
  (RegExp(r'^Hi, (.+)$'), (m) => 'হ্যালো, ${m[1]}'),
  (RegExp(r'^Resend code in (\d+)s$'), (m) => '${m[1]} সেকেন্ড পর আবার কোড পাঠান'),
  (RegExp(r'^Enter the 6-digit code sent to (.+)$'),
      (m) => '${m[1]} নম্বরে পাঠানো 6 সংখ্যার কোডটি লিখুন'),
  (RegExp(r'^Number verified: (.+)$'), (m) => 'নম্বর যাচাই হয়েছে: ${m[1]}'),
  (
    RegExp(r'^There is no PayBD account for (.+) on this device\. Create one in a minute\.$'),
    (m) => 'এই ডিভাইসে ${m[1]} নম্বরের কোনো PayBD অ্যাকাউন্ট নেই। এক মিনিটেই একটি খুলুন।',
  ),
  (RegExp(r'^Too many wrong attempts\. Try again in (\d+) min\.$'),
      (m) => 'অনেকবার ভুল হয়েছে। ${m[1]} মিনিট পর আবার চেষ্টা করুন।'),
  (RegExp(r'^Wrong PIN\. (\d+) attempts left\.$'),
      (m) => 'ভুল পিন। আর ${m[1]} বার চেষ্টা করা যাবে।'),
  (RegExp(r'^Minimum amount is (.+)\.$'), (m) => 'সর্বনিম্ন পরিমাণ ${m[1]}।'),
  (RegExp(r'^Maximum per transaction is (.+)\.$'),
      (m) => 'প্রতি লেনদেনে সর্বোচ্চ ${m[1]}।'),
  (RegExp(r'^Amount must be (.+) to (.+)\.$'),
      (m) => 'পরিমাণ ${m[1]} থেকে ${m[2]}-এর মধ্যে হতে হবে।'),
  (RegExp(r'^Insufficient balance \(including (.+) fee\)\.$'),
      (m) => 'ব্যালেন্স যথেষ্ট নয় (${m[1]} ফি সহ)।'),
  (RegExp(r'^Request (৳ .+)$'), (m) => 'চাওয়া হচ্ছে ${m[1]}'),
  (RegExp(r'^(.+?): (৳ [\d,.]+)(.*)$'), (m) => '${_t(m[1]!)}: ${m[2]}${m[3]}'),
];

String _core(String c) {
  final exact = bnStrings[c];
  if (exact != null) return exact;
  for (final (re, build) in _rules) {
    final m = re.firstMatch(c);
    if (m != null) return build(m);
  }
  // Paragraphs made of several known sentences.
  final parts = c.split(RegExp(r'(?<=[.!?])\s+'));
  if (parts.length > 1) {
    var any = false;
    final out = <String>[];
    for (final p in parts) {
      final t = bnStrings[p];
      if (t != null) any = true;
      out.add(t ?? p);
    }
    if (any) return out.join(' ');
  }
  return c;
}

/// Drop-in replacement for Text() that translates (and re-translates when the language changes).
class Tr extends ConsumerWidget {
  final String data;
  final TextStyle? style;
  final TextAlign? textAlign;
  final int? maxLines;
  final TextOverflow? overflow;
  final bool? softWrap;

  const Tr(
    this.data, {
    super.key,
    this.style,
    this.textAlign,
    this.maxLines,
    this.overflow,
    this.softWrap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(languageProvider);
    return Text(
      tr(data),
      style: style,
      textAlign: textAlign,
      maxLines: maxLines,
      overflow: overflow,
      softWrap: softWrap,
    );
  }
}
