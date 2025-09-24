import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/concern_models.dart';

class SentimentService {
  static const String _baseUrl = 'https://language.googleapis.com/v1/documents:analyzeSentiment';
  final String _apiKey;

  SentimentService({required String apiKey}) : _apiKey = apiKey;

  /// Analyze sentiment of concern text using Google NLP API
  /// DISABLED: Client-side sentiment analysis is disabled for security reasons.
  /// Use server-side Cloud Functions instead.
  Future<SentimentAnalysisResult> analyzeSentiment(String text) async {
    // SECURITY: Client-side sentiment analysis disabled to prevent API key exposure
    // Use server-side Cloud Functions for sentiment analysis instead
    throw Exception('Client-side sentiment analysis is disabled. Use server-side Cloud Functions.');
  }

  /// Map numeric score to SentimentScore enum
  SentimentScore _mapScoreToSentiment(double score) {
    if (score >= 0.6) return SentimentScore.veryPositive;
    if (score >= 0.2) return SentimentScore.positive;
    if (score >= -0.2) return SentimentScore.neutral;
    if (score >= -0.6) return SentimentScore.negative;
    return SentimentScore.veryNegative;
  }

  /// Analyze sentiment for multiple texts (batch processing)
  Future<List<SentimentAnalysisResult>> analyzeBatchSentiment(List<String> texts) async {
    final results = <SentimentAnalysisResult>[];
    
    for (final text in texts) {
      try {
        final result = await analyzeSentiment(text);
        results.add(result);
      } catch (e) {
        // Add neutral sentiment for failed analyses
        results.add(SentimentAnalysisResult(
          score: 0.0,
          magnitude: 0.0,
          sentimentScore: SentimentScore.neutral,
        ));
      }
    }
    
    return results;
  }

  /// Determine priority based on sentiment analysis
  ConcernPriority determinePriorityFromSentiment(SentimentAnalysisResult sentiment) {
    // Very negative sentiment with high magnitude = critical priority
    if (sentiment.sentimentScore == SentimentScore.veryNegative && sentiment.magnitude > 0.5) {
      return ConcernPriority.critical;
    }
    
    // Negative sentiment with medium magnitude = high priority
    if (sentiment.sentimentScore == SentimentScore.negative && sentiment.magnitude > 0.3) {
      return ConcernPriority.high;
    }
    
    // Very negative sentiment = high priority
    if (sentiment.sentimentScore == SentimentScore.veryNegative) {
      return ConcernPriority.high;
    }
    
    // Negative sentiment = medium priority
    if (sentiment.sentimentScore == SentimentScore.negative) {
      return ConcernPriority.medium;
    }
    
    // Default to low priority
    return ConcernPriority.low;
  }
}

class SentimentAnalysisResult {
  final double score;
  final double magnitude;
  final SentimentScore sentimentScore;

  SentimentAnalysisResult({
    required this.score,
    required this.magnitude,
    required this.sentimentScore,
  });

  @override
  String toString() {
    return 'SentimentAnalysisResult(score: $score, magnitude: $magnitude, sentiment: $sentimentScore)';
  }
}
