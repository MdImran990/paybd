import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../storage/prefs.dart';

/// Current language code ('en' or 'bn'). Read by tr(); kept in sync by languageProvider.
String appLang = 'en';

/// Call once in main() before runApp so the very first screen is already translated.
void initLanguage(SharedPreferences prefs) {
  appLang = prefs.getString('language') ?? 'en';
}

class LanguageNotifier extends Notifier<String> {
  @override
  String build() => appLang;

  void set(String code) {
    appLang = code;
    state = code;
    ref.read(sharedPreferencesProvider).setString('language', code);
  }
}

final languageProvider =
    NotifierProvider<LanguageNotifier, String>(LanguageNotifier.new);
