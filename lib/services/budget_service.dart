import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/budget_models.dart';

class BudgetService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  // Collection names
  static const String budgetCategoriesCollection = 'budget_categories';
  static const String budgetSubcategoriesCollection = 'budget_subcategories';
  static const String budgetItemsCollection = 'budget_items';

  /// Get all budget categories
  Future<List<BudgetCategory>> getBudgetCategories() async {
    try {
      QuerySnapshot snapshot = await _firestore
          .collection(budgetCategoriesCollection)
          .orderBy('allocatedAmount', descending: true)
          .get();

      List<BudgetCategory> categories = [];
      for (DocumentSnapshot doc in snapshot.docs) {
        BudgetCategory category = BudgetCategory.fromFirestore(doc);
        categories.add(category);
      }

      return categories;
    } catch (e) {
      print('Error fetching budget categories: $e');
      throw Exception('Failed to fetch budget categories: $e');
    }
  }

  /// Get all budget categories with their subcategories
  Future<List<BudgetCategory>> getBudgetCategoriesWithSubcategories() async {
    try {
      QuerySnapshot snapshot = await _firestore
          .collection(budgetCategoriesCollection)
          .orderBy('allocatedAmount', descending: true)
          .get();

      List<BudgetCategory> categories = [];
      for (DocumentSnapshot doc in snapshot.docs) {
        BudgetCategory category = BudgetCategory.fromFirestore(doc);
        
        // Load subcategories for this category
        try {
          List<BudgetSubcategory> subcategories = await getBudgetSubcategories(category.id);
          category = category.copyWith(subcategories: subcategories);
        } catch (e) {
          print('Error loading subcategories for category ${category.id}: $e');
          // Continue with empty subcategories list
        }
        
        categories.add(category);
      }

      return categories;
    } catch (e) {
      print('Error fetching budget categories with subcategories: $e');
      throw Exception('Failed to fetch budget categories with subcategories: $e');
    }
  }

  /// Get subcategories for a specific budget category
  Future<List<BudgetSubcategory>> getBudgetSubcategories(String categoryId) async {
    try {
      QuerySnapshot snapshot = await _firestore
          .collection(budgetCategoriesCollection)
          .doc(categoryId)
          .collection(budgetSubcategoriesCollection)
          .orderBy('allocatedAmount', descending: true)
          .get();

      List<BudgetSubcategory> subcategories = [];
      for (DocumentSnapshot doc in snapshot.docs) {
        BudgetSubcategory subcategory = BudgetSubcategory.fromFirestore(doc);
        
        // Load items for this subcategory
        try {
          List<BudgetItem> items = await getBudgetItems(categoryId, subcategory.id);
          subcategory = subcategory.copyWith(items: items);
        } catch (e) {
          print('Error loading items for subcategory ${subcategory.id}: $e');
          // Continue with empty items list
        }
        
        subcategories.add(subcategory);
      }

      return subcategories;
    } catch (e) {
      print('Error fetching budget subcategories: $e');
      throw Exception('Failed to fetch budget subcategories: $e');
    }
  }

  /// Get budget items for a specific subcategory
  Future<List<BudgetItem>> getBudgetItems(String categoryId, String subcategoryId) async {
    try {
      QuerySnapshot snapshot = await _firestore
          .collection(budgetCategoriesCollection)
          .doc(categoryId)
          .collection(budgetSubcategoriesCollection)
          .doc(subcategoryId)
          .collection(budgetItemsCollection)
          .orderBy('allocatedAmount', descending: true)
          .get();

      List<BudgetItem> items = [];
      for (DocumentSnapshot doc in snapshot.docs) {
        BudgetItem item = BudgetItem.fromFirestore(doc);
        items.add(item);
      }

      return items;
    } catch (e) {
      print('Error fetching budget items: $e');
      throw Exception('Failed to fetch budget items: $e');
    }
  }

  /// Get a specific budget category by ID
  Future<BudgetCategory?> getBudgetCategory(String categoryId) async {
    try {
      DocumentSnapshot doc = await _firestore
          .collection(budgetCategoriesCollection)
          .doc(categoryId)
          .get();

      if (doc.exists) {
        return BudgetCategory.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      print('Error fetching budget category: $e');
      throw Exception('Failed to fetch budget category: $e');
    }
  }

  /// Get a specific budget subcategory by ID
  Future<BudgetSubcategory?> getBudgetSubcategory(String categoryId, String subcategoryId) async {
    try {
      DocumentSnapshot doc = await _firestore
          .collection(budgetCategoriesCollection)
          .doc(categoryId)
          .collection(budgetSubcategoriesCollection)
          .doc(subcategoryId)
          .get();

      if (doc.exists) {
        return BudgetSubcategory.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      print('Error fetching budget subcategory: $e');
      throw Exception('Failed to fetch budget subcategory: $e');
    }
  }

  /// Get total budget amount across all categories
  Future<double> getTotalBudgetAmount() async {
    try {
      List<BudgetCategory> categories = await getBudgetCategories();
      double total = 0;
      for (BudgetCategory category in categories) {
        total += category.allocatedAmount;
      }
      return total;
    } catch (e) {
      print('Error calculating total budget amount: $e');
      throw Exception('Failed to calculate total budget amount: $e');
    }
  }

  /// Get total spent amount across all categories
  Future<double> getTotalSpentAmount() async {
    try {
      List<BudgetCategory> categories = await getBudgetCategories();
      double total = 0;
      for (BudgetCategory category in categories) {
        total += category.spentAmount;
      }
      return total;
    } catch (e) {
      print('Error calculating total spent amount: $e');
      throw Exception('Failed to calculate total spent amount: $e');
    }
  }

  /// Get budget statistics
  Future<Map<String, dynamic>> getBudgetStatistics() async {
    try {
      double totalAllocated = await getTotalBudgetAmount();
      double totalSpent = await getTotalSpentAmount();
      double totalRemaining = totalAllocated - totalSpent;
      double spendingPercentage = totalAllocated > 0 ? (totalSpent / totalAllocated) * 100 : 0;

      return {
        'totalAllocated': totalAllocated,
        'totalSpent': totalSpent,
        'totalRemaining': totalRemaining,
        'spendingPercentage': spendingPercentage,
        'remainingPercentage': 100 - spendingPercentage,
      };
    } catch (e) {
      print('Error calculating budget statistics: $e');
      throw Exception('Failed to calculate budget statistics: $e');
    }
  }

  /// Stream budget categories for real-time updates
  Stream<List<BudgetCategory>> streamBudgetCategories() {
    return _firestore
        .collection(budgetCategoriesCollection)
        .orderBy('allocatedAmount', descending: true)
        .snapshots()
        .map((snapshot) {
      List<BudgetCategory> categories = [];
      for (DocumentSnapshot doc in snapshot.docs) {
        BudgetCategory category = BudgetCategory.fromFirestore(doc);
        categories.add(category);
      }
      return categories;
    });
  }

  /// Stream budget subcategories for real-time updates
  Stream<List<BudgetSubcategory>> streamBudgetSubcategories(String categoryId) {
    return _firestore
        .collection(budgetCategoriesCollection)
        .doc(categoryId)
        .collection(budgetSubcategoriesCollection)
        .orderBy('allocatedAmount', descending: true)
        .snapshots()
        .map((snapshot) {
      List<BudgetSubcategory> subcategories = [];
      for (DocumentSnapshot doc in snapshot.docs) {
        BudgetSubcategory subcategory = BudgetSubcategory.fromFirestore(doc);
        subcategories.add(subcategory);
      }
      return subcategories;
    });
  }

  /// Stream budget items for real-time updates
  Stream<List<BudgetItem>> streamBudgetItems(String categoryId, String subcategoryId) {
    return _firestore
        .collection(budgetCategoriesCollection)
        .doc(categoryId)
        .collection(budgetSubcategoriesCollection)
        .doc(subcategoryId)
        .collection(budgetItemsCollection)
        .orderBy('allocatedAmount', descending: true)
        .snapshots()
        .map((snapshot) {
      List<BudgetItem> items = [];
      for (DocumentSnapshot doc in snapshot.docs) {
        BudgetItem item = BudgetItem.fromFirestore(doc);
        items.add(item);
      }
      return items;
    });
  }

  /// Search budget categories by name
  Future<List<BudgetCategory>> searchBudgetCategories(String query) async {
    try {
      QuerySnapshot snapshot = await _firestore
          .collection(budgetCategoriesCollection)
          .where('name', isGreaterThanOrEqualTo: query)
          .where('name', isLessThan: query + 'z')
          .get();

      List<BudgetCategory> categories = [];
      for (DocumentSnapshot doc in snapshot.docs) {
        BudgetCategory category = BudgetCategory.fromFirestore(doc);
        categories.add(category);
      }

      return categories;
    } catch (e) {
      print('Error searching budget categories: $e');
      throw Exception('Failed to search budget categories: $e');
    }
  }

  /// Get budget categories with spending analysis
  Future<List<Map<String, dynamic>>> getBudgetCategoriesWithAnalysis() async {
    try {
      List<BudgetCategory> categories = await getBudgetCategories();
      double totalAllocated = await getTotalBudgetAmount();

      List<Map<String, dynamic>> categoriesWithAnalysis = [];
      for (BudgetCategory category in categories) {
        double percentage = totalAllocated > 0 ? (category.allocatedAmount / totalAllocated) * 100 : 0;
        String spendingColor = BudgetFormatter.getSpendingColor(category.spendingPercentage);

        categoriesWithAnalysis.add({
          'category': category,
          'percentage': percentage,
          'spendingColor': spendingColor,
          'isOverBudget': category.spentAmount > category.allocatedAmount,
        });
      }

      return categoriesWithAnalysis;
    } catch (e) {
      print('Error getting budget categories with analysis: $e');
      throw Exception('Failed to get budget categories with analysis: $e');
    }
  }

  // Legacy method aliases for compatibility
  Future<List<BudgetCategory>> getCategories() async {
    return getBudgetCategoriesWithSubcategories();
  }

  /// Create a new budget category
  Future<void> createCategory(BudgetCategory category) async {
    try {
      await _firestore
          .collection(budgetCategoriesCollection)
          .doc(category.id)
          .set(category.toFirestore());
    } catch (e) {
      print('Error creating budget category: $e');
      throw Exception('Failed to create budget category: $e');
    }
  }

  /// Update an existing budget category
  Future<void> updateCategory(BudgetCategory category) async {
    try {
      await _firestore
          .collection(budgetCategoriesCollection)
          .doc(category.id)
          .update(category.toFirestore());
    } catch (e) {
      print('Error updating budget category: $e');
      throw Exception('Failed to update budget category: $e');
    }
  }

  /// Delete a budget category
  Future<void> deleteCategory(String categoryId) async {
    try {
      await _firestore
          .collection(budgetCategoriesCollection)
          .doc(categoryId)
          .delete();
    } catch (e) {
      print('Error deleting budget category: $e');
      throw Exception('Failed to delete budget category: $e');
    }
  }

  /// Create a budget entry (for CSV uploads)
  Future<void> createBudgetEntry(BudgetEntry entry) async {
    try {
      await _firestore
          .collection('budget_entries')
          .doc(entry.id)
          .set(entry.toMap());
    } catch (e) {
      print('Error creating budget entry: $e');
      throw Exception('Failed to create budget entry: $e');
    }
  }

  /// Upload budget file (CSV processing)
  Future<List<BudgetCategory>> uploadBudgetFile(List<int> fileBytes, String fileName) async {
    try {
      // This is a placeholder implementation
      // In a real app, you would parse the CSV file and create categories
      print('Uploading budget file: $fileName');
      
      // For now, return empty list
      // You would implement CSV parsing logic here
      return [];
    } catch (e) {
      print('Error uploading budget file: $e');
      throw Exception('Failed to upload budget file: $e');
    }
  }

  /// Get budget analytics
  Future<BudgetAnalytics> getBudgetAnalytics() async {
    try {
      final statistics = await getBudgetStatistics();
      final categories = await getBudgetCategories();
      
      // Convert categories to category analytics
      List<CategoryAnalytics> categoryAnalytics = categories.map((category) {
        return CategoryAnalytics(
          categoryId: category.id,
          categoryName: category.name,
          allocatedAmount: category.allocatedAmount,
          spentAmount: category.spentAmount,
          remainingAmount: category.remainingAmount,
          spendingPercentage: category.spendingPercentage,
          subcategoryAnalytics: [],
          color: category.color,
        );
      }).toList();

      return BudgetAnalytics(
        totalAllocated: statistics['totalAllocated'] as double,
        totalSpent: statistics['totalSpent'] as double,
        totalRemaining: statistics['totalRemaining'] as double,
        spendingPercentage: statistics['spendingPercentage'] as double,
        categoryAnalytics: categoryAnalytics,
        monthlyTrends: [],
        yearlyComparisons: [],
      );
    } catch (e) {
      print('Error getting budget analytics: $e');
      throw Exception('Failed to get budget analytics: $e');
    }
  }

  /// Get grouped analytics
  Future<Map<String, CategoryGroupAnalytics>> getGroupedAnalytics() async {
    try {
      final categories = await getBudgetCategories();
      
      // Group categories by type (this is a simple grouping)
      Map<String, List<BudgetCategory>> grouped = {};
      for (BudgetCategory category in categories) {
        String group = _getCategoryGroup(category.name);
        grouped[group] ??= [];
        grouped[group]!.add(category);
      }

      Map<String, CategoryGroupAnalytics> result = {};
      grouped.forEach((groupName, categoryList) {
        double totalAllocated = categoryList.fold(0, (sum, cat) => sum + cat.allocatedAmount);
        double totalSpent = categoryList.fold(0, (sum, cat) => sum + cat.spentAmount);
        double totalRemaining = totalAllocated - totalSpent;
        double spendingPercentage = totalAllocated > 0 ? (totalSpent / totalAllocated) * 100 : 0;

        List<CategoryAnalytics> categoryAnalytics = categoryList.map((category) {
          return CategoryAnalytics(
            categoryId: category.id,
            categoryName: category.name,
            allocatedAmount: category.allocatedAmount,
            spentAmount: category.spentAmount,
            remainingAmount: category.remainingAmount,
            spendingPercentage: category.spendingPercentage,
            subcategoryAnalytics: [],
            color: category.color,
          );
        }).toList();

        result[groupName] = CategoryGroupAnalytics(
          groupName: groupName,
          categories: categoryAnalytics,
          totalAllocated: totalAllocated,
          totalSpent: totalSpent,
          totalRemaining: totalRemaining,
          spendingPercentage: spendingPercentage,
        );
      });

      return result;
    } catch (e) {
      print('Error getting grouped analytics: $e');
      throw Exception('Failed to get grouped analytics: $e');
    }
  }

  /// Get AI suggestions
  Future<List<AISuggestion>> getAISuggestions() async {
    try {
      // This is a placeholder implementation
      // In a real app, you would integrate with AI services
      return [
        AISuggestion(
          id: '1',
          title: 'Optimize Infrastructure Spending',
          description: 'Consider reallocating funds from over-budget categories to under-utilized ones.',
          category: 'Infrastructure',
          confidence: 'high',
          impact: 'high',
          potentialSavings: 5000000,
          rationale: 'Based on spending patterns and budget utilization analysis.',
          tags: ['optimization', 'infrastructure', 'cost-saving'],
          createdAt: DateTime.now(),
        ),
        AISuggestion(
          id: '2',
          title: 'Review Healthcare Budget Allocation',
          description: 'Healthcare spending is 15% over budget. Consider cost reduction strategies.',
          category: 'Healthcare',
          confidence: 'medium',
          impact: 'medium',
          potentialSavings: 2000000,
          rationale: 'Healthcare category shows consistent overspending trends.',
          tags: ['healthcare', 'cost-reduction', 'budget-review'],
          createdAt: DateTime.now(),
        ),
      ];
    } catch (e) {
      print('Error getting AI suggestions: $e');
      throw Exception('Failed to get AI suggestions: $e');
    }
  }

  /// Helper method to determine category group
  String _getCategoryGroup(String categoryName) {
    if (categoryName.toLowerCase().contains('infrastructure') || 
        categoryName.toLowerCase().contains('road') ||
        categoryName.toLowerCase().contains('bridge')) {
      return 'Infrastructure';
    } else if (categoryName.toLowerCase().contains('health') ||
               categoryName.toLowerCase().contains('medical')) {
      return 'Healthcare';
    } else if (categoryName.toLowerCase().contains('education') ||
               categoryName.toLowerCase().contains('school')) {
      return 'Education';
    } else if (categoryName.toLowerCase().contains('security') ||
               categoryName.toLowerCase().contains('defense')) {
      return 'Security';
    } else {
      return 'Other';
    }
  }

  /// Create a new budget subcategory
  Future<void> createSubcategory(BudgetSubcategory subcategory) async {
    try {
      await _firestore
          .collection(budgetCategoriesCollection)
          .doc(subcategory.categoryId)
          .collection(budgetSubcategoriesCollection)
          .doc(subcategory.id)
          .set(subcategory.toFirestore());
    } catch (e) {
      print('Error creating budget subcategory: $e');
      throw Exception('Failed to create budget subcategory: $e');
    }
  }

  /// Update an existing budget subcategory
  Future<void> updateSubcategory(BudgetSubcategory subcategory) async {
    try {
      await _firestore
          .collection(budgetCategoriesCollection)
          .doc(subcategory.categoryId)
          .collection(budgetSubcategoriesCollection)
          .doc(subcategory.id)
          .update(subcategory.toFirestore());
    } catch (e) {
      print('Error updating budget subcategory: $e');
      throw Exception('Failed to update budget subcategory: $e');
    }
  }

  /// Delete a budget subcategory
  Future<void> deleteSubcategory(String categoryId, String subcategoryId) async {
    try {
      await _firestore
          .collection(budgetCategoriesCollection)
          .doc(categoryId)
          .collection(budgetSubcategoriesCollection)
          .doc(subcategoryId)
          .delete();
    } catch (e) {
      print('Error deleting budget subcategory: $e');
      throw Exception('Failed to delete budget subcategory: $e');
    }
  }

  /// Create a new budget item
  Future<void> createBudgetItem(String categoryId, String subcategoryId, BudgetItem item) async {
    try {
      await _firestore
          .collection(budgetCategoriesCollection)
          .doc(categoryId)
          .collection(budgetSubcategoriesCollection)
          .doc(subcategoryId)
          .collection(budgetItemsCollection)
          .doc(item.id)
          .set(item.toFirestore());
    } catch (e) {
      print('Error creating budget item: $e');
      throw Exception('Failed to create budget item: $e');
    }
  }

  /// Update an existing budget item
  Future<void> updateBudgetItem(String categoryId, String subcategoryId, BudgetItem item) async {
    try {
      await _firestore
          .collection(budgetCategoriesCollection)
          .doc(categoryId)
          .collection(budgetSubcategoriesCollection)
          .doc(subcategoryId)
          .collection(budgetItemsCollection)
          .doc(item.id)
          .update(item.toFirestore());
    } catch (e) {
      print('Error updating budget item: $e');
      throw Exception('Failed to update budget item: $e');
    }
  }

  /// Delete a budget item
  Future<void> deleteBudgetItem(String categoryId, String subcategoryId, String itemId) async {
    try {
      await _firestore
          .collection(budgetCategoriesCollection)
          .doc(categoryId)
          .collection(budgetSubcategoriesCollection)
          .doc(subcategoryId)
          .collection(budgetItemsCollection)
          .doc(itemId)
          .delete();
    } catch (e) {
      print('Error deleting budget item: $e');
      throw Exception('Failed to delete budget item: $e');
    }
  }
}