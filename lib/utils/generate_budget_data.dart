import '../models/budget_models.dart';
import '../services/budget_service.dart';

class BudgetDataGenerator {
  static final BudgetService _budgetService = BudgetService();

  static Future<void> generateSampleBudgetData() async {
    try {
      // Generate comprehensive sample categories
      final sampleCategories = [
        BudgetCategory(
          id: '1',
          name: 'Infrastructure Development',
          description: 'Roads, bridges, public buildings, and utilities',
          allocatedAmount: 120000000, // $120 Crores
          spentAmount: 85000000,      // $85 Crores spent (70.8% utilization)
          color: '#2196F3', // Blue
          createdAt: DateTime.now(),
          subcategories: [
            BudgetSubcategory(
              id: '1_1',
              name: 'Road Construction',
              description: 'New road construction and maintenance',
              allocatedAmount: 70000000,
              spentAmount: 52000000,
              color: '#4A90E2',
              createdAt: DateTime.now(),
              categoryId: '1',
            ),
            BudgetSubcategory(
              id: '1_2',
              name: 'Bridge Development',
              description: 'Bridge construction and repair',
              allocatedAmount: 30000000,
              spentAmount: 21000000,
              color: '#4A90E2',
              createdAt: DateTime.now(),
              categoryId: '1',
            ),
            BudgetSubcategory(
              id: '1_3',
              name: 'Public Buildings',
              description: 'Government buildings and facilities',
              allocatedAmount: 20000000,
              spentAmount: 12000000,
              color: '#4A90E2',
              createdAt: DateTime.now(),
              categoryId: '1',
            ),
          ],
        ),
        BudgetCategory(
          id: '2',
          name: 'Healthcare',
          description: 'Medical facilities, equipment, and services',
          allocatedAmount: 80000000,  // $80 Crores
          spentAmount: 65000000,      // $65 Crores spent (81.3% utilization)
          color: '#4CAF50', // Green
          createdAt: DateTime.now(),
          subcategories: [
            BudgetSubcategory(
              id: '2_1',
              name: 'Hospital Equipment',
              description: 'Medical equipment and machinery',
              allocatedAmount: 35000000,
              spentAmount: 28000000,
              color: '#4A90E2',
              createdAt: DateTime.now(),
              categoryId: '2',
            ),
            BudgetSubcategory(
              id: '2_2',
              name: 'Medicine Procurement',
              description: 'Essential medicines and supplies',
              allocatedAmount: 25000000,
              spentAmount: 22000000,
              color: '#4A90E2',
              createdAt: DateTime.now(),
              categoryId: '2',
            ),
            BudgetSubcategory(
              id: '2_3',
              name: 'Staff Training',
              description: 'Medical staff training and development',
              allocatedAmount: 20000000,
              spentAmount: 15000000,
              color: '#4A90E2',
              createdAt: DateTime.now(),
              categoryId: '2',
            ),
          ],
        ),
        BudgetCategory(
          id: '3',
          name: 'Education',
          description: 'Schools, colleges, educational programs',
          allocatedAmount: 95000000,  // $95 Crores
          spentAmount: 62000000,      // $62 Crores spent (65.3% utilization)
          color: '#FF9800', // Orange
          createdAt: DateTime.now(),
          subcategories: [
            BudgetSubcategory(
              id: '3_1',
              name: 'School Infrastructure',
              description: 'New schools and classroom construction',
              allocatedAmount: 50000000,
              spentAmount: 30000000,
              color: '#4A90E2',
              createdAt: DateTime.now(),
              categoryId: '3',
            ),
            BudgetSubcategory(
              id: '3_2',
              name: 'Digital Learning',
              description: 'Computers, tablets, and digital resources',
              allocatedAmount: 25000000,
              spentAmount: 18000000,
              color: '#4A90E2',
              createdAt: DateTime.now(),
              categoryId: '3',
            ),
            BudgetSubcategory(
              id: '3_3',
              name: 'Teacher Training',
              description: 'Professional development for educators',
              allocatedAmount: 20000000,
              spentAmount: 14000000,
              color: '#4A90E2',
              createdAt: DateTime.now(),
              categoryId: '3',
            ),
          ],
        ),
        BudgetCategory(
          id: '4',
          name: 'Public Safety',
          description: 'Police, fire department, emergency services',
          allocatedAmount: 60000000,  // $60 Crores
          spentAmount: 52000000,      // $52 Crores spent (86.7% utilization)
          color: '#F44336', // Red
          createdAt: DateTime.now(),
          subcategories: [
            BudgetSubcategory(
              id: '4_1',
              name: 'Police Equipment',
              description: 'Vehicles, communication, and safety gear',
              allocatedAmount: 30000000,
              spentAmount: 27000000,
              color: '#4A90E2',
              createdAt: DateTime.now(),
              categoryId: '4',
            ),
            BudgetSubcategory(
              id: '4_2',
              name: 'Fire Department',
              description: 'Fire trucks, equipment, and training',
              allocatedAmount: 20000000,
              spentAmount: 17000000,
              color: '#4A90E2',
              createdAt: DateTime.now(),
              categoryId: '4',
            ),
            BudgetSubcategory(
              id: '4_3',
              name: 'Emergency Services',
              description: 'Ambulances and emergency response',
              allocatedAmount: 10000000,
              spentAmount: 8000000,
              color: '#4A90E2',
              createdAt: DateTime.now(),
              categoryId: '4',
            ),
          ],
        ),
        BudgetCategory(
          id: '5',
          name: 'Social Welfare',
          description: 'Poverty alleviation and social programs',
          allocatedAmount: 75000000,  // $75 Crores
          spentAmount: 58000000,      // $58 Crores spent (77.3% utilization)
          color: '#9C27B0', // Purple
          createdAt: DateTime.now(),
          subcategories: [
            BudgetSubcategory(
              id: '5_1',
              name: 'Food Security',
              description: 'Public distribution system and nutrition',
              allocatedAmount: 40000000,
              spentAmount: 32000000,
              color: '#4A90E2',
              createdAt: DateTime.now(),
              categoryId: '5',
            ),
            BudgetSubcategory(
              id: '5_2',
              name: 'Housing for Poor',
              description: 'Affordable housing schemes',
              allocatedAmount: 25000000,
              spentAmount: 18000000,
              color: '#4A90E2',
              createdAt: DateTime.now(),
              categoryId: '5',
            ),
            BudgetSubcategory(
              id: '5_3',
              name: 'Skill Development',
              description: 'Vocational training programs',
              allocatedAmount: 10000000,
              spentAmount: 8000000,
              color: '#4A90E2',
              createdAt: DateTime.now(),
              categoryId: '5',
            ),
          ],
        ),
        BudgetCategory(
          id: '6',
          name: 'Environment & Parks',
          description: 'Green spaces, waste management, pollution control',
          allocatedAmount: 45000000,  // $45 Crores
          spentAmount: 28000000,      // $28 Crores spent (62.2% utilization)
          color: '#4CAF50', // Green
          createdAt: DateTime.now(),
          subcategories: [
            BudgetSubcategory(
              id: '6_1',
              name: 'Waste Management',
              description: 'Garbage collection and processing',
              allocatedAmount: 25000000,
              spentAmount: 18000000,
              color: '#4A90E2',
              createdAt: DateTime.now(),
              categoryId: '6',
            ),
            BudgetSubcategory(
              id: '6_2',
              name: 'Park Development',
              description: 'Public parks and recreation areas',
              allocatedAmount: 15000000,
              spentAmount: 8000000,
              color: '#4A90E2',
              createdAt: DateTime.now(),
              categoryId: '6',
            ),
            BudgetSubcategory(
              id: '6_3',
              name: 'Tree Plantation',
              description: 'Urban forestry and green cover',
              allocatedAmount: 5000000,
              spentAmount: 2000000,
              color: '#4A90E2',
              createdAt: DateTime.now(),
              categoryId: '6',
            ),
          ],
        ),
      ];

      // Save categories to Firestore
      for (final category in sampleCategories) {
        await _budgetService.createCategory(category);
        print('Created category: ${category.name}');
      }

      // Generate sample budget entries (transactions)
      final sampleEntries = [
        // Infrastructure entries
        BudgetEntry(
          id: 'entry_1',
          categoryName: 'Infrastructure',
          subcategoryName: 'Road Construction',
          itemName: 'Highway expansion project - Phase 1',
          allocatedAmount: 15000000,
          spentAmount: 12000000,
          description: 'Major highway project for traffic improvement',
          createdAt: DateTime.now().subtract(const Duration(days: 30)),
          amount: 15000000,
        ),
        BudgetEntry(
          id: 'entry_2',
          categoryName: 'Infrastructure',
          subcategoryName: 'Bridge Development',
          itemName: 'City bridge repair and maintenance',
          allocatedAmount: 8000000,
          spentAmount: 6500000,
          description: 'Essential bridge maintenance for safety',
          createdAt: DateTime.now().subtract(const Duration(days: 45)),
          amount: 8000000,
        ),
        BudgetEntry(
          id: 'entry_3',
          categoryName: 'Infrastructure',
          subcategoryName: 'Public Buildings',
          itemName: 'New district office construction',
          allocatedAmount: 5000000,
          spentAmount: 3500000,
          description: 'Modern district administrative building',
          createdAt: DateTime.now().subtract(const Duration(days: 20)),
          amount: 5000000,
        ),
        
        // Healthcare entries
        BudgetEntry(
          id: 'entry_4',
          categoryName: 'Healthcare',
          subcategoryName: 'Hospital Services',
          itemName: 'MRI machine procurement for district hospital',
          allocatedAmount: 12000000,
          spentAmount: 10000000,
          description: 'Advanced medical equipment for better diagnosis',
          createdAt: DateTime.now().subtract(const Duration(days: 60)),
        ),
        BudgetEntry(
          id: 'entry_5',
          categoryName: 'Healthcare',
          subcategoryName: 'Primary Healthcare',
          itemName: 'Emergency medicine stock for 6 months',
          allocatedAmount: 8000000,
          spentAmount: 6500000,
          description: 'Essential medicines for public health',
          createdAt: DateTime.now().subtract(const Duration(days: 15)),
          amount: 8000000,
        ),
        
        // Education entries
        BudgetEntry(
          id: 'entry_6',
          categoryName: 'Education',
          subcategoryName: 'School Infrastructure',
          itemName: 'Primary school construction - 5 schools',
          allocatedAmount: 18000000,
          spentAmount: 15000000,
          description: 'New schools in rural areas',
          createdAt: DateTime.now().subtract(const Duration(days: 90)),
        ),
        BudgetEntry(
          id: 'entry_7',
          categoryName: 'Education',
          subcategoryName: 'Teacher Training',
          itemName: 'Tablets for digital learning initiative',
          allocatedAmount: 7000000,
          spentAmount: 5500000,
          description: '1000 tablets for government schools',
          createdAt: DateTime.now().subtract(const Duration(days: 25)),
        ),
        
        // Public Safety entries
        BudgetEntry(
          id: 'entry_8',
          categoryName: 'Security',
          subcategoryName: 'Police Services',
          itemName: 'Police vehicles - 20 patrol cars',
          allocatedAmount: 15000000,
          spentAmount: 12000000,
          description: 'Enhanced patrol coverage for city',
          createdAt: DateTime.now().subtract(const Duration(days: 40)),
          amount: 15000000,
        ),
        BudgetEntry(
          id: 'entry_9',
          categoryName: 'Security',
          subcategoryName: 'Emergency Response',
          itemName: 'Fire station equipment upgrade',
          allocatedAmount: 6000000,
          spentAmount: 4500000,
          description: 'Modern firefighting equipment',
          createdAt: DateTime.now().subtract(const Duration(days: 35)),
          amount: 6000000,
        ),
        
        // Social Welfare entries
        BudgetEntry(
          id: 'entry_10',
          categoryName: 'Social Welfare',
          subcategoryName: 'Pension Programs',
          itemName: 'Food distribution for 10,000 families',
          allocatedAmount: 12000000,
          spentAmount: 10000000,
          description: 'Monthly food security program',
          createdAt: DateTime.now().subtract(const Duration(days: 10)),
          amount: 12000000,
        ),
        BudgetEntry(
          id: 'entry_11',
          categoryName: 'Social Welfare',
          subcategoryName: 'Food Security',
          itemName: 'Affordable housing - 100 units',
          allocatedAmount: 8000000,
          spentAmount: 7500000,
          description: 'Housing for economically weaker sections',
          createdAt: DateTime.now().subtract(const Duration(days: 50)),
          amount: 8000000,
        ),
      ];

      // Save entries to Firestore
      for (final entry in sampleEntries) {
        await _budgetService.createBudgetEntry(entry);
        print('Created budget entry: ${entry.description}');
      }

      print('✅ Sample budget data generated successfully!');
      print('📊 Generated ${sampleCategories.length} categories with subcategories');
      print('💰 Generated ${sampleEntries.length} budget entries');
      print('🎯 Total Budget: \$${(sampleCategories.fold(0.0, (sum, cat) => sum + cat.allocatedAmount) / 10000000).toStringAsFixed(1)} Crores');
      print('💸 Total Spent: \$${(sampleCategories.fold(0.0, (sum, cat) => sum + cat.spentAmount) / 10000000).toStringAsFixed(1)} Crores');

    } catch (e) {
      print('❌ Error generating sample data: $e');
      throw e;
    }
  }

  static Future<void> clearAllBudgetData() async {
    // This method would clear all budget data from Firestore
    // Implementation depends on your specific requirements
    print('🧹 Clearing all budget data...');
    // Add implementation here if needed
  }
}
