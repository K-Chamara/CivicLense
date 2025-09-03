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
    this.spentAmount = 0.0,
    required this.color,
    required this.createdAt,
    this.subcategories = const [],
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'allocatedAmount': allocatedAmount,
      'spentAmount': spentAmount,
      'color': color,
      'createdAt': createdAt.toIso8601String(),
      'subcategories': subcategories.map((e) => e.toMap()).toList(),
    };
  }

  factory BudgetCategory.fromMap(Map<String, dynamic> map) {
    return BudgetCategory(
      id: map['id'],
      name: map['name'],
      description: map['description'],
      allocatedAmount: map['allocatedAmount']?.toDouble() ?? 0.0,
      spentAmount: map['spentAmount']?.toDouble() ?? 0.0,
      color: map['color'],
      createdAt: DateTime.parse(map['createdAt']),
      subcategories: List<BudgetSubcategory>.from(
        map['subcategories']?.map((x) => BudgetSubcategory.fromMap(x)) ?? [],
      ),
    );
  }

  double get remainingAmount => allocatedAmount - spentAmount;
  double get utilizationPercentage => (spentAmount / allocatedAmount) * 100;
}

class BudgetSubcategory {
  final String id;
  final String name;
  final String description;
  final double allocatedAmount;
  final double spentAmount;
  final String categoryId;

  BudgetSubcategory({
    required this.id,
    required this.name,
    required this.description,
    required this.allocatedAmount,
    this.spentAmount = 0.0,
    required this.categoryId,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'allocatedAmount': allocatedAmount,
      'spentAmount': spentAmount,
      'categoryId': categoryId,
    };
  }

  factory BudgetSubcategory.fromMap(Map<String, dynamic> map) {
    return BudgetSubcategory(
      id: map['id'],
      name: map['name'],
      description: map['description'],
      allocatedAmount: map['allocatedAmount']?.toDouble() ?? 0.0,
      spentAmount: map['spentAmount']?.toDouble() ?? 0.0,
      categoryId: map['categoryId'],
    );
  }

  double get remainingAmount => allocatedAmount - spentAmount;
  double get utilizationPercentage => (spentAmount / allocatedAmount) * 100;
}

class BudgetEntry {
  final String id;
  final String categoryId;
  final String subcategoryId;
  final String description;
  final double amount;
  final DateTime date;
  final String type; // 'income' or 'expense'
  final String status; // 'pending', 'approved', 'rejected'
  final String? notes;

  BudgetEntry({
    required this.id,
    required this.categoryId,
    required this.subcategoryId,
    required this.description,
    required this.amount,
    required this.date,
    required this.type,
    required this.status,
    this.notes,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'categoryId': categoryId,
      'subcategoryId': subcategoryId,
      'description': description,
      'amount': amount,
      'date': date.toIso8601String(),
      'type': type,
      'status': status,
      'notes': notes,
    };
  }

  factory BudgetEntry.fromMap(Map<String, dynamic> map) {
    return BudgetEntry(
      id: map['id'],
      categoryId: map['categoryId'],
      subcategoryId: map['subcategoryId'],
      description: map['description'],
      amount: map['amount']?.toDouble() ?? 0.0,
      date: DateTime.parse(map['date']),
      type: map['type'],
      status: map['status'],
      notes: map['notes'],
    );
  }
}

class BudgetAnalytics {
  final double totalBudget;
  final double totalSpent;
  final double totalRemaining;
  final List<CategoryAnalytics> categoryAnalytics;
  final List<MonthlyTrend> monthlyTrends;
  final List<YearlyComparison> yearlyComparisons;

  BudgetAnalytics({
    required this.totalBudget,
    required this.totalSpent,
    required this.totalRemaining,
    required this.categoryAnalytics,
    required this.monthlyTrends,
    required this.yearlyComparisons,
  });

  double get utilizationPercentage => (totalSpent / totalBudget) * 100;
}

class CategoryAnalytics {
  final String categoryName;
  final double allocatedAmount;
  final double spentAmount;
  final double utilizationPercentage;
  final String color;

  CategoryAnalytics({
    required this.categoryName,
    required this.allocatedAmount,
    required this.spentAmount,
    required this.utilizationPercentage,
    required this.color,
  });
}

class CategoryGroupAnalytics {
  final String categoryName;
  final double totalAllocated;
  final double totalSpent;
  final double totalRemaining;
  final double utilizationPercentage;
  final String color;
  final List<BudgetCategory> individualEntries;

  CategoryGroupAnalytics({
    required this.categoryName,
    required this.totalAllocated,
    required this.totalSpent,
    required this.totalRemaining,
    required this.utilizationPercentage,
    required this.color,
    required this.individualEntries,
  });
}

class MonthlyTrend {
  final String month;
  final double budgeted;
  final double actual;
  final double variance;

  MonthlyTrend({
    required this.month,
    required this.budgeted,
    required this.actual,
    required this.variance,
  });
}

class YearlyComparison {
  final int year;
  final double totalBudget;
  final double totalSpent;
  final double utilizationPercentage;
  final double growthRate;

  YearlyComparison({
    required this.year,
    required this.totalBudget,
    required this.totalSpent,
    required this.utilizationPercentage,
    required this.growthRate,
  });
}

class AISuggestion {
  final String category;
  final String suggestion;
  final double recommendedAmount;
  final String reasoning;
  final String confidence; // 'high', 'medium', 'low'

  AISuggestion({
    required this.category,
    required this.suggestion,
    required this.recommendedAmount,
    required this.reasoning,
    required this.confidence,
  });
}
