import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:excel/excel.dart';
import 'dart:convert';
import '../models/budget_models.dart';

class BudgetService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Categories CRUD
  Future<List<BudgetCategory>> getCategories() async {
    try {
      final snapshot = await _firestore.collection('budget_categories').get();
      final categories = <BudgetCategory>[];
      
      for (final doc in snapshot.docs) {
        final data = doc.data();
        data['id'] = doc.id;
        final category = BudgetCategory.fromMap(data);
        
        // Fetch subcategories for this category
        try {
          final subcategories = await getSubcategories(category.id);
          final updatedCategory = BudgetCategory(
            id: category.id,
            name: category.name,
            description: category.description,
            allocatedAmount: category.allocatedAmount,
            spentAmount: category.spentAmount,
            color: category.color,
            createdAt: category.createdAt,
            subcategories: subcategories,
          );
          categories.add(updatedCategory);
        } catch (e) {
          // If subcategories fail to load, add category without them
          categories.add(category);
        }
      }
      
      return categories;
    } catch (e) {
      throw Exception('Failed to fetch categories: $e');
    }
  }

  Future<void> createCategory(BudgetCategory category) async {
    try {
      await _firestore.collection('budget_categories').add(category.toMap());
    } catch (e) {
      throw Exception('Failed to create category: $e');
    }
  }

  Future<void> updateCategory(BudgetCategory category) async {
    try {
      await _firestore
          .collection('budget_categories')
          .doc(category.id)
          .update(category.toMap());
    } catch (e) {
      throw Exception('Failed to update category: $e');
    }
  }

  Future<void> deleteCategory(String categoryId) async {
    try {
      await _firestore.collection('budget_categories').doc(categoryId).delete();
    } catch (e) {
      throw Exception('Failed to delete category: $e');
    }
  }

  // Subcategories CRUD
  Future<List<BudgetSubcategory>> getSubcategories(String categoryId) async {
    try {
      final snapshot = await _firestore
          .collection('budget_subcategories')
          .where('categoryId', isEqualTo: categoryId)
          .get();
      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return BudgetSubcategory.fromMap(data);
      }).toList();
    } catch (e) {
      throw Exception('Failed to fetch subcategories: $e');
    }
  }

  Future<void> createSubcategory(BudgetSubcategory subcategory) async {
    try {
      await _firestore.collection('budget_subcategories').add(subcategory.toMap());
    } catch (e) {
      throw Exception('Failed to create subcategory: $e');
    }
  }

  Future<void> updateSubcategory(BudgetSubcategory subcategory) async {
    try {
      await _firestore
          .collection('budget_subcategories')
          .doc(subcategory.id)
          .update(subcategory.toMap());
    } catch (e) {
      throw Exception('Failed to update subcategory: $e');
    }
  }

  Future<void> deleteSubcategory(String subcategoryId) async {
    try {
      await _firestore.collection('budget_subcategories').doc(subcategoryId).delete();
    } catch (e) {
      throw Exception('Failed to delete subcategory: $e');
    }
  }

  // Budget Entries CRUD
  Future<List<BudgetEntry>> getBudgetEntries() async {
    try {
      final snapshot = await _firestore.collection('budget_entries').get();
      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return BudgetEntry.fromMap(data);
      }).toList();
    } catch (e) {
      throw Exception('Failed to fetch budget entries: $e');
    }
  }

  Future<void> createBudgetEntry(BudgetEntry entry) async {
    try {
      await _firestore.collection('budget_entries').add(entry.toMap());
    } catch (e) {
      throw Exception('Failed to create budget entry: $e');
    }
  }

  // Excel Upload
  Future<List<BudgetCategory>> uploadExcelBudget(List<int> bytes) async {
    try {
      print('Starting Excel processing...');
      print('Bytes received: ${bytes.length}');
      
      // Try to decode Excel file
      Excel? excel;
      try {
        excel = Excel.decodeBytes(bytes);
        print('Excel decoded successfully');
      } catch (excelError) {
        print('Excel decode failed: $excelError');
        // Try alternative approach for corrupted files
        throw Exception('Invalid Excel file format. Please ensure the file is a valid .xlsx or .xls file.');
      }
      
      if (excel == null) {
        throw Exception('Failed to decode Excel file');
      }
      
      print('Tables found: ${excel.tables.keys.length}');
      final categories = <BudgetCategory>[];

      for (var table in excel.tables.keys) {
        print('Processing table: $table');
        final sheet = excel.tables[table]!;
        print('Sheet max rows: ${sheet.maxRows}');
        
        // Skip if no data
        if (sheet.maxRows <= 1) {
          print('Sheet has no data rows');
          continue;
        }
        
        for (int row = 1; row < sheet.maxRows; row++) {
          try {
            final categoryName = sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: row)).value?.toString();
            final description = sheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: row)).value?.toString();
            final amount = sheet.cell(CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: row)).value?.toString();
            final spentAmount = sheet.cell(CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: row)).value?.toString();

            print('Row $row: Name="$categoryName", Desc="$description", Amount="$amount", Spent="$spentAmount"');

            if (categoryName != null && categoryName.isNotEmpty && amount != null && amount.isNotEmpty) {
              // Clean up the amount string (remove currency symbols, commas, etc.)
              final cleanAmount = amount.replaceAll(RegExp(r'[^\d.]'), '');
              final parsedAmount = double.tryParse(cleanAmount);
              
              if (parsedAmount != null && parsedAmount > 0) {
                // Parse spent amount
                final cleanSpentAmount = (spentAmount ?? '0').replaceAll(RegExp(r'[^\d.]'), '');
                final parsedSpentAmount = double.tryParse(cleanSpentAmount) ?? 0.0;
                
                final category = BudgetCategory(
                  id: DateTime.now().millisecondsSinceEpoch.toString() + '_$row',
                  name: categoryName.trim(),
                  description: description?.trim() ?? '',
                  allocatedAmount: parsedAmount,
                  spentAmount: parsedSpentAmount,
                  color: _getRandomColor(),
                  createdAt: DateTime.now(),
                );
                categories.add(category);
                print('Added category: ${category.name} with amount: ${category.allocatedAmount}');
              } else {
                print('Invalid amount format: $amount (cleaned: $cleanAmount)');
              }
            } else {
              print('Skipping row $row - missing required data');
            }
          } catch (rowError) {
            print('Error processing row $row: $rowError');
            continue; // Skip problematic rows
          }
        }
      }

      print('Total categories processed: ${categories.length}');
      if (categories.isEmpty) {
        throw Exception('No valid budget categories found in the Excel file. Please check the file format.');
      }
      
      return categories;
    } catch (e) {
      print('Error in Excel processing: $e');
      throw Exception('Failed to process Excel file: $e');
    }
  }

  // CSV Upload
  Future<List<BudgetCategory>> uploadCSVBudget(List<int> bytes) async {
    try {
      print('Starting CSV processing...');
      print('Bytes received: ${bytes.length}');
      
      // Convert bytes to string
      final csvString = utf8.decode(bytes);
      print('CSV string length: ${csvString.length}');
      
      // Split into lines
      final lines = csvString.split('\n');
      print('Total lines: ${lines.length}');
      
      final categories = <BudgetCategory>[];
      
      // Skip header row (line 0) and process data rows
      for (int i = 1; i < lines.length; i++) {
        final line = lines[i].trim();
        if (line.isEmpty) continue; // Skip empty lines
        
        try {
          // Simple CSV parsing - split by comma
          // For more robust CSV parsing, consider using a CSV library
          final parts = parseCSVLine(line);
          
          if (parts.length >= 3) {
            final categoryName = parts[0].trim();
            final description = parts[1].trim();
            final amount = parts[2].trim();
            final spentAmount = parts.length >= 4 ? parts[3].trim() : '0';
            
            print('Row $i: Name="$categoryName", Desc="$description", Amount="$amount"');
            
            if (categoryName.isNotEmpty && amount.isNotEmpty) {
              // Clean up the amount string (remove currency symbols, commas, etc.)
              final cleanAmount = amount.replaceAll(RegExp(r'[^\d.]'), '');
              final parsedAmount = double.tryParse(cleanAmount);
              
              if (parsedAmount != null && parsedAmount > 0) {
                // Parse spent amount
                final cleanSpentAmount = spentAmount.replaceAll(RegExp(r'[^\d.]'), '');
                final parsedSpentAmount = double.tryParse(cleanSpentAmount) ?? 0.0;
                
                final category = BudgetCategory(
                  id: DateTime.now().millisecondsSinceEpoch.toString() + '_$i',
                  name: categoryName,
                  description: description,
                  allocatedAmount: parsedAmount,
                  spentAmount: parsedSpentAmount,
                  color: _getRandomColor(),
                  createdAt: DateTime.now(),
                );
                categories.add(category);
                print('Added category: ${category.name} with amount: ${category.allocatedAmount}');
              } else {
                print('Invalid amount format: $amount (cleaned: $cleanAmount)');
              }
            } else {
              print('Skipping row $i - missing required data');
            }
          } else {
            print('Skipping row $i - insufficient columns (${parts.length})');
          }
        } catch (rowError) {
          print('Error processing row $i: $rowError');
          continue; // Skip problematic rows
        }
      }
      
      print('Total categories processed: ${categories.length}');
      if (categories.isEmpty) {
        throw Exception('No valid budget categories found in the CSV file. Please check the file format.');
      }
      
      return categories;
    } catch (e) {
      print('Error in CSV processing: $e');
      throw Exception('Failed to process CSV file: $e');
    }
  }

  // Universal file upload method that detects file type
  Future<List<BudgetCategory>> uploadBudgetFile(List<int> bytes, String fileName) async {
    final extension = fileName.split('.').last.toLowerCase();
    
    switch (extension) {
      case 'csv':
        return await uploadCSVBudget(bytes);
      case 'xlsx':
      case 'xls':
        return await uploadExcelBudget(bytes);
      default:
        throw Exception('Unsupported file format. Please use CSV (.csv) or Excel (.xlsx, .xls) files.');
    }
  }

  // Helper method to parse CSV lines, handling quoted fields
  List<String> parseCSVLine(String line) {
    final result = <String>[];
    final buffer = StringBuffer();
    bool inQuotes = false;
    
    for (int i = 0; i < line.length; i++) {
      final char = line[i];
      
      if (char == '"') {
        inQuotes = !inQuotes;
      } else if (char == ',' && !inQuotes) {
        result.add(buffer.toString());
        buffer.clear();
      } else {
        buffer.write(char);
      }
    }
    
    // Add the last field
    result.add(buffer.toString());
    
    // Remove quotes from fields
    return result.map((field) => field.replaceAll('"', '')).toList();
  }

  // Analytics
  Future<BudgetAnalytics> getBudgetAnalytics() async {
    try {
      final categories = await getCategories();
      final entries = await getBudgetEntries();

      double totalBudget = 0;
      double totalSpent = 0;

      final categoryAnalytics = <CategoryAnalytics>[];
      final monthlyTrends = <MonthlyTrend>[];
      final yearlyComparisons = <YearlyComparison>[];

      // Calculate totals and category analytics
      for (final category in categories) {
        totalBudget += category.allocatedAmount;
        totalSpent += category.spentAmount;

        categoryAnalytics.add(CategoryAnalytics(
          categoryName: category.name,
          allocatedAmount: category.allocatedAmount,
          spentAmount: category.spentAmount,
          utilizationPercentage: category.utilizationPercentage,
          color: category.color,
        ));
      }

      // Generate monthly trends (mock data for now)
      final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun'];
      for (int i = 0; i < months.length; i++) {
        final budgeted = totalBudget / 12;
        final actual = budgeted * (0.8 + (i * 0.1));
        monthlyTrends.add(MonthlyTrend(
          month: months[i],
          budgeted: budgeted,
          actual: actual,
          variance: actual - budgeted,
        ));
      }

      // Generate yearly comparisons (mock data for now)
      final currentYear = DateTime.now().year;
      double previousYearBudget = 0;
      
      for (int year = currentYear - 2; year <= currentYear; year++) {
        final yearBudget = totalBudget * (0.9 + (year - currentYear + 2) * 0.1);
        final yearSpent = yearBudget * 0.85;
        
        // Calculate growth rate (compared to previous year)
        double growthRate = 0;
        if (previousYearBudget > 0) {
          growthRate = ((yearBudget - previousYearBudget) / previousYearBudget) * 100;
        }
        
        yearlyComparisons.add(YearlyComparison(
          year: year,
          totalBudget: yearBudget,
          totalSpent: yearSpent,
          utilizationPercentage: (yearSpent / yearBudget) * 100,
          growthRate: growthRate,
        ));
        
        previousYearBudget = yearBudget;
      }

      return BudgetAnalytics(
        totalBudget: totalBudget,
        totalSpent: totalSpent,
        totalRemaining: totalBudget - totalSpent,
        categoryAnalytics: categoryAnalytics,
        monthlyTrends: monthlyTrends,
        yearlyComparisons: yearlyComparisons,
      );
    } catch (e) {
      throw Exception('Failed to generate analytics: $e');
    }
  }

  // Get categories grouped by name with individual entries
  Future<Map<String, List<BudgetCategory>>> getGroupedCategories() async {
    try {
      final categories = await getCategories();
      final Map<String, List<BudgetCategory>> groupedCategories = {};
      
      for (final category in categories) {
        final key = category.name.trim().toLowerCase();
        if (groupedCategories.containsKey(key)) {
          groupedCategories[key]!.add(category);
        } else {
          groupedCategories[key] = [category];
        }
      }
      
      return groupedCategories;
    } catch (e) {
      throw Exception('Failed to fetch grouped categories: $e');
    }
  }

  // Get grouped analytics with individual entries
  Future<Map<String, CategoryGroupAnalytics>> getGroupedAnalytics() async {
    try {
      final groupedCategories = await getGroupedCategories();
      final Map<String, CategoryGroupAnalytics> groupedAnalytics = {};
      
      for (final entry in groupedCategories.entries) {
        final categoryName = entry.value.first.name; // Use the first category's name
        final categoryColor = entry.value.first.color; // Use the first category's color
        
        // Calculate totals for the group
        double totalAllocated = 0;
        double totalSpent = 0;
        
        for (final category in entry.value) {
          totalAllocated += category.allocatedAmount;
          totalSpent += category.spentAmount;
        }
        
        groupedAnalytics[entry.key] = CategoryGroupAnalytics(
          categoryName: categoryName,
          totalAllocated: totalAllocated,
          totalSpent: totalSpent,
          totalRemaining: totalAllocated - totalSpent,
          utilizationPercentage: (totalSpent / totalAllocated) * 100,
          color: categoryColor,
          individualEntries: entry.value,
        );
      }
      
      return groupedAnalytics;
    } catch (e) {
      throw Exception('Failed to generate grouped analytics: $e');
    }
  }

  // AI Suggestions
  Future<List<AISuggestion>> getAISuggestions() async {
    try {
      // Mock AI suggestions based on common government budget patterns
      return [
        AISuggestion(
          category: 'Infrastructure Development',
          suggestion: 'Increase allocation by 15%',
          recommendedAmount: 50000000,
          reasoning: 'Based on historical data and current infrastructure needs',
          confidence: 'high',
        ),
        AISuggestion(
          category: 'Healthcare',
          suggestion: 'Maintain current allocation',
          recommendedAmount: 30000000,
          reasoning: 'Current spending patterns are optimal',
          confidence: 'medium',
        ),
        AISuggestion(
          category: 'Education',
          suggestion: 'Reduce allocation by 5%',
          recommendedAmount: 25000000,
          reasoning: 'Underutilization in previous quarters',
          confidence: 'high',
        ),
        AISuggestion(
          category: 'Public Safety',
          suggestion: 'Increase allocation by 10%',
          recommendedAmount: 20000000,
          reasoning: 'Rising security requirements',
          confidence: 'medium',
        ),
      ];
    } catch (e) {
      throw Exception('Failed to generate AI suggestions: $e');
    }
  }

  // Utility methods
  String _getRandomColor() {
    final colors = [
      '#FF6B6B', '#4ECDC4', '#45B7D1', '#96CEB4', '#FFEAA7',
      '#DDA0DD', '#98D8C8', '#F7DC6F', '#BB8FCE', '#85C1E9'
    ];
    return colors[DateTime.now().millisecond % colors.length];
  }

  // Sample data generation
  Future<void> generateSampleData() async {
    try {
      final sampleCategories = [
        BudgetCategory(
          id: '1',
          name: 'Infrastructure Development',
          description: 'Roads, bridges, and public facilities',
          allocatedAmount: 50000000,
          spentAmount: 35000000,
          color: '#FF6B6B',
          createdAt: DateTime.now(),
        ),
        BudgetCategory(
          id: '2',
          name: 'Healthcare',
          description: 'Medical facilities and services',
          allocatedAmount: 30000000,
          spentAmount: 22000000,
          color: '#4ECDC4',
          createdAt: DateTime.now(),
        ),
        BudgetCategory(
          id: '3',
          name: 'Education',
          description: 'Schools and educational programs',
          allocatedAmount: 25000000,
          spentAmount: 18000000,
          color: '#45B7D1',
          createdAt: DateTime.now(),
        ),
        BudgetCategory(
          id: '4',
          name: 'Public Safety',
          description: 'Police, fire, and emergency services',
          allocatedAmount: 20000000,
          spentAmount: 15000000,
          color: '#96CEB4',
          createdAt: DateTime.now(),
        ),
      ];

      for (final category in sampleCategories) {
        await createCategory(category);
      }
    } catch (e) {
      throw Exception('Failed to generate sample data: $e');
    }
  }
}
