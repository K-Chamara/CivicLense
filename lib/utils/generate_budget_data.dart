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
          allocatedAmount: 120000000, // ₹120 Crores
          spentAmount: 85000000,      // ₹85 Crores spent (70.8% utilization)
          color: '#2196F3', // Blue
          createdAt: DateTime.now(),
          subcategories: [
            BudgetSubcategory(
              id: '1_1',
              name: 'Road Construction',
              description: 'New road construction and maintenance',
              allocatedAmount: 70000000,
              spentAmount: 52000000,
              categoryId: '1',
            ),
            BudgetSubcategory(
              id: '1_2',
              name: 'Bridge Development',
              description: 'Bridge construction and repair',
              allocatedAmount: 30000000,
              spentAmount: 21000000,
              categoryId: '1',
            ),
            BudgetSubcategory(
              id: '1_3',
              name: 'Public Buildings',
              description: 'Government buildings and facilities',
              allocatedAmount: 20000000,
              spentAmount: 12000000,
              categoryId: '1',
            ),
          ],
        ),
        BudgetCategory(
          id: '2',
          name: 'Healthcare',
          description: 'Medical facilities, equipment, and services',
          allocatedAmount: 80000000,  // ₹80 Crores
          spentAmount: 65000000,      // ₹65 Crores spent (81.3% utilization)
          color: '#4CAF50', // Green
          createdAt: DateTime.now(),
          subcategories: [
            BudgetSubcategory(
              id: '2_1',
              name: 'Hospital Equipment',
              description: 'Medical equipment and machinery',
              allocatedAmount: 35000000,
              spentAmount: 28000000,
              categoryId: '2',
            ),
            BudgetSubcategory(
              id: '2_2',
              name: 'Medicine Procurement',
              description: 'Essential medicines and supplies',
              allocatedAmount: 25000000,
              spentAmount: 22000000,
              categoryId: '2',
            ),
            BudgetSubcategory(
              id: '2_3',
              name: 'Staff Training',
              description: 'Medical staff training and development',
              allocatedAmount: 20000000,
              spentAmount: 15000000,
              categoryId: '2',
            ),
          ],
        ),
        BudgetCategory(
          id: '3',
          name: 'Education',
          description: 'Schools, colleges, educational programs',
          allocatedAmount: 95000000,  // ₹95 Crores
          spentAmount: 62000000,      // ₹62 Crores spent (65.3% utilization)
          color: '#FF9800', // Orange
          createdAt: DateTime.now(),
          subcategories: [
            BudgetSubcategory(
              id: '3_1',
              name: 'School Infrastructure',
              description: 'New schools and classroom construction',
              allocatedAmount: 50000000,
              spentAmount: 30000000,
              categoryId: '3',
            ),
            BudgetSubcategory(
              id: '3_2',
              name: 'Digital Learning',
              description: 'Computers, tablets, and digital resources',
              allocatedAmount: 25000000,
              spentAmount: 18000000,
              categoryId: '3',
            ),
            BudgetSubcategory(
              id: '3_3',
              name: 'Teacher Training',
              description: 'Professional development for educators',
              allocatedAmount: 20000000,
              spentAmount: 14000000,
              categoryId: '3',
            ),
          ],
        ),
        BudgetCategory(
          id: '4',
          name: 'Public Safety',
          description: 'Police, fire department, emergency services',
          allocatedAmount: 60000000,  // ₹60 Crores
          spentAmount: 52000000,      // ₹52 Crores spent (86.7% utilization)
          color: '#F44336', // Red
          createdAt: DateTime.now(),
          subcategories: [
            BudgetSubcategory(
              id: '4_1',
              name: 'Police Equipment',
              description: 'Vehicles, communication, and safety gear',
              allocatedAmount: 30000000,
              spentAmount: 27000000,
              categoryId: '4',
            ),
            BudgetSubcategory(
              id: '4_2',
              name: 'Fire Department',
              description: 'Fire trucks, equipment, and training',
              allocatedAmount: 20000000,
              spentAmount: 17000000,
              categoryId: '4',
            ),
            BudgetSubcategory(
              id: '4_3',
              name: 'Emergency Services',
              description: 'Ambulances and emergency response',
              allocatedAmount: 10000000,
              spentAmount: 8000000,
              categoryId: '4',
            ),
          ],
        ),
        BudgetCategory(
          id: '5',
          name: 'Social Welfare',
          description: 'Poverty alleviation and social programs',
          allocatedAmount: 75000000,  // ₹75 Crores
          spentAmount: 58000000,      // ₹58 Crores spent (77.3% utilization)
          color: '#9C27B0', // Purple
          createdAt: DateTime.now(),
          subcategories: [
            BudgetSubcategory(
              id: '5_1',
              name: 'Food Security',
              description: 'Public distribution system and nutrition',
              allocatedAmount: 40000000,
              spentAmount: 32000000,
              categoryId: '5',
            ),
            BudgetSubcategory(
              id: '5_2',
              name: 'Housing for Poor',
              description: 'Affordable housing schemes',
              allocatedAmount: 25000000,
              spentAmount: 18000000,
              categoryId: '5',
            ),
            BudgetSubcategory(
              id: '5_3',
              name: 'Skill Development',
              description: 'Vocational training programs',
              allocatedAmount: 10000000,
              spentAmount: 8000000,
              categoryId: '5',
            ),
          ],
        ),
        BudgetCategory(
          id: '6',
          name: 'Environment & Parks',
          description: 'Green spaces, waste management, pollution control',
          allocatedAmount: 45000000,  // ₹45 Crores
          spentAmount: 28000000,      // ₹28 Crores spent (62.2% utilization)
          color: '#4CAF50', // Green
          createdAt: DateTime.now(),
          subcategories: [
            BudgetSubcategory(
              id: '6_1',
              name: 'Waste Management',
              description: 'Garbage collection and processing',
              allocatedAmount: 25000000,
              spentAmount: 18000000,
              categoryId: '6',
            ),
            BudgetSubcategory(
              id: '6_2',
              name: 'Park Development',
              description: 'Public parks and recreation areas',
              allocatedAmount: 15000000,
              spentAmount: 8000000,
              categoryId: '6',
            ),
            BudgetSubcategory(
              id: '6_3',
              name: 'Tree Plantation',
              description: 'Urban forestry and green cover',
              allocatedAmount: 5000000,
              spentAmount: 2000000,
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
          categoryId: '1',
          subcategoryId: '1_1',
          description: 'Highway expansion project - Phase 1',
          amount: 15000000,
          date: DateTime.now().subtract(const Duration(days: 30)),
          type: 'expense',
          status: 'approved',
          notes: 'Major highway project for traffic improvement',
        ),
        BudgetEntry(
          id: 'entry_2',
          categoryId: '1',
          subcategoryId: '1_2',
          description: 'City bridge repair and maintenance',
          amount: 8000000,
          date: DateTime.now().subtract(const Duration(days: 45)),
          type: 'expense',
          status: 'approved',
          notes: 'Essential bridge maintenance for safety',
        ),
        BudgetEntry(
          id: 'entry_3',
          categoryId: '1',
          subcategoryId: '1_3',
          description: 'New district office construction',
          amount: 5000000,
          date: DateTime.now().subtract(const Duration(days: 20)),
          type: 'expense',
          status: 'approved',
          notes: 'Modern district administrative building',
        ),
        
        // Healthcare entries
        BudgetEntry(
          id: 'entry_4',
          categoryId: '2',
          subcategoryId: '2_1',
          description: 'MRI machine procurement for district hospital',
          amount: 12000000,
          date: DateTime.now().subtract(const Duration(days: 60)),
          type: 'expense',
          status: 'approved',
          notes: 'Advanced medical equipment for better diagnosis',
        ),
        BudgetEntry(
          id: 'entry_5',
          categoryId: '2',
          subcategoryId: '2_2',
          description: 'Emergency medicine stock for 6 months',
          amount: 8000000,
          date: DateTime.now().subtract(const Duration(days: 15)),
          type: 'expense',
          status: 'approved',
          notes: 'Essential medicines for public health',
        ),
        
        // Education entries
        BudgetEntry(
          id: 'entry_6',
          categoryId: '3',
          subcategoryId: '3_1',
          description: 'Primary school construction - 5 schools',
          amount: 18000000,
          date: DateTime.now().subtract(const Duration(days: 90)),
          type: 'expense',
          status: 'approved',
          notes: 'New schools in rural areas',
        ),
        BudgetEntry(
          id: 'entry_7',
          categoryId: '3',
          subcategoryId: '3_2',
          description: 'Tablets for digital learning initiative',
          amount: 7000000,
          date: DateTime.now().subtract(const Duration(days: 25)),
          type: 'expense',
          status: 'approved',
          notes: '1000 tablets for government schools',
        ),
        
        // Public Safety entries
        BudgetEntry(
          id: 'entry_8',
          categoryId: '4',
          subcategoryId: '4_1',
          description: 'Police vehicles - 20 patrol cars',
          amount: 15000000,
          date: DateTime.now().subtract(const Duration(days: 40)),
          type: 'expense',
          status: 'approved',
          notes: 'Enhanced patrol coverage for city',
        ),
        BudgetEntry(
          id: 'entry_9',
          categoryId: '4',
          subcategoryId: '4_2',
          description: 'Fire station equipment upgrade',
          amount: 6000000,
          date: DateTime.now().subtract(const Duration(days: 35)),
          type: 'expense',
          status: 'approved',
          notes: 'Modern firefighting equipment',
        ),
        
        // Social Welfare entries
        BudgetEntry(
          id: 'entry_10',
          categoryId: '5',
          subcategoryId: '5_1',
          description: 'Food distribution for 10,000 families',
          amount: 12000000,
          date: DateTime.now().subtract(const Duration(days: 10)),
          type: 'expense',
          status: 'approved',
          notes: 'Monthly food security program',
        ),
        BudgetEntry(
          id: 'entry_11',
          categoryId: '5',
          subcategoryId: '5_2',
          description: 'Affordable housing - 100 units',
          amount: 8000000,
          date: DateTime.now().subtract(const Duration(days: 50)),
          type: 'expense',
          status: 'approved',
          notes: 'Housing for economically weaker sections',
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
      print('🎯 Total Budget: ₹${(sampleCategories.fold(0.0, (sum, cat) => sum + cat.allocatedAmount) / 10000000).toStringAsFixed(1)} Crores');
      print('💸 Total Spent: ₹${(sampleCategories.fold(0.0, (sum, cat) => sum + cat.spentAmount) / 10000000).toStringAsFixed(1)} Crores');

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
