import 'dart:math';
import '../models/concern_models.dart';

/// Smart Priority Service - Client-side AI for concern prioritization
/// Works without Cloud Functions or external APIs
class SmartPriorityService {
  
  /// Analyze concern text and determine priority using keyword analysis
  static SmartAnalysisResult analyzeConcern(String title, String description, ConcernCategory category) {
    final textToAnalyze = '$title $description'.toLowerCase();
    
    // 1. Sentiment Analysis using keywords
    final sentimentResult = _analyzeSentiment(textToAnalyze);
    
    // 2. Priority calculation
    final priorityResult = _calculatePriority(textToAnalyze, category, sentimentResult);
    
    // 3. Extract key topics
    final topics = _extractTopics(textToAnalyze);
    
    // 4. Generate summary
    final summary = _generateSummary(title, description, sentimentResult, priorityResult);
    
    return SmartAnalysisResult(
      sentiment: sentimentResult,
      priority: priorityResult,
      topics: topics,
      summary: summary,
      confidence: _calculateConfidence(sentimentResult, priorityResult),
      analyzedAt: DateTime.now(),
      aiModel: 'SmartKeyword v1.0'
    );
  }
  
  /// Sentiment analysis using keyword matching
  static SentimentAnalysisResult _analyzeSentiment(String text) {
    // Negative keywords with weights
    final negativeKeywords = {
      // Strong negative/hate speech
      'hate': 0.95,
      'fucking': 0.9,
      'fuck': 0.85,
      'damn': 0.8,
      'shit': 0.85,
      'stupid': 0.7,
      'idiot': 0.75,
      'moron': 0.8,
      'disgusting': 0.85,
      'terrible': 0.8,
      'awful': 0.8,
      'horrible': 0.85,
      'pathetic': 0.8,
      'worthless': 0.85,
      'useless': 0.8,
      'ridiculous': 0.75,
      'absurd': 0.7,
      'outrageous': 0.85,
      'appalling': 0.85,
      'disgraceful': 0.9,
      'scandalous': 0.9,
      'shameful': 0.85,
      'unacceptable': 0.8,
      'intolerable': 0.85,
      'unbearable': 0.8,
      
      // Corruption and crime
      'corruption': 0.9,
      'bribe': 0.95,
      'fraud': 0.9,
      'theft': 0.85,
      'steal': 0.85,
      'illegal': 0.8,
      'unfair': 0.7,
      'injustice': 0.8,
      'abuse': 0.85,
      'misconduct': 0.8,
      'violation': 0.75,
      'scandal': 0.9,
      'embezzlement': 0.95,
      'kickback': 0.9,
      'nepotism': 0.8,
      'discrimination': 0.75,
      'harassment': 0.85,
      'exploitation': 0.8,
      'neglect': 0.7,
      
      // Urgency and severity
      'urgent': 0.6,
      'critical': 0.8,
      'emergency': 0.7,
      'serious': 0.6,
      'severe': 0.7,
      'dangerous': 0.8,
      'threat': 0.75,
      'risk': 0.6,
      'problem': 0.5,
      'issue': 0.4,
      'concern': 0.3,
      'worry': 0.5,
      'trouble': 0.6,
      'difficulty': 0.5,
      'challenge': 0.4,
      
      // Additional negative sentiment
      'angry': 0.8,
      'furious': 0.85,
      'enraged': 0.9,
      'livid': 0.85,
      'frustrated': 0.7,
      'annoyed': 0.6,
      'disappointed': 0.6,
      'disgusted': 0.8,
      'shocked': 0.7,
      'devastated': 0.85,
      'betrayed': 0.8,
      'cheated': 0.8,
      'lied': 0.75,
      'deceived': 0.8,
    };
    
    // Positive keywords with weights
    final positiveKeywords = {
      'good': -0.3,
      'great': -0.4,
      'excellent': -0.5,
      'wonderful': -0.4,
      'amazing': -0.4,
      'fantastic': -0.4,
      'perfect': -0.5,
      'improvement': -0.3,
      'better': -0.3,
      'progress': -0.3,
      'success': -0.4,
      'achievement': -0.3,
      'solution': -0.3,
      'helpful': -0.3,
      'support': -0.2,
      'thank': -0.2,
      'appreciate': -0.3,
      'satisfied': -0.3,
      'happy': -0.2,
      'pleased': -0.3,
    };
    
    double totalScore = 0.0;
    int keywordCount = 0;
    
    // Check negative keywords
    for (final entry in negativeKeywords.entries) {
      if (text.contains(entry.key)) {
        totalScore += entry.value;
        keywordCount++;
      }
    }
    
    // Check positive keywords
    for (final entry in positiveKeywords.entries) {
      if (text.contains(entry.key)) {
        totalScore += entry.value; // Already negative values
        keywordCount++;
      }
    }
    
    // Calculate final sentiment
    double finalScore = keywordCount > 0 ? (totalScore / keywordCount) : 0.0;
    
    // Map to sentiment categories
    SentimentScore sentimentScore;
    if (finalScore >= 0.6) {
      sentimentScore = SentimentScore.veryNegative;
    } else if (finalScore >= 0.3) {
      sentimentScore = SentimentScore.negative;
    } else if (finalScore >= -0.3) {
      sentimentScore = SentimentScore.neutral;
    } else if (finalScore >= -0.6) {
      sentimentScore = SentimentScore.positive;
    } else {
      sentimentScore = SentimentScore.veryPositive;
    }
    
    return SentimentAnalysisResult(
      score: finalScore,
      magnitude: finalScore.abs(),
      sentimentScore: sentimentScore,
    );
  }
  
  /// Calculate priority based on sentiment and category
  static PriorityAnalysisResult _calculatePriority(String text, ConcernCategory category, SentimentAnalysisResult sentiment) {
    
    // Base priority from sentiment
    ConcernPriority basePriority;
    double priorityScore = 0.3;
    
    if (sentiment.sentimentScore == SentimentScore.veryNegative && sentiment.magnitude > 0.6) {
      basePriority = ConcernPriority.critical;
      priorityScore = 0.9;
    } else if (sentiment.sentimentScore == SentimentScore.veryNegative) {
      basePriority = ConcernPriority.high;
      priorityScore = 0.8;
    } else if (sentiment.sentimentScore == SentimentScore.negative && sentiment.magnitude > 0.4) {
      basePriority = ConcernPriority.high;
      priorityScore = 0.7;
    } else if (sentiment.sentimentScore == SentimentScore.negative) {
      basePriority = ConcernPriority.medium;
      priorityScore = 0.6;
    } else {
      basePriority = ConcernPriority.low;
      priorityScore = 0.3;
    }
    
    // Category-based boosting
    if (category == ConcernCategory.corruption) {
      if (basePriority == ConcernPriority.low) {
        basePriority = ConcernPriority.medium;
        priorityScore = 0.6;
      } else if (basePriority == ConcernPriority.medium) {
        basePriority = ConcernPriority.high;
        priorityScore = 0.8;
      } else {
        basePriority = ConcernPriority.critical;
        priorityScore = 0.95;
      }
    }
    
    // Urgency keywords boost
    final urgencyKeywords = ['urgent', 'critical', 'emergency', 'immediate', 'asap', 'now'];
    final hasUrgency = urgencyKeywords.any((keyword) => text.contains(keyword));
    
    if (hasUrgency && basePriority != ConcernPriority.critical) {
      if (basePriority == ConcernPriority.low) {
        basePriority = ConcernPriority.medium;
        priorityScore = 0.6;
      } else if (basePriority == ConcernPriority.medium) {
        basePriority = ConcernPriority.high;
        priorityScore = 0.8;
      }
    }
    
    // Financial impact keywords
    final financialKeywords = ['money', 'fund', 'budget', 'cost', 'expensive', 'waste', 'loss'];
    final hasFinancialImpact = financialKeywords.any((keyword) => text.contains(keyword));
    
    if (hasFinancialImpact) {
      priorityScore = (priorityScore + 0.1).clamp(0.0, 1.0);
    }
    
    return PriorityAnalysisResult(
      priority: basePriority,
      score: priorityScore,
      reasoning: _generatePriorityReasoning(basePriority, sentiment, category, hasUrgency, hasFinancialImpact),
    );
  }
  
  /// Extract key topics from the text
  static List<String> _extractTopics(String text) {
    final topics = <String>[];
    
    final topicKeywords = {
      'corruption': ['corruption', 'bribe', 'fraud', 'kickback', 'embezzlement'],
      'financial': ['money', 'fund', 'budget', 'cost', 'expense', 'financial'],
      'legal': ['illegal', 'violation', 'law', 'legal', 'court', 'judge'],
      'administrative': ['admin', 'bureaucracy', 'process', 'procedure', 'system'],
      'social': ['community', 'people', 'citizen', 'public', 'society'],
      'environmental': ['environment', 'pollution', 'waste', 'nature', 'green'],
      'infrastructure': ['road', 'building', 'construction', 'development', 'project'],
      'education': ['school', 'education', 'teacher', 'student', 'learning'],
      'health': ['health', 'hospital', 'medical', 'doctor', 'medicine'],
      'security': ['security', 'safety', 'police', 'crime', 'threat'],
    };
    
    for (final entry in topicKeywords.entries) {
      if (entry.value.any((keyword) => text.contains(keyword))) {
        topics.add(entry.key);
      }
    }
    
    return topics;
  }
  
  /// Generate a smart summary
  static String _generateSummary(String title, String description, SentimentAnalysisResult sentiment, PriorityAnalysisResult priority) {
    final sentimentText = sentiment.sentimentScore.name.replaceAll(RegExp(r'([A-Z])'), ' \$1').trim().toLowerCase();
    final priorityText = priority.priority.name.toUpperCase();
    
    return "AI Analysis: $priorityText priority concern with $sentimentText sentiment (${(priority.score * 100).round()}% confidence)";
  }
  
  /// Calculate confidence score
  static double _calculateConfidence(SentimentAnalysisResult sentiment, PriorityAnalysisResult priority) {
    // Higher confidence when sentiment magnitude is high and keywords are specific
    final baseConfidence = (sentiment.magnitude * 0.6 + priority.score * 0.4);
    return baseConfidence.clamp(0.3, 0.95);
  }
  
  /// Generate reasoning for priority assignment
  static String _generatePriorityReasoning(ConcernPriority priority, SentimentAnalysisResult sentiment, ConcernCategory category, bool hasUrgency, bool hasFinancialImpact) {
    final reasons = <String>[];
    
    if (sentiment.sentimentScore == SentimentScore.veryNegative) {
      reasons.add('Very negative sentiment detected');
    } else if (sentiment.sentimentScore == SentimentScore.negative) {
      reasons.add('Negative sentiment detected');
    }
    
    if (category == ConcernCategory.corruption) {
      reasons.add('Corruption-related concern');
    }
    
    if (hasUrgency) {
      reasons.add('Urgency keywords detected');
    }
    
    if (hasFinancialImpact) {
      reasons.add('Financial impact identified');
    }
    
    if (reasons.isEmpty) {
      reasons.add('Standard concern processing');
    }
    
    return reasons.join(', ');
  }
}

/// Result of smart analysis
class SmartAnalysisResult {
  final SentimentAnalysisResult sentiment;
  final PriorityAnalysisResult priority;
  final List<String> topics;
  final String summary;
  final double confidence;
  final DateTime analyzedAt;
  final String aiModel;
  
  SmartAnalysisResult({
    required this.sentiment,
    required this.priority,
    required this.topics,
    required this.summary,
    required this.confidence,
    required this.analyzedAt,
    required this.aiModel,
  });
}

/// Priority analysis result
class PriorityAnalysisResult {
  final ConcernPriority priority;
  final double score;
  final String reasoning;
  
  PriorityAnalysisResult({
    required this.priority,
    required this.score,
    required this.reasoning,
  });
}
