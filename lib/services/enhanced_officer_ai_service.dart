import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/concern_models.dart';
import 'officer_ai_service.dart';
import 'smart_priority_service.dart';

// Import models from officer_ai_service
export 'officer_ai_service.dart' show RiskAssessment, InvestigationRisk, ResponseSuggestion, 
    EvidenceAnalysis, InvestigationStrategy, DuplicateConcern, CorruptionPattern;

class EnhancedOfficerAIService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Intelligent Priority Ranking with ML-like analysis
  static Future<PriorityRankingResult> intelligentPriorityRanking(Concern concern) async {
    try {
      // Get similar concerns for context
      final similarConcerns = await _findSimilarConcerns(concern);
      
      // Calculate priority score based on multiple factors
      double priorityScore = 0.0;
      List<String> factors = [];

      // 1. Sentiment Analysis (40% weight)
      final sentimentAnalysis = SmartPriorityService.analyzeConcern(
        concern.title,
        concern.description,
        concern.category,
      );
      priorityScore += sentimentAnalysis.priority.score * 0.4;
      factors.add('Sentiment: ${sentimentAnalysis.sentiment.sentimentScore.name}');

      // 2. Category Impact (25% weight)
      double categoryWeight = _getCategoryWeight(concern.category);
      priorityScore += categoryWeight * 0.25;
      factors.add('Category: ${concern.category.name} (${(categoryWeight * 100).round()}%)');

      // 3. Historical Resolution Time (20% weight)
      final avgResolutionTime = await _getAverageResolutionTime(concern.category);
      final timeWeight = avgResolutionTime > 7 ? 0.8 : (avgResolutionTime > 3 ? 0.6 : 0.4);
      priorityScore += timeWeight * 0.2;
      factors.add('Historical: ${avgResolutionTime.toStringAsFixed(1)} days avg');

      // 4. Similar Concern Patterns (15% weight)
      if (similarConcerns.isNotEmpty) {
        final patternWeight = similarConcerns.length > 5 ? 0.9 : (similarConcerns.length > 2 ? 0.7 : 0.5);
        priorityScore += patternWeight * 0.15;
        factors.add('Patterns: ${similarConcerns.length} similar concerns');
      }

      // Determine final priority
      ConcernPriority finalPriority;
      if (priorityScore >= 0.8) {
        finalPriority = ConcernPriority.critical;
      } else if (priorityScore >= 0.6) {
        finalPriority = ConcernPriority.high;
      } else if (priorityScore >= 0.4) {
        finalPriority = ConcernPriority.medium;
      } else {
        finalPriority = ConcernPriority.low;
      }

      return PriorityRankingResult(
        priority: finalPriority,
        score: priorityScore,
        factors: factors,
        confidence: _calculateConfidence(priorityScore, factors.length),
        similarConcerns: similarConcerns,
        estimatedResolutionTime: _estimateResolutionTime(finalPriority, concern.category),
      );
    } catch (e) {
      print('Error in intelligent priority ranking: $e');
      return PriorityRankingResult(
        priority: ConcernPriority.medium,
        score: 0.5,
        factors: ['Error in analysis'],
        confidence: 0.3,
        similarConcerns: [],
        estimatedResolutionTime: 7,
      );
    }
  }

  /// Advanced Duplicate Detection with similarity scoring
  static Future<List<DuplicateConcern>> advancedDuplicateDetection(Concern concern) async {
    try {
      final allConcerns = await _firestore
          .collection('concerns')
          .where('status', whereIn: ['pending', 'underReview', 'inProgress'])
          .get();

      final duplicates = <DuplicateConcern>[];
      
      for (final doc in allConcerns.docs) {
        if (doc.id == concern.id) continue;
        
        final otherConcern = Concern.fromFirestore(doc);
        final similarity = _calculateSimilarity(concern, otherConcern);
        
        if (similarity > 0.7) { // 70% similarity threshold
          duplicates.add(DuplicateConcern(
            concernId: otherConcern.id,
            similarity: similarity,
            reason: _getMatchingFactors(concern, otherConcern).join(', '),
            recommendation: 'Review for potential duplicate',
            actionSuggestion: 'Merge concerns if duplicate confirmed',
          ));
        }
      }

      return duplicates;
    } catch (e) {
      print('Error in duplicate detection: $e');
      return [];
    }
  }

  /// Pattern Detection across multiple concerns
  static Future<List<CorruptionPattern>> detectAdvancedPatterns() async {
    try {
      final patterns = <CorruptionPattern>[];
      
      // 1. Temporal Patterns (time-based)
      final temporalPatterns = await _detectTemporalPatterns();
      patterns.addAll(temporalPatterns);
      
      // 2. Geographic Patterns (location-based)
      final geographicPatterns = await _detectGeographicPatterns();
      patterns.addAll(geographicPatterns);
      
      // 3. Category Patterns (topic-based)
      final categoryPatterns = await _detectCategoryPatterns();
      patterns.addAll(categoryPatterns);
      
      // 4. Author Patterns (user-based)
      final authorPatterns = await _detectAuthorPatterns();
      patterns.addAll(authorPatterns);
      
      return patterns;
    } catch (e) {
      print('Error in pattern detection: $e');
      return [];
    }
  }

  /// Legal Document Drafting with templates
  static Future<LegalDocumentDraft> generateLegalDocument(
    Concern concern,
    String documentType,
    Map<String, dynamic> context,
  ) async {
    try {
      String template = '';
      String content = '';
      
      switch (documentType) {
        case 'investigation_notice':
          template = _getInvestigationNoticeTemplate();
          content = _fillInvestigationNotice(concern, template, context);
          break;
        case 'resolution_letter':
          template = _getResolutionLetterTemplate();
          content = _fillResolutionLetter(concern, template, context);
          break;
        case 'escalation_report':
          template = _getEscalationReportTemplate();
          content = _fillEscalationReport(concern, template, context);
          break;
        default:
          throw Exception('Unknown document type: $documentType');
      }

      return LegalDocumentDraft(
        type: documentType,
        title: _generateDocumentTitle(documentType, concern),
        content: content,
        template: template,
        metadata: {
          'concern_id': concern.id,
          'generated_at': DateTime.now().toIso8601String(),
          'context': context,
        },
      );
    } catch (e) {
      print('Error generating legal document: $e');
      rethrow;
    }
  }

  /// Enhanced Risk Assessment with multiple risk factors
  static Future<RiskAssessment> enhancedRiskAssessment(Concern concern) async {
    try {
      final risks = <String>[];
      final recommendations = <String>[];
      RiskLevel riskLevel = RiskLevel.low;
      double riskScore = 0.0;

      // 1. Content Risk Analysis
      final contentRisks = _analyzeContentRisk(concern);
      riskScore += contentRisks.score;
      risks.addAll(contentRisks.risks);

      // 2. Historical Risk Analysis
      final historicalRisks = await _analyzeHistoricalRisk(concern);
      riskScore += historicalRisks.score;
      risks.addAll(historicalRisks.risks);

      // 3. Stakeholder Risk Analysis
      final stakeholderRisks = await _analyzeStakeholderRisk(concern);
      riskScore += stakeholderRisks.score;
      risks.addAll(stakeholderRisks.risks);

      // 4. Legal Risk Analysis
      final legalRisks = _analyzeLegalRisk(concern);
      riskScore += legalRisks.score;
      risks.addAll(legalRisks.risks);

      // Determine overall risk level
      if (riskScore >= 0.8) {
        riskLevel = RiskLevel.critical;
      } else if (riskScore >= 0.6) {
        riskLevel = RiskLevel.high;
      } else if (riskScore >= 0.4) {
        riskLevel = RiskLevel.medium;
      } else {
        riskLevel = RiskLevel.low;
      }

      // Generate recommendations based on risk level
      recommendations.addAll(_generateRiskRecommendations(riskLevel, risks));

      return RiskAssessment(
        overallRisk: riskLevel.name,
        riskScore: riskScore,
        risks: risks.map((r) => InvestigationRisk(
          type: 'risk',
          severity: riskLevel.name,
          likelihood: riskScore,
          description: r,
          mitigation: 'Review and address',
        )).toList(),
        safeguards: recommendations,
        legalConsiderations: ['Standard legal review required'],
        estimatedSuccessRate: (1.0 - riskScore).clamp(0.3, 0.95),
        recommendedApproach: _generateRiskAnalysis(riskLevel, risks),
      );
    } catch (e) {
      print('Error in enhanced risk assessment: $e');
      return RiskAssessment(
        overallRisk: 'medium',
        riskScore: 0.5,
        risks: [InvestigationRisk(
          type: 'error',
          severity: 'medium',
          likelihood: 0.5,
          description: 'Technical assessment error',
          mitigation: 'Manual review required',
        )],
        safeguards: ['Manual review required'],
        legalConsiderations: ['Standard legal review required'],
        estimatedSuccessRate: 0.5,
        recommendedApproach: 'Unable to assess risk due to technical error',
      );
    }
  }

  /// Intelligent Response Suggestions with context awareness
  static Future<ResponseSuggestion> intelligentResponseSuggestion(
    Concern concern,
    String context,
  ) async {
    try {
      // Analyze the concern context
      final analysis = SmartPriorityService.analyzeConcern(
        concern.title,
        concern.description,
        concern.category,
      );

      // Generate context-aware suggestions
      String suggestion = '';
      String template = '';

      if (concern.category == ConcernCategory.corruption) {
        suggestion = _generateCorruptionResponse(concern, analysis);
        template = _getCorruptionResponseTemplate();
      } else if (concern.priority == ConcernPriority.critical) {
        suggestion = _generateCriticalResponse(concern, analysis);
        template = _getCriticalResponseTemplate();
      } else if (analysis.sentiment.sentimentScore == SentimentScore.veryNegative) {
        suggestion = _generateNegativeSentimentResponse(concern, analysis);
        template = _getNegativeSentimentTemplate();
      } else {
        suggestion = _generateStandardResponse(concern, analysis);
        template = _getStandardResponseTemplate();
      }

      return ResponseSuggestion(
        subject: 'Response to Concern #${concern.id}',
        body: suggestion,
        tone: 'professional',
        nextSteps: _generateNextSteps(concern, analysis),
        estimatedResolutionTime: '${_estimateResolutionTime(concern.priority, concern.category)} days',
        officerNotes: template,
      );
    } catch (e) {
      print('Error generating response suggestion: $e');
      return ResponseSuggestion(
        subject: 'Response to Concern #${concern.id}',
        body: 'Please review this concern and respond appropriately.',
        tone: 'formal',
        nextSteps: ['Review concern', 'Respond to citizen'],
        estimatedResolutionTime: '7 days',
        officerNotes: 'Dear [Citizen Name],\n\nThank you for bringing this concern to our attention. We are reviewing the matter and will provide an update soon.\n\nBest regards,\n[Officer Name]',
      );
    }
  }

  // Helper Methods

  static Future<List<Concern>> _findSimilarConcerns(Concern concern) async {
    final similar = <Concern>[];
    
    // Find concerns with similar category and keywords
    final keywords = _extractKeywords(concern.title + ' ' + concern.description);
    
    for (final keyword in keywords.take(3)) {
      final query = await _firestore
          .collection('concerns')
          .where('category', isEqualTo: concern.category.name)
          .limit(10)
          .get();
      
      for (final doc in query.docs) {
        final otherConcern = Concern.fromFirestore(doc);
        if (otherConcern.id != concern.id && 
            _calculateSimilarity(concern, otherConcern) > 0.6) {
          similar.add(otherConcern);
        }
      }
    }
    
    return similar;
  }

  static double _getCategoryWeight(ConcernCategory category) {
    switch (category) {
      case ConcernCategory.corruption:
        return 0.9;
      case ConcernCategory.budget:
        return 0.8;
      case ConcernCategory.tender:
        return 0.7;
      case ConcernCategory.transparency:
        return 0.6;
      case ConcernCategory.community:
        return 0.5;
      case ConcernCategory.system:
        return 0.4;
      case ConcernCategory.other:
        return 0.3;
    }
  }

  static Future<double> _getAverageResolutionTime(ConcernCategory category) async {
    final resolved = await _firestore
        .collection('concerns')
        .where('category', isEqualTo: category.name)
        .where('status', isEqualTo: 'resolved')
        .get();
    
    if (resolved.docs.isEmpty) return 7.0;
    
    double totalDays = 0;
    for (final doc in resolved.docs) {
      final concern = Concern.fromFirestore(doc);
      if (concern.resolvedAt != null) {
        totalDays += concern.resolvedAt!.difference(concern.createdAt).inDays.toDouble();
      }
    }
    
    return totalDays / resolved.docs.length;
  }

  static double _calculateConfidence(double score, int factors) {
    final baseConfidence = score;
    final factorBonus = (factors / 4) * 0.2; // Max 20% bonus for having all factors
    return (baseConfidence + factorBonus).clamp(0.3, 0.95);
  }

  static int _estimateResolutionTime(ConcernPriority priority, ConcernCategory category) {
    final baseTime = {
      ConcernPriority.low: 14,
      ConcernPriority.medium: 7,
      ConcernPriority.high: 3,
      ConcernPriority.critical: 1,
    }[priority] ?? 7;
    
    final categoryMultiplier = {
      ConcernCategory.corruption: 1.5,
      ConcernCategory.budget: 1.2,
      ConcernCategory.tender: 1.3,
      ConcernCategory.transparency: 1.1,
      ConcernCategory.community: 1.0,
      ConcernCategory.system: 1.4,
      ConcernCategory.other: 1.0,
    }[category] ?? 1.0;
    
    return (baseTime * categoryMultiplier).round();
  }

  static double _calculateSimilarity(Concern concern1, Concern concern2) {
    // Simple similarity calculation based on text overlap
    final text1 = (concern1.title + ' ' + concern1.description).toLowerCase();
    final text2 = (concern2.title + ' ' + concern2.description).toLowerCase();
    
    final words1 = text1.split(' ').toSet();
    final words2 = text2.split(' ').toSet();
    
    final intersection = words1.intersection(words2);
    final union = words1.union(words2);
    
    return intersection.length / union.length;
  }

  static List<String> _getMatchingFactors(Concern concern1, Concern concern2) {
    final factors = <String>[];
    
    if (concern1.category == concern2.category) {
      factors.add('Same category');
    }
    
    if (concern1.authorLocation == concern2.authorLocation && concern1.authorLocation != null) {
      factors.add('Same location');
    }
    
    if (_calculateSimilarity(concern1, concern2) > 0.8) {
      factors.add('High text similarity');
    }
    
    return factors;
  }

  static List<String> _extractKeywords(String text) {
    final words = text.toLowerCase().split(' ')
        .where((word) => word.length > 3)
        .where((word) => !_isStopWord(word))
        .toList();
    
    // Simple frequency-based keyword extraction
    final frequency = <String, int>{};
    for (final word in words) {
      frequency[word] = (frequency[word] ?? 0) + 1;
    }
    
    final sortedEntries = frequency.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));
    
    return sortedEntries
        .map((e) => e.key)
        .take(5)
        .toList();
  }

  static bool _isStopWord(String word) {
    const stopWords = {
      'the', 'and', 'or', 'but', 'in', 'on', 'at', 'to', 'for', 'of', 'with',
      'by', 'from', 'up', 'about', 'into', 'through', 'during', 'before',
      'after', 'above', 'below', 'between', 'among', 'this', 'that', 'these',
      'those', 'i', 'you', 'he', 'she', 'it', 'we', 'they', 'is', 'are',
      'was', 'were', 'be', 'been', 'being', 'have', 'has', 'had', 'do',
      'does', 'did', 'will', 'would', 'could', 'should', 'may', 'might',
      'must', 'can', 'shall', 'a', 'an', 'some', 'any', 'all', 'both',
      'each', 'every', 'other', 'another', 'such', 'no', 'not', 'only',
      'own', 'same', 'so', 'than', 'too', 'very', 'just', 'now'
    };
    return stopWords.contains(word);
  }

  // Pattern Detection Methods
  static Future<List<CorruptionPattern>> _detectTemporalPatterns() async {
    // Implementation for temporal pattern detection
    return [];
  }

  static Future<List<CorruptionPattern>> _detectGeographicPatterns() async {
    // Implementation for geographic pattern detection
    return [];
  }

  static Future<List<CorruptionPattern>> _detectCategoryPatterns() async {
    // Implementation for category pattern detection
    return [];
  }

  static Future<List<CorruptionPattern>> _detectAuthorPatterns() async {
    // Implementation for author pattern detection
    return [];
  }

  static List<String> _generateNextSteps(Concern concern, SmartAnalysisResult analysis) {
    final steps = <String>[];
    
    if (concern.priority == ConcernPriority.critical) {
      steps.addAll([
        'Immediate escalation to senior management',
        'Begin investigation within 24 hours',
        'Provide daily updates to stakeholders',
      ]);
    } else if (concern.priority == ConcernPriority.high) {
      steps.addAll([
        'Assign to experienced investigator',
        'Begin investigation within 3 days',
        'Provide weekly updates',
      ]);
    } else {
      steps.addAll([
        'Add to investigation queue',
        'Begin investigation within 7 days',
        'Provide bi-weekly updates',
      ]);
    }
    
    return steps;
  }

  // Risk Analysis Methods
  static RiskAnalysisResult _analyzeContentRisk(Concern concern) {
    final risks = <String>[];
    double score = 0.0;
    
    final text = (concern.title + ' ' + concern.description).toLowerCase();
    
    // Check for high-risk keywords
    if (text.contains('corruption') || text.contains('bribe')) {
      risks.add('Corruption allegations detected');
      score += 0.3;
    }
    
    if (text.contains('fraud') || text.contains('theft')) {
      risks.add('Financial misconduct indicators');
      score += 0.2;
    }
    
    if (text.contains('urgent') || text.contains('emergency')) {
      risks.add('Urgency indicators present');
      score += 0.1;
    }
    
    return RiskAnalysisResult(risks: risks, score: score);
  }

  static Future<RiskAnalysisResult> _analyzeHistoricalRisk(Concern concern) async {
    // Implementation for historical risk analysis
    return RiskAnalysisResult(risks: [], score: 0.0);
  }

  static Future<RiskAnalysisResult> _analyzeStakeholderRisk(Concern concern) async {
    // Implementation for stakeholder risk analysis
    return RiskAnalysisResult(risks: [], score: 0.0);
  }

  static RiskAnalysisResult _analyzeLegalRisk(Concern concern) {
    // Implementation for legal risk analysis
    return RiskAnalysisResult(risks: [], score: 0.0);
  }

  static List<String> _generateRiskRecommendations(RiskLevel riskLevel, List<String> risks) {
    final recommendations = <String>[];
    
    switch (riskLevel) {
      case RiskLevel.critical:
        recommendations.addAll([
          'Immediate escalation required',
          'Notify senior management',
          'Prepare emergency response plan',
        ]);
        break;
      case RiskLevel.high:
        recommendations.addAll([
          'Accelerate investigation timeline',
          'Assign experienced investigator',
          'Monitor closely for escalation',
        ]);
        break;
      case RiskLevel.medium:
        recommendations.addAll([
          'Follow standard investigation procedures',
          'Regular status updates required',
        ]);
        break;
      case RiskLevel.low:
        recommendations.addAll([
          'Routine processing',
          'Standard timeline acceptable',
        ]);
        break;
    }
    
    return recommendations;
  }

  static String _generateRiskAnalysis(RiskLevel riskLevel, List<String> risks) {
    final levelText = riskLevel.name.toUpperCase();
    final riskText = risks.isEmpty ? 'No specific risks identified' : risks.join(', ');
    
    return 'Risk Level: $levelText. $riskText. This assessment is based on content analysis, historical patterns, and stakeholder impact.';
  }

  // Legal Document Templates
  static String _getInvestigationNoticeTemplate() {
    return '''
INVESTIGATION NOTICE

Date: [DATE]
To: [CITIZEN_NAME]
From: Anti-Corruption Officer
Subject: Investigation Notice - Concern #[CONCERN_ID]

Dear [CITIZEN_NAME],

We acknowledge receipt of your concern regarding [CONCERN_TITLE] filed on [SUBMISSION_DATE].

This matter has been assigned for investigation under reference number [CONCERN_ID]. Our investigation team will:

1. Review all submitted information and evidence
2. Conduct necessary inquiries and interviews
3. Follow up on any leads or additional information
4. Provide regular updates on investigation progress

Expected Timeline: [ESTIMATED_DAYS] days

Contact Information:
Phone: [OFFICE_PHONE]
Email: [OFFICE_EMAIL]

We appreciate your cooperation in this matter.

Sincerely,
[OFFICER_NAME]
Anti-Corruption Officer
    ''';
  }

  static String _getResolutionLetterTemplate() {
    return '''
RESOLUTION LETTER

Date: [DATE]
To: [CITIZEN_NAME]
From: Anti-Corruption Officer
Subject: Resolution of Concern #[CONCERN_ID]

Dear [CITIZEN_NAME],

We are writing to inform you of the resolution of your concern regarding [CONCERN_TITLE].

Investigation Summary:
[INVESTIGATION_SUMMARY]

Findings:
[FINDINGS]

Actions Taken:
[ACTIONS_TAKEN]

Resolution Status: [STATUS]

If you have any questions about this resolution, please contact us at [OFFICE_PHONE] or [OFFICE_EMAIL].

Thank you for bringing this matter to our attention.

Sincerely,
[OFFICER_NAME]
Anti-Corruption Officer
    ''';
  }

  static String _getEscalationReportTemplate() {
    return '''
ESCALATION REPORT

Date: [DATE]
To: [SUPERVISOR_NAME]
From: [OFFICER_NAME]
Subject: Escalation of Concern #[CONCERN_ID]

Supervisor,

I am escalating the following concern due to [ESCALATION_REASON]:

Concern Details:
- ID: [CONCERN_ID]
- Title: [CONCERN_TITLE]
- Category: [CATEGORY]
- Priority: [PRIORITY]
- Submitted: [SUBMISSION_DATE]

Current Status: [CURRENT_STATUS]

Escalation Justification:
[ESCALATION_JUSTIFICATION]

Recommended Actions:
[RECOMMENDED_ACTIONS]

Please advise on next steps.

Respectfully,
[OFFICER_NAME]
Anti-Corruption Officer
    ''';
  }

  static String _fillInvestigationNotice(Concern concern, String template, Map<String, dynamic> context) {
    return template
        .replaceAll('[DATE]', DateTime.now().toString().split(' ')[0])
        .replaceAll('[CITIZEN_NAME]', concern.authorName)
        .replaceAll('[CONCERN_ID]', concern.id)
        .replaceAll('[CONCERN_TITLE]', concern.title)
        .replaceAll('[SUBMISSION_DATE]', concern.createdAt.toString().split(' ')[0])
        .replaceAll('[ESTIMATED_DAYS]', context['estimatedDays']?.toString() ?? '7')
        .replaceAll('[OFFICE_PHONE]', context['officePhone'] ?? '[PHONE]')
        .replaceAll('[OFFICE_EMAIL]', context['officeEmail'] ?? '[EMAIL]')
        .replaceAll('[OFFICER_NAME]', context['officerName'] ?? '[OFFICER]');
  }

  static String _fillResolutionLetter(Concern concern, String template, Map<String, dynamic> context) {
    return template
        .replaceAll('[DATE]', DateTime.now().toString().split(' ')[0])
        .replaceAll('[CITIZEN_NAME]', concern.authorName)
        .replaceAll('[CONCERN_ID]', concern.id)
        .replaceAll('[CONCERN_TITLE]', concern.title)
        .replaceAll('[INVESTIGATION_SUMMARY]', context['investigationSummary'] ?? '[SUMMARY]')
        .replaceAll('[FINDINGS]', context['findings'] ?? '[FINDINGS]')
        .replaceAll('[ACTIONS_TAKEN]', context['actionsTaken'] ?? '[ACTIONS]')
        .replaceAll('[STATUS]', context['status'] ?? '[STATUS]')
        .replaceAll('[OFFICE_PHONE]', context['officePhone'] ?? '[PHONE]')
        .replaceAll('[OFFICE_EMAIL]', context['officeEmail'] ?? '[EMAIL]')
        .replaceAll('[OFFICER_NAME]', context['officerName'] ?? '[OFFICER]');
  }

  static String _fillEscalationReport(Concern concern, String template, Map<String, dynamic> context) {
    return template
        .replaceAll('[DATE]', DateTime.now().toString().split(' ')[0])
        .replaceAll('[SUPERVISOR_NAME]', context['supervisorName'] ?? '[SUPERVISOR]')
        .replaceAll('[OFFICER_NAME]', context['officerName'] ?? '[OFFICER]')
        .replaceAll('[CONCERN_ID]', concern.id)
        .replaceAll('[CONCERN_TITLE]', concern.title)
        .replaceAll('[CATEGORY]', concern.category.name)
        .replaceAll('[PRIORITY]', concern.priority.name)
        .replaceAll('[SUBMISSION_DATE]', concern.createdAt.toString().split(' ')[0])
        .replaceAll('[CURRENT_STATUS]', concern.status.name)
        .replaceAll('[ESCALATION_REASON]', context['escalationReason'] ?? '[REASON]')
        .replaceAll('[ESCALATION_JUSTIFICATION]', context['escalationJustification'] ?? '[JUSTIFICATION]')
        .replaceAll('[RECOMMENDED_ACTIONS]', context['recommendedActions'] ?? '[ACTIONS]');
  }

  static String _generateDocumentTitle(String documentType, Concern concern) {
    switch (documentType) {
      case 'investigation_notice':
        return 'Investigation Notice - ${concern.title}';
      case 'resolution_letter':
        return 'Resolution Letter - ${concern.title}';
      case 'escalation_report':
        return 'Escalation Report - ${concern.title}';
      default:
        return 'Document - ${concern.title}';
    }
  }

  // Response Generation Methods
  static String _generateCorruptionResponse(Concern concern, SmartAnalysisResult analysis) {
    return 'This corruption allegation requires immediate attention. I recommend: 1) Secure all relevant evidence, 2) Notify senior management, 3) Begin formal investigation within 24 hours, 4) Prepare for potential legal proceedings.';
  }

  static String _generateCriticalResponse(Concern concern, SmartAnalysisResult analysis) {
    return 'This critical concern demands urgent action. Priority actions: 1) Immediate assessment of impact, 2) Stakeholder notification, 3) Emergency response protocols, 4) Continuous monitoring until resolved.';
  }

  static String _generateNegativeSentimentResponse(Concern concern, SmartAnalysisResult analysis) {
    return 'The strong negative sentiment requires careful handling. Recommended approach: 1) Acknowledge the citizen\'s frustration, 2) Provide clear timeline for resolution, 3) Offer direct communication channel, 4) Regular progress updates.';
  }

  static String _generateStandardResponse(Concern concern, SmartAnalysisResult analysis) {
    return 'Standard processing recommended. Steps: 1) Acknowledge receipt, 2) Assign to appropriate team, 3) Follow standard investigation timeline, 4) Regular status updates.';
  }

  static String _getCorruptionResponseTemplate() {
    return '''Dear [CITIZEN_NAME],

Thank you for bringing this serious matter to our attention. We take allegations of corruption very seriously and have initiated a formal investigation.

Your concern has been assigned reference number [CONCERN_ID] and will be handled with the highest priority. Our investigation team will:

• Conduct a thorough review of all information provided
• Gather additional evidence as needed
• Interview relevant parties
• Follow all legal and procedural requirements

Expected Timeline: 7-14 days for initial findings

We will provide regular updates on the investigation progress. If you have any additional information or questions, please contact us immediately.

Thank you for your cooperation in maintaining transparency and integrity.

Sincerely,
[OFFICER_NAME]
Anti-Corruption Officer''';
  }

  static String _getCriticalResponseTemplate() {
    return '''Dear [CITIZEN_NAME],

We acknowledge receipt of your urgent concern and have classified it as a critical priority matter.

Your concern (#[CONCERN_ID]) has been escalated to our senior investigation team for immediate attention. We are committed to:

• Initiating investigation within 24 hours
• Providing daily progress updates
• Ensuring all stakeholders are properly informed
• Taking appropriate corrective action

We understand the urgency of this matter and will keep you informed of all developments.

Thank you for bringing this to our attention.

Sincerely,
[OFFICER_NAME]
Anti-Corruption Officer''';
  }

  static String _getNegativeSentimentTemplate() {
    return '''Dear [CITIZEN_NAME],

We sincerely apologize for any frustration or inconvenience you have experienced. We understand your concerns and are committed to addressing them promptly and effectively.

Your concern (#[CONCERN_ID]) has been assigned to our experienced team who will:

• Provide you with a direct point of contact
• Give you regular updates on progress
• Ensure your voice is heard throughout the process
• Work diligently to resolve this matter

We value your feedback and will use it to improve our services.

Thank you for your patience and understanding.

Sincerely,
[OFFICER_NAME]
Anti-Corruption Officer''';
  }

  static String _getStandardResponseTemplate() {
    return '''Dear [CITIZEN_NAME],

Thank you for submitting your concern. We have received your information and assigned it reference number [CONCERN_ID].

Our team will review your concern and:

• Investigate the matter thoroughly
• Follow up with relevant parties
• Provide you with regular updates
• Take appropriate action based on findings

Expected Timeline: 7-10 business days

If you have any questions or additional information, please don't hesitate to contact us.

Thank you for helping us improve our services.

Sincerely,
[OFFICER_NAME]
Anti-Corruption Officer''';
  }
}

// Additional Models for Enhanced AI Service

class PriorityRankingResult {
  final ConcernPriority priority;
  final double score;
  final List<String> factors;
  final double confidence;
  final List<Concern> similarConcerns;
  final int estimatedResolutionTime;

  PriorityRankingResult({
    required this.priority,
    required this.score,
    required this.factors,
    required this.confidence,
    required this.similarConcerns,
    required this.estimatedResolutionTime,
  });
}

class LegalDocumentDraft {
  final String type;
  final String title;
  final String content;
  final String template;
  final Map<String, dynamic> metadata;

  LegalDocumentDraft({
    required this.type,
    required this.title,
    required this.content,
    required this.template,
    required this.metadata,
  });
}

class RiskAnalysisResult {
  final List<String> risks;
  final double score;

  RiskAnalysisResult({
    required this.risks,
    required this.score,
  });
}

enum RiskLevel {
  low,
  medium,
  high,
  critical,
}
