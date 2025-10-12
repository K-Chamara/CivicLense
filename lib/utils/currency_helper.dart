import 'package:intl/intl.dart';

/// Helper class for LKR currency formatting (Sri Lankan context)
class CurrencyHelper {
  /// Format amount in LKR with compact notation (K, M, B)
  static String formatAmount(double amount) {
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

  /// Format amount with full number (no compact notation)
  static String formatAmountFull(double amount) {
    const symbol = '₨';
    return '$symbol${NumberFormat('#,##,##,##0').format(amount)}';
  }

  /// Format amount with decimal places
  static String formatAmountWithDecimals(double amount, {int decimals = 2}) {
    const symbol = '₨';
    return '$symbol${NumberFormat('#,##,##,##0.${'0' * decimals}').format(amount)}';
  }

  /// Get LKR currency symbol
  static String getSymbol() {
    return '₨';
  }
}

