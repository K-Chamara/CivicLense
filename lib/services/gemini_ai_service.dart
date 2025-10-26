import 'package:google_generative_ai/google_generative_ai.dart';
import '../models/concern_models.dart';
import 'dart:convert';

class GeminiAIService {
  // Your Gemini API Key
  static const String _apiKey = 'AIzaSyCa_3C65rqlj6xOZNtjHQSjQ_h8c42dz2w';
  
  // Initialize Gemini model
  static final _model = GenerativeModel(
    model: 'gemini-2.0-flash-exp',
    apiKey: _apiKey,
  );

  /// Generate content using Gemini AI
  static Future<String> generateContent(String prompt) async {
    try {
      final content = [Content.text(prompt)];
      final response = await _model.generateContent(content);
      return response.text?.trim() ?? '';
    } catch (e) {
      print('❌ Gemini content generation failed: $e');
      rethrow;
    }
  }

  /// OPTIMIZED: Generate all concern suggestions in ONE API call
  static Future<ComprehensiveSuggestions> generateAllSuggestions({
    required String description,
  }) async {
    try {
      final prompt = '''
Analyze this concern description and provide comprehensive suggestions:

Description: $description

Provide your analysis in this EXACT JSON format:
{
  "suggestedTitle": "Clear, concise title (max 100 characters)",
  "suggestedCategory": "budget|tender|corruption|transparency|community|system|other",
  "suggestedType": "complaint|suggestion|question|report",
  "priority": "critical|high|medium|low",
  "sentiment": "veryNegative|negative|neutral|positive|veryPositive",
  "confidence": 0.92,
  "topics": ["topic1", "topic2", "topic3"],
  "descriptionFeedback": {
    "strengths": ["Good: Description is detailed", "Good: Includes specific location"],
    "improvements": ["Add specific dates/timeframe", "Include monetary amounts if available"],
    "overallQuality": "good|fair|needs_improvement"
  }
}

Consider:
- Sri Lankan context and laws
- Corruption severity
- Public impact
- Financial amounts mentioned
- Urgency indicators
- Location specifics

IMPORTANT: 
- For category: Choose the most relevant category based on keywords
- For type: complaint (negative), suggestion (positive), report (urgent), question (neutral)
- For feedback: Be specific and actionable
- Return ONLY valid JSON, no other text

Available categories:
- budget: Budget allocation issues, fund misuse
- tender: Tender fraud, contract irregularities  
- corruption: Bribery, embezzlement, fraud
- transparency: Access to information issues
- community: Community-related concerns
- system: Technical or system issues
- other: General concerns
''';

      final content = [Content.text(prompt)];
      final response = await _model.generateContent(content);
      final responseText = response.text ?? '{}';
      
      // Extract JSON from response
      String jsonText = responseText.trim();
      if (jsonText.contains('{')) {
        final startIndex = jsonText.indexOf('{');
        final endIndex = jsonText.lastIndexOf('}') + 1;
        jsonText = jsonText.substring(startIndex, endIndex);
      }
      
      final data = jsonDecode(jsonText);
      
      return ComprehensiveSuggestions.fromJson(data);
    } catch (e) {
      print('❌ Comprehensive suggestions failed: $e');
      rethrow;
    }
  }

  /// Analyze concern and return comprehensive AI analysis
  static Future<GeminiAnalysisResult> analyzeConcern({
    required String title,
    required String description,
    required ConcernCategory category,
  }) async {
    try {
      final prompt = '''
Analyze this civic concern report for an anti-corruption system in Sri Lanka:

Title: $title
Description: $description
Category: ${category.name}

Provide a comprehensive analysis in this EXACT JSON format:
{
  "priority": "critical|high|medium|low",
  "priorityScore": 0.85,
  "sentiment": "veryNegative|negative|neutral|positive|veryPositive",
  "sentimentScore": -0.75,
  "confidence": 0.92,
  "topics": ["corruption", "financial", "legal"],
  "reasoning": "Detailed explanation of why this priority was assigned",
  "suggestedActions": [
    "Specific action item 1",
    "Specific action item 2"
  ],
  "urgencyLevel": 8,
  "estimatedResolutionDays": 14,
  "legalImplications": ["Bribery Act violation"],
  "departments": ["Department of Roads"],
  "locations": ["Colombo"],
  "amounts": ["Rs. 50,000"]
}

Consider:
- Sri Lankan context and laws
- Corruption severity
- Public impact
- Financial amounts mentioned
- Urgency indicators
- Legal violations

IMPORTANT: For sentiment analysis:
- "hate", "fucking", "useless", "shit" = VERY NEGATIVE (-0.8 to -1.0)
- "terrible", "awful", "disgusting" = NEGATIVE (-0.5 to -0.8)
- "okay", "fine", "normal" = NEUTRAL (-0.2 to 0.2)
- "good", "great", "excellent" = POSITIVE (0.5 to 0.8)

Return ONLY valid JSON, no other text.
''';

      final content = [Content.text(prompt)];
      final response = await _model.generateContent(content);
      final responseText = response.text ?? '{}';
      
      // Extract JSON from response (in case there's any extra text)
      String jsonText = responseText.trim();
      if (jsonText.contains('{')) {
        final startIndex = jsonText.indexOf('{');
        final endIndex = jsonText.lastIndexOf('}') + 1;
        jsonText = jsonText.substring(startIndex, endIndex);
      }
      
      final analysisData = jsonDecode(jsonText);
      
      return GeminiAnalysisResult.fromJson(analysisData);
    } catch (e) {
      print('❌ Gemini API error: $e');
      // Return null to fall back to keyword-based system
      throw Exception('Gemini analysis failed: $e');
    }
  }

  /// Suggest category based on description
  static Future<CategorySuggestion> suggestCategory({
    required String title,
    required String description,
  }) async {
    try {
      final prompt = '''
Based on this concern, suggest the most appropriate category:

Title: $title
Description: $description

Available categories:
- budget: Budget allocation issues, fund misuse
- tender: Tender fraud, contract irregularities
- corruption: Bribery, embezzlement, fraud
- transparency: Access to information issues
- community: Community-related concerns
- system: Technical or system issues
- other: General concerns

Return ONLY valid JSON:
{
  "suggestedCategory": "corruption",
  "confidence": 0.95,
  "reasoning": "Contains bribery allegations and financial fraud"
}
''';

      final content = [Content.text(prompt)];
      final response = await _model.generateContent(content);
      final responseText = response.text ?? '{}';
      
      String jsonText = responseText.trim();
      if (jsonText.contains('{')) {
        final startIndex = jsonText.indexOf('{');
        final endIndex = jsonText.lastIndexOf('}') + 1;
        jsonText = jsonText.substring(startIndex, endIndex);
      }
      
      final data = jsonDecode(jsonText);
      
      return CategorySuggestion(
        category: _parseConcernCategory(data['suggestedCategory']),
        confidence: (data['confidence'] as num?)?.toDouble() ?? 0.0,
        reasoning: data['reasoning'] as String? ?? '',
      );
    } catch (e) {
      print('❌ Category suggestion failed: $e');
      throw Exception('Category suggestion failed: $e');
    }
  }

  /// Analyze content for moderation (community posts)
  static Future<String> analyzeContentModeration(String content) async {
    try {
      final prompt = '''
Analyze this community post content for potential violations:

Content: "$content"

Check for:
1. Hate speech or discrimination
2. Spam or promotional content
3. Inappropriate language
4. Misinformation or fake news
5. Personal attacks or harassment
6. Off-topic content
7. Copyright violations
8. Threats or violence
9. Adult content
10. Political propaganda

Provide your analysis in this format:
VIOLATION STATUS: [SAFE/FLAGGED/DANGEROUS]
VIOLATION TYPE: [None/Spam/Hate Speech/Misinformation/Inappropriate/etc.]
CONFIDENCE: [0.0-1.0]
REASONING: [Detailed explanation of your assessment]
RECOMMENDED ACTION: [Approve/Warning/Reject/Delete]
ADDITIONAL NOTES: [Any additional context or recommendations]

Consider Sri Lankan context and cultural sensitivities.
''';

      final response = await _model.generateContent([Content.text(prompt)]);
      return response.text ?? 'Unable to analyze content';
    } catch (e) {
      print('❌ Gemini content moderation error: $e');
      return 'Error analyzing content: $e';
    }
  }

  /// Check quality and completeness of concern
  static Future<QualityCheck> checkQuality({
    required String title,
    required String description,
  }) async {
    try {
      final prompt = '''
Evaluate the quality and completeness of this concern report:

Title: $title
Description: $description

Analyze and return ONLY valid JSON:
{
  "qualityScore": 0.75,
  "missingElements": ["specific date", "department name"],
  "suggestions": [
    "Add when this occurred (date and time)",
    "Specify which department or office",
    "Include any evidence you have"
  ],
  "strengths": ["Clear description", "Specific allegations"],
  "isSubmittable": true
}
''';

      final content = [Content.text(prompt)];
      final response = await _model.generateContent(content);
      final responseText = response.text ?? '{}';
      
      String jsonText = responseText.trim();
      if (jsonText.contains('{')) {
        final startIndex = jsonText.indexOf('{');
        final endIndex = jsonText.lastIndexOf('}') + 1;
        jsonText = jsonText.substring(startIndex, endIndex);
      }
      
      final data = jsonDecode(jsonText);
      
      return QualityCheck(
        qualityScore: (data['qualityScore'] as num?)?.toDouble() ?? 0.0,
        missingElements: List<String>.from(data['missingElements'] ?? []),
        suggestions: List<String>.from(data['suggestions'] ?? []),
        strengths: List<String>.from(data['strengths'] ?? []),
        isSubmittable: data['isSubmittable'] as bool? ?? true,
      );
    } catch (e) {
      print('❌ Quality check failed: $e');
      throw Exception('Quality check failed: $e');
    }
  }

  /// Find similar existing concerns
  static Future<List<SimilarConcern>> findSimilarConcerns({
    required String title,
    required String description,
    required List<Concern> existingConcerns,
  }) async {
    try {
      // Limit to recent concerns for performance
      final recentConcerns = existingConcerns.take(50).toList();
      
      final concernsList = recentConcerns.map((c) => 
        'ID: ${c.id}, Title: ${c.title}, Description: ${c.description.substring(0, c.description.length > 100 ? 100 : c.description.length)}...'
      ).join('\n');

      final prompt = '''
Compare this NEW concern with existing concerns and find similar ones:

NEW CONCERN:
Title: $title
Description: $description

EXISTING CONCERNS:
$concernsList

Return ONLY valid JSON array of similar concerns (max 3):
[
  {
    "concernId": "abc123",
    "similarity": 0.87,
    "reason": "Both involve bribery in tender process"
  }
]

Only include similarities above 70% (0.70). If none found, return [].
''';

      final content = [Content.text(prompt)];
      final response = await _model.generateContent(content);
      final responseText = response.text ?? '[]';
      
      String jsonText = responseText.trim();
      if (jsonText.contains('[')) {
        final startIndex = jsonText.indexOf('[');
        final endIndex = jsonText.lastIndexOf(']') + 1;
        jsonText = jsonText.substring(startIndex, endIndex);
      }
      
      final dataList = jsonDecode(jsonText) as List;
      
      return dataList.map((item) => SimilarConcern(
        concernId: item['concernId'] as String,
        similarity: (item['similarity'] as num).toDouble(),
        reason: item['reason'] as String,
      )).toList();
    } catch (e) {
      print('❌ Similar concerns check failed: $e');
      // Return empty list on error
      return [];
    }
  }

  /// Parse string to ConcernCategory enum
  static ConcernCategory _parseConcernCategory(String? categoryStr) {
    switch (categoryStr?.toLowerCase()) {
      case 'budget':
        return ConcernCategory.budget;
      case 'tender':
        return ConcernCategory.tender;
      case 'corruption':
        return ConcernCategory.corruption;
      case 'transparency':
        return ConcernCategory.transparency;
      case 'community':
        return ConcernCategory.community;
      case 'system':
        return ConcernCategory.system;
      default:
        return ConcernCategory.other;
    }
  }

  /// Parse priority string to ConcernPriority enum
  static ConcernPriority parsePriority(String? priority) {
    switch (priority?.toLowerCase()) {
      case 'critical':
        return ConcernPriority.critical;
      case 'high':
        return ConcernPriority.high;
      case 'medium':
        return ConcernPriority.medium;
      case 'low':
        return ConcernPriority.low;
      default:
        return ConcernPriority.medium;
    }
  }

  /// Parse sentiment string to SentimentScore enum
  static SentimentScore parseSentiment(String? sentiment) {
    switch (sentiment?.toLowerCase()) {
      case 'verypositive':
        return SentimentScore.veryPositive;
      case 'positive':
        return SentimentScore.positive;
      case 'neutral':
        return SentimentScore.neutral;
      case 'negative':
        return SentimentScore.negative;
      case 'verynegative':
        return SentimentScore.veryNegative;
      default:
        return SentimentScore.neutral;
    }
  }

  /// Parse concern type string to ConcernType enum
  static ConcernType _parseConcernType(String? type) {
    switch (type?.toLowerCase()) {
      case 'complaint':
        return ConcernType.complaint;
      case 'suggestion':
        return ConcernType.suggestion;
      case 'question':
        return ConcernType.question;
      case 'report':
        return ConcernType.report;
      default:
        return ConcernType.complaint;
    }
  }
}

// Data Models

class GeminiAnalysisResult {
  final ConcernPriority priority;
  final double priorityScore;
  final SentimentScore sentiment;
  final double sentimentScore;
  final double confidence;
  final List<String> topics;
  final String reasoning;
  final List<String> suggestedActions;
  final int urgencyLevel;
  final int estimatedResolutionDays;
  final List<String> legalImplications;
  final List<String> departments;
  final List<String> locations;
  final List<String> amounts;

  GeminiAnalysisResult({
    required this.priority,
    required this.priorityScore,
    required this.sentiment,
    required this.sentimentScore,
    required this.confidence,
    required this.topics,
    required this.reasoning,
    required this.suggestedActions,
    required this.urgencyLevel,
    required this.estimatedResolutionDays,
    required this.legalImplications,
    required this.departments,
    required this.locations,
    required this.amounts,
  });

  factory GeminiAnalysisResult.fromJson(Map<String, dynamic> json) {
    return GeminiAnalysisResult(
      priority: GeminiAIService.parsePriority(json['priority']),
      priorityScore: (json['priorityScore'] as num?)?.toDouble() ?? 0.5,
      sentiment: GeminiAIService.parseSentiment(json['sentiment']),
      sentimentScore: (json['sentimentScore'] as num?)?.toDouble() ?? 0.0,
      confidence: (json['confidence'] as num?)?.toDouble() ?? 0.0,
      topics: List<String>.from(json['topics'] ?? []),
      reasoning: json['reasoning'] as String? ?? '',
      suggestedActions: List<String>.from(json['suggestedActions'] ?? []),
      urgencyLevel: json['urgencyLevel'] as int? ?? 5,
      estimatedResolutionDays: json['estimatedResolutionDays'] as int? ?? 30,
      legalImplications: List<String>.from(json['legalImplications'] ?? []),
      departments: List<String>.from(json['departments'] ?? []),
      locations: List<String>.from(json['locations'] ?? []),
      amounts: List<String>.from(json['amounts'] ?? []),
    );
  }
}

class CategorySuggestion {
  final ConcernCategory category;
  final double confidence;
  final String reasoning;

  CategorySuggestion({
    required this.category,
    required this.confidence,
    required this.reasoning,
  });
}

class QualityCheck {
  final double qualityScore;
  final List<String> missingElements;
  final List<String> suggestions;
  final List<String> strengths;
  final bool isSubmittable;

  QualityCheck({
    required this.qualityScore,
    required this.missingElements,
    required this.suggestions,
    required this.strengths,
    required this.isSubmittable,
  });
}

class SimilarConcern {
  final String concernId;
  final double similarity;
  final String reason;

  SimilarConcern({
    required this.concernId,
    required this.similarity,
    required this.reason,
  });
}

/// OPTIMIZED: Comprehensive suggestions from a single API call
class ComprehensiveSuggestions {
  final String suggestedTitle;
  final ConcernCategory suggestedCategory;
  final ConcernType suggestedType;
  final ConcernPriority priority;
  final SentimentScore sentiment;
  final double confidence;
  final List<String> topics;
  final DescriptionFeedback descriptionFeedback;

  ComprehensiveSuggestions({
    required this.suggestedTitle,
    required this.suggestedCategory,
    required this.suggestedType,
    required this.priority,
    required this.sentiment,
    required this.confidence,
    required this.topics,
    required this.descriptionFeedback,
  });

  factory ComprehensiveSuggestions.fromJson(Map<String, dynamic> json) {
    return ComprehensiveSuggestions(
      suggestedTitle: json['suggestedTitle'] as String? ?? 'Untitled Concern',
      suggestedCategory: GeminiAIService._parseConcernCategory(json['suggestedCategory']),
      suggestedType: GeminiAIService._parseConcernType(json['suggestedType']),
      priority: GeminiAIService.parsePriority(json['priority']),
      sentiment: GeminiAIService.parseSentiment(json['sentiment']),
      confidence: (json['confidence'] as num?)?.toDouble() ?? 0.0,
      topics: (json['topics'] as List?)?.map((e) => e.toString()).toList() ?? [],
      descriptionFeedback: DescriptionFeedback.fromJson(json['descriptionFeedback'] ?? {}),
    );
  }
}

class DescriptionFeedback {
  final List<String> strengths;
  final List<String> improvements;
  final String overallQuality;

  DescriptionFeedback({
    required this.strengths,
    required this.improvements,
    required this.overallQuality,
  });

  factory DescriptionFeedback.fromJson(Map<String, dynamic> json) {
    return DescriptionFeedback(
      strengths: (json['strengths'] as List?)?.map((e) => e.toString()).toList() ?? [],
      improvements: (json['improvements'] as List?)?.map((e) => e.toString()).toList() ?? [],
      overallQuality: json['overallQuality'] as String? ?? 'fair',
    );
  }

  String get formattedFeedback {
    final buffer = StringBuffer();
    
    if (strengths.isNotEmpty) {
      buffer.writeln('✅ Strengths:');
      for (final strength in strengths) {
        buffer.writeln('  • $strength');
      }
      buffer.writeln();
    }
    
    if (improvements.isNotEmpty) {
      buffer.writeln('💡 Suggestions for Improvement:');
      for (final improvement in improvements) {
        buffer.writeln('  • $improvement');
      }
    }
    
    return buffer.toString().trim();
  }
}

