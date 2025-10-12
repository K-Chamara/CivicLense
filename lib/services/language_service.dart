import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Service to manage app language/locale changes
class LanguageService extends ChangeNotifier {
  static const String _languageKeyPrefix = 'selected_language_';
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
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
  
  /// Get user-specific language key
  String _getUserLanguageKey() {
    final userId = _auth.currentUser?.uid ?? 'guest';
    return '$_languageKeyPrefix$userId';
  }
  
  /// Load saved language from preferences (user-specific)
  Future<void> _loadSavedLanguage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final languageKey = _getUserLanguageKey();
      final languageCode = prefs.getString(languageKey);
      
      if (languageCode != null) {
        // Find the locale by language code
        final locale = availableLanguages.values.firstWhere(
          (locale) => locale.languageCode == languageCode,
          orElse: () => const Locale('en', 'US'),
        );
        _currentLocale = locale;
        print('🌍 Loaded language for user: ${_auth.currentUser?.uid ?? "guest"} -> $languageCode');
      } else {
        // Default to English if no language is saved for this user
        _currentLocale = const Locale('en', 'US');
        print('🌍 No saved language for user: ${_auth.currentUser?.uid ?? "guest"}, defaulting to English');
      }
    } catch (e) {
      print('Error loading saved language: $e');
      _currentLocale = const Locale('en', 'US');
    }
  }
  
  /// Change app language (user-specific)
  Future<void> changeLanguage(Locale locale) async {
    try {
      _currentLocale = locale;
      await _saveLanguage(locale.languageCode);
      notifyListeners();
      print('🌍 Language changed to: ${locale.languageCode} for user: ${_auth.currentUser?.uid ?? "guest"}');
    } catch (e) {
      print('Error changing language: $e');
    }
  }
  
  /// Save language to preferences (user-specific)
  Future<void> _saveLanguage(String languageCode) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final languageKey = _getUserLanguageKey();
      await prefs.setString(languageKey, languageCode);
      print('🌍 Saved language: $languageCode for user: ${_auth.currentUser?.uid ?? "guest"}');
    } catch (e) {
      print('Error saving language: $e');
    }
  }
  
  /// Reset language to English (call this on logout)
  Future<void> resetToEnglish() async {
    try {
      _currentLocale = const Locale('en', 'US');
      notifyListeners();
      print('🌍 Language reset to English on logout');
    } catch (e) {
      print('Error resetting language: $e');
    }
  }
  
  /// Reload language for new user (call this after login)
  Future<void> reloadForUser() async {
    await _loadSavedLanguage();
    notifyListeners();
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
