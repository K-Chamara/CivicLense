# 🤗 Hugging Face Sentiment Analysis Setup

This guide will help you set up Hugging Face Inference API for automatic concern prioritization in your Civic Lense app.

## 🚀 **Quick Setup (5 minutes)**

### 1. **Get Your Free Hugging Face API Key**

1. Go to [Hugging Face Settings](https://huggingface.co/settings/tokens)
2. Click "New token"
3. Name it: `civic-lense-sentiment`
4. Select "Read" permissions
5. Copy the token (starts with `hf_...`)

### 2. **Set Up Firebase Functions Configuration**

```bash
# Set your Hugging Face API key
firebase functions:config:set huggingface.key="YOUR_HF_API_KEY_HERE"

# Set your Gmail credentials (for email notifications)
firebase functions:config:set gmail.email="your-email@gmail.com" gmail.password="your-app-password"
```

### 3. **Deploy the Functions**

```bash
# Deploy all functions
firebase deploy --only functions

# Or deploy specific function
firebase deploy --only functions:autoPrioritizeConcerns
```

## 🧠 **How It Works**

### **Automatic Processing Flow:**
1. **Citizen submits concern** → Stored in Firestore
2. **Cloud Function triggers** → Analyzes text with AI
3. **AI determines priority** → Updates concern with results
4. **Officers get notified** → High-priority concerns flagged

### **AI Models Used:**
- **Sentiment Analysis**: `distilbert-base-uncased-finetuned-sst-2-english`
  - Detects: `positive`, `negative`, `neutral`
  - Confidence scores: 0.0 to 1.0
- **Topic Classification**: `cardiffnlp/tweet-topic-21-multi`
  - Categorizes concerns automatically
  - Topics: corruption, budget, tender, etc.

### **Priority Calculation:**
```javascript
// Critical: Very negative sentiment (90%+ confidence)
if (sentiment === 'negative' && score > 0.9) → 'critical'

// High: Negative sentiment (70%+ confidence)  
if (sentiment === 'negative' && score > 0.7) → 'high'

// Medium: Negative sentiment OR high engagement
if (sentiment === 'negative' || supportCount > 5) → 'medium'

// Low: Neutral/positive sentiment
else → 'low'
```

## 📊 **What Gets Added to Your Concerns**

After AI analysis, each concern gets these new fields:

```json
{
  "sentiment": "negative",
  "sentimentScore": 0.87,
  "priority": "high", 
  "priorityScore": 0.8,
  "category": "corruption",
  "confidence": 0.87,
  "aiAnalyzed": true,
  "analyzedAt": "2024-01-20T10:30:00Z",
  "metadata": {
    "ai_analysis": {
      "sentiment": {
        "sentiment": "negative",
        "score": 0.87,
        "confidence": 0.87
      },
      "topic": {
        "category": "corruption", 
        "confidence": 0.92
      },
      "priority": {
        "level": "high",
        "score": 0.8
      },
      "analyzed_at": "2024-01-20T10:30:00Z",
      "model_used": "distilbert-base-uncased-finetuned-sst-2-english"
    }
  }
}
```

## 🔔 **Notifications**

High-priority concerns automatically notify anti-corruption officers:

```json
{
  "type": "concern_priority_alert",
  "title": "🚨 HIGH Priority Concern: Corruption in Budget",
  "body": "AI analysis detected a high priority concern requiring immediate attention.",
  "data": {
    "concernId": "abc123",
    "priority": "high",
    "sentiment": "negative"
  }
}
```

## 🧪 **Testing**

### **Test with Sample Concerns:**

1. **High Priority Test:**
   ```
   Title: "Corruption in budget allocation"
   Description: "I am very angry about this terrible corruption and demand immediate action!"
   Expected: priority = "high", sentiment = "negative"
   ```

2. **Low Priority Test:**
   ```
   Title: "Great work on the new park"
   Description: "Thank you for the excellent work on the new community park!"
   Expected: priority = "low", sentiment = "positive"
   ```

### **Check Results:**
- Go to Firebase Console → Firestore → `concerns` collection
- Look for concerns with `aiAnalyzed: true`
- Check the `metadata.ai_analysis` field

## 📈 **Free Tier Limits**

- **Hugging Face Free Tier**: 1,000 requests/day
- **Perfect for**: Testing, pilot programs, small deployments
- **Upgrade path**: Move to self-hosted models on Cloud Run (still free)

## 🚨 **Troubleshooting**

### **Common Issues:**

1. **"Missing or insufficient permissions"**
   ```bash
   # Make sure you're logged in to Firebase
   firebase login
   firebase use your-project-id
   ```

2. **"Hugging Face API error"**
   ```bash
   # Check your API key
   firebase functions:config:get
   ```

3. **Function not triggering**
   ```bash
   # Check function logs
   firebase functions:log --only autoPrioritizeConcerns
   ```

### **Debug Commands:**
```bash
# View function logs
firebase functions:log

# Test function locally
firebase emulators:start --only functions

# Check configuration
firebase functions:config:get
```

## 🎯 **Next Steps**

1. **Deploy and test** with sample concerns
2. **Monitor logs** for any errors
3. **Check officer notifications** are working
4. **Customize priority rules** if needed
5. **Scale up** when ready (Cloud Run hosting)

## 💡 **Pro Tips**

- **Start small**: Test with 5-10 concerns first
- **Monitor costs**: Check Firebase usage dashboard
- **Customize models**: Switch to different Hugging Face models if needed
- **Add more AI**: Consider adding toxicity detection, language detection, etc.

---

**🎉 You're all set!** Your Civic Lense app now has AI-powered concern prioritization using Hugging Face's free tier.

