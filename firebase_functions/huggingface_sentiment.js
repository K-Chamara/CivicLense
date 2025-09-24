const functions = require('firebase-functions');
const admin = require('firebase-admin');
const fetch = require('node-fetch');

// Initialize Firebase Admin
admin.initializeApp();

// Hugging Face API configuration
const HF_API_KEY = functions.config().huggingface?.key || 'your-hf-api-key';
const HF_SENTIMENT_MODEL = 'distilbert-base-uncased-finetuned-sst-2-english';
const HF_TOPIC_MODEL = 'cardiffnlp/tweet-topic-21-multi';

/**
 * Auto-prioritize concerns using Hugging Face sentiment analysis
 * Triggered when a new concern is created
 */
exports.autoPrioritizeConcerns = functions.firestore
  .document('concerns/{concernId}')
  .onCreate(async (snap, context) => {
    const concernData = snap.data();
    const concernId = context.params.concernId;
    
    try {
      console.log(`🤖 Auto-prioritizing concern: ${concernId}`);
      
      // Combine title and description for analysis
      const textToAnalyze = `${concernData.title || ''} ${concernData.description || ''}`.trim();
      
      if (!textToAnalyze) {
        console.log('⚠️ No text to analyze, skipping AI processing');
        return;
      }
      
      // 1. Analyze sentiment using Hugging Face
      const sentimentResult = await analyzeSentiment(textToAnalyze);
      
      // 2. Analyze topic/category (optional)
      const topicResult = await analyzeTopic(textToAnalyze);
      
      // 3. Calculate priority based on sentiment and engagement
      const priority = calculatePriority(sentimentResult, concernData);
      
      // 4. Update concern with AI results
      await admin.firestore().collection('concerns').doc(concernId).update({
        sentiment: sentimentResult.sentiment,
        sentimentScore: sentimentResult.score,
        priority: priority.level,
        priorityScore: priority.score,
        category: topicResult.category,
        confidence: sentimentResult.confidence,
        analyzedAt: admin.firestore.FieldValue.serverTimestamp(),
        aiAnalyzed: true,
        metadata: {
          ...concernData.metadata,
          ai_analysis: {
            sentiment: sentimentResult,
            topic: topicResult,
            priority: priority,
            analyzed_at: new Date().toISOString(),
            model_used: HF_SENTIMENT_MODEL
          }
        }
      });
      
      // 5. Create update record
      await admin.firestore().collection('concern_updates').add({
        concernId: concernId,
        officerId: 'ai_system',
        officerName: 'AI Analysis System',
        action: 'auto_prioritized',
        description: `Concern auto-prioritized to ${priority.level} based on sentiment analysis (${sentimentResult.sentiment}: ${Math.round(sentimentResult.score * 100)}%)`,
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
        changes: {
          priority: priority.level,
          sentiment: sentimentResult.sentiment,
          sentimentScore: sentimentResult.score,
          category: topicResult.category
        }
      });
      
      // 6. Send notification to officers if high priority
      if (priority.level === 'high' || priority.level === 'critical') {
        await notifyOfficers(concernId, concernData, priority);
      }
      
      console.log(`✅ Successfully auto-prioritized concern ${concernId} to ${priority.level}`);
      
    } catch (error) {
      console.error(`❌ Error auto-prioritizing concern ${concernId}:`, error);
      
      // Fallback: set default priority
      await admin.firestore().collection('concerns').doc(concernId).update({
        priority: 'medium',
        priorityScore: 0.5,
        aiAnalyzed: false,
        analysisError: error.message,
        analyzedAt: admin.firestore.FieldValue.serverTimestamp()
      });
    }
  });

/**
 * Analyze sentiment using Hugging Face API
 */
async function analyzeSentiment(text) {
  try {
    const response = await fetch(
      `https://api-inference.huggingface.co/models/${HF_SENTIMENT_MODEL}`,
      {
        method: 'POST',
        headers: {
          'Authorization': `Bearer ${HF_API_KEY}`,
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({ inputs: text }),
      }
    );

    if (!response.ok) {
      throw new Error(`Hugging Face API error: ${response.status}`);
    }

    const result = await response.json();
    
    if (Array.isArray(result) && result.length > 0) {
      const prediction = result[0];
      return {
        sentiment: prediction.label.toLowerCase(),
        score: prediction.score,
        confidence: prediction.score
      };
    }
    
    // Fallback if API returns unexpected format
    return {
      sentiment: 'neutral',
      score: 0.5,
      confidence: 0.5
    };
    
  } catch (error) {
    console.error('Error analyzing sentiment:', error);
    return {
      sentiment: 'neutral',
      score: 0.5,
      confidence: 0.5
    };
  }
}

/**
 * Analyze topic/category using Hugging Face API
 */
async function analyzeTopic(text) {
  try {
    const response = await fetch(
      `https://api-inference.huggingface.co/models/${HF_TOPIC_MODEL}`,
      {
        method: 'POST',
        headers: {
          'Authorization': `Bearer ${HF_API_KEY}`,
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({ inputs: text }),
      }
    );

    if (!response.ok) {
      throw new Error(`Hugging Face API error: ${response.status}`);
    }

    const result = await response.json();
    
    if (Array.isArray(result) && result.length > 0) {
      const prediction = result[0];
      return {
        category: prediction.label.toLowerCase(),
        confidence: prediction.score
      };
    }
    
    return {
      category: 'general',
      confidence: 0.5
    };
    
  } catch (error) {
    console.error('Error analyzing topic:', error);
    return {
      category: 'general',
      confidence: 0.5
    };
  }
}

/**
 * Calculate priority based on sentiment and engagement
 */
function calculatePriority(sentimentResult, concernData) {
  const { sentiment, score } = sentimentResult;
  
  // Base priority from sentiment
  let priorityLevel = 'low';
  let priorityScore = 0.3;
  
  // Critical: Very negative sentiment with high confidence
  if (sentiment === 'negative' && score > 0.9) {
    priorityLevel = 'critical';
    priorityScore = 0.95;
  }
  // High: Negative sentiment with good confidence
  else if (sentiment === 'negative' && score > 0.7) {
    priorityLevel = 'high';
    priorityScore = 0.8;
  }
  // Medium: Negative sentiment or high engagement
  else if (sentiment === 'negative' || (concernData.supportCount || 0) > 5) {
    priorityLevel = 'medium';
    priorityScore = 0.6;
  }
  // Low: Neutral or positive sentiment
  else {
    priorityLevel = 'low';
    priorityScore = 0.3;
  }
  
  // Boost priority for corruption-related concerns
  if (concernData.category === 'corruption' || 
      (concernData.title && concernData.title.toLowerCase().includes('corruption'))) {
    priorityLevel = priorityLevel === 'low' ? 'medium' : priorityLevel;
    priorityScore = Math.min(priorityScore + 0.2, 1.0);
  }
  
  // Boost priority for flagged concerns
  if (concernData.isFlaggedByCitizens) {
    priorityLevel = priorityLevel === 'low' ? 'medium' : 
                   priorityLevel === 'medium' ? 'high' : 'critical';
    priorityScore = Math.min(priorityScore + 0.3, 1.0);
  }
  
  return {
    level: priorityLevel,
    score: priorityScore
  };
}

/**
 * Notify anti-corruption officers about high priority concerns
 */
async function notifyOfficers(concernId, concern, priority) {
  try {
    // Get all anti-corruption officers
    const officersSnapshot = await admin.firestore()
      .collection('users')
      .where('role.id', '==', 'anticorruption_officer')
      .get();
    
    const notifications = [];
    
    officersSnapshot.forEach(doc => {
      const officer = doc.data();
      notifications.push({
        userId: doc.id,
        type: 'concern_priority_alert',
        title: `🚨 ${priority.level.toUpperCase()} Priority Concern: ${concern.title}`,
        body: `AI analysis detected a ${priority.level} priority concern requiring immediate attention.`,
        data: {
          concernId: concernId,
          priority: priority.level,
          category: concern.category,
          authorName: concern.authorName,
          sentiment: concern.sentiment
        },
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
        read: false,
        priority: priority.level
      });
    });
    
    // Batch write notifications
    if (notifications.length > 0) {
      const batch = admin.firestore().batch();
      notifications.forEach(notification => {
        const notificationRef = admin.firestore().collection('notifications').doc();
        batch.set(notificationRef, notification);
      });
      await batch.commit();
    }
    
    console.log(`📢 Sent ${notifications.length} priority notifications to officers`);
    
  } catch (error) {
    console.error('Error sending notifications:', error);
  }
}

