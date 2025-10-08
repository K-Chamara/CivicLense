import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/budget_models.dart';
import 'budget_service.dart';

/// TransparencyService - Enhanced transparency and accountability features
/// 
/// This service provides advanced transparency features without modifying
/// existing BudgetService functionality. All methods are additive only.
class TransparencyService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final BudgetService _budgetService = BudgetService();
  
  // Collection names
  static const String _transparencyReportsCollection = 'transparency_reports';
  static const String _budgetAnomaliesCollection = 'budget_anomalies';
  static const String _contractAnalysisCollection = 'contract_analysis';
  
  /// Get comprehensive transparency report
  /// This method enhances existing budget data with transparency metrics
  static Future<Map<String, dynamic>> getTransparencyReport() async {
    try {
      // Get existing budget data (no changes to existing methods)
      final categories = await _budgetService.getBudgetCategories();
      final statistics = await _budgetService.getBudgetStatistics();
      
      // Calculate transparency metrics
      final totalAllocated = statistics['totalAllocated'] ?? 0.0;
      final totalSpent = statistics['totalSpent'] ?? 0.0;
      final utilizationRate = totalAllocated > 0 ? (totalSpent / totalAllocated) * 100 : 0.0;
      
      // Calculate transparency score (0-100)
      final transparencyScore = _calculateTransparencyScore(categories, statistics);
      
      // Get contract performance data
      final contractPerformance = await _getContractPerformance();
      
      // Get anomaly detection results
      final anomalies = await _detectBudgetAnomalies(categories);
      
      return {
        'transparencyScore': transparencyScore,
        'utilizationRate': utilizationRate,
        'totalAllocated': totalAllocated,
        'totalSpent': totalSpent,
        'remainingBudget': totalAllocated - totalSpent,
        'contractPerformance': contractPerformance,
        'anomalies': anomalies,
        'categories': categories.map((cat) => {
          'name': cat.name,
          'allocated': cat.allocatedAmount,
          'spent': cat.spentAmount,
          'utilization': cat.allocatedAmount > 0 ? (cat.spentAmount / cat.allocatedAmount) * 100 : 0,
          'transparency': _calculateCategoryTransparency(cat),
        }).toList(),
        'generatedAt': DateTime.now().toIso8601String(),
      };
    } catch (e) {
      print('Error generating transparency report: $e');
      throw Exception('Failed to generate transparency report: $e');
    }
  }
  
  /// Calculate overall transparency score (0-100)
  static double _calculateTransparencyScore(List<BudgetCategory> categories, Map<String, dynamic> statistics) {
    double score = 0.0;
    int factors = 0;
    
    // Factor 1: Data completeness (30%)
    final dataCompleteness = _calculateDataCompleteness(categories);
    score += dataCompleteness * 0.3;
    factors++;
    
    // Factor 2: Spending transparency (40%)
    final spendingTransparency = _calculateSpendingTransparency(categories);
    score += spendingTransparency * 0.4;
    factors++;
    
    // Factor 3: Timeliness (30%)
    final timeliness = _calculateTimeliness(statistics);
    score += timeliness * 0.3;
    factors++;
    
    return factors > 0 ? score / factors : 0.0;
  }
  
  /// Calculate data completeness score
  static double _calculateDataCompleteness(List<BudgetCategory> categories) {
    if (categories.isEmpty) return 0.0;
    
    int completeCategories = 0;
    for (final category in categories) {
      if (category.name.isNotEmpty && 
          category.allocatedAmount > 0 && 
          category.spentAmount >= 0) {
        completeCategories++;
      }
    }
    
    return (completeCategories / categories.length) * 100;
  }
  
  /// Calculate spending transparency score
  static double _calculateSpendingTransparency(List<BudgetCategory> categories) {
    if (categories.isEmpty) return 0.0;
    
    double totalScore = 0.0;
    for (final category in categories) {
      final utilization = category.allocatedAmount > 0 ? 
          (category.spentAmount / category.allocatedAmount) * 100 : 0;
      
      // Higher utilization with proper documentation = higher transparency
      if (utilization > 0 && utilization <= 100) {
        totalScore += utilization;
      }
    }
    
    return totalScore / categories.length;
  }
  
  /// Calculate timeliness score
  static double _calculateTimeliness(Map<String, dynamic> statistics) {
    // This would check how recent the data is
    // For now, return a base score
    return 85.0; // Assume data is relatively current
  }
  
  /// Calculate category-level transparency
  static double _calculateCategoryTransparency(BudgetCategory category) {
    if (category.allocatedAmount <= 0) return 0.0;
    
    final utilization = (category.spentAmount / category.allocatedAmount) * 100;
    final completeness = category.name.isNotEmpty ? 100.0 : 0.0;
    
    return (utilization + completeness) / 2;
  }
  
  /// Get contract performance data
  static Future<Map<String, dynamic>> _getContractPerformance() async {
    try {
      // Get tenders data
      final tendersSnapshot = await _firestore.collection('tenders').get();
      final tenders = tendersSnapshot.docs.map((doc) => doc.data()).toList();
      
      // Calculate performance metrics
      final totalTenders = tenders.length;
      final activeTenders = tenders.where((t) => t['status'] == 'active').length;
      final completedTenders = tenders.where((t) => t['status'] == 'closed').length;
      final cancelledTenders = tenders.where((t) => t['status'] == 'cancelled').length;
      
      // Calculate average budget vs actual
      double totalBudget = 0.0;
      double totalActual = 0.0;
      
      for (final tender in tenders) {
        totalBudget += (tender['budget'] ?? 0.0).toDouble();
        totalActual += (tender['actualCost'] ?? 0.0).toDouble();
      }
      
      final budgetAccuracy = totalBudget > 0 ? (totalActual / totalBudget) * 100 : 0.0;
      
      return {
        'totalTenders': totalTenders,
        'activeTenders': activeTenders,
        'completedTenders': completedTenders,
        'cancelledTenders': cancelledTenders,
        'completionRate': totalTenders > 0 ? (completedTenders / totalTenders) * 100 : 0.0,
        'budgetAccuracy': budgetAccuracy,
        'totalBudget': totalBudget,
        'totalActual': totalActual,
      };
    } catch (e) {
      print('Error getting contract performance: $e');
      return {
        'totalTenders': 0,
        'activeTenders': 0,
        'completedTenders': 0,
        'cancelledTenders': 0,
        'completionRate': 0.0,
        'budgetAccuracy': 0.0,
        'totalBudget': 0.0,
        'totalActual': 0.0,
      };
    }
  }
  
  /// Detect budget anomalies
  static Future<List<Map<String, dynamic>>> _detectBudgetAnomalies(List<BudgetCategory> categories) async {
    List<Map<String, dynamic>> anomalies = [];
    
    for (final category in categories) {
      // Check for overspending
      if (category.spentAmount > category.allocatedAmount) {
        anomalies.add({
          'type': 'overspending',
          'category': category.name,
          'allocated': category.allocatedAmount,
          'spent': category.spentAmount,
          'excess': category.spentAmount - category.allocatedAmount,
          'severity': 'high',
        });
      }
      
      // Check for underutilization
      final utilization = category.allocatedAmount > 0 ? 
          (category.spentAmount / category.allocatedAmount) * 100 : 0;
      
      if (utilization < 20 && category.allocatedAmount > 100000) { // Less than 20% utilization for large budgets
        anomalies.add({
          'type': 'underutilization',
          'category': category.name,
          'allocated': category.allocatedAmount,
          'spent': category.spentAmount,
          'utilization': utilization,
          'severity': 'medium',
        });
      }
      
      // Check for zero spending
      if (category.spentAmount == 0 && category.allocatedAmount > 0) {
        anomalies.add({
          'type': 'zero_spending',
          'category': category.name,
          'allocated': category.allocatedAmount,
          'spent': category.spentAmount,
          'severity': 'low',
        });
      }
    }
    
    return anomalies;
  }
  
  /// Get district-wise spending (Sri Lanka context)
  static Future<Map<String, dynamic>> getDistrictSpending() async {
    try {
      // This would connect with Sri Lanka government data
      // For now, return sample data structure
      return {
        'districts': [
          {'name': 'Colombo', 'allocated': 50000000, 'spent': 35000000, 'utilization': 70.0},
          {'name': 'Gampaha', 'allocated': 30000000, 'spent': 22000000, 'utilization': 73.3},
          {'name': 'Kalutara', 'allocated': 25000000, 'spent': 18000000, 'utilization': 72.0},
          {'name': 'Kandy', 'allocated': 40000000, 'spent': 28000000, 'utilization': 70.0},
          {'name': 'Matale', 'allocated': 20000000, 'spent': 15000000, 'utilization': 75.0},
        ],
        'totalAllocated': 165000000,
        'totalSpent': 118000000,
        'overallUtilization': 71.5,
      };
    } catch (e) {
      print('Error getting district spending: $e');
      return {'districts': [], 'totalAllocated': 0, 'totalSpent': 0, 'overallUtilization': 0.0};
    }
  }
  
  /// Get sector performance (Sri Lanka context)
  static Future<Map<String, dynamic>> getSectorPerformance() async {
    try {
      return {
        'sectors': [
          {
            'name': 'Infrastructure Development',
            'allocated': 80000000,
            'spent': 60000000,
            'utilization': 75.0,
            'priority': 'high',
            'projects': 15,
            'completed': 8,
          },
          {
            'name': 'Education',
            'allocated': 60000000,
            'spent': 45000000,
            'utilization': 75.0,
            'priority': 'high',
            'projects': 25,
            'completed': 18,
          },
          {
            'name': 'Healthcare',
            'allocated': 50000000,
            'spent': 40000000,
            'utilization': 80.0,
            'priority': 'high',
            'projects': 12,
            'completed': 7,
          },
          {
            'name': 'Agriculture',
            'allocated': 30000000,
            'spent': 20000000,
            'utilization': 66.7,
            'priority': 'medium',
            'projects': 8,
            'completed': 3,
          },
        ],
        'totalAllocated': 220000000,
        'totalSpent': 165000000,
        'overallUtilization': 75.0,
      };
    } catch (e) {
      print('Error getting sector performance: $e');
      return {'sectors': [], 'totalAllocated': 0, 'totalSpent': 0, 'overallUtilization': 0.0};
    }
  }
}
