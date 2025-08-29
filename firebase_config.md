# Firebase Configuration Guide

## Step 1: Create Firebase Project

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Click "Create a project"
3. Enter project name: "Civic Lense"
4. Enable Google Analytics (optional)
5. Click "Create project"

## Step 2: Enable Authentication

1. In Firebase Console, go to "Authentication"
2. Click "Get started"
3. Go to "Sign-in method" tab
4. Enable "Email/Password" provider
5. Click "Save"

## Step 3: Create Firestore Database

1. In Firebase Console, go to "Firestore Database"
2. Click "Create database"
3. Choose "Start in test mode" (for development)
4. Select a location close to your users
5. Click "Done"

## Step 4: Add Android App

1. In Firebase Console, click the gear icon → "Project settings"
2. Scroll down to "Your apps" section
3. Click "Add app" → Android icon
4. Enter Android package name: `com.example.civic_lense`
5. Enter app nickname: "Civic Lense Android"
6. Click "Register app"
7. Download `google-services.json`
8. Place `google-services.json` in `android/app/` directory

## Step 5: Update Android Configuration

### Update `android/app/build.gradle.kts`:
```kotlin
plugins {
    id("com.android.application")
    id("kotlin-android")
    id("com.google.gms.google-services")  // Add this line
}

android {
    // ... existing configuration
}

dependencies {
    // ... existing dependencies
    implementation(platform("com.google.firebase:firebase-bom:32.7.0"))
    implementation("com.google.firebase:firebase-analytics")
}
```

### Update `android/build.gradle.kts`:
```kotlin
buildscript {
    dependencies {
        // ... existing dependencies
        classpath("com.google.gms:google-services:4.4.0")
    }
}
```

## Step 6: Add iOS App (Optional)

1. In Firebase Console, click "Add app" → iOS icon
2. Enter iOS bundle ID: `com.example.civicLense`
3. Enter app nickname: "Civic Lense iOS"
4. Click "Register app"
5. Download `GoogleService-Info.plist`
6. Place `GoogleService-Info.plist` in `ios/Runner/` directory

## Step 7: Test Configuration

1. Run `flutter pub get`
2. Run `flutter run`
3. Test registration and login functionality

## Security Rules (Firestore)

Add these security rules to your Firestore database:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Users can read and write their own data
    match /users/{userId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }
    
    // Public data (to be added later)
    match /budgets/{document=**} {
      allow read: if true;
      allow write: if request.auth != null;
    }
    
    match /tenders/{document=**} {
      allow read: if true;
      allow write: if request.auth != null;
    }
    
    match /concerns/{document=**} {
      allow read: if true;
      allow write: if request.auth != null;
    }
  }
}
```

## Environment Variables (Optional)

For production, consider using environment variables:

1. Create `.env` file in project root:
```
FIREBASE_API_KEY=your_api_key
FIREBASE_PROJECT_ID=your_project_id
FIREBASE_MESSAGING_SENDER_ID=your_sender_id
FIREBASE_APP_ID=your_app_id
```

2. Add `flutter_dotenv` dependency to `pubspec.yaml`:
```yaml
dependencies:
  flutter_dotenv: ^5.1.0
```

3. Load environment variables in `main.dart`:
```dart
import 'package:flutter_dotenv/flutter_dotenv.dart';

void main() async {
  await dotenv.load(fileName: ".env");
  // ... rest of initialization
}
```

## Troubleshooting

### Common Issues:

1. **"No Firebase App '[DEFAULT]' has been created"**
   - Ensure `google-services.json` is in the correct location
   - Check that Firebase is properly initialized in `main.dart`

2. **"Permission denied" errors**
   - Check Firestore security rules
   - Ensure user is authenticated before accessing data

3. **"Email not verified" errors**
   - Check that email verification is enabled in Firebase Console
   - Ensure verification emails are being sent

4. **Build errors**
   - Run `flutter clean` and `flutter pub get`
   - Check that all dependencies are properly installed

## Next Steps

After completing Firebase setup:

1. Test user registration and login
2. Verify email verification works
3. Test role-based dashboard access
4. Implement actual features for each user role
5. Add proper error handling and validation



