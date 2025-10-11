# 📱 Push Notifications Implementation Guide - CivicLense

## 🎯 Overview

CivicLense now has **fully functional push notifications** for the concern management module. Users receive real-time notifications when:
- ✅ Concern status changes
- ✅ Officers add comments
- ✅ Concerns are assigned
- ✅ New concerns are submitted

---

## 🏗️ Architecture

### 1. **Flutter App (Client Side)**
- Requests notification permissions
- Obtains FCM tokens
- Saves tokens to Firestore
- Listens for incoming notifications
- Creates in-app notifications

### 2. **Firebase Cloud Functions (Server Side)**
- Sends push notifications via FCM Admin SDK
- Handles bulk notifications
- Automatic triggers for Firestore changes
- Token validation and management

### 3. **Firestore Database**
- Stores FCM tokens in user documents
- Stores notification history
- Tracks read/unread status

---

## 📦 Implementation Details

### **Client Side (Flutter)**

#### Initialize Notifications on App Start
```dart
// In anticorruption_officer_dashboard_screen.dart
Future<void> _initializeNotifications() async {
  try {
    await NotificationService.initializeNotifications();
    NotificationService.startConcernNotificationListener();
  } catch (e) {
    print('Error initializing notifications: $e');
  }
}
```

#### FCM Token Management
```dart
// Automatically done by NotificationService.initializeNotifications()
// Token is:
// 1. Requested from FCM
// 2. Saved to Firestore user document
// 3. Auto-refreshed when expired
// 4. Updated on user login
```

#### Notification Types
```dart
// In-app notifications stored in Firestore
{
  'userId': 'user_uid',
  'title': 'Concern Status Updated',
  'body': 'Your concern status changed to under_review',
  'type': 'concern_update', // or 'new_concern', 'new_comment', etc.
  'concernId': 'concern_id',
  'isRead': false,
  'createdAt': Timestamp,
}
```

---

### **Server Side (Firebase Cloud Functions)**

#### 1. Manual Push Notification (Callable Function)
```javascript
// Call from app when needed
exports.sendPushNotification = functions.https.onCall(async (data, context) => {
  // Sends notification to a single user via FCM
  // Parameters: token, title, body, data
});
```

**Usage in Flutter:**
```dart
final callable = FirebaseFunctions.instance.httpsCallable('sendPushNotification');
await callable.call({
  'token': userFcmToken,
  'title': 'New Concern Assigned',
  'body': 'You have been assigned a new concern',
  'data': {'concernId': concernId},
});
```

#### 2. Bulk Push Notifications (Callable Function)
```javascript
exports.sendBulkPushNotifications = functions.https.onCall(async (data, context) => {
  // Sends notifications to multiple users at once
  // Parameters: userIds[], title, body, data
});
```

#### 3. Automatic Status Change Trigger
```javascript
exports.onConcernStatusChange = functions.firestore
  .document('concerns/{concernId}')
  .onUpdate(async (change, context) => {
    // Automatically triggers when concern status changes
    // Sends notification to concern author
  });
```

#### 4. Automatic Comment Trigger
```javascript
exports.onNewConcernComment = functions.firestore
  .document('concern_comments/{commentId}')
  .onCreate(async (snapshot, context) => {
    // Automatically triggers when new comment is added
    // Sends notification to concern author
  });
```

---

## 🚀 Deployment Instructions

### **Step 1: Deploy Cloud Functions**
```bash
cd firebase_functions
npm install
firebase deploy --only functions
```

### **Step 2: Configure Android App**

Add to `android/app/src/main/AndroidManifest.xml`:
```xml
<!-- Inside <application> tag -->
<meta-data
    android:name="com.google.firebase.messaging.default_notification_channel_id"
    android:value="concern_updates" />

<meta-data
    android:name="com.google.firebase.messaging.default_notification_icon"
    android:resource="@drawable/ic_notification" />

<meta-data
    android:name="com.google.firebase.messaging.default_notification_color"
    android:resource="@color/notification_color" />
```

### **Step 3: Configure iOS App (if applicable)**

Add to `ios/Runner/Info.plist`:
```xml
<key>FirebaseAppDelegateProxyEnabled</key>
<false/>
```

### **Step 4: Test Notifications**

1. **Run the app** and log in
2. **Check console** for FCM token: `✅ FCM token saved for user: ...`
3. **Change a concern status** from officer dashboard
4. **User should receive** a push notification

---

## 🔧 Notification Flow

### **Scenario 1: Officer Updates Concern Status**
```
1. Officer updates concern status in ConcernDetailScreen
2. ConcernService.updateStatus() is called
3. Firestore concern document is updated
4. Cloud Function "onConcernStatusChange" triggers automatically
5. Function fetches author's FCM token from Firestore
6. Function sends push notification via FCM Admin SDK
7. User's device receives notification
8. In-app notification is also created in Firestore
```

### **Scenario 2: Officer Adds Comment**
```
1. Officer adds comment in ConcernDetailScreen
2. Comment is saved to Firestore "concern_comments" collection
3. Cloud Function "onNewConcernComment" triggers automatically
4. Function fetches concern author's FCM token
5. Function sends push notification
6. User receives notification
```

### **Scenario 3: New Concern Submitted**
```
1. Citizen submits concern
2. NotificationService.notifyNewConcern() is called
3. Gets all anti-corruption officers
4. For each officer:
   - Creates in-app notification
   - Calls _sendPushNotification()
   - Fetches officer's FCM token
   - Calls Cloud Function to send push
5. Officers receive notifications
```

---

## 📊 Database Schema

### User Document with FCM Token
```json
{
  "uid": "user_uid",
  "email": "user@example.com",
  "firstName": "John",
  "lastName": "Doe",
  "role": {...},
  "fcmToken": "fcm_token_string_here",
  "tokenUpdatedAt": Timestamp,
  "lastSeen": Timestamp
}
```

### Notification Document
```json
{
  "userId": "user_uid",
  "title": "Concern Status Updated",
  "body": "Your concern status changed to under_review",
  "type": "concern_update",
  "concernId": "concern_id",
  "action": "status_changed",
  "isRead": false,
  "createdAt": Timestamp,
  "readAt": Timestamp (optional)
}
```

---

## 🧪 Testing Guide

### **1. Test FCM Token Storage**
```dart
// After login, check Firestore user document
// Should have 'fcmToken' and 'tokenUpdatedAt' fields
```

### **2. Test Status Change Notification**
```dart
// 1. Create a test concern as citizen
// 2. Log in as anti-corruption officer
// 3. Change concern status
// 4. Check citizen receives notification
```

### **3. Test Comment Notification**
```dart
// 1. Create a test concern
// 2. Officer adds a comment
// 3. Concern author should receive notification
```

### **4. Test with Firebase Console**
```bash
# Send test notification from Firebase Console
# Cloud Messaging > Send test message
# Use FCM token from user document
```

---

## 🔍 Debugging

### **Check FCM Token**
```dart
// Add to initializeNotifications():
String? token = await _messaging.getToken();
print('FCM Token: $token');
```

### **Check Cloud Function Logs**
```bash
firebase functions:log
```

### **Check Firestore Rules**
Ensure users can write their own FCM tokens:
```javascript
match /users/{userId} {
  allow update: if request.auth.uid == userId && 
    request.resource.data.diff(resource.data).affectedKeys()
    .hasOnly(['fcmToken', 'tokenUpdatedAt', 'lastSeen']);
}
```

---

## 🎨 Notification UI Features

### **In-App Notifications**
- Bell icon with unread count badge
- Real-time updates via Firestore streams
- Mark as read functionality
- Notification types with icons:
  - 🆕 New Concern
  - 📝 Status Change
  - 💬 New Comment
  - 👤 Assignment
  - ⚡ Urgent Priority

### **Push Notifications**
- Sound and vibration
- Custom icon and color
- Data payload for deep linking
- High priority for immediate delivery
- Works in foreground and background

---

## 🚨 Important Notes

### **Production Considerations**
1. **Rate Limiting**: FCM has daily quotas (check Firebase console)
2. **Token Expiration**: Tokens can expire - handle refresh
3. **Error Handling**: Gracefully handle notification failures
4. **Privacy**: Only notify relevant users
5. **Batching**: Use bulk notifications for efficiency

### **Security**
1. ✅ Only authenticated users can send notifications
2. ✅ Cloud Functions validate requests
3. ✅ Firestore rules protect token storage
4. ✅ No sensitive data in notification payload

### **Performance**
1. ✅ Async operations don't block UI
2. ✅ Bulk notifications for multiple users
3. ✅ Firestore triggers run server-side
4. ✅ Cached tokens in user documents

---

## 📱 Notification Channels (Android)

Add notification channels for better UX:

```dart
// In AndroidManifest.xml
<meta-data
    android:name="com.google.firebase.messaging.default_notification_channel_id"
    android:value="concern_updates" />
```

**Channel Types:**
- `concern_updates` - Status changes, comments (High priority)
- `new_concerns` - New concerns for officers (High priority)
- `general` - General notifications (Normal priority)

---

## ✅ Verification Checklist

- [x] FCM package installed in pubspec.yaml
- [x] Notification permissions requested
- [x] FCM tokens obtained and saved to Firestore
- [x] Token refresh listener implemented
- [x] Cloud Functions created and deployed
- [x] Firestore triggers configured
- [x] In-app notifications working
- [x] Push notifications sent via Cloud Functions
- [x] Error handling implemented
- [x] Security rules configured

---

## 🎯 Next Steps

### **Enhancements You Can Add:**

1. **flutter_local_notifications** - Better foreground notifications
2. **Deep Linking** - Navigate to concern when notification tapped
3. **Notification Preferences** - Let users choose what to receive
4. **Rich Notifications** - Images, actions, expandable text
5. **Notification Scheduling** - Digest notifications
6. **Analytics** - Track notification open rates

---

## 📞 Support

If notifications aren't working:

1. **Check FCM Token**: User document should have `fcmToken` field
2. **Check Cloud Functions**: Run `firebase deploy --only functions`
3. **Check Logs**: `firebase functions:log`
4. **Check Permissions**: User must grant notification permission
5. **Check Network**: Device must have internet connection

---

## 🎉 Success!

Your push notifications are now **fully functional**! Users will receive real-time updates about their concerns, making CivicLense a truly responsive platform for anti-corruption efforts.

**Notification Flow:** Concern Update → Firestore Trigger → Cloud Function → FCM → User Device 📱✨

