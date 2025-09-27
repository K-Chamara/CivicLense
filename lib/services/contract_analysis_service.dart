import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/budget_models.dart';

/// ContractAnalysisService - Advanced contract analysis and performance tracking
/// 
/// This service provides contract analysis features that enhance existing
/// tender management without modifying existing functionality.
class ContractAnalysisService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  // Collection names
  static const String _tendersCollection = 'tenders';
  static const String _contractAnalysisCollection = 'contract_analysis';
  static const String _contractPerformanceCollection = 'contract_performance';
  
  /// Analyze contract performance vs budget
  static Future<Map<String, dynamic>> analyzeContractPerformance() async {
    try {
      // Get all tenders
      final tendersSnapshot = await _firestore.collection(_tendersCollection).get();
      final tenders = tendersSnapshot.docs.map((doc) => {
        'id': doc.id,
        ...doc.data(),
      }).toList();
      
      // Calculate performance metrics
      final performanceMetrics = _calculatePerformanceMetrics(tenders);
      
      // Detect suspicious patterns
      final suspiciousPatterns = _detectSuspiciousPatterns(tenders);
      
      // Analyze budget vs actual spending
      final budgetAnalysis = _analyzeBudgetVsActual(tenders);
      
      // Get contract timeline analysis
      final timelineAnalysis = _analyzeContractTimelines(tenders);
      
      return {
        'performanceMetrics': performanceMetrics,
        'suspiciousPatterns': suspiciousPatterns,
        'budgetAnalysis': budgetAnalysis,
        'timelineAnalysis': timelineAnalysis,
        'totalContracts': tenders.length,
        'analysisDate': DateTime.now().toIso8601String(),
      };
    } catch (e) {
      print('Error analyzing contract performance: $e');
      throw Exception('Failed to analyze contract performance: $e');
    }
  }
  
  /// Calculate performance metrics
  static Map<String, dynamic> _calculatePerformanceMetrics(List<Map<String, dynamic>> tenders) {
    if (tenders.isEmpty) {
      return {
        'onTimeDelivery': 0.0,
        'budgetAccuracy': 0.0,
        'qualityScore': 0.0,
        'completionRate': 0.0,
      };
    }
    
    int onTimeCount = 0;
    int completedCount = 0;
    double totalBudgetAccuracy = 0.0;
    int accuracyCount = 0;
    
    for (final tender in tenders) {
      final status = tender['status'] as String? ?? '';
      final deadline = tender['deadline'] as String? ?? '';
      final actualCompletion = tender['actualCompletion'] as String? ?? '';
      
      // Check on-time delivery
      if (status == 'closed' && deadline.isNotEmpty && actualCompletion.isNotEmpty) {
        final deadlineDate = DateTime.tryParse(deadline);
        final completionDate = DateTime.tryParse(actualCompletion);
        
        if (deadlineDate != null && completionDate != null) {
          if (completionDate.isBefore(deadlineDate) || completionDate.isAtSameMomentAs(deadlineDate)) {
            onTimeCount++;
          }
        }
      }
      
      // Check completion
      if (status == 'closed') {
        completedCount++;
      }
      
      // Calculate budget accuracy
      final budget = (tender['budget'] ?? 0.0).toDouble();
      final actualCost = (tender['actualCost'] ?? 0.0).toDouble();
      
      if (budget > 0 && actualCost > 0) {
        final accuracy = (budget / actualCost) * 100;
        totalBudgetAccuracy += accuracy;
        accuracyCount++;
      }
    }
    
    final onTimeDelivery = completedCount > 0 ? (onTimeCount / completedCount) * 100 : 0.0;
    final completionRate = tenders.length > 0 ? (completedCount / tenders.length) * 100 : 0.0;
    final budgetAccuracy = accuracyCount > 0 ? totalBudgetAccuracy / accuracyCount : 0.0;
    
    return {
      'onTimeDelivery': onTimeDelivery,
      'budgetAccuracy': budgetAccuracy,
      'qualityScore': (onTimeDelivery + budgetAccuracy) / 2, // Combined score
      'completionRate': completionRate,
    };
  }
  
  /// Detect suspicious patterns in contracts
  static List<Map<String, dynamic>> _detectSuspiciousPatterns(List<Map<String, dynamic>> tenders) {
    List<Map<String, dynamic>> suspiciousPatterns = [];
    
    // Group by contractor
    Map<String, List<Map<String, dynamic>>> contractorGroups = {};
    for (final tender in tenders) {
      final contractor = tender['awardedTo'] as String? ?? '';
      if (contractor.isNotEmpty) {
        contractorGroups[contractor] = contractorGroups[contractor] ?? [];
        contractorGroups[contractor]!.add(tender);
      }
    }
    
    // Check for single contractor dominance
    for (final entry in contractorGroups.entries) {
      final contractor = entry.key;
      final contracts = entry.value;
      
      if (contracts.length > 3) { // More than 3 contracts
        final totalValue = contracts.fold<double>(0.0, (sum, contract) => 
            sum + (contract['budget'] ?? 0.0).toDouble());
        
        suspiciousPatterns.add({
          'type': 'contractor_dominance',
          'contractor': contractor,
          'contractCount': contracts.length,
          'totalValue': totalValue,
          'severity': contracts.length > 5 ? 'high' : 'medium',
          'description': '$contractor has won ${contracts.length} contracts worth ${_formatCurrency(totalValue)}',
        });
      }
    }
    
    // Check for budget anomalies
    for (final tender in tenders) {
      final budget = (tender['budget'] ?? 0.0).toDouble();
      final actualCost = (tender['actualCost'] ?? 0.0).toDouble();
      
      if (actualCost > 0 && budget > 0) {
        final costOverrun = ((actualCost - budget) / budget) * 100;
        
        if (costOverrun > 50) { // More than 50% overrun
          suspiciousPatterns.add({
            'type': 'cost_overrun',
            'tenderId': tender['id'],
            'title': tender['title'] ?? 'Unknown',
            'budget': budget,
            'actualCost': actualCost,
            'overrun': costOverrun,
            'severity': costOverrun > 100 ? 'high' : 'medium',
            'description': 'Contract "${tender['title']}" exceeded budget by ${costOverrun.toStringAsFixed(1)}%',
          });
        }
      }
    }
    
    // Check for timeline anomalies
    for (final tender in tenders) {
      final deadline = tender['deadline'] as String? ?? '';
      final actualCompletion = tender['actualCompletion'] as String? ?? '';
      final status = tender['status'] as String? ?? '';
      
      if (status == 'closed' && deadline.isNotEmpty && actualCompletion.isNotEmpty) {
        final deadlineDate = DateTime.tryParse(deadline);
        final completionDate = DateTime.tryParse(actualCompletion);
        
        if (deadlineDate != null && completionDate != null) {
          final delay = completionDate.difference(deadlineDate).inDays;
          
          if (delay > 30) { // More than 30 days delay
            suspiciousPatterns.add({
              'type': 'timeline_delay',
              'tenderId': tender['id'],
              'title': tender['title'] ?? 'Unknown',
              'deadline': deadline,
              'actualCompletion': actualCompletion,
              'delayDays': delay,
              'severity': delay > 90 ? 'high' : 'medium',
              'description': 'Contract "${tender['title']}" was delayed by $delay days',
            });
          }
        }
      }
    }
    
    return suspiciousPatterns;
  }
  
  /// Analyze budget vs actual spending
  static Map<String, dynamic> _analyzeBudgetVsActual(List<Map<String, dynamic>> tenders) {
    double totalBudget = 0.0;
    double totalActual = 0.0;
    int contractsWithActual = 0;
    
    for (final tender in tenders) {
      final budget = (tender['budget'] ?? 0.0).toDouble();
      final actualCost = (tender['actualCost'] ?? 0.0).toDouble();
      
      totalBudget += budget;
      
      if (actualCost > 0) {
        totalActual += actualCost;
        contractsWithActual++;
      }
    }
    
    final budgetAccuracy = totalBudget > 0 ? (totalActual / totalBudget) * 100 : 0.0;
    final averageOverrun = contractsWithActual > 0 ? 
        ((totalActual - totalBudget) / totalBudget) * 100 : 0.0;
    
    return {
      'totalBudget': totalBudget,
      'totalActual': totalActual,
      'budgetAccuracy': budgetAccuracy,
      'averageOverrun': averageOverrun,
      'contractsWithActual': contractsWithActual,
      'totalContracts': tenders.length,
    };
  }
  
  /// Analyze contract timelines
  static Map<String, dynamic> _analyzeContractTimelines(List<Map<String, dynamic>> tenders) {
    int onTimeCount = 0;
    int delayedCount = 0;
    int earlyCount = 0;
    double totalDelayDays = 0.0;
    double totalEarlyDays = 0.0;
    
    for (final tender in tenders) {
      final deadline = tender['deadline'] as String? ?? '';
      final actualCompletion = tender['actualCompletion'] as String? ?? '';
      final status = tender['status'] as String? ?? '';
      
      if (status == 'closed' && deadline.isNotEmpty && actualCompletion.isNotEmpty) {
        final deadlineDate = DateTime.tryParse(deadline);
        final completionDate = DateTime.tryParse(actualCompletion);
        
        if (deadlineDate != null && completionDate != null) {
          final difference = completionDate.difference(deadlineDate).inDays;
          
          if (difference > 0) {
            delayedCount++;
            totalDelayDays += difference;
          } else if (difference < 0) {
            earlyCount++;
            totalEarlyDays += difference.abs();
          } else {
            onTimeCount++;
          }
        }
      }
    }
    
    final totalCompleted = onTimeCount + delayedCount + earlyCount;
    final onTimeRate = totalCompleted > 0 ? (onTimeCount / totalCompleted) * 100 : 0.0;
    final averageDelay = delayedCount > 0 ? totalDelayDays / delayedCount : 0.0;
    final averageEarly = earlyCount > 0 ? totalEarlyDays / earlyCount : 0.0;
    
    return {
      'onTimeCount': onTimeCount,
      'delayedCount': delayedCount,
      'earlyCount': earlyCount,
      'onTimeRate': onTimeRate,
      'averageDelay': averageDelay,
      'averageEarly': averageEarly,
      'totalCompleted': totalCompleted,
    };
  }
  
  /// Get contract risk assessment
  static Future<Map<String, dynamic>> getContractRiskAssessment() async {
    try {
      final analysis = await analyzeContractPerformance();
      final performanceMetrics = analysis['performanceMetrics'] as Map<String, dynamic>;
      final suspiciousPatterns = analysis['suspiciousPatterns'] as List<Map<String, dynamic>>;
      
      // Calculate risk score (0-100, higher = more risk)
      double riskScore = 0.0;
      
      // Factor 1: Performance metrics (40%)
      final onTimeDelivery = performanceMetrics['onTimeDelivery'] as double;
      final budgetAccuracy = performanceMetrics['budgetAccuracy'] as double;
      final performanceRisk = 100 - ((onTimeDelivery + budgetAccuracy) / 2);
      riskScore += performanceRisk * 0.4;
      
      // Factor 2: Suspicious patterns (60%)
      final highSeverityCount = suspiciousPatterns.where((p) => p['severity'] == 'high').length;
      final mediumSeverityCount = suspiciousPatterns.where((p) => p['severity'] == 'medium').length;
      final patternRisk = (highSeverityCount * 20) + (mediumSeverityCount * 10);
      riskScore += patternRisk * 0.6;
      
      // Cap risk score at 100
      riskScore = riskScore > 100 ? 100 : riskScore;
      
      String riskLevel;
      if (riskScore < 30) {
        riskLevel = 'Low';
      } else if (riskScore < 60) {
        riskLevel = 'Medium';
      } else {
        riskLevel = 'High';
      }
      
      return {
        'riskScore': riskScore,
        'riskLevel': riskLevel,
        'performanceRisk': performanceRisk,
        'patternRisk': patternRisk,
        'highSeverityCount': highSeverityCount,
        'mediumSeverityCount': mediumSeverityCount,
        'recommendations': _generateRiskRecommendations(riskScore, suspiciousPatterns),
      };
    } catch (e) {
      print('Error getting contract risk assessment: $e');
      return {
        'riskScore': 0.0,
        'riskLevel': 'Unknown',
        'performanceRisk': 0.0,
        'patternRisk': 0.0,
        'highSeverityCount': 0,
        'mediumSeverityCount': 0,
        'recommendations': [],
      };
    }
  }
  
  /// Generate risk recommendations
  static List<String> _generateRiskRecommendations(double riskScore, List<Map<String, dynamic>> suspiciousPatterns) {
    List<String> recommendations = [];
    
    if (riskScore > 60) {
      recommendations.add('Implement stricter contract monitoring and oversight');
      recommendations.add('Review contractor selection criteria and processes');
      recommendations.add('Establish early warning systems for contract delays');
    }
    
    if (suspiciousPatterns.any((p) => p['type'] == 'contractor_dominance')) {
      recommendations.add('Diversify contractor selection to prevent dominance');
      recommendations.add('Implement contractor rotation policies');
    }
    
    if (suspiciousPatterns.any((p) => p['type'] == 'cost_overrun')) {
      recommendations.add('Implement stricter budget controls and monitoring');
      recommendations.add('Require detailed cost breakdowns before contract approval');
    }
    
    if (suspiciousPatterns.any((p) => p['type'] == 'timeline_delay')) {
      recommendations.add('Improve project timeline planning and management');
      recommendations.add('Implement milestone-based progress tracking');
    }
    
    if (recommendations.isEmpty) {
      recommendations.add('Continue current contract management practices');
      recommendations.add('Regular monitoring and review of contract performance');
    }
    
    return recommendations;
  }
  
  /// Format currency for display
  static String _formatCurrency(double amount) {
    if (amount >= 1000000) {
      return 'LKR ${(amount / 1000000).toStringAsFixed(1)}M';
    } else if (amount >= 1000) {
      return 'LKR ${(amount / 1000).toStringAsFixed(1)}K';
    } else {
      return 'LKR ${amount.toStringAsFixed(0)}';
    }
  }
}
