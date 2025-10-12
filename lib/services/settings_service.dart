import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';

class SettingsService {
  static const String _languageKey = 'language';
  static const String _currencyKey = 'currency';
  
  static const String _defaultLanguage = 'en';
  static const String _defaultCurrency = 'LKR';
  
  // Available languages
  static const Map<String, String> languages = {
    'en': 'English',
    'si': 'සිංහල',
    'ta': 'தமிழ்',
  };
  
  // Available currencies (LKR only for Sri Lankan context)
  static const Map<String, String> currencies = {
    'LKR': 'LKR (₨)',
  };

  /// Get current language
  static Future<String> getLanguage() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_languageKey) ?? _defaultLanguage;
  }

  /// Get current locale
  static Future<Locale?> getLocale() async {
    final language = await getLanguage();
    return Locale(language, '');
  }

  /// Set language
  static Future<void> setLanguage(String language) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_languageKey, language);
  }

  /// Get current currency
  static Future<String> getCurrency() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_currencyKey) ?? _defaultCurrency;
  }

  /// Set currency
  static Future<void> setCurrency(String currency) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_currencyKey, currency);
  }

  /// Get currency symbol (LKR only)
  static String getCurrencySymbol(String currency) {
    return '₨'; // Always LKR for Sri Lankan context
  }

  /// Format amount in LKR
  static Future<String> formatAmount(double amount) async {
    const symbol = '₨';
    
    if (amount >= 1000000000) {
      return '$symbol${(amount / 1000000000).toStringAsFixed(1)}B';
    } else if (amount >= 1000000) {
      return '$symbol${(amount / 1000000).toStringAsFixed(1)}M';
    } else if (amount >= 1000) {
      return '$symbol${(amount / 1000).toStringAsFixed(1)}K';
    } else {
      return '$symbol${amount.toStringAsFixed(0)}';
    }
  }

  /// Reset to default settings
  static Future<void> resetToDefaults() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_languageKey);
    await prefs.remove(_currencyKey);
  }
}
