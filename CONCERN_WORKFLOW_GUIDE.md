# 📋 Concern Management Workflow - CivicLense

## 🎯 Overview

This document explains the complete workflow when a citizen raises a concern in the CivicLense app, from submission to resolution, including all AI-powered features and notifications.

---

## 🔄 Complete Concern Flow

### **Phase 1: Citizen Raises Concern**

#### **1.1 Initial Submission**
```
Citizen → Raise Concern Screen → Fill Form
```

**What the Citizen Provides:**
- ✏️ **Title** (required)
- 📝 **Description** (required)
- 🏷️ **Category** (budget, tender, corruption, community, etc.)
- 📍 **Location/District** (optional)
- 📎 **Attachments** (photos, documents, videos)
- 👤 **Anonymous option** (can hide identity)

#### **1.2 AI Analysis (Automatic - Google Gemini)**
```
Submit Button Clicked → AI Analysis Triggered
```

**AI Processes:**
1. **Sentiment Analysis**
   - Analyzes emotional tone (Very Negative → Very Positive)
   - Measures sentiment magnitude (intensity)
   - Output: `SentimentScore` with confidence level

2. **Category Suggestion**
   - AI suggests appropriate category based on content
   - Provides reasoning for suggestion
   - Output: Suggested category with confidence %

3. **Priority Assessment**
   - Evaluates urgency and severity
   - Considers keywords like "urgent", "emergency", "corruption"
   - Output: Priority level (low, medium, high, critical)

4. **Real Engagement Score**
   - Searches Firestore for similar concerns (by keywords)
   - Calculates average support count
   - Shows how many citizens support similar issues
   - Output: Engagement percentage and citizen count

#### **1.3 Data Saved to Firestore**
```
concerns collection:
{
  id: "unique_concern_id",
  title: "Concern title",
  description: "Full description",
  category: ConcernCategory,
  status: "pending",
  priority: "medium",
  userId: "citizen_uid",
  userEmail: "citizen@email.com",
  location: "Colombo",
  attachmentUrls: ["url1", "url2"],
  isAnonymous: false,
  supportCount: 0,
  viewCount: 0,
  createdAt: Timestamp,
  updatedAt: Timestamp,
  
  // AI Analysis Results
  sentimentScore: {
    score: -0.8,
    magnitude: 0.9,
    label: "negative"
  },
  aiAnalysis: {
    priority: "high",
    confidence: 0.85,
    sentiment: "verynegative",
    urgencyLevel: 4,
    estimatedDays: 7,
    topics: ["corruption", "public funds", "tender"],
    summary: "AI-generated summary"
  }
}
```

#### **1.4 Notifications Sent**
```
Concern Created → Trigger Notifications
```

**Notifications Go To:**
1. ✅ **Citizen** - Confirmation that concern was submitted
2. ✅ **All Anti-Corruption Officers** - New concern alert
3. ✅ **Admin** - New concern notification (if high priority)

**Notification Types:**
- 📱 **Push Notification** (via FCM - Firebase Cloud Messaging)
- 🔔 **In-App Notification** (saved to `notifications` collection)
- 📧 **Email** (optional, for critical concerns)

---

### **Phase 2: Anti-Corruption Officer Reviews**

#### **2.1 Officer Receives Notification**
```
Push Notification → Officer Opens App → Dashboard Updated
```

**Dashboard Shows:**
- 📊 **Priority Concerns** (sorted by AI priority)
- 🔥 **Critical Alerts** (red badge)
- 📈 **Sentiment Trends** (overall mood of concerns)
- 🤖 **AI Analysis Card** (visible for each concern)

#### **2.2 Officer Views Concern Detail**
```
Concern List → Click Concern → Detail Screen
```

**Officer Sees:**
- Full concern details
- Citizen information (unless anonymous)
- All attachments and evidence
- **AI Analysis Panel:**
  - Priority Score (with confidence %)
  - Sentiment Analysis (emotion & magnitude)
  - Urgency Level (timeline estimate)
  - Key Topics Extracted
  - Similar Concerns (duplicates detected)

#### **2.3 AI Assistant Tools Available**
```
AI Assistant Button → Officer Access AI Features
```

**Officer Can Use:**

1. **🎯 Priority Ranking**
   - Re-analyze concern priority
   - Get AI recommendations for urgency

2. **🔍 Duplicate Detection**
   - Find similar concerns in database
   - Merge duplicates suggestion

3. **🧩 Pattern Detection**
   - Identify recurring issues
   - Find connected concerns (corruption networks)

4. **📊 Risk Assessment**
   - Evaluate investigation risks
   - Get safety recommendations

5. **💬 Response Suggestions**
   - AI-generated draft responses
   - Tone selection (formal, empathetic, etc.)

6. **📈 Predictive Analytics**
   - Forecast future trends
   - Identify hotspot locations

7. **🌐 Network Detection**
   - Find interconnected entities
   - Visualize corruption networks

8. **📝 Evidence Validation**
   - Assess attachment quality
   - Verify evidence authenticity

---

### **Phase 3: Officer Takes Action**

#### **3.1 Status Update**
```
Officer → Change Status → Save
```

**Status Options:**
- 🟡 **Pending** (initial state)
- 🔵 **Under Review** (officer assigned)
- 🟢 **Resolved** (case closed)
- 🔴 **Rejected** (invalid/spam)

**What Happens:**
1. Status updated in Firestore
2. **Notification sent to citizen** (push + in-app)
3. Timeline entry added
4. Officer comment can be added

#### **3.2 Officer Adds Comment**
```
Comment Box → Write Response → Post
```

**Comment Features:**
- 💬 Public comments (visible to citizen)
- 📝 Internal notes (officer-only)
- 🤖 AI-assisted drafting (optional)
- 📎 Attach additional documents

**What Happens:**
1. Comment saved to `comments` subcollection
2. **Notification sent to citizen** (push + in-app)
3. Citizen can reply
4. Email notification (if enabled)

#### **3.3 Cloud Function Triggers**
```
Firestore Update → Cloud Function → Send Push Notification
```

**Firebase Cloud Functions:**
1. **`onConcernStatusChange`**
   - Triggers when status changes
   - Sends push notification to citizen
   - Updates analytics

2. **`onNewConcernComment`**
   - Triggers when officer comments
   - Sends push notification to citizen
   - Logs activity

3. **`sendPushNotification`**
   - Sends FCM message to specific user
   - Handles token validation
   - Retries on failure

4. **`sendBulkPushNotifications`**
   - Sends to multiple users at once
   - Used for mass announcements

---

### **Phase 4: Citizen Receives Updates**

#### **4.1 Push Notification**
```
Cloud Function → FCM → Citizen's Device
```

**Notification Shows:**
- Title: "Concern Update"
- Body: "Your concern has been updated to: Under Review"
- Data: concern ID, status, officer name
- Action: Tap to open concern detail

#### **4.2 In-App Notification**
```
Notifications Tab → Badge Count → List of Notifications
```

**Notification Details:**
- ✉️ **Unread badge** on notifications icon
- 📋 **List view** with timestamps
- 👆 **Tap to open** concern detail
- ✅ **Mark as read** functionality

#### **4.3 Citizen Responds**
```
Concern Detail → Add Comment → Reply to Officer
```

**Citizen Can:**
- 💬 Reply to officer comments
- 📎 Add more evidence
- 👍 Mark response as helpful
- 📢 Share concern with community

---

### **Phase 5: Resolution & Follow-up**

#### **5.1 Concern Resolved**
```
Officer → Mark as Resolved → Provide Resolution Details
```

**Resolution Process:**
1. Officer changes status to "Resolved"
2. Adds resolution notes
3. Attaches proof of resolution (optional)
4. **Final notification sent to citizen**

#### **5.2 Citizen Feedback**
```
Citizen → Rate Resolution → Provide Feedback
```

**Feedback Options:**
- ⭐ Rating (1-5 stars)
- 💬 Comment on resolution
- ✅ Confirm issue resolved
- ❌ Request re-opening

#### **5.3 Analytics & Reporting**
```
Resolved Concern → Update Statistics → Dashboard Metrics
```

**Metrics Tracked:**
- ⏱️ Average resolution time
- 📊 Resolution rate by category
- 👍 Citizen satisfaction score
- 🎯 Officer performance metrics
- 📈 Trending issues
- 🗺️ Hotspot locations

---

## 🔔 Notification Flow Diagram

```
┌─────────────────────────────────────────────────────────────┐
│                      NOTIFICATION FLOW                       │
└─────────────────────────────────────────────────────────────┘

1. CITIZEN SUBMITS CONCERN
   ↓
2. FIRESTORE: Concern Document Created
   ↓
3. FLUTTER APP: NotificationService.notifyNewConcern()
   ↓
4. FIRESTORE: Create notification documents for officers
   ↓
5. CLOUD FUNCTION: sendPushNotification() called
   ↓
6. FCM: Fetch officer FCM tokens from Firestore
   ↓
7. FCM ADMIN SDK: Send push notifications
   ↓
8. OFFICER DEVICE: Notification received
   ├─ Foreground: Shows banner
   └─ Background: Shows system notification
   ↓
9. OFFICER TAPS NOTIFICATION
   ↓
10. APP: Navigate to concern detail screen

───────────────────────────────────────────────────────────

OFFICER UPDATES STATUS
   ↓
1. FIRESTORE: Status field updated
   ↓
2. CLOUD FUNCTION TRIGGER: onConcernStatusChange()
   ↓
3. FETCH CITIZEN FCM TOKEN: From users/{userId}
   ↓
4. FCM ADMIN SDK: Send push to citizen
   ↓
5. CITIZEN DEVICE: Notification received
   ↓
6. CITIZEN TAPS: Opens concern detail

───────────────────────────────────────────────────────────

OFFICER ADDS COMMENT
   ↓
1. FIRESTORE: Comment document created
   ↓
2. CLOUD FUNCTION TRIGGER: onNewConcernComment()
   ↓
3. FETCH CITIZEN FCM TOKEN
   ↓
4. FCM ADMIN SDK: Send push notification
   ↓
5. CITIZEN DEVICE: "Officer replied to your concern"
   ↓
6. CITIZEN READS: In-app notification + detail view
```

---

## 🚀 Push Notification Setup

### **1. Required Components**

#### **Flutter App (Client):**
- ✅ `firebase_messaging` package
- ✅ `NotificationService` class
- ✅ FCM token acquisition
- ✅ Permission handling

#### **Firebase (Backend):**
- ✅ Cloud Functions deployed
- ✅ FCM Admin SDK configured
- ✅ Firestore triggers active

#### **User Device:**
- ✅ Notification permission granted
- ✅ FCM token saved to Firestore
- ✅ App registered with FCM

### **2. First-Time Setup Flow**

```
1. USER INSTALLS APP
   ↓
2. ONBOARDING SCREENS
   ↓
3. PERMISSION REQUEST SCREEN (NEW!)
   ├─ Request Notification Permission
   └─ Request Storage Permission
   ↓
4. IF GRANTED:
   ├─ FCM token acquired
   ├─ Token saved to Firestore (users/{uid}/fcmToken)
   └─ NotificationService initialized
   ↓
5. USER LOGS IN
   ↓
6. COMMON HOME SCREEN
   ├─ Re-initialize notifications
   └─ Listen for foreground messages
   ↓
7. READY TO RECEIVE NOTIFICATIONS!
```

### **3. FCM Token Management**

**Token Storage (Firestore):**
```javascript
users/{userId}: {
  email: "user@example.com",
  fcmToken: "device_fcm_token_here",  // ← Stored here
  fcmTokenUpdatedAt: Timestamp,
  ...
}
```

**Token Refresh:**
- Automatically refreshes when token expires
- Updated in Firestore on refresh
- Handled by `NotificationService`

---

## 🧪 Testing Notifications

### **Method 1: Use Test Widget**

```dart
// Add to any screen (e.g., officer dashboard)
import '../widgets/notification_test_widget.dart';

// In build method:
NotificationTestWidget(),
```

**Test Features:**
- ✅ Check FCM token saved
- ✅ Verify notification permissions
- ✅ Send test notification
- ✅ Run full notification flow test

### **Method 2: Manual Test**

1. **Deploy Cloud Functions:**
   ```bash
   cd firebase_functions
   npm install
   firebase deploy --only functions
   ```

2. **Create a Test Concern:**
   - Log in as citizen
   - Raise a concern
   - Check officer receives notification

3. **Update Status:**
   - Log in as officer
   - Change concern status
   - Check citizen receives notification

4. **Check Logs:**
   - Flutter console: Look for `📤 Sending push notification...`
   - Firebase console: Check Cloud Functions logs

---

## 🔐 Permission Requirements

### **On First App Launch:**

```
APP LAUNCH → ONBOARDING → PERMISSION REQUEST SCREEN
```

**Two Permissions Requested:**

1. **📱 Notification Permission**
   - **Why:** Receive real-time concern updates
   - **When:** Status changes, new comments, assignments
   - **Required:** Highly recommended

2. **📁 Storage Permission**
   - **Why:** Upload photos and documents as evidence
   - **When:** Raising concerns, adding evidence
   - **Required:** For file uploads only

**User Can:**
- ✅ Grant all permissions (recommended)
- ⏭️ Skip (can enable later in Settings)
- 🔄 Re-request if denied

---

## 📊 Key Metrics & KPIs

### **Concern Management:**
- Total concerns submitted
- Average resolution time
- Resolution rate by category
- Officer response time
- Citizen satisfaction score

### **Notification Performance:**
- Push notification delivery rate
- Notification open rate
- Time to first read
- FCM token validation rate

### **AI Performance:**
- Sentiment accuracy
- Priority prediction accuracy
- Duplicate detection rate
- Pattern detection success

---

## 🐛 Troubleshooting

### **Issue: Notifications Not Received**

**Check:**
1. ✅ Permission granted? (Settings → Notifications)
2. ✅ FCM token saved? (Firestore `users` collection)
3. ✅ Cloud Functions deployed? (Firebase console)
4. ✅ Internet connection active?
5. ✅ App in background or foreground?

**Solution:**
- Re-request permissions
- Re-initialize NotificationService
- Check Firebase logs for errors
- Verify FCM token is valid

### **Issue: Duplicate Notifications**

**Cause:**
- Multiple FCM tokens for same user
- Cloud Function called multiple times

**Solution:**
- Clear old FCM tokens
- Add idempotency checks in Cloud Functions
- Use transaction locks in Firestore

---

## 🎯 Best Practices

### **For Citizens:**
1. ✅ Provide detailed descriptions
2. ✅ Upload clear evidence (photos/docs)
3. ✅ Check notifications regularly
4. ✅ Respond to officer questions promptly
5. ✅ Provide feedback after resolution

### **For Officers:**
1. ✅ Review AI analysis before deciding
2. ✅ Use AI assistant for complex cases
3. ✅ Add detailed comments for transparency
4. ✅ Update status promptly
5. ✅ Provide resolution proof

### **For Developers:**
1. ✅ Deploy Cloud Functions before testing
2. ✅ Monitor Firestore read/write quotas
3. ✅ Use batch writes for bulk operations
4. ✅ Implement retry logic for FCM
5. ✅ Log all notification attempts

---

## 📚 Related Documentation

- 📄 `PUSH_NOTIFICATIONS_GUIDE.md` - Detailed push notification setup
- 📄 `NOTIFICATION_QUICK_START.md` - Quick deployment guide
- 📄 `GEMINI_USER_GUIDE.md` - AI features documentation
- 📄 `FIRESTORE_SCHEMA.md` - Database structure

---

## 🚀 Quick Commands

### **Deploy All Functions:**
```bash
cd firebase_functions
npm install
firebase deploy --only functions
```

### **Test Notifications:**
```bash
# Run the app
flutter run

# Check console for:
# ✅ FCM Token: ABC123...
# ✅ Notification permissions granted
# 📤 Sending push notification...
```

### **Debug Mode:**
```bash
# Enable verbose logging
flutter run --verbose
```

---

## ✅ Summary

The concern management workflow in CivicLense is a **complete, AI-powered, real-time system** that:

1. ✅ **Empowers citizens** to raise concerns easily
2. 🤖 **Uses AI (Google Gemini)** for intelligent analysis
3. 📱 **Sends push notifications** at every step
4. 👮 **Helps officers** manage concerns efficiently
5. 📊 **Tracks metrics** for continuous improvement
6. 🔐 **Requests permissions** on first launch
7. 🌐 **Works offline** with Firestore caching

**Result:** A transparent, efficient, and citizen-friendly corruption reporting system! 🎉

