import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../features/auth/domain/auth_models.dart';

class LanguageController extends ChangeNotifier {
  static const String _key = 'app_locale_code';
  AppLocale _locale = AppLocale.vi;

  AppLocale get locale => _locale;
  bool get isEnglish => _locale == AppLocale.en;
  bool get isVietnamese => _locale == AppLocale.vi;

  LanguageController() {
    _loadFromPrefs();
  }

  Future<void> _loadFromPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final code = prefs.getString(_key);
      if (code == 'en') {
        _locale = AppLocale.en;
        notifyListeners();
      } else if (code == 'vi') {
        _locale = AppLocale.vi;
        notifyListeners();
      }
    } catch (_) {}
  }

  Future<void> setLocale(AppLocale newLocale) async {
    if (_locale == newLocale) return;
    _locale = newLocale;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_key, newLocale == AppLocale.en ? 'en' : 'vi');
    } catch (_) {}
  }

  void toggleLanguage() {
    setLocale(_locale == AppLocale.vi ? AppLocale.en : AppLocale.vi);
  }
}
