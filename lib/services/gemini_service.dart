import 'package:google_generative_ai/google_generative_ai.dart';

class GeminiService {
  // Your Gemini API Key
  static const String _apiKey = 'AIzaSyCa_3C65rqlj6xOZNtjHQSjQ_h8c42dz2w';
  
  // Initialize Gemini model
  static final _model = GenerativeModel(
    model: 'gemini-2.0-flash-exp',
    apiKey: _apiKey,
  );

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

  /// Analyze community content for violations
  static Future<String> analyzeCommunityViolation({
    required String communityName,
    required String content,
    required String authorName,
  }) async {
    try {
      final prompt = '''
Analyze this community post for potential violations in the context of the "$communityName" community:

Author: $authorName
Content: "$content"

Check for:
1. Community guideline violations
2. Off-topic content for this community
3. Spam or promotional content
4. Inappropriate language or behavior
5. Personal attacks or harassment
6. Misinformation
7. Hate speech or discrimination
8. Copyright violations

Provide your analysis in this format:
VIOLATION STATUS: [SAFE/FLAGGED/DANGEROUS]
VIOLATION TYPE: [None/Guideline Violation/Spam/Inappropriate/etc.]
CONFIDENCE: [0.0-1.0]
REASONING: [Detailed explanation of your assessment]
RECOMMENDED ACTION: [Approve/Warning/Reject/Delete]
SEVERITY: [Low/Medium/High/Critical]
ADDITIONAL NOTES: [Any additional context or recommendations]

Consider Sri Lankan context and cultural sensitivities.
''';

      final response = await _model.generateContent([Content.text(prompt)]);
      return response.text ?? 'Unable to analyze content';
    } catch (e) {
      print('❌ Gemini community violation analysis error: $e');
      return 'Error analyzing community violation: $e';
    }
  }

  /// Generate community moderation report
  static Future<String> generateModerationReport({
    required String communityName,
    required List<String> violations,
    required List<String> actions,
  }) async {
    try {
      final prompt = '''
Generate a comprehensive moderation report for the community "$communityName":

Recent Violations:
${violations.map((v) => '- $v').join('\n')}

Actions Taken:
${actions.map((a) => '- $a').join('\n')}

Provide a professional moderation report including:
1. Summary of community health
2. Violation trends and patterns
3. Recommendations for community improvement
4. Action items for moderators
5. Community guidelines suggestions

Format as a structured report suitable for anti-corruption officers.
''';

      final response = await _model.generateContent([Content.text(prompt)]);
      return response.text ?? 'Unable to generate report';
    } catch (e) {
      print('❌ Gemini moderation report error: $e');
      return 'Error generating moderation report: $e';
    }
  }
}
