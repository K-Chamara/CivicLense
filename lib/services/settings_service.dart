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
  
  // Available currencies
  static const Map<String, String> currencies = {
    'USD': 'USD (\$)',
    'LKR': 'LKR (₨)',
  };
  
  // Currency exchange rates (base: USD)
  static const Map<String, double> exchangeRates = {
    'USD': 1.0,
    'LKR': 320.0, // Approximate rate
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

  /// Get currency symbol
  static String getCurrencySymbol(String currency) {
    switch (currency) {
      case 'USD':
        return '\$';
      case 'LKR':
        return '₨';
      default:
        return '₨';
    }
  }

  /// Format amount based on current currency
  static Future<String> formatAmount(double amount) async {
    final currency = await getCurrency();
    final symbol = getCurrencySymbol(currency);
    
    if (currency == 'USD') {
      // Convert LKR to USD if needed
      if (amount > 1000) {
        amount = amount / exchangeRates['LKR']!;
      }
      return '$symbol${amount.toStringAsFixed(2)}';
    } else {
      // Keep as LKR
      if (amount < 1000) {
        amount = amount * exchangeRates['LKR']!;
      }
      if (amount >= 1000000) {
        return '$symbol ${(amount / 1000000).toStringAsFixed(1)}M';
      } else if (amount >= 1000) {
        return '$symbol ${(amount / 1000).toStringAsFixed(1)}K';
      } else {
        return '$symbol ${amount.toStringAsFixed(0)}';
      }
    }
  }

  /// Convert amount between currencies
  static double convertAmount(double amount, String fromCurrency, String toCurrency) {
    if (fromCurrency == toCurrency) return amount;
    
    // Convert to USD first
    double usdAmount = amount / exchangeRates[fromCurrency]!;
    
    // Convert to target currency
    return usdAmount * exchangeRates[toCurrency]!;
  }

  /// Reset to default settings
  static Future<void> resetToDefaults() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_languageKey);
    await prefs.remove(_currencyKey);
  }
}
