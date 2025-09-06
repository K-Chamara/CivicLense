import 'package:cloud_firestore/cloud_firestore.dart';

/// Budget Category Model - Represents a main budget category
class BudgetCategory {
  final String id;
  final String name;
  final String description;
  final double allocatedAmount;
  final double spentAmount;
  final String color;
  final DateTime createdAt;
  final List<BudgetSubcategory> subcategories;

  BudgetCategory({
    required this.id,
    required this.name,
    required this.description,
    required this.allocatedAmount,
    required this.spentAmount,
    required this.color,
    required this.createdAt,
    this.subcategories = const [],
  });

  /// Calculate the remaining amount
  double get remainingAmount => allocatedAmount - spentAmount;

  /// Calculate the spending percentage
  double get spendingPercentage => allocatedAmount > 0 ? (spentAmount / allocatedAmount) * 100 : 0;

  /// Calculate the remaining percentage
  double get remainingPercentage => 100 - spendingPercentage;

  /// Calculate the utilization percentage (alias for spendingPercentage for compatibility)
  double get utilizationPercentage => spendingPercentage;

  /// Convert from Firestore document
  factory BudgetCategory.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    
    return BudgetCategory(
      id: doc.id,
      name: data['name'] ?? '',
      description: data['description'] ?? '',
      allocatedAmount: (data['allocatedAmount'] ?? 0).toDouble(),
      spentAmount: (data['spentAmount'] ?? 0).toDouble(),
      color: data['color'] ?? '#4A90E2',
      createdAt: _parseDateTime(data['createdAt']),
      subcategories: [], // Will be populated separately
    );
  }

  /// Convert to Firestore document
  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'description': description,
      'allocatedAmount': allocatedAmount,
      'spentAmount': spentAmount,
      'color': color,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  /// Create a copy with updated values
  BudgetCategory copyWith({
    String? id,
    String? name,
    String? description,
    double? allocatedAmount,
    double? spentAmount,
    String? color,
    DateTime? createdAt,
    List<BudgetSubcategory>? subcategories,
  }) {
    return BudgetCategory(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      allocatedAmount: allocatedAmount ?? this.allocatedAmount,
      spentAmount: spentAmount ?? this.spentAmount,
      color: color ?? this.color,
      createdAt: createdAt ?? this.createdAt,
      subcategories: subcategories ?? this.subcategories,
    );
  }
}

/// Budget Subcategory Model - Represents a subcategory within a main category
class BudgetSubcategory {
  final String id;
  final String name;
  final String description;
  final double allocatedAmount;
  final double spentAmount;
  final String color;
  final DateTime createdAt;
  final List<BudgetItem> items;
  final String categoryId;

  BudgetSubcategory({
    required this.id,
    required this.name,
    required this.description,
    required this.allocatedAmount,
    required this.spentAmount,
    required this.color,
    required this.createdAt,
    this.items = const [],
    required this.categoryId,
  });

  /// Calculate the remaining amount
  double get remainingAmount => allocatedAmount - spentAmount;

  /// Calculate the spending percentage
  double get spendingPercentage => allocatedAmount > 0 ? (spentAmount / allocatedAmount) * 100 : 0;

  /// Calculate the remaining percentage
  double get remainingPercentage => 100 - spendingPercentage;

  /// Calculate the utilization percentage (alias for spendingPercentage for compatibility)
  double get utilizationPercentage => spendingPercentage;

  /// Convert from Firestore document
  factory BudgetSubcategory.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    
    return BudgetSubcategory(
      id: doc.id,
      name: data['name'] ?? '',
      description: data['description'] ?? '',
      allocatedAmount: (data['allocatedAmount'] ?? 0).toDouble(),
      spentAmount: (data['spentAmount'] ?? 0).toDouble(),
      color: data['color'] ?? '#4A90E2',
      createdAt: _parseDateTime(data['createdAt']),
      items: [], // Will be populated separately
      categoryId: data['categoryId'] ?? '',
    );
  }

  /// Convert to Firestore document
  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'description': description,
      'allocatedAmount': allocatedAmount,
      'spentAmount': spentAmount,
      'color': color,
      'createdAt': Timestamp.fromDate(createdAt),
      'categoryId': categoryId,
    };
  }

  /// Create a copy with updated values
  BudgetSubcategory copyWith({
    String? id,
    String? name,
    String? description,
    double? allocatedAmount,
    double? spentAmount,
    String? color,
    DateTime? createdAt,
    List<BudgetItem>? items,
    String? categoryId,
  }) {
    return BudgetSubcategory(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      allocatedAmount: allocatedAmount ?? this.allocatedAmount,
      spentAmount: spentAmount ?? this.spentAmount,
      color: color ?? this.color,
      createdAt: createdAt ?? this.createdAt,
      items: items ?? this.items,
      categoryId: categoryId ?? this.categoryId,
    );
  }
}

/// Budget Item Model - Represents individual budget items within subcategories
class BudgetItem {
  final String id;
  final String name;
  final String description;
  final double allocatedAmount;
  final double spentAmount;
  final String color;
  final DateTime createdAt;

  BudgetItem({
    required this.id,
    required this.name,
    required this.description,
    required this.allocatedAmount,
    required this.spentAmount,
    required this.color,
    required this.createdAt,
  });

  /// Calculate the remaining amount
  double get remainingAmount => allocatedAmount - spentAmount;

  /// Calculate the spending percentage
  double get spendingPercentage => allocatedAmount > 0 ? (spentAmount / allocatedAmount) * 100 : 0;

  /// Calculate the remaining percentage
  double get remainingPercentage => 100 - spendingPercentage;

  /// Calculate the utilization percentage (alias for spendingPercentage for compatibility)
  double get utilizationPercentage => spendingPercentage;

  /// Convert from Firestore document
  factory BudgetItem.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    
    return BudgetItem(
      id: doc.id,
      name: data['name'] ?? '',
      description: data['description'] ?? '',
      allocatedAmount: (data['allocatedAmount'] ?? 0).toDouble(),
      spentAmount: (data['spentAmount'] ?? 0).toDouble(),
      color: data['color'] ?? '#4A90E2',
      createdAt: _parseDateTime(data['createdAt']),
    );
  }

  /// Convert to Firestore document
  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'description': description,
      'allocatedAmount': allocatedAmount,
      'spentAmount': spentAmount,
      'color': color,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  /// Create a copy with updated values
  BudgetItem copyWith({
    String? id,
    String? name,
    String? description,
    double? allocatedAmount,
    double? spentAmount,
    String? color,
    DateTime? createdAt,
  }) {
    return BudgetItem(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      allocatedAmount: allocatedAmount ?? this.allocatedAmount,
      spentAmount: spentAmount ?? this.spentAmount,
      color: color ?? this.color,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

/// Budget Navigation State - Tracks the current navigation level
class BudgetNavigationState {
  final List<BudgetCategory> categories;
  final List<BudgetSubcategory> subcategories;
  final List<BudgetItem> items;
  final int currentLevel; // 0: categories, 1: subcategories, 2: items
  final String? parentId;
  final String? parentName;

  BudgetNavigationState({
    required this.categories,
    this.subcategories = const [],
    this.items = const [],
    this.currentLevel = 0,
    this.parentId,
    this.parentName,
  });

  /// Create a copy with updated values
  BudgetNavigationState copyWith({
    List<BudgetCategory>? categories,
    List<BudgetSubcategory>? subcategories,
    List<BudgetItem>? items,
    int? currentLevel,
    String? parentId,
    String? parentName,
  }) {
    return BudgetNavigationState(
      categories: categories ?? this.categories,
      subcategories: subcategories ?? this.subcategories,
      items: items ?? this.items,
      currentLevel: currentLevel ?? this.currentLevel,
      parentId: parentId ?? this.parentId,
      parentName: parentName ?? this.parentName,
    );
  }
}

/// Budget Analytics Model - For analytics and reporting
class BudgetAnalytics {
  final double totalAllocated;
  final double totalSpent;
  final double totalRemaining;
  final double spendingPercentage;
  final List<CategoryAnalytics> categoryAnalytics;
  final List<MonthlyTrend> monthlyTrends;
  final List<YearlyComparison> yearlyComparisons;

  BudgetAnalytics({
    required this.totalAllocated,
    required this.totalSpent,
    required this.totalRemaining,
    required this.spendingPercentage,
    required this.categoryAnalytics,
    required this.monthlyTrends,
    required this.yearlyComparisons,
  });

  /// Alias for totalAllocated (for compatibility)
  double get totalBudget => totalAllocated;

  /// Alias for spendingPercentage (for compatibility)
  double get utilizationPercentage => spendingPercentage;

  factory BudgetAnalytics.fromMap(Map<String, dynamic> data) {
    return BudgetAnalytics(
      totalAllocated: (data['totalAllocated'] ?? 0).toDouble(),
      totalSpent: (data['totalSpent'] ?? 0).toDouble(),
      totalRemaining: (data['totalRemaining'] ?? 0).toDouble(),
      spendingPercentage: (data['spendingPercentage'] ?? 0).toDouble(),
      categoryAnalytics: (data['categoryAnalytics'] as List<dynamic>?)
          ?.map((e) => CategoryAnalytics.fromMap(e))
          .toList() ?? [],
      monthlyTrends: (data['monthlyTrends'] as List<dynamic>?)
          ?.map((e) => MonthlyTrend.fromMap(e))
          .toList() ?? [],
      yearlyComparisons: (data['yearlyComparisons'] as List<dynamic>?)
          ?.map((e) => YearlyComparison.fromMap(e))
          .toList() ?? [],
    );
  }
}

/// Category Analytics Model
class CategoryAnalytics {
  final String categoryId;
  final String categoryName;
  final double allocatedAmount;
  final double spentAmount;
  final double remainingAmount;
  final double spendingPercentage;
  final List<SubcategoryAnalytics> subcategoryAnalytics;
  final String color;

  CategoryAnalytics({
    required this.categoryId,
    required this.categoryName,
    required this.allocatedAmount,
    required this.spentAmount,
    required this.remainingAmount,
    required this.spendingPercentage,
    required this.subcategoryAnalytics,
    this.color = '#4A90E2',
  });

  /// Alias for spendingPercentage (for compatibility)
  double get utilizationPercentage => spendingPercentage;

  factory CategoryAnalytics.fromMap(Map<String, dynamic> data) {
    return CategoryAnalytics(
      categoryId: data['categoryId'] ?? '',
      categoryName: data['categoryName'] ?? '',
      allocatedAmount: (data['allocatedAmount'] ?? 0).toDouble(),
      spentAmount: (data['spentAmount'] ?? 0).toDouble(),
      remainingAmount: (data['remainingAmount'] ?? 0).toDouble(),
      spendingPercentage: (data['spendingPercentage'] ?? 0).toDouble(),
      subcategoryAnalytics: (data['subcategoryAnalytics'] as List<dynamic>?)
          ?.map((e) => SubcategoryAnalytics.fromMap(e))
          .toList() ?? [],
      color: data['color'] ?? '#4A90E2',
    );
  }
}

/// Subcategory Analytics Model
class SubcategoryAnalytics {
  final String subcategoryId;
  final String subcategoryName;
  final double allocatedAmount;
  final double spentAmount;
  final double spendingPercentage;

  SubcategoryAnalytics({
    required this.subcategoryId,
    required this.subcategoryName,
    required this.allocatedAmount,
    required this.spentAmount,
    required this.spendingPercentage,
  });

  factory SubcategoryAnalytics.fromMap(Map<String, dynamic> data) {
    return SubcategoryAnalytics(
      subcategoryId: data['subcategoryId'] ?? '',
      subcategoryName: data['subcategoryName'] ?? '',
      allocatedAmount: (data['allocatedAmount'] ?? 0).toDouble(),
      spentAmount: (data['spentAmount'] ?? 0).toDouble(),
      spendingPercentage: (data['spendingPercentage'] ?? 0).toDouble(),
    );
  }
}

/// Monthly Trend Model
class MonthlyTrend {
  final String month;
  final int year;
  final double allocatedAmount;
  final double spentAmount;
  final double variance;

  MonthlyTrend({
    required this.month,
    required this.year,
    required this.allocatedAmount,
    required this.spentAmount,
    required this.variance,
  });

  /// Alias for allocatedAmount (for compatibility)
  double get budgeted => allocatedAmount;

  /// Alias for spentAmount (for compatibility)
  double get actual => spentAmount;

  factory MonthlyTrend.fromMap(Map<String, dynamic> data) {
    return MonthlyTrend(
      month: data['month'] ?? '',
      year: data['year'] ?? 0,
      allocatedAmount: (data['allocatedAmount'] ?? 0).toDouble(),
      spentAmount: (data['spentAmount'] ?? 0).toDouble(),
      variance: (data['variance'] ?? 0).toDouble(),
    );
  }
}

/// Yearly Comparison Model
class YearlyComparison {
  final int year;
  final double allocatedAmount;
  final double spentAmount;
  final double variance;
  final double variancePercentage;

  YearlyComparison({
    required this.year,
    required this.allocatedAmount,
    required this.spentAmount,
    required this.variance,
    required this.variancePercentage,
  });

  /// Alias for allocatedAmount (for compatibility)
  double get totalBudget => allocatedAmount;

  /// Alias for spentAmount (for compatibility)
  double get totalSpent => spentAmount;

  /// Calculate growth rate (for compatibility)
  double get growthRate => variancePercentage;

  factory YearlyComparison.fromMap(Map<String, dynamic> data) {
    return YearlyComparison(
      year: data['year'] ?? 0,
      allocatedAmount: (data['allocatedAmount'] ?? 0).toDouble(),
      spentAmount: (data['spentAmount'] ?? 0).toDouble(),
      variance: (data['variance'] ?? 0).toDouble(),
      variancePercentage: (data['variancePercentage'] ?? 0).toDouble(),
    );
  }
}

/// Category Group Analytics Model
class CategoryGroupAnalytics {
  final String groupName;
  final List<CategoryAnalytics> categories;
  final double totalAllocated;
  final double totalSpent;
  final double totalRemaining;
  final double spendingPercentage;
  final String color;
  final List<BudgetEntry> individualEntries;

  CategoryGroupAnalytics({
    required this.groupName,
    required this.categories,
    required this.totalAllocated,
    required this.totalSpent,
    required this.totalRemaining,
    required this.spendingPercentage,
    this.color = '#4A90E2',
    this.individualEntries = const [],
  });

  /// Alias for groupName (for compatibility)
  String get categoryName => groupName;

  /// Alias for spendingPercentage (for compatibility)
  double get utilizationPercentage => spendingPercentage;

  factory CategoryGroupAnalytics.fromMap(Map<String, dynamic> data) {
    return CategoryGroupAnalytics(
      groupName: data['groupName'] ?? '',
      categories: (data['categories'] as List<dynamic>?)
          ?.map((e) => CategoryAnalytics.fromMap(e))
          .toList() ?? [],
      totalAllocated: (data['totalAllocated'] ?? 0).toDouble(),
      totalSpent: (data['totalSpent'] ?? 0).toDouble(),
      totalRemaining: (data['totalRemaining'] ?? 0).toDouble(),
      spendingPercentage: (data['spendingPercentage'] ?? 0).toDouble(),
      color: data['color'] ?? '#4A90E2',
      individualEntries: (data['individualEntries'] as List<dynamic>?)
          ?.map((e) => BudgetEntry.fromMap(e))
          .toList() ?? [],
    );
  }
}

/// AI Suggestion Model
class AISuggestion {
  final String id;
  final String title;
  final String description;
  final String category;
  final String confidence; // 'high', 'medium', 'low'
  final String impact; // 'high', 'medium', 'low'
  final double potentialSavings;
  final String rationale;
  final List<String> tags;
  final DateTime createdAt;
  final bool isApplied;

  AISuggestion({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.confidence,
    required this.impact,
    required this.potentialSavings,
    required this.rationale,
    required this.tags,
    required this.createdAt,
    this.isApplied = false,
  });

  /// Alias for description (for compatibility)
  String get suggestion => description;

  /// Alias for potentialSavings (for compatibility)
  double get recommendedAmount => potentialSavings;

  /// Alias for rationale (for compatibility)
  String get reasoning => rationale;

  factory AISuggestion.fromMap(Map<String, dynamic> data) {
    return AISuggestion(
      id: data['id'] ?? '',
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      category: data['category'] ?? '',
      confidence: data['confidence'] ?? 'medium',
      impact: data['impact'] ?? 'medium',
      potentialSavings: (data['potentialSavings'] ?? 0).toDouble(),
      rationale: data['rationale'] ?? '',
      tags: (data['tags'] as List<dynamic>?)?.cast<String>() ?? [],
      createdAt: _parseDateTime(data['createdAt']),
      isApplied: data['isApplied'] ?? false,
    );
  }
}

/// Budget Entry Model (for CSV uploads)
class BudgetEntry {
  final String id;
  final String categoryName;
  final String subcategoryName;
  final String itemName;
  final double allocatedAmount;
  final double spentAmount;
  final String description;
  final DateTime createdAt;
  final double amount; // For compatibility with existing code

  BudgetEntry({
    required this.id,
    required this.categoryName,
    required this.subcategoryName,
    required this.itemName,
    required this.allocatedAmount,
    required this.spentAmount,
    required this.description,
    required this.createdAt,
    this.amount = 0.0, // Default value for compatibility
  });

  /// Calculate the remaining amount
  double get remainingAmount => allocatedAmount - spentAmount;

  factory BudgetEntry.fromMap(Map<String, dynamic> data) {
    return BudgetEntry(
      id: data['id'] ?? '',
      categoryName: data['categoryName'] ?? '',
      subcategoryName: data['subcategoryName'] ?? '',
      itemName: data['itemName'] ?? '',
      allocatedAmount: (data['allocatedAmount'] ?? 0).toDouble(),
      spentAmount: (data['spentAmount'] ?? 0).toDouble(),
      description: data['description'] ?? '',
      createdAt: _parseDateTime(data['createdAt']),
      amount: (data['amount'] ?? 0).toDouble(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'categoryName': categoryName,
      'subcategoryName': subcategoryName,
      'itemName': itemName,
      'allocatedAmount': allocatedAmount,
      'spentAmount': spentAmount,
      'description': description,
      'createdAt': Timestamp.fromDate(createdAt),
      'amount': amount,
    };
  }
}

/// Helper function to parse DateTime from various formats
DateTime _parseDateTime(dynamic data) {
  if (data == null) {
    return DateTime.now();
  }
  
  if (data is Timestamp) {
    return data.toDate();
  }
  
  if (data is String) {
    try {
      return DateTime.parse(data);
    } catch (e) {
      print('Error parsing date string: $data, error: $e');
      return DateTime.now();
    }
  }
  
  if (data is DateTime) {
    return data;
  }
  
  print('Unknown date format: ${data.runtimeType}, value: $data');
  return DateTime.now();
}

/// Utility class for formatting budget amounts
class BudgetFormatter {
  /// Format amount to currency string
  static String formatAmount(double amount) {
    if (amount >= 1000000000) {
      return '\$${(amount / 1000000000).toStringAsFixed(1)}B';
    } else if (amount >= 1000000) {
      return '\$${(amount / 1000000).toStringAsFixed(1)}M';
    } else if (amount >= 1000) {
      return '\$${(amount / 1000).toStringAsFixed(1)}K';
    } else {
      return '\$${amount.toStringAsFixed(0)}';
    }
  }

  /// Format percentage
  static String formatPercentage(double percentage) {
    return '${percentage.toStringAsFixed(1)}%';
  }

  /// Get color based on spending percentage
  static String getSpendingColor(double percentage) {
    if (percentage >= 90) return '#E74C3C'; // Red - High spending
    if (percentage >= 70) return '#F39C12'; // Orange - Medium spending
    if (percentage >= 50) return '#F1C40F'; // Yellow - Moderate spending
    return '#27AE60'; // Green - Low spending
  }
}