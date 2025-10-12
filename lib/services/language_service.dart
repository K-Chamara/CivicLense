import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Service to manage app language/locale changes
class LanguageService extends ChangeNotifier {
  static const String _languageKey = 'selected_language';
  
  Locale _currentLocale = const Locale('en', 'US');
  
  Locale get currentLocale => _currentLocale;
  
  /// Available languages
  static const Map<String, Locale> availableLanguages = {
    'English': Locale('en', 'US'),
    'සිංහල': Locale('si', 'LK'),
    'தமிழ்': Locale('ta', 'LK'),
  };
  
  /// Initialize language service
  Future<void> initialize() async {
    await _loadSavedLanguage();
  }
  
  /// Load saved language from preferences
  Future<void> _loadSavedLanguage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final languageCode = prefs.getString(_languageKey);
      
      if (languageCode != null) {
        // Find the locale by language code
        final locale = availableLanguages.values.firstWhere(
          (locale) => locale.languageCode == languageCode,
          orElse: () => const Locale('en', 'US'),
        );
        _currentLocale = locale;
      }
    } catch (e) {
      print('Error loading saved language: $e');
    }
  }
  
  /// Change app language
  Future<void> changeLanguage(Locale locale) async {
    try {
      _currentLocale = locale;
      await _saveLanguage(locale.languageCode);
      notifyListeners();
      print('🌍 Language changed to: ${locale.languageCode}');
    } catch (e) {
      print('Error changing language: $e');
    }
  }
  
  /// Save language to preferences
  Future<void> _saveLanguage(String languageCode) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_languageKey, languageCode);
    } catch (e) {
      print('Error saving language: $e');
    }
  }
  
  /// Get language display name for current locale
  String getCurrentLanguageName() {
    return availableLanguages.entries
        .firstWhere(
          (entry) => entry.value.languageCode == _currentLocale.languageCode,
          orElse: () => const MapEntry('English', Locale('en', 'US')),
        )
        .key;
  }
  
  /// Check if current language is Sinhala
  bool get isSinhala => _currentLocale.languageCode == 'si';
  
  /// Check if current language is Tamil
  bool get isTamil => _currentLocale.languageCode == 'ta';
  
  /// Check if current language is English
  bool get isEnglish => _currentLocale.languageCode == 'en';
}
