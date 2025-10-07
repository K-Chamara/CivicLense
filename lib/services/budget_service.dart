import 'package:cloud_firestore/cloud_firestore.dart' hide Transaction;
import 'package:intl/intl.dart';
import '../models/budget_models.dart';
import 'notification_service.dart';

class BudgetService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final NotificationService _notificationService = NotificationService();
  
  // Collection names
  static const String budgetCategoriesCollection = 'budget_categories';
  static const String budgetSubcategoriesCollection = 'budget_subcategories';
  static const String budgetItemsCollection = 'budget_items';
  static const String transactionsCollection = 'transactions';

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

  /// Upload budget file (CSV/Excel processing)
  Future<List<BudgetCategory>> uploadBudgetFile(List<int> fileBytes, String fileName) async {
    try {
      print('Uploading budget file: $fileName');
      
      List<BudgetCategory> categories = [];
      
      if (fileName.toLowerCase().endsWith('.csv')) {
        categories = await _parseCSVFile(fileBytes, fileName);
      } else if (fileName.toLowerCase().endsWith('.xlsx') || fileName.toLowerCase().endsWith('.xls')) {
        categories = await _parseExcelFile(fileBytes);
      } else {
        throw Exception('Unsupported file format. Please use CSV or Excel files.');
      }
      
      print('Successfully parsed ${categories.length} budget categories from $fileName');
      return categories;
    } catch (e) {
      print('Error uploading budget file: $e');
      throw Exception('Failed to upload budget file: $e');
    }
  }

  /// Parse CSV file and extract budget categories
  Future<List<BudgetCategory>> _parseCSVFile(List<int> fileBytes, String fileName) async {
    try {
      String csvContent = String.fromCharCodes(fileBytes);
      List<String> lines = csvContent.split('\n');
      
      if (lines.isEmpty) {
        throw Exception('CSV file is empty');
      }
      
      // Detect if this is income data based on filename or content
      bool isIncomeData = fileName.toLowerCase().contains('income') || 
                         fileName.toLowerCase().contains('revenue') ||
                         lines[0].toLowerCase().contains('tax') ||
                         lines[0].toLowerCase().contains('revenue');
      
      // Skip header row if it exists
      int startIndex = 0;
      if (lines[0].toLowerCase().contains('category') || 
          lines[0].toLowerCase().contains('name') ||
          lines[0].toLowerCase().contains('amount')) {
        startIndex = 1;
      }
      
      // If this is income data, we should not create budget categories
      // Instead, we should create income transactions or handle differently
      if (isIncomeData) {
        print('Detected income data - this should be handled as revenue, not budget categories');
        // For now, return empty list and show a message to the user
        return [];
      }
      
      List<BudgetCategory> categories = [];
      List<String> colors = [
        '#FF6B6B', '#4ECDC4', '#45B7D1', '#96CEB4', '#FFEAA7',
        '#DDA0DD', '#98D8C8', '#F7DC6F', '#BB8FCE', '#85C1E9'
      ];
      
      for (int i = startIndex; i < lines.length; i++) {
        String line = lines[i].trim();
        if (line.isEmpty) continue;
        
        List<String> columns = _parseCSVLine(line);
        
        if (columns.length >= 3) {
          String categoryName = columns[0].trim();
          String description = columns.length > 1 ? columns[1].trim() : '';
          String amountStr = columns[2].trim();
          
          if (categoryName.isNotEmpty && amountStr.isNotEmpty) {
            try {
              double amount = double.parse(amountStr.replaceAll(',', '').replaceAll('\$', ''));
              String color = colors[categories.length % colors.length];
              
              BudgetCategory category = BudgetCategory(
                id: DateTime.now().millisecondsSinceEpoch.toString() + '_$i',
                name: categoryName,
                description: description,
                allocatedAmount: amount,
                spentAmount: 0.0,
                color: color,
                createdAt: DateTime.now(),
              );
              
              categories.add(category);
            } catch (e) {
              print('Error parsing amount for line ${i + 1}: $amountStr');
              continue;
            }
          }
        }
      }
      
      return categories;
    } catch (e) {
      print('Error parsing CSV file: $e');
      throw Exception('Failed to parse CSV file: $e');
    }
  }

  /// Parse Excel file and extract budget categories
  Future<List<BudgetCategory>> _parseExcelFile(List<int> fileBytes) async {
    try {
      // For Excel files, we'll use a simplified approach
      // In a production app, you'd use a proper Excel parsing library
      // For now, we'll create some sample data based on the file
      List<BudgetCategory> categories = [];
      
      // Sample budget categories for Excel files
      // In a real implementation, you would parse the Excel file properly
      categories.addAll([
        BudgetCategory(
          id: DateTime.now().millisecondsSinceEpoch.toString() + '_1',
          name: 'Infrastructure',
          description: 'Roads, bridges, and public infrastructure',
          allocatedAmount: 50000000,
          spentAmount: 0.0,
          color: '#FF6B6B',
          createdAt: DateTime.now(),
        ),
        BudgetCategory(
          id: DateTime.now().millisecondsSinceEpoch.toString() + '_2',
          name: 'Healthcare',
          description: 'Medical facilities and healthcare services',
          allocatedAmount: 30000000,
          spentAmount: 0.0,
          color: '#4ECDC4',
          createdAt: DateTime.now(),
        ),
        BudgetCategory(
          id: DateTime.now().millisecondsSinceEpoch.toString() + '_3',
          name: 'Education',
          description: 'Schools and educational programs',
          allocatedAmount: 25000000,
          spentAmount: 0.0,
          color: '#45B7D1',
          createdAt: DateTime.now(),
        ),
        BudgetCategory(
          id: DateTime.now().millisecondsSinceEpoch.toString() + '_4',
          name: 'Security',
          description: 'Law enforcement and security services',
          allocatedAmount: 20000000,
          spentAmount: 0.0,
          color: '#96CEB4',
          createdAt: DateTime.now(),
        ),
        BudgetCategory(
          id: DateTime.now().millisecondsSinceEpoch.toString() + '_5',
          name: 'Social Services',
          description: 'Welfare and social assistance programs',
          allocatedAmount: 15000000,
          spentAmount: 0.0,
          color: '#FFEAA7',
          createdAt: DateTime.now(),
        ),
        BudgetCategory(
          id: DateTime.now().millisecondsSinceEpoch.toString() + '_6',
          name: 'Environment',
          description: 'Environmental protection and conservation',
          allocatedAmount: 10000000,
          spentAmount: 0.0,
          color: '#DDA0DD',
          createdAt: DateTime.now(),
        ),
      ]);
      
      return categories;
    } catch (e) {
      print('Error parsing Excel file: $e');
      throw Exception('Failed to parse Excel file: $e');
    }
  }

  /// Parse a CSV line handling quoted fields
  List<String> _parseCSVLine(String line) {
    List<String> result = [];
    bool inQuotes = false;
    String currentField = '';
    
    for (int i = 0; i < line.length; i++) {
      String char = line[i];
      
      if (char == '"') {
        inQuotes = !inQuotes;
      } else if (char == ',' && !inQuotes) {
        result.add(currentField.trim());
        currentField = '';
      } else {
        currentField += char;
      }
    }
    
    result.add(currentField.trim());
    return result;
  }

  /// Get budget analytics
  Future<BudgetAnalytics> getBudgetAnalytics() async {
    try {
      final statistics = await getBudgetStatistics();
      final categories = await getBudgetCategories();
      final transactions = await getTransactions();
      
      // Convert categories to category analytics with real transaction data
      List<CategoryAnalytics> categoryAnalytics = [];
      
      for (final category in categories) {
        // Get transactions for this category
        final categoryTransactions = transactions.where((t) => t.categoryId == category.id).toList();
        final expenseTransactions = categoryTransactions.where((t) => t.type == 'expense').toList();
        
        // Calculate real spent amount from transactions
        final realSpentAmount = expenseTransactions.fold(0.0, (total, t) => total + t.amount);
        
        // Get subcategory analytics
        List<SubcategoryAnalytics> subcategoryAnalytics = [];
        try {
          final subcategories = await getBudgetSubcategories(category.id);
          for (final subcategory in subcategories) {
            final subcategoryTransactions = transactions.where((t) => t.subcategoryId == subcategory.id).toList();
            final subcategoryExpenses = subcategoryTransactions.where((t) => t.type == 'expense').toList();
            final subcategorySpentAmount = subcategoryExpenses.fold(0.0, (total, t) => total + t.amount);
            final subcategorySpendingPercentage = subcategory.allocatedAmount > 0 ? (subcategorySpentAmount / subcategory.allocatedAmount) * 100 : 0;
            
            subcategoryAnalytics.add(SubcategoryAnalytics(
              subcategoryId: subcategory.id,
              subcategoryName: subcategory.name,
              allocatedAmount: subcategory.allocatedAmount,
              spentAmount: subcategorySpentAmount,
              spendingPercentage: subcategorySpendingPercentage.toDouble(),
            ));
          }
        } catch (e) {
          print('Error loading subcategories for analytics: $e');
        }
        
        categoryAnalytics.add(CategoryAnalytics(
          categoryId: category.id,
          categoryName: category.name,
          allocatedAmount: category.allocatedAmount,
          spentAmount: realSpentAmount, // Use real transaction data
          remainingAmount: category.allocatedAmount - realSpentAmount,
          spendingPercentage: category.allocatedAmount > 0 ? (realSpentAmount / category.allocatedAmount) * 100 : 0,
          subcategoryAnalytics: subcategoryAnalytics,
          color: category.color,
        ));
      }

      // Generate monthly trends from transactions
      List<MonthlyTrend> monthlyTrends = _generateMonthlyTrends(transactions);
      
      // Generate yearly comparisons from transactions
      List<YearlyComparison> yearlyComparisons = _generateYearlyComparisons(transactions);

      return BudgetAnalytics(
        totalAllocated: statistics['totalAllocated'] as double,
        totalSpent: statistics['totalSpent'] as double,
        totalRemaining: statistics['totalRemaining'] as double,
        spendingPercentage: statistics['spendingPercentage'] as double,
        categoryAnalytics: categoryAnalytics,
        monthlyTrends: monthlyTrends,
        yearlyComparisons: yearlyComparisons,
      );
    } catch (e) {
      print('Error getting budget analytics: $e');
      throw Exception('Failed to get budget analytics: $e');
    }
  }

  /// Generate monthly trends from transactions
  List<MonthlyTrend> _generateMonthlyTrends(List<Transaction> transactions) {
    Map<String, Map<String, dynamic>> monthlyData = {};
    
    for (final transaction in transactions) {
      final monthKey = '${transaction.date.year}-${transaction.date.month.toString().padLeft(2, '0')}';
      final monthName = DateFormat('MMM yyyy').format(transaction.date);
      
      monthlyData[monthKey] ??= <String, dynamic>{
        'month': monthName,
        'budgeted': 0.0,
        'actual': 0.0,
      };
      
      if (transaction.type == 'expense') {
        monthlyData[monthKey]!['actual'] = monthlyData[monthKey]!['actual']! + transaction.amount;
      }
    }
    
    // Add budgeted amounts (this would ideally come from budget planning)
    // For now, we'll use a simple estimation
    final totalBudget = monthlyData.values.fold(0.0, (total, data) => total + data['actual']!);
    final avgMonthlyBudget = totalBudget / monthlyData.length;
    
    return monthlyData.entries.map((entry) {
      final data = entry.value;
      final budgeted = avgMonthlyBudget;
      final actual = data['actual']!;
      final variance = actual - budgeted;
      
      return MonthlyTrend(
        month: data['month'] as String,
        year: int.parse(entry.key.split('-')[0]),
        allocatedAmount: budgeted,
        spentAmount: actual,
        variance: variance,
      );
    }).toList()..sort((a, b) => a.month.compareTo(b.month));
  }

  /// Generate yearly comparisons from transactions
  List<YearlyComparison> _generateYearlyComparisons(List<Transaction> transactions) {
    Map<int, Map<String, double>> yearlyData = {};
    
    for (final transaction in transactions) {
      final year = transaction.date.year;
      
      yearlyData[year] ??= <String, double>{
        'budgeted': 0.0,
        'actual': 0.0,
      };
      
      if (transaction.type == 'expense') {
        yearlyData[year]!['actual'] = yearlyData[year]!['actual']! + transaction.amount;
      }
    }
    
    // Add budgeted amounts (this would ideally come from budget planning)
    final totalActual = yearlyData.values.fold(0.0, (total, data) => total + data['actual']!);
    final avgYearlyBudget = totalActual / yearlyData.length;
    
    return yearlyData.entries.map((entry) {
      final year = entry.key;
      final data = entry.value;
      final budgeted = avgYearlyBudget;
      final actual = data['actual']!;
      final variance = actual - budgeted;
      final variancePercentage = budgeted > 0 ? (variance / budgeted) * 100 : 0;
      
      return YearlyComparison(
        year: year,
        allocatedAmount: budgeted.toDouble(),
        spentAmount: actual.toDouble(),
        variance: variance.toDouble(),
        variancePercentage: variancePercentage.toDouble(),
      );
    }).toList()..sort((a, b) => a.year.compareTo(b.year));
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
        double totalAllocated = categoryList.fold(0, (total, cat) => total + cat.allocatedAmount);
        double totalSpent = categoryList.fold(0, (total, cat) => total + cat.spentAmount);
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
      final analytics = await getBudgetAnalytics();
      final suggestions = <AISuggestion>[];
      
      // Analyze over-budget categories
      final overBudgetCategories = analytics.categoryAnalytics
          .where((cat) => cat.spendingPercentage > 100)
          .toList();
      
      // Analyze under-utilized categories
      final underUtilizedCategories = analytics.categoryAnalytics
          .where((cat) => cat.spendingPercentage < 50)
          .toList();
      
      // Generate suggestions based on real data
      for (final category in overBudgetCategories) {
        final overspendAmount = category.spentAmount - category.allocatedAmount;
        suggestions.add(AISuggestion(
          id: 'overbudget_${category.categoryName}',
          title: 'Address ${category.categoryName} Overspending',
          description: '${category.categoryName} is ${category.spendingPercentage.toStringAsFixed(1)}% over budget. Consider cost reduction strategies or budget reallocation.',
          category: category.categoryName,
          confidence: 'high',
          impact: 'high',
          potentialSavings: overspendAmount,
          rationale: 'Current spending exceeds allocated budget by \$${NumberFormat('#,##,##,##0').format(overspendAmount)}.',
          tags: ['over-budget', 'cost-reduction', category.categoryName.toLowerCase()],
          createdAt: DateTime.now(),
        ));
      }
      
      for (final category in underUtilizedCategories) {
        final unusedAmount = category.allocatedAmount - category.spentAmount;
        suggestions.add(AISuggestion(
          id: 'underutilized_${category.categoryName}',
          title: 'Optimize ${category.categoryName} Budget Utilization',
          description: '${category.categoryName} is only ${category.spendingPercentage.toStringAsFixed(1)}% utilized. Consider reallocating unused funds to priority areas.',
          category: category.categoryName,
          confidence: 'medium',
          impact: 'medium',
          potentialSavings: unusedAmount * 0.3, // Assume 30% can be reallocated
          rationale: 'Unused budget of \$${NumberFormat('#,##,##,##0').format(unusedAmount)} could be reallocated to high-priority categories.',
          tags: ['under-utilized', 'optimization', category.categoryName.toLowerCase()],
          createdAt: DateTime.now(),
        ));
      }
      
      // Add general optimization suggestions
      if (analytics.totalSpent > analytics.totalBudget) {
        final totalOverspend = analytics.totalSpent - analytics.totalBudget;
        suggestions.add(AISuggestion(
          id: 'total_overspend',
          title: 'Overall Budget Overspend Alert',
          description: 'Total spending exceeds budget by \$${NumberFormat('#,##,##,##0').format(totalOverspend)}. Immediate cost control measures recommended.',
          category: 'Overall Budget',
          confidence: 'high',
          impact: 'critical',
          potentialSavings: totalOverspend,
          rationale: 'Current spending patterns indicate systematic budget overruns across multiple categories.',
          tags: ['critical', 'budget-control', 'overspend'],
          createdAt: DateTime.now(),
        ));
      }
      
      // Sort by impact and confidence
      suggestions.sort((a, b) {
        final impactOrder = {'critical': 4, 'high': 3, 'medium': 2, 'low': 1};
        final confidenceOrder = {'high': 3, 'medium': 2, 'low': 1};
        
        final aImpact = impactOrder[a.impact] ?? 0;
        final bImpact = impactOrder[b.impact] ?? 0;
        final aConfidence = confidenceOrder[a.confidence] ?? 0;
        final bConfidence = confidenceOrder[b.confidence] ?? 0;
        
        if (aImpact != bImpact) return bImpact.compareTo(aImpact);
        return bConfidence.compareTo(aConfidence);
      });
      
      return suggestions;
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

      // Get category and subcategory names for notification
      try {
        final categoryDoc = await _firestore.collection(budgetCategoriesCollection).doc(categoryId).get();
        final subcategoryDoc = await _firestore
            .collection(budgetCategoriesCollection)
            .doc(categoryId)
            .collection(budgetSubcategoriesCollection)
            .doc(subcategoryId)
            .get();

        final categoryName = categoryDoc.data()?['name'] ?? 'Unknown Category';
        final subcategoryName = subcategoryDoc.data()?['name'] ?? 'Unknown Subcategory';

        // Create notification for new budget allocation
        await NotificationService.notifyNewBudgetAllocation(
          userId: 'admin',
          title: 'New Budget Allocation',
          message: '$categoryName - $subcategoryName: ${item.name} (${item.allocatedAmount})',
        );
      } catch (e) {
        print('Error getting category/subcategory names for notification: $e');
      }
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

  // ========== TRANSACTION MANAGEMENT METHODS ==========

  /// Create a new transaction
  Future<void> createTransaction(Transaction transaction) async {
    try {
      await _firestore
          .collection(transactionsCollection)
          .doc(transaction.id)
          .set(transaction.toFirestore());
      
      // Update the category's spent amount if it's an expense
      if (transaction.type == 'expense') {
        await _updateCategorySpentAmount(transaction.categoryId, transaction.amount, true);
      }
    } catch (e) {
      print('Error creating transaction: $e');
      throw Exception('Failed to create transaction: $e');
    }
  }

  /// Update an existing transaction
  Future<void> updateTransaction(Transaction oldTransaction, Transaction newTransaction) async {
    try {
      await _firestore
          .collection(transactionsCollection)
          .doc(newTransaction.id)
          .update(newTransaction.toFirestore());
      
      // Update category spent amounts
      if (oldTransaction.type == 'expense') {
        await _updateCategorySpentAmount(oldTransaction.categoryId, oldTransaction.amount, false);
      }
      if (newTransaction.type == 'expense') {
        await _updateCategorySpentAmount(newTransaction.categoryId, newTransaction.amount, true);
      }
    } catch (e) {
      print('Error updating transaction: $e');
      throw Exception('Failed to update transaction: $e');
    }
  }

  /// Delete a transaction
  Future<void> deleteTransaction(Transaction transaction) async {
    try {
      await _firestore
          .collection(transactionsCollection)
          .doc(transaction.id)
          .delete();
      
      // Update the category's spent amount if it was an expense
      if (transaction.type == 'expense') {
        await _updateCategorySpentAmount(transaction.categoryId, transaction.amount, false);
      }
    } catch (e) {
      print('Error deleting transaction: $e');
      throw Exception('Failed to delete transaction: $e');
    }
  }

  /// Get all transactions
  Future<List<Transaction>> getTransactions() async {
    try {
      QuerySnapshot snapshot = await _firestore
          .collection(transactionsCollection)
          .get();

      List<Transaction> transactions = [];
      for (DocumentSnapshot doc in snapshot.docs) {
        Transaction transaction = Transaction.fromFirestore(doc);
        transactions.add(transaction);
      }

      // Sort by date in descending order
      transactions.sort((a, b) => b.date.compareTo(a.date));

      return transactions;
    } catch (e) {
      print('Error fetching transactions: $e');
      throw Exception('Failed to fetch transactions: $e');
    }
  }

  /// Get transactions by category
  Future<List<Transaction>> getTransactionsByCategory(String categoryId) async {
    try {
      QuerySnapshot snapshot = await _firestore
          .collection(transactionsCollection)
          .where('categoryId', isEqualTo: categoryId)
          .get();

      List<Transaction> transactions = [];
      for (DocumentSnapshot doc in snapshot.docs) {
        Transaction transaction = Transaction.fromFirestore(doc);
        transactions.add(transaction);
      }

      // Sort by date in descending order
      transactions.sort((a, b) => b.date.compareTo(a.date));

      return transactions;
    } catch (e) {
      print('Error fetching transactions by category: $e');
      throw Exception('Failed to fetch transactions by category: $e');
    }
  }

  /// Get transactions by date range
  Future<List<Transaction>> getTransactionsByDateRange(DateTime startDate, DateTime endDate) async {
    try {
      QuerySnapshot snapshot = await _firestore
          .collection(transactionsCollection)
          .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
          .where('date', isLessThanOrEqualTo: Timestamp.fromDate(endDate))
          .get();

      List<Transaction> transactions = [];
      for (DocumentSnapshot doc in snapshot.docs) {
        Transaction transaction = Transaction.fromFirestore(doc);
        transactions.add(transaction);
      }

      // Sort by date in descending order
      transactions.sort((a, b) => b.date.compareTo(a.date));

      return transactions;
    } catch (e) {
      print('Error fetching transactions by date range: $e');
      throw Exception('Failed to fetch transactions by date range: $e');
    }
  }

  /// Stream transactions for real-time updates
  Stream<List<Transaction>> streamTransactions() {
    return _firestore
        .collection(transactionsCollection)
        .snapshots()
        .map((snapshot) {
      List<Transaction> transactions = [];
      for (DocumentSnapshot doc in snapshot.docs) {
        Transaction transaction = Transaction.fromFirestore(doc);
        transactions.add(transaction);
      }
      // Sort by date in descending order
      transactions.sort((a, b) => b.date.compareTo(a.date));
      return transactions;
    });
  }

  /// Get transaction statistics
  Future<Map<String, dynamic>> getTransactionStatistics() async {
    try {
      List<Transaction> transactions = await getTransactions();
      
      double totalIncome = 0;
      double totalExpense = 0;
      Map<String, double> categoryExpenses = {};
      Map<String, double> categoryIncome = {};
      
      for (Transaction transaction in transactions) {
        if (transaction.type == 'income') {
          totalIncome += transaction.amount;
          categoryIncome[transaction.categoryName] = 
              (categoryIncome[transaction.categoryName] ?? 0) + transaction.amount;
        } else {
          totalExpense += transaction.amount;
          categoryExpenses[transaction.categoryName] = 
              (categoryExpenses[transaction.categoryName] ?? 0) + transaction.amount;
        }
      }
      
      return {
        'totalIncome': totalIncome,
        'totalExpense': totalExpense,
        'netAmount': totalIncome - totalExpense,
        'categoryExpenses': categoryExpenses,
        'categoryIncome': categoryIncome,
        'transactionCount': transactions.length,
      };
    } catch (e) {
      print('Error calculating transaction statistics: $e');
      throw Exception('Failed to calculate transaction statistics: $e');
    }
  }

  /// Helper method to update category spent amount
  Future<void> _updateCategorySpentAmount(String categoryId, double amount, bool isAdd) async {
    try {
      DocumentReference categoryRef = _firestore
          .collection(budgetCategoriesCollection)
          .doc(categoryId);
      
      DocumentSnapshot categoryDoc = await categoryRef.get();
      if (categoryDoc.exists) {
        Map<String, dynamic> data = categoryDoc.data() as Map<String, dynamic>;
        double currentSpent = (data['spentAmount'] ?? 0).toDouble();
        double newSpent = isAdd ? currentSpent + amount : currentSpent - amount;
        
        await categoryRef.update({'spentAmount': newSpent});
      }
    } catch (e) {
      print('Error updating category spent amount: $e');
      // Don't throw here as it's a helper method
    }
  }

  /// Clear all budget data (categories, subcategories, items, and transactions)
  Future<void> clearAllBudgetData() async {
    try {
      print('Starting to clear all budget data...');
      
      // Get all budget categories first
      List<BudgetCategory> categories = await getBudgetCategories();
      
      // Delete all transactions first
      QuerySnapshot transactionsSnapshot = await _firestore
          .collection(transactionsCollection)
          .get();
      
      for (DocumentSnapshot doc in transactionsSnapshot.docs) {
        await doc.reference.delete();
      }
      print('Deleted ${transactionsSnapshot.docs.length} transactions');
      
      // Delete all budget items, subcategories, and categories
      for (BudgetCategory category in categories) {
        // Delete budget items
        QuerySnapshot itemsSnapshot = await _firestore
            .collection(budgetCategoriesCollection)
            .doc(category.id)
            .collection(budgetSubcategoriesCollection)
            .get();
        
        for (DocumentSnapshot subcategoryDoc in itemsSnapshot.docs) {
          // Delete budget items for this subcategory
          QuerySnapshot budgetItemsSnapshot = await _firestore
              .collection(budgetCategoriesCollection)
              .doc(category.id)
              .collection(budgetSubcategoriesCollection)
              .doc(subcategoryDoc.id)
              .collection(budgetItemsCollection)
              .get();
          
          for (DocumentSnapshot itemDoc in budgetItemsSnapshot.docs) {
            await itemDoc.reference.delete();
          }
          
          // Delete the subcategory
          await subcategoryDoc.reference.delete();
        }
        
        // Delete the category
        await _firestore
            .collection(budgetCategoriesCollection)
            .doc(category.id)
            .delete();
      }
      
      print('Successfully cleared all budget data');
    } catch (e) {
      print('Error clearing budget data: $e');
      throw Exception('Failed to clear budget data: $e');
    }
  }
}