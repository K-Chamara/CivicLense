const functions = require('firebase-functions');
const admin = require('firebase-admin');
const { GoogleLanguageServiceClient } = require('@google-cloud/language');

// Initialize Google Cloud Language client
const languageClient = new GoogleLanguageServiceClient();

/**
 * Auto-prioritize concerns based on sentiment analysis and engagement
 * Triggered when a new concern is created
 */
exports.autoPrioritizeConcerns = functions.firestore
  .document('concerns/{concernId}')
  .onCreate(async (snap, context) => {
    const concern = snap.data();
    const concernId = context.params.concernId;
    
    try {
      console.log(`Auto-prioritizing concern: ${concernId}`);
      
      // Analyze sentiment using Google NLP
      const sentimentResult = await analyzeSentiment(concern.title + ' ' + concern.description);
      
      // Calculate engagement score
      const engagementScore = calculateEngagementScore(concern);
      
      // Determine priority based on sentiment and engagement
      const priority = determinePriority(sentimentResult, engagementScore, concern);
      
      // Update concern with auto-prioritization data
      await admin.firestore().collection('concerns').doc(concernId).update({
        priority: priority,
        sentimentScore: sentimentResult.sentiment,
        sentimentMagnitude: sentimentResult.magnitude,
        engagementScore: engagementScore,
        autoPrioritized: true,
        prioritizedAt: admin.firestore.FieldValue.serverTimestamp(),
        metadata: {
          ...concern.metadata,
          auto_prioritization: {
            sentiment_score: sentimentResult.score,
            sentiment_magnitude: sentimentResult.magnitude,
            engagement_score: engagementScore,
            priority: priority,
            analyzed_at: new Date().toISOString()
          }
        }
      });
      
      // Create update record
      await admin.firestore().collection('concern_updates').add({
        concernId: concernId,
        officerId: 'system',
        officerName: 'Auto-Prioritization System',
        action: 'auto_prioritized',
        description: `Concern auto-prioritized to ${priority} based on sentiment analysis`,
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
        changes: {
          priority: priority,
          sentiment_score: sentimentResult.score,
          engagement_score: engagementScore
        }
      });
      
      // Send notification to anti-corruption officers if high priority
      if (priority === 'high' || priority === 'critical') {
        await notifyOfficers(concernId, concern, priority);
      }
      
      console.log(`Successfully auto-prioritized concern ${concernId} to ${priority}`);
      
    } catch (error) {
      console.error(`Error auto-prioritizing concern ${concernId}:`, error);
    }
  });

/**
 * Analyze sentiment using Google Cloud Language API
 */
async function analyzeSentiment(text) {
  try {
    const document = {
      content: text,
      type: 'PLAIN_TEXT',
    };
    
    const [result] = await languageClient.analyzeSentiment({ document });
    const sentiment = result.documentSentiment;
    
    return {
      score: sentiment.score,
      magnitude: sentiment.magnitude,
      sentiment: mapScoreToSentiment(sentiment.score)
    };
  } catch (error) {
    console.error('Error analyzing sentiment:', error);
    return {
      score: 0,
      magnitude: 0,
      sentiment: 'neutral'
    };
  }
}

/**
 * Map numeric score to sentiment category
 */
function mapScoreToSentiment(score) {
  if (score >= 0.6) return 'very_positive';
  if (score >= 0.2) return 'positive';
  if (score >= -0.2) return 'neutral';
  if (score >= -0.6) return 'negative';
  return 'very_negative';
}

/**
 * Calculate engagement score based on various factors
 */
function calculateEngagementScore(concern) {
  let score = 0;
  
  // Base score from support count
  score += (concern.supportCount || 0) * 2;
  
  // Bonus for comments
  score += (concern.commentCount || 0) * 1;
  
  // Bonus for upvotes
  score += (concern.upvotes || 0) * 1;
  
  // Penalty for downvotes
  score -= (concern.downvotes || 0) * 0.5;
  
  // Bonus for flagged concerns
  if (concern.isFlaggedByCitizens) {
    score += 10;
  }
  
  // Bonus for corruption-related concerns
  if (concern.category === 'corruption') {
    score += 5;
  }
  
  return Math.max(0, score);
}

/**
 * Determine priority based on sentiment and engagement
 */
function determinePriority(sentimentResult, engagementScore, concern) {
  const { sentiment, magnitude } = sentimentResult;
  
  // Critical priority conditions
  if (sentiment === 'very_negative' && magnitude > 0.5 && engagementScore > 20) {
    return 'critical';
  }
  
  if (concern.category === 'corruption' && sentiment === 'very_negative') {
    return 'critical';
  }
  
  // High priority conditions
  if (sentiment === 'very_negative' && magnitude > 0.3) {
    return 'high';
  }
  
  if (engagementScore > 15 && (sentiment === 'negative' || sentiment === 'very_negative')) {
    return 'high';
  }
  
  if (concern.category === 'corruption' && engagementScore > 10) {
    return 'high';
  }
  
  // Medium priority conditions
  if (sentiment === 'negative' || engagementScore > 5) {
    return 'medium';
  }
  
  // Default to low priority
  return 'low';
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
        title: `High Priority Concern: ${concern.title}`,
        body: `A ${priority} priority concern has been flagged and requires attention.`,
        data: {
          concernId: concernId,
          priority: priority,
          category: concern.category,
          authorName: concern.authorName
        },
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
        read: false
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
    
    console.log(`Sent ${notifications.length} priority notifications to officers`);
    
  } catch (error) {
    console.error('Error sending notifications:', error);
  }
}
