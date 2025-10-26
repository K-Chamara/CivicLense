import 'package:google_generative_ai/google_generative_ai.dart';
import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;

/// AI Service for Document Validation
/// Uses FREE Gemini API to detect fake, AI-generated, or forged documents
class DocumentValidationAIService {
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

  /// Analyze document image for authenticity
  /// Detects: fake documents, AI-generated, hand-made forgeries, quality issues
  static Future<DocumentValidationResult> analyzeDocument({
    required String documentUrl,
    required String userRole,
    String? documentType,
  }) async {
    try {
      print('🔍 Starting AI document validation for: $documentUrl');
      
      // Download image from URL for analysis
      final imageBytes = await _downloadImage(documentUrl);
      print('📸 Image downloaded successfully, size: ${imageBytes.length} bytes');
      
      // Determine expected document characteristics based on role
      final expectedDocs = _getExpectedDocuments(userRole);
      
      final prompt = '''
You are an expert document fraud detection AI for a Sri Lankan government anti-corruption system.

USER ROLE: $userRole
EXPECTED DOCUMENTS: ${expectedDocs.join(', ')}
DOCUMENT TYPE: ${documentType ?? 'Unknown'}

Analyze this uploaded document image and provide a detailed analysis including:

1. **DOCUMENT DESCRIPTION**
   - What type of document is this?
   - Describe the visual characteristics you can see
   - What text, logos, seals, or other elements are present?
   - What is the overall layout and design?

2. **AUTHENTICITY ASSESSMENT**
   - Is this a real government/official document?
   - Are there official stamps, signatures, seals?
   - Does it have security features (watermarks, holograms)?
   - Is the layout professional and official?

3. **FORGERY DETECTION**
   - Signs of manual editing (cut/paste, white-out)
   - Inconsistent fonts or spacing
   - Poor quality scans/photos of printed forgeries
   - Misaligned elements
   - Color inconsistencies
   - Pixelation or blur in specific areas (sign of editing)

4. **AI-GENERATED DETECTION**
   - Does this look AI-generated or fake?
   - Unrealistic text or signatures
   - AI artifacts (weird patterns, impossible details)
   - Too perfect or synthetic appearance

5. **QUALITY ASSESSMENT**
   - Image quality (resolution, clarity)
   - Completeness (all corners visible, not cropped)
   - Readability of text and details
   - Proper lighting and focus

6. **WHAT'S LACKING**
   - What required elements are missing?
   - What would make this document more credible?
   - What additional verification might be needed?

7. **APPROVAL RECOMMENDATION**
   - Should this be APPROVED, REQUEST_CLARIFICATION, or REJECTED?
   - Why or why not?
   - What specific concerns exist?

Return analysis in this EXACT JSON format:
{
  "isAuthentic": true|false,
  "confidenceScore": 0.95,
  "riskLevel": "low|medium|high|critical",
  "verdict": "APPROVED|SUSPICIOUS|LIKELY_FAKE|REJECT",
  "documentType": "Press ID Card|Business License|etc",
  "documentDescription": "Detailed description of what you see in the image",
  "whatsLacking": "What elements are missing or concerning",
  "approvalRecommendation": "APPROVE|REQUEST_CLARIFICATION|REJECT",
  "reasoning": "Detailed explanation for the recommendation",
  "detectedIssues": [
    {
      "issue": "Inconsistent font sizes",
      "severity": "medium",
      "description": "Header font appears different from body text",
      "location": "Top section"
    }
  ],
  "authenticityIndicators": {
    "hasOfficialSeal": true,
    "hasWatermark": false,
    "hasSecurityFeatures": true,
    "professionalLayout": true,
    "qualityScore": 0.85
  },
  "forgeryIndicators": {
    "manualEditing": false,
    "digitalManipulation": false,
    "aiGenerated": false,
    "inconsistentElements": false,
    "poorQualityCopy": false
  },
  "qualityAssessment": {
    "imageQuality": "high|medium|low",
    "resolution": "sufficient|insufficient",
    "completeness": "complete|partial",
    "readability": "excellent|good|poor"
  },
  "redFlags": [
    "Signature appears digitally added",
    "Date format inconsistent with Sri Lankan standards"
  ],
  "positiveIndicators": [
    "Official government seal present",
    "Proper formatting for this document type",
    "Security watermark visible"
  ],
  "adminNotes": "Detailed explanation for admin to understand the analysis and make informed decision",
  "suggestedActions": [
    "Request clearer photo",
    "Ask for additional verification",
    "Contact issuing department"
  ],
  "matchesUserRole": true|false,
  "expectedVsActual": "Expected: Press Card, Actual: Press ID Card (matches)"
}

IMPORTANT CHECKS FOR SRI LANKAN DOCUMENTS:
- Government seals should have Sri Lankan emblem
- Dates should be in DD/MM/YYYY or similar format
- Sinhala/Tamil/English text may be present
- Official stamps should be clear and aligned
- ID numbers should follow Sri Lankan formats

Be thorough and conservative - flag anything suspicious. Provide detailed descriptions so the admin can understand exactly what you see and why you're making your recommendation.
''';

      print('🤖 Sending request to Gemini API...');
      final content = [
        Content.multi([
          TextPart(prompt),
          DataPart('image/jpeg', imageBytes),
        ])
      ];

      final response = await _model.generateContent(content);
      final responseText = response.text ?? '{}';
      
      print('📝 Raw API response: $responseText');
      
      // Extract JSON from response
      String jsonText = responseText.trim();
      if (jsonText.contains('{')) {
        final startIndex = jsonText.indexOf('{');
        final endIndex = jsonText.lastIndexOf('}') + 1;
        jsonText = jsonText.substring(startIndex, endIndex);
      }
      
      print('🔍 Extracted JSON: $jsonText');
      
      final analysisData = jsonDecode(jsonText);
      
      print('✅ Document validation completed');
      return DocumentValidationResult.fromJson(analysisData);
      
    } catch (e) {
      print('❌ Document validation error: $e');
      
      // Return a fallback result with error information
      return DocumentValidationResult(
        isAuthentic: false,
        confidenceScore: 0.0,
        riskLevel: 'critical',
        verdict: 'ERROR',
        documentType: 'Unknown',
        documentDescription: 'Failed to analyze document due to technical error',
        whatsLacking: 'Unable to process document - technical error occurred',
        approvalRecommendation: 'REQUEST_CLARIFICATION',
        reasoning: 'Document analysis failed due to: $e',
        detectedIssues: [
          DetectedIssue(
            issue: 'Analysis Error',
            severity: 'critical',
            description: 'Failed to process document: $e',
            location: 'System Error'
          )
        ],
        authenticityIndicators: AuthenticityIndicators(
          hasOfficialSeal: false,
          hasWatermark: false,
          hasSecurityFeatures: false,
          professionalLayout: false,
          qualityScore: 0.0,
        ),
        forgeryIndicators: ForgeryIndicators(
          manualEditing: false,
          digitalManipulation: false,
          aiGenerated: false,
          inconsistentElements: false,
          poorQualityCopy: false,
        ),
        qualityAssessment: QualityAssessment(
          imageQuality: 'unknown',
          resolution: 'unknown',
          completeness: 'unknown',
          readability: 'unknown',
        ),
        redFlags: ['Technical error prevented analysis'],
        positiveIndicators: [],
        recommendation: 'REQUEST_CLARIFICATION',
        adminNotes: 'Document analysis failed due to technical error: $e. Please try again or contact support.',
        suggestedActions: [
          'Try uploading the document again',
          'Check internet connection',
          'Contact technical support if issue persists'
        ],
        matchesUserRole: false,
        expectedVsActual: 'Analysis failed - unable to determine',
      );
    }
  }

  /// Batch analyze multiple documents for a user
  static Future<BatchValidationResult> analyzeBatchDocuments({
    required List<String> documentUrls,
    required String userRole,
  }) async {
    try {
      print('🔍 Analyzing ${documentUrls.length} documents in batch...');
      
      final results = <DocumentValidationResult>[];
      final issues = <String>[];
      
      for (int i = 0; i < documentUrls.length; i++) {
        try {
          final result = await analyzeDocument(
            documentUrl: documentUrls[i],
            userRole: userRole,
            documentType: 'Document ${i + 1}',
          );
          results.add(result);
        } catch (e) {
          issues.add('Document ${i + 1}: Failed to analyze - $e');
        }
      }
      
      // Calculate overall assessment
      final averageConfidence = results.isEmpty ? 0.0 :
        results.map((r) => r.confidenceScore).reduce((a, b) => a + b) / results.length;
      
      final hasHighRisk = results.any((r) => r.riskLevel == 'high' || r.riskLevel == 'critical');
      final hasSuspicious = results.any((r) => r.verdict == 'SUSPICIOUS' || r.verdict == 'LIKELY_FAKE');
      
      String overallRecommendation;
      if (hasHighRisk || hasSuspicious) {
        overallRecommendation = 'REJECT';
      } else if (averageConfidence < 0.7) {
        overallRecommendation = 'REQUEST_CLARIFICATION';
      } else {
        overallRecommendation = 'APPROVE';
      }
      
      return BatchValidationResult(
        individualResults: results,
        overallConfidence: averageConfidence,
        overallRecommendation: overallRecommendation,
        hasHighRiskDocuments: hasHighRisk,
        totalDocuments: documentUrls.length,
        analyzedDocuments: results.length,
        failedDocuments: documentUrls.length - results.length,
        issues: issues,
      );
      
    } catch (e) {
      print('❌ Batch validation error: $e');
      throw Exception('Batch validation failed: $e');
    }
  }

  /// Download image from URL
  static Future<Uint8List> _downloadImage(String url) async {
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        return response.bodyBytes;
      } else {
        throw Exception('Failed to download image: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error downloading image: $e');
    }
  }

  /// Get expected documents based on user role
  static List<String> _getExpectedDocuments(String userRole) {
    switch (userRole) {
      case 'journalist':
        return ['Press Card', 'Journalist ID', 'Media Organization Letter'];
      case 'ngo':
        return ['NGO Registration Certificate', 'Organization Letter', 'Tax Exemption Certificate'];
      case 'contractor':
        return ['Business License', 'Tax Registration', 'Insurance Certificate'];
      case 'researcher':
        return ['University ID', 'Research Organization Letter', 'Academic Credentials'];
      case 'activist':
      case 'community_leader':
        return ['Community Organization Letter', 'Reference Letter', 'Membership Certificate'];
      case 'finance_officer':
      case 'procurement_officer':
      case 'anticorruption_officer':
        return ['Government ID Card', 'Department Letter', 'Employment Verification'];
      default:
        return ['Official Document', 'Verification Document'];
    }
  }

  /// Test API connection
  static Future<bool> testConnection() async {
    try {
      print('🧪 Testing Gemini API connection with gemini-2.0-flash...');
      
      final prompt = 'Respond with: {"status": "connected", "message": "API is working", "model": "gemini-2.0-flash"}';
      final content = [Content.text(prompt)];
      
      final response = await _model.generateContent(content);
      final responseText = response.text ?? '{}';
      
      print('📝 API Test Response: $responseText');
      
      // Check if response contains expected content
      if (responseText.toLowerCase().contains('connected') || 
          responseText.toLowerCase().contains('working')) {
        print('✅ API connection test successful with gemini-2.0-flash');
        return true;
      } else {
        print('⚠️ API connection test returned unexpected response');
        return false;
      }
      
    } catch (e) {
      print('❌ API connection test failed: $e');
      return false;
    }
  }

  /// Quick scan - faster analysis for initial screening
  static Future<QuickScanResult> quickScan(String documentUrl) async {
    try {
      final imageBytes = await _downloadImage(documentUrl);
      
      final prompt = '''
Quick document scan for initial screening.

Analyze this document image and return ONLY:
{
  "isLikelyLegit": true|false,
  "quickVerdict": "PASS|FLAG|FAIL",
  "mainIssue": "Brief description or 'None'",
  "needsFullAnalysis": true|false
}

Quick checks:
- Is it a clear, professional document photo?
- Any obvious signs of forgery or AI generation?
- Is it readable and complete?
''';

      final content = [
        Content.multi([
          TextPart(prompt),
          DataPart('image/jpeg', imageBytes),
        ])
      ];

      final response = await _model.generateContent(content);
      final responseText = response.text ?? '{}';
      
      String jsonText = responseText.trim();
      if (jsonText.contains('{')) {
        final startIndex = jsonText.indexOf('{');
        final endIndex = jsonText.lastIndexOf('}') + 1;
        jsonText = jsonText.substring(startIndex, endIndex);
      }
      
      final data = jsonDecode(jsonText);
      return QuickScanResult.fromJson(data);
      
    } catch (e) {
      print('❌ Quick scan error: $e');
      throw Exception('Quick scan failed: $e');
    }
  }
}

// Data Models

class DocumentValidationResult {
  final bool isAuthentic;
  final double confidenceScore;
  final String riskLevel;
  final String verdict;
  final String documentType;
  final String documentDescription;
  final String whatsLacking;
  final String approvalRecommendation;
  final String reasoning;
  final List<DetectedIssue> detectedIssues;
  final AuthenticityIndicators authenticityIndicators;
  final ForgeryIndicators forgeryIndicators;
  final QualityAssessment qualityAssessment;
  final List<String> redFlags;
  final List<String> positiveIndicators;
  final String recommendation;
  final String adminNotes;
  final List<String> suggestedActions;
  final bool matchesUserRole;
  final String expectedVsActual;

  DocumentValidationResult({
    required this.isAuthentic,
    required this.confidenceScore,
    required this.riskLevel,
    required this.verdict,
    required this.documentType,
    required this.documentDescription,
    required this.whatsLacking,
    required this.approvalRecommendation,
    required this.reasoning,
    required this.detectedIssues,
    required this.authenticityIndicators,
    required this.forgeryIndicators,
    required this.qualityAssessment,
    required this.redFlags,
    required this.positiveIndicators,
    required this.recommendation,
    required this.adminNotes,
    required this.suggestedActions,
    required this.matchesUserRole,
    required this.expectedVsActual,
  });

  factory DocumentValidationResult.fromJson(Map<String, dynamic> json) {
    return DocumentValidationResult(
      isAuthentic: json['isAuthentic'] ?? false,
      confidenceScore: (json['confidenceScore'] as num?)?.toDouble() ?? 0.0,
      riskLevel: json['riskLevel'] ?? 'high',
      verdict: json['verdict'] ?? 'SUSPICIOUS',
      documentType: json['documentType'] ?? 'Unknown',
      documentDescription: json['documentDescription'] ?? 'No description provided',
      whatsLacking: json['whatsLacking'] ?? 'Analysis pending',
      approvalRecommendation: json['approvalRecommendation'] ?? 'REJECT',
      reasoning: json['reasoning'] ?? 'Analysis pending',
      detectedIssues: (json['detectedIssues'] as List?)
          ?.map((i) => DetectedIssue.fromJson(i))
          .toList() ?? [],
      authenticityIndicators: AuthenticityIndicators.fromJson(
        json['authenticityIndicators'] ?? {}
      ),
      forgeryIndicators: ForgeryIndicators.fromJson(
        json['forgeryIndicators'] ?? {}
      ),
      qualityAssessment: QualityAssessment.fromJson(
        json['qualityAssessment'] ?? {}
      ),
      redFlags: List<String>.from(json['redFlags'] ?? []),
      positiveIndicators: List<String>.from(json['positiveIndicators'] ?? []),
      recommendation: json['recommendation'] ?? 'REJECT',
      adminNotes: json['adminNotes'] ?? 'Analysis completed',
      suggestedActions: List<String>.from(json['suggestedActions'] ?? []),
      matchesUserRole: json['matchesUserRole'] ?? false,
      expectedVsActual: json['expectedVsActual'] ?? 'Analysis pending',
    );
  }
}

class DetectedIssue {
  final String issue;
  final String severity;
  final String description;
  final String location;

  DetectedIssue({
    required this.issue,
    required this.severity,
    required this.description,
    required this.location,
  });

  factory DetectedIssue.fromJson(Map<String, dynamic> json) {
    return DetectedIssue(
      issue: json['issue'] ?? '',
      severity: json['severity'] ?? 'medium',
      description: json['description'] ?? '',
      location: json['location'] ?? 'Unknown',
    );
  }
}

class AuthenticityIndicators {
  final bool hasOfficialSeal;
  final bool hasWatermark;
  final bool hasSecurityFeatures;
  final bool professionalLayout;
  final double qualityScore;

  AuthenticityIndicators({
    required this.hasOfficialSeal,
    required this.hasWatermark,
    required this.hasSecurityFeatures,
    required this.professionalLayout,
    required this.qualityScore,
  });

  factory AuthenticityIndicators.fromJson(Map<String, dynamic> json) {
    return AuthenticityIndicators(
      hasOfficialSeal: json['hasOfficialSeal'] ?? false,
      hasWatermark: json['hasWatermark'] ?? false,
      hasSecurityFeatures: json['hasSecurityFeatures'] ?? false,
      professionalLayout: json['professionalLayout'] ?? false,
      qualityScore: (json['qualityScore'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

class ForgeryIndicators {
  final bool manualEditing;
  final bool digitalManipulation;
  final bool aiGenerated;
  final bool inconsistentElements;
  final bool poorQualityCopy;

  ForgeryIndicators({
    required this.manualEditing,
    required this.digitalManipulation,
    required this.aiGenerated,
    required this.inconsistentElements,
    required this.poorQualityCopy,
  });

  factory ForgeryIndicators.fromJson(Map<String, dynamic> json) {
    return ForgeryIndicators(
      manualEditing: json['manualEditing'] ?? false,
      digitalManipulation: json['digitalManipulation'] ?? false,
      aiGenerated: json['aiGenerated'] ?? false,
      inconsistentElements: json['inconsistentElements'] ?? false,
      poorQualityCopy: json['poorQualityCopy'] ?? false,
    );
  }
}

class QualityAssessment {
  final String imageQuality;
  final String resolution;
  final String completeness;
  final String readability;

  QualityAssessment({
    required this.imageQuality,
    required this.resolution,
    required this.completeness,
    required this.readability,
  });

  factory QualityAssessment.fromJson(Map<String, dynamic> json) {
    return QualityAssessment(
      imageQuality: json['imageQuality'] ?? 'low',
      resolution: json['resolution'] ?? 'insufficient',
      completeness: json['completeness'] ?? 'partial',
      readability: json['readability'] ?? 'poor',
    );
  }
}

class BatchValidationResult {
  final List<DocumentValidationResult> individualResults;
  final double overallConfidence;
  final String overallRecommendation;
  final bool hasHighRiskDocuments;
  final int totalDocuments;
  final int analyzedDocuments;
  final int failedDocuments;
  final List<String> issues;

  BatchValidationResult({
    required this.individualResults,
    required this.overallConfidence,
    required this.overallRecommendation,
    required this.hasHighRiskDocuments,
    required this.totalDocuments,
    required this.analyzedDocuments,
    required this.failedDocuments,
    required this.issues,
  });
}

class QuickScanResult {
  final bool isLikelyLegit;
  final String quickVerdict;
  final String mainIssue;
  final bool needsFullAnalysis;

  QuickScanResult({
    required this.isLikelyLegit,
    required this.quickVerdict,
    required this.mainIssue,
    required this.needsFullAnalysis,
  });

  factory QuickScanResult.fromJson(Map<String, dynamic> json) {
    return QuickScanResult(
      isLikelyLegit: json['isLikelyLegit'] ?? false,
      quickVerdict: json['quickVerdict'] ?? 'FLAG',
      mainIssue: json['mainIssue'] ?? 'Unknown',
      needsFullAnalysis: json['needsFullAnalysis'] ?? true,
    );
  }
}

