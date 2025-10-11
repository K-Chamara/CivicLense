import 'package:google_generative_ai/google_generative_ai.dart';
import '../models/concern_models.dart';
import 'dart:convert';

/// AI Service for Anti-Corruption Officers
/// Provides intelligent analysis, pattern detection, and investigation assistance
class OfficerAIService {
  static const String _apiKey = 'AIzaSyCa_3C65rqlj6xOZNtjHQSjQ_h8c42dz2w';
  
  static final _model = GenerativeModel(
    model: 'gemini-2.0-flash-exp',
    apiKey: _apiKey,
  );

  /// 1. Intelligent Priority Ranking
  /// Re-ranks concerns based on officer's context and investigation load
  static Future<List<RankedConcern>> rankConcerns({
    required List<Concern> concerns,
    required int currentCaseLoad,
    String? focusArea, // e.g., "corruption", "tender", "budget"
  }) async {
    try {
      final concernsList = concerns.take(20).map((c) => 
        'ID: ${c.id}, Title: ${c.title}, Category: ${c.category.name}, '
        'Priority: ${c.priority.name}, Submitted: ${c.createdAt}'
      ).join('\n');

      final prompt = '''
You are an AI assistant for anti-corruption officers in Sri Lanka.

OFFICER CONTEXT:
- Current case load: $currentCaseLoad active cases
- Focus area: ${focusArea ?? 'general'}

CONCERNS TO RANK:
$concernsList

Re-rank these concerns for investigation priority considering:
1. Severity and public impact
2. Time sensitivity
3. Evidence quality
4. Legal implications
5. Officer's current workload

Return ONLY valid JSON array (max 10 concerns):
[
  {
    "concernId": "abc123",
    "newRank": 1,
    "urgencyScore": 95,
    "reasoning": "Critical corruption with solid evidence, requires immediate action",
    "recommendedTimeframe": "24 hours",
    "estimatedInvestigationDays": 7
  }
]

Order by urgency (highest first). If >10 concerns, return top 10 only.
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
      
      return dataList.map((item) => RankedConcern(
        concernId: item['concernId'] as String,
        newRank: item['newRank'] as int,
        urgencyScore: (item['urgencyScore'] as num).toInt(),
        reasoning: item['reasoning'] as String,
        recommendedTimeframe: item['recommendedTimeframe'] as String,
        estimatedInvestigationDays: item['estimatedInvestigationDays'] as int,
      )).toList();
    } catch (e) {
      print('❌ Priority ranking failed: $e');
      return [];
    }
  }

  /// 2. Duplicate Detection
  /// Find potential duplicate concerns before processing
  static Future<List<DuplicateConcern>> findDuplicates({
    required Concern newConcern,
    required List<Concern> existingConcerns,
  }) async {
    try {
      final recentConcerns = existingConcerns.take(50).toList();
      
      final concernsList = recentConcerns.map((c) => 
        'ID: ${c.id}, Title: ${c.title}, '
        'Description: ${c.description.substring(0, c.description.length > 150 ? 150 : c.description.length)}..., '
        'Status: ${c.status.name}'
      ).join('\n');

      final prompt = '''
Analyze if this NEW concern is a duplicate of existing concerns:

NEW CONCERN:
Title: ${newConcern.title}
Description: ${newConcern.description}
Category: ${newConcern.category.name}

EXISTING CONCERNS:
$concernsList

Find potential duplicates and return ONLY valid JSON:
[
  {
    "concernId": "xyz789",
    "similarity": 0.92,
    "reason": "Same tender fraud allegation, same department, similar timeframe",
    "recommendation": "merge|link|separate",
    "actionSuggestion": "Link to existing case #xyz789 and mark as related incident"
  }
]

Only include if similarity >= 70%. If no duplicates, return [].
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
      
      return dataList.map((item) => DuplicateConcern(
        concernId: item['concernId'] as String,
        similarity: (item['similarity'] as num).toDouble(),
        reason: item['reason'] as String,
        recommendation: item['recommendation'] as String,
        actionSuggestion: item['actionSuggestion'] as String,
      )).toList();
    } catch (e) {
      print('❌ Duplicate detection failed: $e');
      return [];
    }
  }

  /// 3. Pattern Detection
  /// Detect corruption patterns across multiple concerns
  static Future<PatternAnalysis> detectPatterns({
    required List<Concern> concerns,
    String? timeframe, // e.g., "last 30 days"
  }) async {
    try {
      final concernsList = concerns.take(100).map((c) => 
        'Date: ${c.createdAt}, Category: ${c.category.name}, '
        'Location: ${c.location ?? 'N/A'}, '
        'Summary: ${c.title}'
      ).join('\n');

      final prompt = '''
Analyze these concerns for corruption patterns in Sri Lanka:

TIMEFRAME: ${timeframe ?? 'Recent concerns'}

CONCERNS DATA:
$concernsList

Detect patterns and return ONLY valid JSON:
{
  "patterns": [
    {
      "type": "recurring_bribery|systematic_fraud|network|geographic|temporal",
      "description": "Bribery pattern in road department tenders",
      "concernIds": ["abc", "def", "ghi"],
      "confidence": 0.88,
      "severity": "high|medium|low",
      "affectedDepartments": ["Department of Roads"],
      "estimatedFinancialImpact": "Rs. 5M - 10M",
      "locations": ["Colombo", "Gampaha"]
    }
  ],
  "networkConnections": [
    {
      "entities": ["Person A", "Company X"],
      "connectionType": "bribery|kickback|collusion",
      "concernIds": ["abc", "def"]
    }
  ],
  "recommendations": [
    "Launch joint investigation into road department",
    "Request audit of all tenders in past 6 months",
    "Coordinate with CIABOC"
  ],
  "riskLevel": "critical|high|medium|low"
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
      
      return PatternAnalysis.fromJson(data);
    } catch (e) {
      print('❌ Pattern detection failed: $e');
      throw Exception('Pattern detection failed: $e');
    }
  }

  /// 4. Risk Assessment
  /// Assess investigation risks and provide mitigation strategies
  static Future<RiskAssessment> assessRisk({
    required Concern concern,
    String? investigationPlan,
  }) async {
    try {
      print('🎯 OfficerAI: Starting risk assessment for concern: ${concern.title}');
      final prompt = '''
Assess investigation risks for this concern in Sri Lankan context:

CONCERN:
Title: ${concern.title}
Description: ${concern.description}
Category: ${concern.category.name}
Priority: ${concern.priority.name}
Anonymous: ${concern.isAnonymous}
Evidence: ${concern.attachments?.isNotEmpty == true ? 'Yes' : 'No'}

${investigationPlan != null ? 'INVESTIGATION PLAN:\n$investigationPlan' : ''}

Provide risk assessment in ONLY valid JSON:
{
  "overallRisk": "critical|high|medium|low",
  "riskScore": 0.75,
  "risks": [
    {
      "type": "evidence_tampering|witness_intimidation|political_pressure|legal_challenges|safety",
      "severity": "high",
      "likelihood": 0.70,
      "description": "Risk of evidence tampering due to high-level involvement",
      "mitigation": "Secure all evidence immediately, create digital backups"
    }
  ],
  "safeguards": [
    "Involve multiple officers in evidence collection",
    "Document everything with timestamps"
  ],
  "legalConsiderations": [
    "Bribery Act Section 19 applies",
    "Witness protection may be needed"
  ],
  "estimatedSuccessRate": 0.65,
  "recommendedApproach": "detailed recommendation here"
}
''';

      print('🎯 OfficerAI: Sending request to Gemini API...');
      final content = [Content.text(prompt)];
      final response = await _model.generateContent(content);
      print('🎯 OfficerAI: Received response from Gemini');
      final responseText = response.text ?? '{}';
      print('🎯 OfficerAI: Response text: ${responseText.substring(0, responseText.length > 100 ? 100 : responseText.length)}...');
      
      String jsonText = responseText.trim();
      if (jsonText.contains('{')) {
        final startIndex = jsonText.indexOf('{');
        final endIndex = jsonText.lastIndexOf('}') + 1;
        jsonText = jsonText.substring(startIndex, endIndex);
      }
      
      print('🎯 OfficerAI: Parsing JSON...');
      final data = jsonDecode(jsonText);
      print('🎯 OfficerAI: Creating RiskAssessment object...');
      
      final result = RiskAssessment.fromJson(data);
      print('✅ OfficerAI: Risk Assessment complete: ${result.overallRisk}');
      return result;
    } catch (e) {
      print('❌ Risk assessment failed: $e');
      throw Exception('Risk assessment failed: $e');
    }
  }

  /// 5. Response Suggestions
  /// Generate professional response drafts for citizens
  static Future<ResponseSuggestion> generateResponse({
    required Concern concern,
    required String responseType, // "acknowledge|request_info|update|resolve|reject"
    String? additionalContext,
  }) async {
    try {
      final prompt = '''
Generate a professional response for this concern:

CONCERN:
Title: ${concern.title}
Description: ${concern.description}
Author: ${concern.isAnonymous ? 'Anonymous' : concern.authorName}
Category: ${concern.category.name}

RESPONSE TYPE: $responseType
${additionalContext != null ? 'CONTEXT: $additionalContext' : ''}

Generate response in ONLY valid JSON:
{
  "subject": "Re: Your concern about...",
  "body": "Dear Citizen,\\n\\nThank you for...",
  "tone": "formal|empathetic|reassuring",
  "nextSteps": [
    "We will investigate within 7 days",
    "You will receive updates via email"
  ],
  "estimatedResolutionTime": "14 days",
  "officerNotes": "Internal notes for case file"
}

Make it professional, empathetic, and appropriate for Sri Lankan government communication.
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
      
      return ResponseSuggestion.fromJson(data);
    } catch (e) {
      print('❌ Response generation failed: $e');
      throw Exception('Response generation failed: $e');
    }
  }

  /// 6. Legal Document Drafting Assistant
  /// Help draft investigation reports and legal documents
  static Future<LegalDraft> draftDocument({
    required String documentType, // "investigation_report|charge_sheet|evidence_list|witness_statement"
    required Concern concern,
    Map<String, dynamic>? evidenceData,
  }) async {
    try {
      final prompt = '''
Draft a ${documentType.replaceAll('_', ' ')} for this corruption case:

CONCERN DETAILS:
Title: ${concern.title}
Description: ${concern.description}
Category: ${concern.category.name}
Priority: ${concern.priority.name}
Submitted: ${concern.createdAt}
${evidenceData != null ? 'EVIDENCE: ${evidenceData.toString()}' : ''}

Create a professional legal document suitable for Sri Lankan anti-corruption proceedings.

Return ONLY valid JSON:
{
  "documentTitle": "Investigation Report - Tender Fraud Case #123",
  "documentBody": "Full formatted document text here...",
  "sections": [
    {
      "heading": "Executive Summary",
      "content": "This investigation concerns..."
    },
    {
      "heading": "Evidence",
      "content": "The following evidence was collected..."
    },
    {
      "heading": "Findings",
      "content": "Based on investigation..."
    },
    {
      "heading": "Recommendations",
      "content": "It is recommended that..."
    }
  ],
  "legalReferences": ["Bribery Act 19", "Penal Code 409"],
  "requiredSignatures": ["Investigating Officer", "Supervisor"],
  "confidentialityLevel": "high|medium|low"
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
      
      return LegalDraft.fromJson(data);
    } catch (e) {
      print('❌ Document drafting failed: $e');
      throw Exception('Document drafting failed: $e');
    }
  }

  /// 7. Evidence Validation
  /// Analyze evidence quality and suggest improvements
  static Future<EvidenceAnalysis> analyzeEvidence({
    required Concern concern,
  }) async {
    try {
      final prompt = '''
Analyze the evidence quality for this corruption allegation:

CONCERN:
Title: ${concern.title}
Description: ${concern.description}
Attachments: ${concern.attachments?.length ?? 0} files
Evidence mentioned in description: ${concern.description}

Evaluate evidence quality and return ONLY valid JSON:
{
  "evidenceQuality": "strong|moderate|weak|insufficient",
  "qualityScore": 0.75,
  "strengths": [
    "Specific financial amounts mentioned",
    "Named individuals and departments"
  ],
  "weaknesses": [
    "No documentary evidence attached",
    "Dates not specified"
  ],
  "missingEvidence": [
    "Bank transfer receipts",
    "Tender documents",
    "Witness statements"
  ],
  "evidenceCollectionPlan": [
    "Request bank records from complainant",
    "Obtain tender files from department",
    "Interview potential witnesses"
  ],
  "admissibility": "likely|uncertain|unlikely",
  "legalStandard": "Sufficient for preliminary investigation but needs corroboration"
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
      
      return EvidenceAnalysis.fromJson(data);
    } catch (e) {
      print('❌ Evidence analysis failed: $e');
      throw Exception('Evidence analysis failed: $e');
    }
  }

  /// 8. Investigation Strategy Generator
  /// Generate comprehensive investigation plan
  static Future<InvestigationStrategy> generateStrategy({
    required Concern concern,
    List<Concern>? relatedConcerns,
  }) async {
    try {
      final relatedInfo = relatedConcerns != null && relatedConcerns.isNotEmpty
          ? '\n\nRELATED CONCERNS:\n' + relatedConcerns.map((c) => '- ${c.title}').join('\n')
          : '';

      final prompt = '''
Create a detailed investigation strategy for this corruption case:

CONCERN:
Title: ${concern.title}
Description: ${concern.description}
Category: ${concern.category.name}
Priority: ${concern.priority.name}
$relatedInfo

Generate comprehensive strategy in ONLY valid JSON:
{
  "investigationPhases": [
    {
      "phase": 1,
      "name": "Initial Assessment",
      "duration": "3 days",
      "tasks": [
        "Review all submitted evidence",
        "Interview complainant (if not anonymous)",
        "Verify basic facts"
      ]
    },
    {
      "phase": 2,
      "name": "Evidence Collection",
      "duration": "7 days",
      "tasks": [
        "Request department records",
        "Interview witnesses",
        "Obtain financial documents"
      ]
    }
  ],
  "keyInvestigationSteps": [
    "Secure all tender documents",
    "Interview tender committee members",
    "Review bank transactions"
  ],
  "requiredResources": [
    "Forensic accountant",
    "Legal advisor",
    "2 investigating officers"
  ],
  "potentialChallenges": [
    "Political interference risk",
    "Evidence may be destroyed"
  ],
  "successFactors": [
    "Act quickly to secure evidence",
    "Maintain confidentiality"
  ],
  "estimatedTimeline": "30-45 days",
  "budgetEstimate": "Rs. 100,000 - 200,000",
  "legalFramework": ["Bribery Act 19", "Financial Transactions Reporting Act"]
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
      
      return InvestigationStrategy.fromJson(data);
    } catch (e) {
      print('❌ Strategy generation failed: $e');
      throw Exception('Strategy generation failed: $e');
    }
  }

  /// 9. Predictive Analytics
  /// Predict future corruption trends and hotspots
  static Future<PredictiveAnalysis> predictTrends({
    required List<Concern> historicalConcerns,
    required String timePeriod, // "3months", "6months", "1year"
  }) async {
    try {
      final concernsList = historicalConcerns.take(50).map((c) => 
        'ID: ${c.id}, Title: ${c.title}, Category: ${c.category.name}, '
        'Priority: ${c.priority.name}, Date: ${c.createdAt}, Location: ${c.location ?? "Unknown"}'
      ).join('\n');

      final prompt = '''
Analyze historical corruption patterns and predict future trends in Sri Lanka:

HISTORICAL DATA ($timePeriod):
$concernsList

Predict trends in ONLY valid JSON:
{
  "predictedHotspots": [
    {
      "location": "Colombo",
      "riskLevel": "high",
      "confidence": 0.85,
      "predictedCases": 15,
      "timeframe": "next 3 months",
      "mainCategories": ["tender", "corruption"],
      "recommendedActions": ["Increase monitoring", "Preventive measures"]
    }
  ],
  "emergingPatterns": [
    {
      "pattern": "Digital corruption in online services",
      "growthRate": "+40%",
      "affectedDepartments": ["ICT Agency", "Registrar General"],
      "predictedImpact": "Rs. 20M annually"
    }
  ],
  "seasonalTrends": {
    "peakPeriods": ["December", "March"],
    "lowPeriods": ["August", "September"],
    "reasons": ["Budget allocation season", "Election periods"]
  },
  "riskFactors": [
    {
      "factor": "Economic pressure",
      "weight": 0.8,
      "description": "Economic downturns increase corruption risk"
    }
  ],
  "recommendations": [
    "Implement AI monitoring in predicted hotspots",
    "Strengthen digital service oversight",
    "Prepare for seasonal spikes"
  ],
  "confidence": 0.78
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
      
      return PredictiveAnalysis.fromJson(data);
    } catch (e) {
      print('❌ Predictive analysis failed: $e');
      throw Exception('Predictive analysis failed: $e');
    }
  }

  /// 10. Corruption Network Detection
  /// Detect and map corruption networks
  static Future<CorruptionNetwork> detectNetwork({
    required List<Concern> concerns,
    required String focusArea, // "department", "location", "category"
  }) async {
    try {
      final concernsList = concerns.take(30).map((c) => 
        'ID: ${c.id}, Title: ${c.title}, Author: ${c.authorName}, '
        'Category: ${c.category.name}, Location: ${c.location ?? "Unknown"}, '
        'Description: ${c.description.substring(0, c.description.length > 100 ? 100 : c.description.length)}...'
      ).join('\n');

      final prompt = '''
Detect corruption networks and connections in Sri Lankan context:

CONCERNS DATA:
$concernsList

FOCUS AREA: $focusArea

Analyze and return ONLY valid JSON:
{
  "networks": [
    {
      "networkId": "network_1",
      "name": "Road Department Bribery Ring",
      "confidence": 0.92,
      "members": [
        {
          "entity": "John Doe",
          "role": "Contractor",
          "connectionType": "bribery_payer",
          "evidenceStrength": "strong",
          "concernIds": ["abc123", "def456"]
        },
        {
          "entity": "Jane Smith",
          "role": "Government Official",
          "connectionType": "bribery_receiver",
          "evidenceStrength": "moderate",
          "concernIds": ["abc123"]
        }
      ],
      "financialImpact": "Rs. 15M - 25M",
      "geographicScope": ["Colombo", "Gampaha"],
      "departments": ["Department of Roads"],
      "modusOperandi": "Inflated tender prices with kickbacks",
      "recommendedActions": [
        "Coordinate with CIABOC for joint investigation",
        "Request financial records audit",
        "Surveillance on key members"
      ]
    }
  ],
  "connections": [
    {
      "from": "Person A",
      "to": "Person B",
      "connectionType": "financial_transaction|communication|meeting",
      "strength": 0.85,
      "evidence": "Multiple financial transactions in tender period"
    }
  ],
  "riskAssessment": {
    "overallRisk": "critical",
    "financialRisk": "Rs. 50M+",
    "operationalRisk": "high",
    "reputationRisk": "severe"
  },
  "investigationPriority": "immediate",
  "estimatedInvestigationTime": "6-8 weeks"
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
      
      return CorruptionNetwork.fromJson(data);
    } catch (e) {
      print('❌ Network detection failed: $e');
      throw Exception('Network detection failed: $e');
    }
  }

  /// 11. Sentiment Trends Analysis
  /// Analyze sentiment trends over time
  static Future<SentimentTrends> analyzeSentimentTrends({
    required List<Concern> concerns,
    required String timePeriod,
  }) async {
    try {
      final concernsList = concerns.take(100).map((c) => 
        'Date: ${c.createdAt}, Title: ${c.title}, '
        'Description: ${c.description.substring(0, c.description.length > 80 ? 80 : c.description.length)}..., '
        'Category: ${c.category.name}'
      ).join('\n');

      final prompt = '''
Analyze sentiment trends in corruption reports over $timePeriod:

DATA:
$concernsList

Return sentiment analysis in ONLY valid JSON:
{
  "overallTrend": {
    "direction": "increasing|decreasing|stable",
    "changePercentage": "+15%",
    "description": "Sentiment becoming more negative over time"
  },
  "monthlyTrends": [
    {
      "month": "January",
      "sentiment": "negative",
      "score": -0.65,
      "concernCount": 25,
      "keyIssues": ["Tender corruption", "Bureaucratic delays"]
    }
  ],
  "categoryTrends": [
    {
      "category": "corruption",
      "trend": "increasing",
      "sentimentScore": -0.78,
      "peakPeriod": "December",
      "description": "Corruption sentiment worsening"
    }
  ],
  "geographicTrends": [
    {
      "location": "Colombo",
      "sentiment": "very_negative",
      "score": -0.82,
      "mainConcerns": ["High-level corruption", "Political interference"]
    }
  ],
  "triggerEvents": [
    {
      "event": "Budget allocation announcement",
      "date": "2024-01-15",
      "sentimentImpact": "+25% negative",
      "affectedCategories": ["budget", "tender"]
    }
  ],
  "recommendations": [
    "Address root causes in Colombo area",
    "Improve transparency in budget allocation",
    "Monitor sentiment after major announcements"
  ],
  "confidence": 0.87
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
      
      return SentimentTrends.fromJson(data);
    } catch (e) {
      print('❌ Sentiment trends analysis failed: $e');
      throw Exception('Sentiment trends analysis failed: $e');
    }
  }

  /// 12. Automated Triage
  /// Automatically triage concerns based on urgency and priority
  static Future<AutomatedTriage> triageConcerns({
    required List<Concern> concerns,
  }) async {
    try {
      final concernsList = concerns.take(50).map((c) => 
        'ID: ${c.id}, Title: ${c.title}, Category: ${c.category.name}, '
        'Priority: ${c.priority.name}, Description: ${c.description.substring(0, c.description.length > 60 ? 60 : c.description.length)}..., '
        'Support: ${c.supportCount}, Date: ${c.createdAt}'
      ).join('\n');

      final prompt = '''
Automatically triage these concerns for anti-corruption officers:

CONCERNS:
$concernsList

Provide triage recommendations in ONLY valid JSON:
{
  "immediate": [
    {
      "concernId": "abc123",
      "reason": "High corruption evidence with public safety impact",
      "assignedOfficer": "Senior Investigator",
      "estimatedTime": "2-3 days",
      "requiredActions": ["Evidence collection", "Witness interviews"]
    }
  ],
  "urgent": [
    {
      "concernId": "def456",
      "reason": "Financial corruption with strong evidence",
      "assignedOfficer": "Financial Crimes Unit",
      "estimatedTime": "1 week",
      "requiredActions": ["Financial audit", "Document review"]
    }
  ],
  "normal": [
    {
      "concernId": "ghi789",
      "reason": "Standard corruption complaint",
      "assignedOfficer": "General Investigation",
      "estimatedTime": "2 weeks",
      "requiredActions": ["Initial investigation", "Evidence gathering"]
    }
  ],
  "low": [
    {
      "concernId": "jkl012",
      "reason": "Minor administrative issue",
      "assignedOfficer": "Junior Officer",
      "estimatedTime": "1 month",
      "requiredActions": ["Documentation review"]
    }
  ],
  "duplicates": [
    {
      "concernIds": ["mno345", "pqr678"],
      "reason": "Same incident reported multiple times",
      "action": "merge_and_investigate_once"
    }
  ],
  "insufficient": [
    {
      "concernId": "stu901",
      "reason": "Lacks sufficient detail for investigation",
      "action": "request_more_information",
      "requiredInfo": ["Specific dates", "Witness names", "Document evidence"]
    }
  ],
  "summary": {
    "totalProcessed": 50,
    "immediateCount": 3,
    "urgentCount": 8,
    "normalCount": 25,
    "lowCount": 10,
    "duplicateCount": 2,
    "insufficientCount": 2
  },
  "resourceRequirements": {
    "seniorInvestigators": 3,
    "financialSpecialists": 2,
    "generalOfficers": 8,
    "estimatedTotalTime": "45 days"
  }
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
      
      return AutomatedTriage.fromJson(data);
    } catch (e) {
      print('❌ Automated triage failed: $e');
      throw Exception('Automated triage failed: $e');
    }
  }

  /// 13. Evidence Validation
  /// Validate and assess evidence quality
  static Future<EvidenceValidation> validateEvidence({
    required Concern concern,
    required List<String> evidenceList, // File names, URLs, descriptions
  }) async {
    try {
      final evidenceText = evidenceList.join('\n');

      final prompt = '''
Validate evidence quality for this corruption investigation:

CONCERN:
Title: ${concern.title}
Description: ${concern.description}
Category: ${concern.category.name}

EVIDENCE:
$evidenceText

Assess evidence in ONLY valid JSON:
{
  "evidenceQuality": {
    "overall": "strong|moderate|weak",
    "score": 0.85,
    "description": "Strong documentary evidence with witness statements"
  },
  "evidenceItems": [
    {
      "item": "document_1.pdf",
      "type": "document|photo|audio|video|witness_statement",
      "quality": "high|medium|low",
      "relevance": 0.9,
      "admissibility": "admissible|questionable|inadmissible",
      "issues": [],
      "recommendations": ["Verify authenticity", "Get notarized copy"]
    }
  ],
  "missingEvidence": [
    {
      "type": "Financial records",
      "importance": "critical",
      "description": "Bank statements showing bribery payments",
      "howToObtain": "Request from bank with court order"
    }
  ],
  "evidenceChain": {
    "isComplete": true,
    "gaps": [],
    "strengths": ["Multiple corroborating sources", "Timely collection"]
  },
  "legalAssessment": {
    "admissibilityScore": 0.9,
    "legalIssues": [],
    "courtReadiness": "ready|needs_work|not_ready"
  },
  "recommendations": [
    "Obtain notarized copies of documents",
    "Interview additional witnesses",
    "Collect financial records"
  ],
  "riskFactors": [
    {
      "factor": "Evidence tampering risk",
      "level": "low",
      "mitigation": "Secure storage, chain of custody"
    }
  ]
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
      
      return EvidenceValidation.fromJson(data);
    } catch (e) {
      print('❌ Evidence validation failed: $e');
      throw Exception('Evidence validation failed: $e');
    }
  }

  /// 9. Batch Analysis
  /// Analyze multiple concerns at once for quick triage
  static Future<BatchAnalysisResult> analyzeBatch({
    required List<Concern> concerns,
  }) async {
    try {
      final concernsList = concerns.take(20).map((c) => 
        'ID: ${c.id}, Title: ${c.title}, Category: ${c.category.name}'
      ).join('\n');

      final prompt = '''
Quick triage analysis for these concerns:

$concernsList

Provide rapid assessment in ONLY valid JSON:
{
  "criticalConcerns": ["id1", "id2"],
  "duplicatePairs": [["id1", "id2"]],
  "patternClusters": [
    {
      "concernIds": ["id3", "id4", "id5"],
      "pattern": "tender fraud pattern"
    }
  ],
  "requiresImmediateAction": ["id1"],
  "canBeDeferred": ["id6"],
  "needsMoreInformation": ["id7"],
  "summary": "5 critical cases require immediate attention, 2 appear to be duplicates"
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
      
      return BatchAnalysisResult.fromJson(data);
    } catch (e) {
      print('❌ Batch analysis failed: $e');
      throw Exception('Batch analysis failed: $e');
    }
  }
}

// Data Models

class RankedConcern {
  final String concernId;
  final int newRank;
  final int urgencyScore;
  final String reasoning;
  final String recommendedTimeframe;
  final int estimatedInvestigationDays;

  RankedConcern({
    required this.concernId,
    required this.newRank,
    required this.urgencyScore,
    required this.reasoning,
    required this.recommendedTimeframe,
    required this.estimatedInvestigationDays,
  });
}

class DuplicateConcern {
  final String concernId;
  final double similarity;
  final String reason;
  final String recommendation;
  final String actionSuggestion;

  DuplicateConcern({
    required this.concernId,
    required this.similarity,
    required this.reason,
    required this.recommendation,
    required this.actionSuggestion,
  });
}

class PatternAnalysis {
  final List<CorruptionPattern> patterns;
  final List<NetworkConnection> networkConnections;
  final List<String> recommendations;
  final String riskLevel;

  PatternAnalysis({
    required this.patterns,
    required this.networkConnections,
    required this.recommendations,
    required this.riskLevel,
  });

  factory PatternAnalysis.fromJson(Map<String, dynamic> json) {
    return PatternAnalysis(
      patterns: (json['patterns'] as List?)
          ?.map((p) => CorruptionPattern.fromJson(p))
          .toList() ?? [],
      networkConnections: (json['networkConnections'] as List?)
          ?.map((n) => NetworkConnection.fromJson(n))
          .toList() ?? [],
      recommendations: List<String>.from(json['recommendations'] ?? []),
      riskLevel: json['riskLevel'] as String? ?? 'medium',
    );
  }
}

class CorruptionPattern {
  final String type;
  final String description;
  final List<String> concernIds;
  final double confidence;
  final String severity;
  final List<String> affectedDepartments;
  final String estimatedFinancialImpact;
  final List<String> locations;

  CorruptionPattern({
    required this.type,
    required this.description,
    required this.concernIds,
    required this.confidence,
    required this.severity,
    required this.affectedDepartments,
    required this.estimatedFinancialImpact,
    required this.locations,
  });

  factory CorruptionPattern.fromJson(Map<String, dynamic> json) {
    return CorruptionPattern(
      type: json['type'] as String,
      description: json['description'] as String,
      concernIds: List<String>.from(json['concernIds'] ?? []),
      confidence: (json['confidence'] as num?)?.toDouble() ?? 0.0,
      severity: json['severity'] as String? ?? 'medium',
      affectedDepartments: List<String>.from(json['affectedDepartments'] ?? []),
      estimatedFinancialImpact: json['estimatedFinancialImpact'] as String? ?? 'Unknown',
      locations: List<String>.from(json['locations'] ?? []),
    );
  }
}

class NetworkConnection {
  final List<String> entities;
  final String connectionType;
  final List<String> concernIds;

  NetworkConnection({
    required this.entities,
    required this.connectionType,
    required this.concernIds,
  });

  factory NetworkConnection.fromJson(Map<String, dynamic> json) {
    return NetworkConnection(
      entities: List<String>.from(json['entities'] ?? []),
      connectionType: json['connectionType'] as String? ?? 'unknown',
      concernIds: List<String>.from(json['concernIds'] ?? []),
    );
  }
}

class RiskAssessment {
  final String overallRisk;
  final double riskScore;
  final List<InvestigationRisk> risks;
  final List<String> safeguards;
  final List<String> legalConsiderations;
  final double estimatedSuccessRate;
  final String recommendedApproach;

  RiskAssessment({
    required this.overallRisk,
    required this.riskScore,
    required this.risks,
    required this.safeguards,
    required this.legalConsiderations,
    required this.estimatedSuccessRate,
    required this.recommendedApproach,
  });

  factory RiskAssessment.fromJson(Map<String, dynamic> json) {
    return RiskAssessment(
      overallRisk: json['overallRisk'] as String? ?? 'medium',
      riskScore: (json['riskScore'] as num?)?.toDouble() ?? 0.5,
      risks: (json['risks'] as List?)
          ?.map((r) => InvestigationRisk.fromJson(r))
          .toList() ?? [],
      safeguards: List<String>.from(json['safeguards'] ?? []),
      legalConsiderations: List<String>.from(json['legalConsiderations'] ?? []),
      estimatedSuccessRate: (json['estimatedSuccessRate'] as num?)?.toDouble() ?? 0.5,
      recommendedApproach: json['recommendedApproach'] as String? ?? '',
    );
  }
}

class InvestigationRisk {
  final String type;
  final String severity;
  final double likelihood;
  final String description;
  final String mitigation;

  InvestigationRisk({
    required this.type,
    required this.severity,
    required this.likelihood,
    required this.description,
    required this.mitigation,
  });

  factory InvestigationRisk.fromJson(Map<String, dynamic> json) {
    return InvestigationRisk(
      type: json['type'] as String,
      severity: json['severity'] as String,
      likelihood: (json['likelihood'] as num?)?.toDouble() ?? 0.5,
      description: json['description'] as String,
      mitigation: json['mitigation'] as String,
    );
  }
}

class ResponseSuggestion {
  final String subject;
  final String body;
  final String tone;
  final List<String> nextSteps;
  final String estimatedResolutionTime;
  final String officerNotes;

  ResponseSuggestion({
    required this.subject,
    required this.body,
    required this.tone,
    required this.nextSteps,
    required this.estimatedResolutionTime,
    required this.officerNotes,
  });

  factory ResponseSuggestion.fromJson(Map<String, dynamic> json) {
    return ResponseSuggestion(
      subject: json['subject'] as String? ?? '',
      body: json['body'] as String? ?? '',
      tone: json['tone'] as String? ?? 'formal',
      nextSteps: List<String>.from(json['nextSteps'] ?? []),
      estimatedResolutionTime: json['estimatedResolutionTime'] as String? ?? 'TBD',
      officerNotes: json['officerNotes'] as String? ?? '',
    );
  }
}

class LegalDraft {
  final String documentTitle;
  final String documentBody;
  final List<DocumentSection> sections;
  final List<String> legalReferences;
  final List<String> requiredSignatures;
  final String confidentialityLevel;

  LegalDraft({
    required this.documentTitle,
    required this.documentBody,
    required this.sections,
    required this.legalReferences,
    required this.requiredSignatures,
    required this.confidentialityLevel,
  });

  factory LegalDraft.fromJson(Map<String, dynamic> json) {
    return LegalDraft(
      documentTitle: json['documentTitle'] as String? ?? '',
      documentBody: json['documentBody'] as String? ?? '',
      sections: (json['sections'] as List?)
          ?.map((s) => DocumentSection.fromJson(s))
          .toList() ?? [],
      legalReferences: List<String>.from(json['legalReferences'] ?? []),
      requiredSignatures: List<String>.from(json['requiredSignatures'] ?? []),
      confidentialityLevel: json['confidentialityLevel'] as String? ?? 'medium',
    );
  }
}

class DocumentSection {
  final String heading;
  final String content;

  DocumentSection({
    required this.heading,
    required this.content,
  });

  factory DocumentSection.fromJson(Map<String, dynamic> json) {
    return DocumentSection(
      heading: json['heading'] as String,
      content: json['content'] as String,
    );
  }
}

class BatchAnalysisResult {
  final List<String> criticalConcerns;
  final List<List<String>> duplicatePairs;
  final List<PatternCluster> patternClusters;
  final List<String> requiresImmediateAction;
  final List<String> canBeDeferred;
  final List<String> needsMoreInformation;
  final String summary;

  BatchAnalysisResult({
    required this.criticalConcerns,
    required this.duplicatePairs,
    required this.patternClusters,
    required this.requiresImmediateAction,
    required this.canBeDeferred,
    required this.needsMoreInformation,
    required this.summary,
  });

  factory BatchAnalysisResult.fromJson(Map<String, dynamic> json) {
    return BatchAnalysisResult(
      criticalConcerns: List<String>.from(json['criticalConcerns'] ?? []),
      duplicatePairs: (json['duplicatePairs'] as List?)
          ?.map((pair) => List<String>.from(pair))
          .toList() ?? [],
      patternClusters: (json['patternClusters'] as List?)
          ?.map((c) => PatternCluster.fromJson(c))
          .toList() ?? [],
      requiresImmediateAction: List<String>.from(json['requiresImmediateAction'] ?? []),
      canBeDeferred: List<String>.from(json['canBeDeferred'] ?? []),
      needsMoreInformation: List<String>.from(json['needsMoreInformation'] ?? []),
      summary: json['summary'] as String? ?? '',
    );
  }
}

class PatternCluster {
  final List<String> concernIds;
  final String pattern;

  PatternCluster({
    required this.concernIds,
    required this.pattern,
  });

  factory PatternCluster.fromJson(Map<String, dynamic> json) {
    return PatternCluster(
      concernIds: List<String>.from(json['concernIds'] ?? []),
      pattern: json['pattern'] as String,
    );
  }
}

class EvidenceAnalysis {
  final String evidenceQuality;
  final double qualityScore;
  final List<String> strengths;
  final List<String> weaknesses;
  final List<String> missingEvidence;
  final List<String> evidenceCollectionPlan;
  final String admissibility;
  final String legalStandard;

  EvidenceAnalysis({
    required this.evidenceQuality,
    required this.qualityScore,
    required this.strengths,
    required this.weaknesses,
    required this.missingEvidence,
    required this.evidenceCollectionPlan,
    required this.admissibility,
    required this.legalStandard,
  });

  factory EvidenceAnalysis.fromJson(Map<String, dynamic> json) {
    return EvidenceAnalysis(
      evidenceQuality: json['evidenceQuality'] as String? ?? 'moderate',
      qualityScore: (json['qualityScore'] as num?)?.toDouble() ?? 0.5,
      strengths: List<String>.from(json['strengths'] ?? []),
      weaknesses: List<String>.from(json['weaknesses'] ?? []),
      missingEvidence: List<String>.from(json['missingEvidence'] ?? []),
      evidenceCollectionPlan: List<String>.from(json['evidenceCollectionPlan'] ?? []),
      admissibility: json['admissibility'] as String? ?? 'uncertain',
      legalStandard: json['legalStandard'] as String? ?? '',
    );
  }
}

class InvestigationStrategy {
  final List<InvestigationPhase> investigationPhases;
  final List<String> keyInvestigationSteps;
  final List<String> requiredResources;
  final List<String> potentialChallenges;
  final List<String> successFactors;
  final String estimatedTimeline;
  final String budgetEstimate;
  final List<String> legalFramework;

  InvestigationStrategy({
    required this.investigationPhases,
    required this.keyInvestigationSteps,
    required this.requiredResources,
    required this.potentialChallenges,
    required this.successFactors,
    required this.estimatedTimeline,
    required this.budgetEstimate,
    required this.legalFramework,
  });

  factory InvestigationStrategy.fromJson(Map<String, dynamic> json) {
    return InvestigationStrategy(
      investigationPhases: (json['investigationPhases'] as List?)
          ?.map((p) => InvestigationPhase.fromJson(p))
          .toList() ?? [],
      keyInvestigationSteps: List<String>.from(json['keyInvestigationSteps'] ?? []),
      requiredResources: List<String>.from(json['requiredResources'] ?? []),
      potentialChallenges: List<String>.from(json['potentialChallenges'] ?? []),
      successFactors: List<String>.from(json['successFactors'] ?? []),
      estimatedTimeline: json['estimatedTimeline'] as String? ?? '',
      budgetEstimate: json['budgetEstimate'] as String? ?? '',
      legalFramework: List<String>.from(json['legalFramework'] ?? []),
    );
  }
}

class InvestigationPhase {
  final int phase;
  final String name;
  final String duration;
  final List<String> tasks;

  InvestigationPhase({
    required this.phase,
    required this.name,
    required this.duration,
    required this.tasks,
  });

  factory InvestigationPhase.fromJson(Map<String, dynamic> json) {
    return InvestigationPhase(
      phase: json['phase'] as int,
      name: json['name'] as String,
      duration: json['duration'] as String,
      tasks: List<String>.from(json['tasks'] ?? []),
    );
  }
}

// Advanced AI Feature Data Models

class PredictiveAnalysis {
  final List<PredictedHotspot> predictedHotspots;
  final List<EmergingPattern> emergingPatterns;
  final SeasonalTrends seasonalTrends;
  final List<RiskFactor> riskFactors;
  final List<String> recommendations;
  final double confidence;

  PredictiveAnalysis({
    required this.predictedHotspots,
    required this.emergingPatterns,
    required this.seasonalTrends,
    required this.riskFactors,
    required this.recommendations,
    required this.confidence,
  });

  factory PredictiveAnalysis.fromJson(Map<String, dynamic> json) {
    return PredictiveAnalysis(
      predictedHotspots: (json['predictedHotspots'] as List?)
          ?.map((h) => PredictedHotspot.fromJson(h))
          .toList() ?? [],
      emergingPatterns: (json['emergingPatterns'] as List?)
          ?.map((p) => EmergingPattern.fromJson(p))
          .toList() ?? [],
      seasonalTrends: SeasonalTrends.fromJson(json['seasonalTrends'] ?? {}),
      riskFactors: (json['riskFactors'] as List?)
          ?.map((r) => RiskFactor.fromJson(r))
          .toList() ?? [],
      recommendations: List<String>.from(json['recommendations'] ?? []),
      confidence: (json['confidence'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

class PredictedHotspot {
  final String location;
  final String riskLevel;
  final double confidence;
  final int predictedCases;
  final String timeframe;
  final List<String> mainCategories;
  final List<String> recommendedActions;

  PredictedHotspot({
    required this.location,
    required this.riskLevel,
    required this.confidence,
    required this.predictedCases,
    required this.timeframe,
    required this.mainCategories,
    required this.recommendedActions,
  });

  factory PredictedHotspot.fromJson(Map<String, dynamic> json) {
    return PredictedHotspot(
      location: json['location'] as String? ?? '',
      riskLevel: json['riskLevel'] as String? ?? 'medium',
      confidence: (json['confidence'] as num?)?.toDouble() ?? 0.0,
      predictedCases: json['predictedCases'] as int? ?? 0,
      timeframe: json['timeframe'] as String? ?? '',
      mainCategories: List<String>.from(json['mainCategories'] ?? []),
      recommendedActions: List<String>.from(json['recommendedActions'] ?? []),
    );
  }
}

class EmergingPattern {
  final String pattern;
  final String growthRate;
  final List<String> affectedDepartments;
  final String predictedImpact;

  EmergingPattern({
    required this.pattern,
    required this.growthRate,
    required this.affectedDepartments,
    required this.predictedImpact,
  });

  factory EmergingPattern.fromJson(Map<String, dynamic> json) {
    return EmergingPattern(
      pattern: json['pattern'] as String? ?? '',
      growthRate: json['growthRate'] as String? ?? '',
      affectedDepartments: List<String>.from(json['affectedDepartments'] ?? []),
      predictedImpact: json['predictedImpact'] as String? ?? '',
    );
  }
}

class SeasonalTrends {
  final List<String> peakPeriods;
  final List<String> lowPeriods;
  final List<String> reasons;

  SeasonalTrends({
    required this.peakPeriods,
    required this.lowPeriods,
    required this.reasons,
  });

  factory SeasonalTrends.fromJson(Map<String, dynamic> json) {
    return SeasonalTrends(
      peakPeriods: List<String>.from(json['peakPeriods'] ?? []),
      lowPeriods: List<String>.from(json['lowPeriods'] ?? []),
      reasons: List<String>.from(json['reasons'] ?? []),
    );
  }
}

class RiskFactor {
  final String factor;
  final double weight;
  final String description;

  RiskFactor({
    required this.factor,
    required this.weight,
    required this.description,
  });

  factory RiskFactor.fromJson(Map<String, dynamic> json) {
    return RiskFactor(
      factor: json['factor'] as String? ?? '',
      weight: (json['weight'] as num?)?.toDouble() ?? 0.0,
      description: json['description'] as String? ?? '',
    );
  }
}

class CorruptionNetwork {
  final List<Network> networks;
  final List<Connection> connections;
  final RiskAssessment riskAssessment;
  final String investigationPriority;
  final String estimatedInvestigationTime;

  CorruptionNetwork({
    required this.networks,
    required this.connections,
    required this.riskAssessment,
    required this.investigationPriority,
    required this.estimatedInvestigationTime,
  });

  factory CorruptionNetwork.fromJson(Map<String, dynamic> json) {
    return CorruptionNetwork(
      networks: (json['networks'] as List?)
          ?.map((n) => Network.fromJson(n))
          .toList() ?? [],
      connections: (json['connections'] as List?)
          ?.map((c) => Connection.fromJson(c))
          .toList() ?? [],
      riskAssessment: RiskAssessment.fromJson(json['riskAssessment'] ?? {}),
      investigationPriority: json['investigationPriority'] as String? ?? 'normal',
      estimatedInvestigationTime: json['estimatedInvestigationTime'] as String? ?? '',
    );
  }
}

class Network {
  final String networkId;
  final String name;
  final double confidence;
  final List<NetworkMember> members;
  final String financialImpact;
  final List<String> geographicScope;
  final List<String> departments;
  final String modusOperandi;
  final List<String> recommendedActions;

  Network({
    required this.networkId,
    required this.name,
    required this.confidence,
    required this.members,
    required this.financialImpact,
    required this.geographicScope,
    required this.departments,
    required this.modusOperandi,
    required this.recommendedActions,
  });

  factory Network.fromJson(Map<String, dynamic> json) {
    return Network(
      networkId: json['networkId'] as String? ?? '',
      name: json['name'] as String? ?? '',
      confidence: (json['confidence'] as num?)?.toDouble() ?? 0.0,
      members: (json['members'] as List?)
          ?.map((m) => NetworkMember.fromJson(m))
          .toList() ?? [],
      financialImpact: json['financialImpact'] as String? ?? '',
      geographicScope: List<String>.from(json['geographicScope'] ?? []),
      departments: List<String>.from(json['departments'] ?? []),
      modusOperandi: json['modusOperandi'] as String? ?? '',
      recommendedActions: List<String>.from(json['recommendedActions'] ?? []),
    );
  }
}

class NetworkMember {
  final String entity;
  final String role;
  final String connectionType;
  final String evidenceStrength;
  final List<String> concernIds;

  NetworkMember({
    required this.entity,
    required this.role,
    required this.connectionType,
    required this.evidenceStrength,
    required this.concernIds,
  });

  factory NetworkMember.fromJson(Map<String, dynamic> json) {
    return NetworkMember(
      entity: json['entity'] as String? ?? '',
      role: json['role'] as String? ?? '',
      connectionType: json['connectionType'] as String? ?? '',
      evidenceStrength: json['evidenceStrength'] as String? ?? '',
      concernIds: List<String>.from(json['concernIds'] ?? []),
    );
  }
}

class Connection {
  final String from;
  final String to;
  final String connectionType;
  final double strength;
  final String evidence;

  Connection({
    required this.from,
    required this.to,
    required this.connectionType,
    required this.strength,
    required this.evidence,
  });

  factory Connection.fromJson(Map<String, dynamic> json) {
    return Connection(
      from: json['from'] as String? ?? '',
      to: json['to'] as String? ?? '',
      connectionType: json['connectionType'] as String? ?? '',
      strength: (json['strength'] as num?)?.toDouble() ?? 0.0,
      evidence: json['evidence'] as String? ?? '',
    );
  }
}

class SentimentTrends {
  final OverallTrend overallTrend;
  final List<MonthlyTrend> monthlyTrends;
  final List<CategoryTrend> categoryTrends;
  final List<GeographicTrend> geographicTrends;
  final List<TriggerEvent> triggerEvents;
  final List<String> recommendations;
  final double confidence;

  SentimentTrends({
    required this.overallTrend,
    required this.monthlyTrends,
    required this.categoryTrends,
    required this.geographicTrends,
    required this.triggerEvents,
    required this.recommendations,
    required this.confidence,
  });

  factory SentimentTrends.fromJson(Map<String, dynamic> json) {
    return SentimentTrends(
      overallTrend: OverallTrend.fromJson(json['overallTrend'] ?? {}),
      monthlyTrends: (json['monthlyTrends'] as List?)
          ?.map((t) => MonthlyTrend.fromJson(t))
          .toList() ?? [],
      categoryTrends: (json['categoryTrends'] as List?)
          ?.map((t) => CategoryTrend.fromJson(t))
          .toList() ?? [],
      geographicTrends: (json['geographicTrends'] as List?)
          ?.map((t) => GeographicTrend.fromJson(t))
          .toList() ?? [],
      triggerEvents: (json['triggerEvents'] as List?)
          ?.map((e) => TriggerEvent.fromJson(e))
          .toList() ?? [],
      recommendations: List<String>.from(json['recommendations'] ?? []),
      confidence: (json['confidence'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

class OverallTrend {
  final String direction;
  final String changePercentage;
  final String description;

  OverallTrend({
    required this.direction,
    required this.changePercentage,
    required this.description,
  });

  factory OverallTrend.fromJson(Map<String, dynamic> json) {
    return OverallTrend(
      direction: json['direction'] as String? ?? 'stable',
      changePercentage: json['changePercentage'] as String? ?? '0%',
      description: json['description'] as String? ?? '',
    );
  }
}

class MonthlyTrend {
  final String month;
  final String sentiment;
  final double score;
  final int concernCount;
  final List<String> keyIssues;

  MonthlyTrend({
    required this.month,
    required this.sentiment,
    required this.score,
    required this.concernCount,
    required this.keyIssues,
  });

  factory MonthlyTrend.fromJson(Map<String, dynamic> json) {
    return MonthlyTrend(
      month: json['month'] as String? ?? '',
      sentiment: json['sentiment'] as String? ?? 'neutral',
      score: (json['score'] as num?)?.toDouble() ?? 0.0,
      concernCount: json['concernCount'] as int? ?? 0,
      keyIssues: List<String>.from(json['keyIssues'] ?? []),
    );
  }
}

class CategoryTrend {
  final String category;
  final String trend;
  final double sentimentScore;
  final String peakPeriod;
  final String description;

  CategoryTrend({
    required this.category,
    required this.trend,
    required this.sentimentScore,
    required this.peakPeriod,
    required this.description,
  });

  factory CategoryTrend.fromJson(Map<String, dynamic> json) {
    return CategoryTrend(
      category: json['category'] as String? ?? '',
      trend: json['trend'] as String? ?? 'stable',
      sentimentScore: (json['sentimentScore'] as num?)?.toDouble() ?? 0.0,
      peakPeriod: json['peakPeriod'] as String? ?? '',
      description: json['description'] as String? ?? '',
    );
  }
}

class GeographicTrend {
  final String location;
  final String sentiment;
  final double score;
  final List<String> mainConcerns;

  GeographicTrend({
    required this.location,
    required this.sentiment,
    required this.score,
    required this.mainConcerns,
  });

  factory GeographicTrend.fromJson(Map<String, dynamic> json) {
    return GeographicTrend(
      location: json['location'] as String? ?? '',
      sentiment: json['sentiment'] as String? ?? 'neutral',
      score: (json['score'] as num?)?.toDouble() ?? 0.0,
      mainConcerns: List<String>.from(json['mainConcerns'] ?? []),
    );
  }
}

class TriggerEvent {
  final String event;
  final String date;
  final String sentimentImpact;
  final List<String> affectedCategories;

  TriggerEvent({
    required this.event,
    required this.date,
    required this.sentimentImpact,
    required this.affectedCategories,
  });

  factory TriggerEvent.fromJson(Map<String, dynamic> json) {
    return TriggerEvent(
      event: json['event'] as String? ?? '',
      date: json['date'] as String? ?? '',
      sentimentImpact: json['sentimentImpact'] as String? ?? '',
      affectedCategories: List<String>.from(json['affectedCategories'] ?? []),
    );
  }
}

class AutomatedTriage {
  final List<TriageItem> immediate;
  final List<TriageItem> urgent;
  final List<TriageItem> normal;
  final List<TriageItem> low;
  final List<DuplicatePair> duplicates;
  final List<InsufficientInfo> insufficient;
  final TriageSummary summary;
  final ResourceRequirements resourceRequirements;

  AutomatedTriage({
    required this.immediate,
    required this.urgent,
    required this.normal,
    required this.low,
    required this.duplicates,
    required this.insufficient,
    required this.summary,
    required this.resourceRequirements,
  });

  factory AutomatedTriage.fromJson(Map<String, dynamic> json) {
    return AutomatedTriage(
      immediate: (json['immediate'] as List?)
          ?.map((i) => TriageItem.fromJson(i))
          .toList() ?? [],
      urgent: (json['urgent'] as List?)
          ?.map((i) => TriageItem.fromJson(i))
          .toList() ?? [],
      normal: (json['normal'] as List?)
          ?.map((i) => TriageItem.fromJson(i))
          .toList() ?? [],
      low: (json['low'] as List?)
          ?.map((i) => TriageItem.fromJson(i))
          .toList() ?? [],
      duplicates: (json['duplicates'] as List?)
          ?.map((d) => DuplicatePair.fromJson(d))
          .toList() ?? [],
      insufficient: (json['insufficient'] as List?)
          ?.map((i) => InsufficientInfo.fromJson(i))
          .toList() ?? [],
      summary: TriageSummary.fromJson(json['summary'] ?? {}),
      resourceRequirements: ResourceRequirements.fromJson(json['resourceRequirements'] ?? {}),
    );
  }
}

class TriageItem {
  final String concernId;
  final String reason;
  final String assignedOfficer;
  final String estimatedTime;
  final List<String> requiredActions;

  TriageItem({
    required this.concernId,
    required this.reason,
    required this.assignedOfficer,
    required this.estimatedTime,
    required this.requiredActions,
  });

  factory TriageItem.fromJson(Map<String, dynamic> json) {
    return TriageItem(
      concernId: json['concernId'] as String? ?? '',
      reason: json['reason'] as String? ?? '',
      assignedOfficer: json['assignedOfficer'] as String? ?? '',
      estimatedTime: json['estimatedTime'] as String? ?? '',
      requiredActions: List<String>.from(json['requiredActions'] ?? []),
    );
  }
}

class DuplicatePair {
  final List<String> concernIds;
  final String reason;
  final String action;

  DuplicatePair({
    required this.concernIds,
    required this.reason,
    required this.action,
  });

  factory DuplicatePair.fromJson(Map<String, dynamic> json) {
    return DuplicatePair(
      concernIds: List<String>.from(json['concernIds'] ?? []),
      reason: json['reason'] as String? ?? '',
      action: json['action'] as String? ?? '',
    );
  }
}

class InsufficientInfo {
  final String concernId;
  final String reason;
  final String action;
  final List<String> requiredInfo;

  InsufficientInfo({
    required this.concernId,
    required this.reason,
    required this.action,
    required this.requiredInfo,
  });

  factory InsufficientInfo.fromJson(Map<String, dynamic> json) {
    return InsufficientInfo(
      concernId: json['concernId'] as String? ?? '',
      reason: json['reason'] as String? ?? '',
      action: json['action'] as String? ?? '',
      requiredInfo: List<String>.from(json['requiredInfo'] ?? []),
    );
  }
}

class TriageSummary {
  final int totalProcessed;
  final int immediateCount;
  final int urgentCount;
  final int normalCount;
  final int lowCount;
  final int duplicateCount;
  final int insufficientCount;

  TriageSummary({
    required this.totalProcessed,
    required this.immediateCount,
    required this.urgentCount,
    required this.normalCount,
    required this.lowCount,
    required this.duplicateCount,
    required this.insufficientCount,
  });

  factory TriageSummary.fromJson(Map<String, dynamic> json) {
    return TriageSummary(
      totalProcessed: json['totalProcessed'] as int? ?? 0,
      immediateCount: json['immediateCount'] as int? ?? 0,
      urgentCount: json['urgentCount'] as int? ?? 0,
      normalCount: json['normalCount'] as int? ?? 0,
      lowCount: json['lowCount'] as int? ?? 0,
      duplicateCount: json['duplicateCount'] as int? ?? 0,
      insufficientCount: json['insufficientCount'] as int? ?? 0,
    );
  }
}

class ResourceRequirements {
  final int seniorInvestigators;
  final int financialSpecialists;
  final int generalOfficers;
  final String estimatedTotalTime;

  ResourceRequirements({
    required this.seniorInvestigators,
    required this.financialSpecialists,
    required this.generalOfficers,
    required this.estimatedTotalTime,
  });

  factory ResourceRequirements.fromJson(Map<String, dynamic> json) {
    return ResourceRequirements(
      seniorInvestigators: json['seniorInvestigators'] as int? ?? 0,
      financialSpecialists: json['financialSpecialists'] as int? ?? 0,
      generalOfficers: json['generalOfficers'] as int? ?? 0,
      estimatedTotalTime: json['estimatedTotalTime'] as String? ?? '',
    );
  }
}

class EvidenceValidation {
  final EvidenceQuality evidenceQuality;
  final List<EvidenceItem> evidenceItems;
  final List<MissingEvidence> missingEvidence;
  final EvidenceChain evidenceChain;
  final LegalAssessment legalAssessment;
  final List<String> recommendations;
  final List<RiskFactor> riskFactors;

  EvidenceValidation({
    required this.evidenceQuality,
    required this.evidenceItems,
    required this.missingEvidence,
    required this.evidenceChain,
    required this.legalAssessment,
    required this.recommendations,
    required this.riskFactors,
  });

  factory EvidenceValidation.fromJson(Map<String, dynamic> json) {
    return EvidenceValidation(
      evidenceQuality: EvidenceQuality.fromJson(json['evidenceQuality'] ?? {}),
      evidenceItems: (json['evidenceItems'] as List?)
          ?.map((e) => EvidenceItem.fromJson(e))
          .toList() ?? [],
      missingEvidence: (json['missingEvidence'] as List?)
          ?.map((e) => MissingEvidence.fromJson(e))
          .toList() ?? [],
      evidenceChain: EvidenceChain.fromJson(json['evidenceChain'] ?? {}),
      legalAssessment: LegalAssessment.fromJson(json['legalAssessment'] ?? {}),
      recommendations: List<String>.from(json['recommendations'] ?? []),
      riskFactors: (json['riskFactors'] as List?)
          ?.map((r) => RiskFactor.fromJson(r))
          .toList() ?? [],
    );
  }
}

class EvidenceQuality {
  final String overall;
  final double score;
  final String description;

  EvidenceQuality({
    required this.overall,
    required this.score,
    required this.description,
  });

  factory EvidenceQuality.fromJson(Map<String, dynamic> json) {
    return EvidenceQuality(
      overall: json['overall'] as String? ?? 'moderate',
      score: (json['score'] as num?)?.toDouble() ?? 0.5,
      description: json['description'] as String? ?? '',
    );
  }
}

class EvidenceItem {
  final String item;
  final String type;
  final String quality;
  final double relevance;
  final String admissibility;
  final List<String> issues;
  final List<String> recommendations;

  EvidenceItem({
    required this.item,
    required this.type,
    required this.quality,
    required this.relevance,
    required this.admissibility,
    required this.issues,
    required this.recommendations,
  });

  factory EvidenceItem.fromJson(Map<String, dynamic> json) {
    return EvidenceItem(
      item: json['item'] as String? ?? '',
      type: json['type'] as String? ?? '',
      quality: json['quality'] as String? ?? 'medium',
      relevance: (json['relevance'] as num?)?.toDouble() ?? 0.5,
      admissibility: json['admissibility'] as String? ?? 'questionable',
      issues: List<String>.from(json['issues'] ?? []),
      recommendations: List<String>.from(json['recommendations'] ?? []),
    );
  }
}

class MissingEvidence {
  final String type;
  final String importance;
  final String description;
  final String howToObtain;

  MissingEvidence({
    required this.type,
    required this.importance,
    required this.description,
    required this.howToObtain,
  });

  factory MissingEvidence.fromJson(Map<String, dynamic> json) {
    return MissingEvidence(
      type: json['type'] as String? ?? '',
      importance: json['importance'] as String? ?? 'medium',
      description: json['description'] as String? ?? '',
      howToObtain: json['howToObtain'] as String? ?? '',
    );
  }
}

class EvidenceChain {
  final bool isComplete;
  final List<String> gaps;
  final List<String> strengths;

  EvidenceChain({
    required this.isComplete,
    required this.gaps,
    required this.strengths,
  });

  factory EvidenceChain.fromJson(Map<String, dynamic> json) {
    return EvidenceChain(
      isComplete: json['isComplete'] as bool? ?? false,
      gaps: List<String>.from(json['gaps'] ?? []),
      strengths: List<String>.from(json['strengths'] ?? []),
    );
  }
}

class LegalAssessment {
  final double admissibilityScore;
  final List<String> legalIssues;
  final String courtReadiness;

  LegalAssessment({
    required this.admissibilityScore,
    required this.legalIssues,
    required this.courtReadiness,
  });

  factory LegalAssessment.fromJson(Map<String, dynamic> json) {
    return LegalAssessment(
      admissibilityScore: (json['admissibilityScore'] as num?)?.toDouble() ?? 0.0,
      legalIssues: List<String>.from(json['legalIssues'] ?? []),
      courtReadiness: json['courtReadiness'] as String? ?? 'needs_work',
    );
  }
}

