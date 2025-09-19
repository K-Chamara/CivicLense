# Government User Dual OTP Authentication Setup Guide

This guide will help you set up the dual OTP (Email + Mobile) authentication system for government users in your CivicLense Flutter app.

## 🔧 Prerequisites

1. **Firebase Project Setup**
   - Firebase project created
   - Authentication enabled
   - Firestore database enabled
   - Firebase Functions enabled

2. **Required Services**
   - Email service (Gmail, SendGrid, etc.)
   - Phone number verification (Firebase Auth Phone)

3. **Android Development Environment**
   - Android Studio installed
   - Flutter SDK installed
   - Android SDK configured
   - Physical Android device or emulator for testing

## 📱 Step 1: Firebase Console Configuration

### 1.1 Enable Authentication Methods

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Select your project
3. Navigate to **Authentication** → **Sign-in method**
4. Enable the following providers:
   - **Email/Password**: Enable
   - **Phone**: Enable and configure

### 1.2 Phone Authentication Setup

1. In **Authentication** → **Sign-in method** → **Phone**
2. Click **Enable**
3. Add your app's SHA-1 and SHA-256 fingerprints:

   **Windows:**
   ```bash
   # Run the provided script
   get_android_fingerprints.bat
   ```

   **macOS/Linux:**
   ```bash
   # Run the provided script
   ./get_android_fingerprints.sh
   ```

   **Manual method:**
   ```bash
   # For Android
   keytool -list -v -keystore ~/.android/debug.keystore -alias androiddebugkey -storepass android -keypass android
   ```

4. Copy the SHA-1 and SHA-256 keys to Firebase Console → Project Settings → Your apps → Add fingerprint

### 1.3 Firestore Security Rules

Update your Firestore rules to allow OTP storage:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Allow users to read/write their own data
    match /users/{userId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }
    
    // Allow OTP collection for verification
    match /email_otps/{otpId} {
      allow read, write: if request.auth != null;
    }
    
    // Allow temp collection for verification IDs
    match /temp/{tempId} {
      allow read, write: if request.auth != null;
    }
  }
}
```

## 📧 Step 2: Email Service Configuration

### 2.1 Gmail Setup (Recommended for Development)

1. **Enable 2-Factor Authentication** on your Gmail account
2. **Generate App Password**:
   - Go to Google Account settings
   - Security → 2-Step Verification → App passwords
   - Generate a new app password for "Mail"
3. **Configure Firebase Functions**:
   ```bash
   cd firebase_functions
   firebase functions:config:set email.user="your-email@gmail.com"
   firebase functions:config:set email.password="your-app-password"
   ```

### 2.2 Alternative Email Services

For production, consider using:
- **SendGrid**
- **Mailgun**
- **Amazon SES**

Update the transporter configuration in `firebase_functions/index.js`:

```javascript
const transporter = nodemailer.createTransporter({
  service: 'sendgrid', // or your preferred service
  auth: {
    user: 'apikey',
    pass: 'your-sendgrid-api-key'
  }
});
```

## 🚀 Step 3: Deploy Firebase Functions

1. **Install Dependencies**:
   ```bash
   cd firebase_functions
   npm install
   ```

2. **Deploy Functions**:
   ```bash
   firebase deploy --only functions
   ```

3. **Verify Deployment**:
   - Check Firebase Console → Functions
   - Ensure `sendEmailOtp` and `verifyEmailOtp` functions are deployed

## 📱 Step 4: Android Configuration

### 4.1 Android Dependencies

The following dependencies are already added to your `android/app/build.gradle.kts`:
```kotlin
dependencies {
    implementation(platform("com.google.firebase:firebase-bom:34.2.0"))
    implementation("com.google.firebase:firebase-auth")
    implementation("com.google.android.gms:play-services-auth:21.4.0")
}
```

### 4.2 Android Permissions

The following permissions are already added to your `android/app/src/main/AndroidManifest.xml`:
```xml
<uses-permission android:name="android.permission.INTERNET" />
<uses-permission android:name="android.permission.ACCESS_NETWORK_STATE" />
<uses-permission android:name="android.permission.RECEIVE_SMS" />
<uses-permission android:name="android.permission.READ_SMS" />
```

### 4.3 Minimum SDK Version

Your `minSdk` is set to 23 (required for Firebase Auth):
```kotlin
defaultConfig {
    minSdk = 23  // Required for Firebase Auth
    // ... other config
}
```

## 📱 Step 5: Flutter App Configuration

### 5.1 Update Dependencies

The following packages are already added to your `pubspec.yaml`:
```yaml
dependencies:
  firebase_core: ^3.15.2
  firebase_auth: ^5.3.1
  cloud_firestore: ^5.4.3
  firebase_functions: ^5.1.3
```

### 5.2 Run Flutter Commands

```bash
flutter pub get
flutter clean
flutter pub get
```

## 🔐 Step 6: Government User Roles

The system supports the following government roles:

1. **System Administrator** (1 user max)
   - Full system management
   - User administration
   - Role: `admin`

2. **Finance Officer** (1 user max)
   - Budget management
   - Financial oversight
   - Role: `finance_officer`

3. **Procurement Officer** (1 user max)
   - Tender management
   - Procurement oversight
   - Role: `procurement_officer`

4. **Anti-corruption Officer** (3 users max)
   - Concern management
   - Anti-corruption oversight
   - Role: `anticorruption_officer`

## 🎯 Step 7: Testing the System

### 7.1 Test Email OTP

1. Navigate to **Government User Registration**
2. Fill in the form with a valid email
3. Check your email for the 4-digit OTP
4. Verify the OTP is received and formatted correctly

### 7.2 Test Phone OTP

1. Use a valid phone number (with country code)
2. Ensure you receive the SMS with 6-digit code
3. Test the verification process

### 7.3 Test Complete Flow

1. **Registration Flow**:
   - Fill registration form
   - Receive email and phone OTPs
   - Enter both OTPs
   - Complete registration

2. **Login Flow**:
   - Enter credentials
   - Receive OTPs
   - Verify and login

## 🛠️ Step 8: Customization

### 8.1 Email Template Customization

Edit the email template in `firebase_functions/index.js`:

```javascript
const mailOptions = {
  from: 'your-email@domain.com',
  to: email,
  subject: 'Your Custom Subject',
  html: `
    <!-- Your custom HTML template -->
  `
};
```

### 8.2 OTP Expiration Time

Modify the expiration time in the Firebase Functions:

```javascript
// Change from 10 minutes to your preferred duration
expiresAt: new Date(Date.now() + 15 * 60 * 1000) // 15 minutes
```

### 8.3 UI Customization

The OTP verification screen can be customized in:
- `lib/screens/government_otp_verification_screen.dart`
- Colors, fonts, and layout can be modified
- Role-specific theming is already implemented

## 🔒 Step 9: Security Considerations

1. **OTP Storage**: OTPs are stored temporarily in Firestore with automatic expiration
2. **Rate Limiting**: Consider implementing rate limiting for OTP requests
3. **Email Security**: Use secure email services with proper authentication
4. **Phone Verification**: Firebase handles phone number verification securely
5. **User Data**: Government user data is stored with enhanced security flags

## 🐛 Step 10: Troubleshooting

### Common Issues

1. **Email OTP Not Received**:
   - Check spam folder
   - Verify email configuration
   - Check Firebase Functions logs

2. **Phone OTP Not Received**:
   - Verify phone number format (+country code)
   - Check Firebase Console for phone auth errors
   - Ensure SHA-1/SHA-256 keys are configured

3. **Firebase Functions Errors**:
   - Check function logs: `firebase functions:log`
   - Verify email service configuration
   - Ensure all dependencies are installed

4. **Flutter Build Errors**:
   - Run `flutter clean && flutter pub get`
   - Check for missing imports
   - Verify Firebase configuration files

### Debug Mode

Enable debug logging in your Flutter app:

```dart
// In main.dart
import 'package:firebase_core/firebase_core.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  
  // Enable debug mode
  FirebaseFirestore.instance.settings = const Settings(
    persistenceEnabled: true,
  );
  
  runApp(const MyApp());
}
```

## 📞 Support

For additional support:
1. Check Firebase documentation
2. Review Flutter Firebase plugin documentation
3. Check the app's error logs
4. Verify all configuration steps are completed

## 🎉 Success!

Once configured, government users will be able to:
- Register with dual OTP verification
- Login with enhanced security
- Access role-specific dashboards
- Enjoy a secure, government-grade authentication experience

The system provides enterprise-level security while maintaining a user-friendly interface for government officials.
