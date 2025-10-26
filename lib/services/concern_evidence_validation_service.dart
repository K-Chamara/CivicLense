import 'package:google_generative_ai/google_generative_ai.dart';
import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';

/// AI Service for Concern Evidence Validation
/// Uses FREE Gemini API to analyze evidence images uploaded with concerns
class ConcernEvidenceValidationService {
  static const String _apiKey = 'AIzaSyCa_3C65rqlj6xOZNtjHQSjQ_h8c42dz2w';
  
  static final _model = GenerativeModel(
    model: 'gemini-2.0-flash',
    apiKey: _apiKey,
    generationConfig: GenerationConfig(
      temperature: 0.1,
      topK: 32,
      topP: 1,
      maxOutputTokens: 4096,
    ),
  );

  /// Analyze evidence image for authenticity and relevance
  /// Detects: fake images, AI-generated, manipulated, relevance to concern
  static Future<EvidenceValidationResult> analyzeEvidence({
    required String imageUrl,
    required String concernTitle,
    required String concernDescription,
    String? evidenceType,
  }) async {
    String responseText = '';
    
    try {
      print('🔍 Starting AI evidence validation for: $imageUrl');
      
      // Download image from URL for analysis
      final imageBytes = await _downloadImage(imageUrl);
      print('📸 Evidence image downloaded successfully, size: ${imageBytes.length} bytes');
      
      final prompt = '''
You are an expert evidence analysis AI for a Sri Lankan government anti-corruption system.

CONCERN DETAILS:
Title: $concernTitle
Description: $concernDescription
Evidence Type: ${evidenceType ?? 'Unknown'}

Analyze this evidence image and provide a detailed analysis including:

1. **EVIDENCE DESCRIPTION**
   - What type of evidence is this? (document, photo, screenshot, etc.)
   - Describe the visual content you can see
   - What text, objects, people, or scenes are present?
   - What is the overall context and setting?

2. **AUTHENTICITY ASSESSMENT**
   - Is this evidence likely authentic/genuine?
   - Are there signs of manipulation, editing, or AI generation?
   - Does the image quality and details suggest it's real?
   - Are there any suspicious elements or inconsistencies?

3. **RELEVANCE TO CONCERN**
   - How relevant is this evidence to the reported concern?
   - Does it support or contradict the concern description?
   - What specific aspects of the concern does it address?
   - Is it strong supporting evidence or weak/irrelevant?

4. **EVIDENCE QUALITY**
   - Is the image clear and readable?
   - Are important details visible?
   - Is the evidence complete or partial?
   - Any quality issues that affect usability?

5. **LEGAL AND INVESTIGATIVE VALUE**
   - What legal implications does this evidence suggest?
   - How useful would this be for investigation?
   - What follow-up actions might be needed?
   - Any red flags or concerns about the evidence?

Provide your analysis in this EXACT JSON format:
{
  "evidenceType": "document|photo|screenshot|other",
  "description": "Detailed description of what you see",
  "authenticity": "AUTHENTIC|SUSPICIOUS|LIKELY_FAKE|INCONCLUSIVE",
  "authenticityScore": 0.85,
  "relevance": "HIGHLY_RELEVANT|RELEVANT|SOMEWHAT_RELEVANT|NOT_RELEVANT",
  "relevanceScore": 0.9,
  "quality": "EXCELLENT|GOOD|FAIR|POOR",
  "qualityScore": 0.8,
  "investigativeValue": "HIGH|MEDIUM|LOW|NONE",
  "confidence": 0.9,
  "redFlags": ["List of any suspicious elements"],
  "positiveIndicators": ["List of authentic elements"],
  "recommendations": ["Specific action items for investigators"],
  "legalImplications": ["Legal considerations"],
  "followUpActions": ["Suggested next steps"]
}

Consider:
- Sri Lankan context and legal system
- Anti-corruption investigation standards
- Evidence admissibility requirements
- Digital forensics best practices
- Image analysis techniques

CRITICAL: Return ONLY valid JSON object, no markdown formatting, no code blocks, no explanations, no additional text. Just the raw JSON object starting with { and ending with }.
''';

      final content = [
        Content.multi([
          TextPart(prompt),
          DataPart('image/jpeg', imageBytes),
        ])
      ];

      final response = await _model.generateContent(content);
      responseText = response.text ?? '{}';
      
      print('🤖 AI Response received: ${responseText.length} characters');
      
      // Extract JSON from response (handle markdown formatting)
      String jsonText = responseText.trim();
      
      // Remove markdown code blocks if present
      if (jsonText.contains('```json')) {
        final startIndex = jsonText.indexOf('```json') + 7;
        final endIndex = jsonText.lastIndexOf('```');
        if (endIndex > startIndex) {
          jsonText = jsonText.substring(startIndex, endIndex).trim();
        }
      } else if (jsonText.contains('```')) {
        final startIndex = jsonText.indexOf('```') + 3;
        final endIndex = jsonText.lastIndexOf('```');
        if (endIndex > startIndex) {
          jsonText = jsonText.substring(startIndex, endIndex).trim();
        }
      }
      
      // Find JSON object boundaries
      if (jsonText.contains('{')) {
        final startIndex = jsonText.indexOf('{');
        final endIndex = jsonText.lastIndexOf('}') + 1;
        if (endIndex > startIndex) {
          jsonText = jsonText.substring(startIndex, endIndex);
        }
      }
      
      print('🧹 Cleaned JSON: ${jsonText.substring(0, jsonText.length > 200 ? 200 : jsonText.length)}...');
      
      // Parse JSON response
      final jsonResponse = jsonDecode(jsonText) as Map<String, dynamic>;
      
      return EvidenceValidationResult.fromJson(jsonResponse);
      
    } catch (e) {
      print('❌ Error analyzing evidence: $e');
      if (responseText.isNotEmpty) {
        print('🔍 Response text was: ${responseText.length > 500 ? responseText.substring(0, 500) + "..." : responseText}');
      }
      
      // Return an error result
      return EvidenceValidationResult.error('Failed to analyze evidence: $e');
    }
  }

  /// Download image from URL
  static Future<Uint8List> _downloadImage(String imageUrl) async {
    try {
      final response = await http.get(Uri.parse(imageUrl));
      if (response.statusCode == 200) {
        return response.bodyBytes;
      } else {
        throw Exception('Failed to download image: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error downloading image: $e');
    }
  }

  /// Analyze multiple evidence images
  static Future<List<EvidenceValidationResult>> analyzeMultipleEvidence({
    required List<String> imageUrls,
    required String concernTitle,
    required String concernDescription,
  }) async {
    final results = <EvidenceValidationResult>[];
    
    for (int i = 0; i < imageUrls.length; i++) {
      try {
        final result = await analyzeEvidence(
          imageUrl: imageUrls[i],
          concernTitle: concernTitle,
          concernDescription: concernDescription,
          evidenceType: 'Evidence ${i + 1}',
        );
        results.add(result);
      } catch (e) {
        results.add(EvidenceValidationResult.error('Failed to analyze evidence ${i + 1}: $e'));
      }
    }
    
    return results;
  }
}

/// Result of evidence validation analysis
class EvidenceValidationResult {
  final String evidenceType;
  final String description;
  final String authenticity;
  final double authenticityScore;
  final String relevance;
  final double relevanceScore;
  final String quality;
  final double qualityScore;
  final String investigativeValue;
  final double confidence;
  final List<String> redFlags;
  final List<String> positiveIndicators;
  final List<String> recommendations;
  final List<String> legalImplications;
  final List<String> followUpActions;
  final bool isError;
  final String? errorMessage;

  EvidenceValidationResult({
    required this.evidenceType,
    required this.description,
    required this.authenticity,
    required this.authenticityScore,
    required this.relevance,
    required this.relevanceScore,
    required this.quality,
    required this.qualityScore,
    required this.investigativeValue,
    required this.confidence,
    required this.redFlags,
    required this.positiveIndicators,
    required this.recommendations,
    required this.legalImplications,
    required this.followUpActions,
    this.isError = false,
    this.errorMessage,
  });

  factory EvidenceValidationResult.fromJson(Map<String, dynamic> json) {
    return EvidenceValidationResult(
      evidenceType: json['evidenceType'] ?? 'unknown',
      description: json['description'] ?? 'No description available',
      authenticity: json['authenticity'] ?? 'INCONCLUSIVE',
      authenticityScore: (json['authenticityScore'] as num?)?.toDouble() ?? 0.0,
      relevance: json['relevance'] ?? 'NOT_RELEVANT',
      relevanceScore: (json['relevanceScore'] as num?)?.toDouble() ?? 0.0,
      quality: json['quality'] ?? 'POOR',
      qualityScore: (json['qualityScore'] as num?)?.toDouble() ?? 0.0,
      investigativeValue: json['investigativeValue'] ?? 'NONE',
      confidence: (json['confidence'] as num?)?.toDouble() ?? 0.0,
      redFlags: List<String>.from(json['redFlags'] ?? []),
      positiveIndicators: List<String>.from(json['positiveIndicators'] ?? []),
      recommendations: List<String>.from(json['recommendations'] ?? []),
      legalImplications: List<String>.from(json['legalImplications'] ?? []),
      followUpActions: List<String>.from(json['followUpActions'] ?? []),
    );
  }

  factory EvidenceValidationResult.error(String message) {
    return EvidenceValidationResult(
      evidenceType: 'error',
      description: 'Error occurred during analysis',
      authenticity: 'INCONCLUSIVE',
      authenticityScore: 0.0,
      relevance: 'NOT_RELEVANT',
      relevanceScore: 0.0,
      quality: 'POOR',
      qualityScore: 0.0,
      investigativeValue: 'NONE',
      confidence: 0.0,
      redFlags: [],
      positiveIndicators: [],
      recommendations: [],
      legalImplications: [],
      followUpActions: [],
      isError: true,
      errorMessage: message,
    );
  }

  /// Get overall recommendation based on analysis
  String get overallRecommendation {
    if (isError) return 'ERROR';
    
    if (authenticity == 'LIKELY_FAKE' && confidence > 0.8) {
      return 'REJECT';
    } else if (authenticity == 'SUSPICIOUS' && relevance == 'NOT_RELEVANT') {
      return 'REJECT';
    } else if (authenticity == 'AUTHENTIC' && relevance == 'HIGHLY_RELEVANT' && investigativeValue == 'HIGH') {
      return 'ACCEPT';
    } else if (authenticity == 'AUTHENTIC' && relevance == 'RELEVANT') {
      return 'ACCEPT';
    } else if (authenticity == 'SUSPICIOUS' && relevance == 'RELEVANT') {
      return 'REVIEW';
    } else {
      return 'REVIEW';
    }
  }

  /// Get color for recommendation
  Color get recommendationColor {
    switch (overallRecommendation) {
      case 'ACCEPT':
        return const Color(0xFF4CAF50); // Green
      case 'REVIEW':
        return const Color(0xFFFF9800); // Orange
      case 'REJECT':
        return const Color(0xFFF44336); // Red
      default:
        return const Color(0xFF9E9E9E); // Grey
    }
  }
}
