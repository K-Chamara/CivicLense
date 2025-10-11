import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/concern_models.dart';
import '../services/smart_priority_service.dart';

/// Development utility to add AI analysis to existing concerns
/// Run this once to update all existing concerns with AI analysis
class AddAIToConcernsUtility {
  static Future<void> addAIAnalysisToExistingConcerns() async {
    print('🤖 Starting AI analysis migration for existing concerns...');
    
    try {
      // Get all concerns without AI analysis
      final querySnapshot = await FirebaseFirestore.instance
          .collection('concerns')
          .get();
      
      int updated = 0;
      int skipped = 0;
      
      for (var doc in querySnapshot.docs) {
        try {
          final data = doc.data();
          final metadata = data['metadata'] as Map<String, dynamic>? ?? {};
          
          // Skip if already has AI analysis
          if (metadata.containsKey('aiAnalysis')) {
            skipped++;
            print('⏭️  Skipping concern ${doc.id} - already has AI analysis');
            continue;
          }
          
          // Get concern data
          final title = data['title'] as String? ?? '';
          final description = data['description'] as String? ?? '';
          final categoryStr = data['category'] as String? ?? 'other';
          
          // Map category string to enum
          ConcernCategory category;
          try {
            category = ConcernCategory.values.firstWhere(
              (e) => e.name == categoryStr,
              orElse: () => ConcernCategory.other,
            );
          } catch (e) {
            category = ConcernCategory.other;
          }
          
          // Run AI analysis
          final aiResult = SmartPriorityService.analyzeConcern(
            title,
            description,
            category,
          );
          
          // Prepare AI analysis metadata
          final aiAnalysis = {
            'priority': aiResult.priority.priority.name,
            'priorityScore': aiResult.priority.score,
            'reasoning': aiResult.priority.reasoning,
            'sentiment': aiResult.sentiment.sentimentScore.name,
            'sentimentScore': aiResult.sentiment.score,
            'sentimentMagnitude': aiResult.sentiment.magnitude,
            'topics': aiResult.topics,
            'confidence': aiResult.confidence,
            'analyzedAt': FieldValue.serverTimestamp(),
            'model': 'SmartPriorityService v1.0 (Keyword-based)',
          };
          
          // Update metadata
          metadata['aiAnalysis'] = aiAnalysis;
          
          // Update the concern in Firestore
          await FirebaseFirestore.instance
              .collection('concerns')
              .doc(doc.id)
              .update({
            'metadata': metadata,
            'priority': aiResult.priority.priority.name,
            'sentimentScore': aiResult.sentiment.sentimentScore.name,
            'sentimentMagnitude': aiResult.sentiment.magnitude,
          });
          
          updated++;
          print('✅ Updated concern ${doc.id} with AI analysis');
          print('   Priority: ${aiResult.priority.priority.name} (${(aiResult.priority.score * 100).toStringAsFixed(0)}%)');
          print('   Sentiment: ${aiResult.sentiment.sentimentScore.name}');
          print('   Topics: ${aiResult.topics.join(", ")}');
          print('   Confidence: ${(aiResult.confidence * 100).toStringAsFixed(0)}%');
          
        } catch (e) {
          print('❌ Error updating concern ${doc.id}: $e');
        }
      }
      
      print('\n🎉 Migration complete!');
      print('✅ Updated: $updated concerns');
      print('⏭️  Skipped: $skipped concerns (already had AI analysis)');
      print('📊 Total processed: ${querySnapshot.docs.length} concerns');
      
    } catch (e) {
      print('❌ Migration failed: $e');
      rethrow;
    }
  }
}

