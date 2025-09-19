# Firestore Database Schema

## Users Collection

The `users` collection stores user information with the following schema:

### Document Structure
```json
{
  "uid": "user_firebase_uid",
  "email": "user@example.com",
  "firstName": "John",
  "lastName": "Doe",
  "role": "journalist|ngo|contractor|researcher|activist|citizen|admin",
  "status": "pending|approved|rejected",
  "documents": [
    "https://firebasestorage.googleapis.com/.../document1.pdf",
    "https://firebasestorage.googleapis.com/.../document2.jpg"
  ],
  "uploadedAt": "2024-01-15T10:30:00Z",
  "approvedAt": "2024-01-16T14:20:00Z",
  "approvedBy": "admin_user_id",
  "rejectedAt": "2024-01-16T14:20:00Z",
  "rejectedBy": "admin_user_id",
  "fcmToken": "fcm_token_for_push_notifications",
  "tokenUpdatedAt": "2024-01-15T10:30:00Z",
  "createdAt": "2024-01-15T10:30:00Z",
  "updatedAt": "2024-01-16T14:20:00Z"
}
```

### Field Descriptions

#### Required Fields
- `uid`: Firebase Auth user ID
- `email`: User's email address
- `role`: User's role in the system
- `status`: Approval status (`pending`, `approved`, `rejected`)

#### Optional Fields
- `firstName`, `lastName`: User's name
- `documents`: Array of uploaded document URLs
- `uploadedAt`: Timestamp when documents were uploaded
- `approvedAt`: Timestamp when account was approved
- `approvedBy`: ID of admin who approved the account
- `rejectedAt`: Timestamp when account was rejected
- `rejectedBy`: ID of admin who rejected the account
- `fcmToken`: Firebase Cloud Messaging token for push notifications
- `tokenUpdatedAt`: When FCM token was last updated
- `createdAt`: Account creation timestamp
- `updatedAt`: Last update timestamp

### Role-Based Document Requirements

#### Journalist
- Press Card
- Journalist ID
- Media Organization Letter

#### NGO
- NGO Registration Certificate
- Organization Letter
- Tax Exemption Certificate

#### Contractor
- Business License
- Tax Registration
- Insurance Certificate

#### Researcher
- University ID
- Research Organization Letter
- Academic Credentials

#### Activist
- Community Organization Letter
- Reference Letter
- Membership Certificate

#### Citizen
- No document requirements

#### Admin
- No document requirements (system-generated)

### Status Flow

1. **User Registration**: `status: "pending"`
2. **Document Upload**: Documents stored in Firebase Storage
3. **Admin Review**: Admin can approve or reject
4. **Approval**: `status: "approved"` + push notification sent
5. **Rejection**: `status: "rejected"` + push notification sent

### Firebase Storage Structure

```
/user_docs/
  /{userId}/
    /{timestamp}_{index}.{extension}
    /{timestamp}_{index}.{extension}
    ...
```

Example:
```
/user_docs/
  /abc123def456/
    /1705312200000_0.pdf
    /1705312200000_1.jpg
    /1705312200000_2.png
```

### Security Rules

```javascript
// Firestore Security Rules
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Users can read their own data
    match /users/{userId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }
    
    // Admins can read all user data
    match /users/{userId} {
      allow read: if request.auth != null && 
        get(/databases/$(database)/documents/users/$(request.auth.uid)).data.role == 'admin';
    }
  }
}
```

```javascript
// Firebase Storage Security Rules
rules_version = '2';
service firebase.storage {
  match /b/{bucket}/o {
    match /user_docs/{userId}/{allPaths=**} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }
  }
}
```

### Example Queries

#### Get all pending users
```javascript
db.collection('users')
  .where('status', '==', 'pending')
  .orderBy('uploadedAt', 'desc')
  .get()
```

#### Get user by role
```javascript
db.collection('users')
  .where('role', '==', 'journalist')
  .where('status', '==', 'approved')
  .get()
```

#### Get user documents
```javascript
db.collection('users')
  .doc(userId)
  .get()
  .then(doc => {
    const documents = doc.data().documents;
    // Process documents array
  })
```

### Push Notification Payload

#### Approval Notification
```json
{
  "title": "Account Approved",
  "body": "Your account has been approved. You can now access your role features.",
  "data": {
    "type": "approval",
    "role": "journalist",
    "userId": "user_id"
  }
}
```

#### Rejection Notification
```json
{
  "title": "Account Review Complete",
  "body": "Your account application has been reviewed. Please contact support for more information.",
  "data": {
    "type": "rejection",
    "userId": "user_id"
  }
}
```
