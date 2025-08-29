# Civic Lense - Public Spending Tracker

A Flutter application for tracking public spending with transparency and community engagement features.

## Features

### Authentication & Onboarding
- **3 Onboarding Screens**: Introduction to app features
- **User Registration**: Email/password signup with role selection
- **Email Verification**: Secure email verification system
- **Login System**: Email/password authentication with "Remember Me" option
- **Role-based Access**: Different user roles with specific dashboards

### User Roles
1. **Citizen/Taxpayer**: Track public spending and raise concerns
2. **Journalist/Media User**: Publish reports and access media resources
3. **Community Leader/Activist**: Lead communities and organize initiatives
4. **Researcher/Academic User**: Access research data and generate reports
5. **NGO/Private Contractor**: Manage projects and access contractor tools

### Technology Stack
- **Frontend**: Flutter
- **Backend**: Firebase
- **Authentication**: Firebase Auth
- **Database**: Cloud Firestore
- **Storage**: Shared Preferences (for local data)

## Setup Instructions

### Prerequisites
- Flutter SDK (3.8.1 or higher)
- Dart SDK
- Android Studio / VS Code
- Firebase project

### Firebase Setup

1. **Create Firebase Project**
   - Go to [Firebase Console](https://console.firebase.google.com/)
   - Create a new project
   - Enable Authentication with Email/Password
   - Create a Firestore database

2. **Configure Firebase for Flutter**
   - Add your Android app to Firebase project
   - Download `google-services.json` and place it in `android/app/`
   - Add your iOS app to Firebase project (if needed)
   - Download `GoogleService-Info.plist` and place it in `ios/Runner/`

3. **Update Android Configuration**
   - Add the following to `android/app/build.gradle.kts`:
   ```kotlin
   plugins {
       id("com.android.application")
       id("kotlin-android")
       id("com.google.gms.google-services")  // Add this line
   }
   ```

   - Add the following to `android/build.gradle.kts`:
   ```kotlin
   dependencies {
       classpath("com.google.gms:google-services:4.4.0")
   }
   ```

### Installation

1. **Clone the repository**
   ```bash
   git clone <repository-url>
   cd civic_lense
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Run the application**
   ```bash
   flutter run
   ```

## Project Structure

```
lib/
├── main.dart                 # App entry point
├── models/
│   └── user_role.dart        # User role model
├── screens/
│   ├── onboarding_screen.dart    # Onboarding screens
│   ├── login_screen.dart         # Login screen
│   ├── signup_screen.dart        # Registration screen
│   ├── email_verification_screen.dart  # Email verification
│   └── dashboard_screen.dart     # Role-based dashboard
├── services/
│   └── auth_service.dart     # Authentication service
└── widgets/
    ├── custom_button.dart    # Reusable button widget
    └── custom_text_field.dart # Reusable text field widget
```

## Data Flow

1. **App Launch**: User sees onboarding screens (first time) or login screen
2. **Registration**: User fills form with personal details and selects role
3. **Email Verification**: User receives verification email and must verify
4. **Login**: Verified users can login with email/password
5. **Dashboard**: Users see role-specific dashboard based on their selected role

## Firebase Collections

### Users Collection
```json
{
  "uid": {
    "email": "user@example.com",
    "firstName": "John",
    "lastName": "Doe",
    "role": {
      "id": "citizen",
      "name": "Citizen/Taxpayer",
      "description": "Track public spending and raise concerns",
      "color": 4280391411
    },
    "createdAt": "timestamp",
    "isActive": true,
    "emailVerified": false
  }
}
```

## Development Notes

- The app uses Firebase Authentication for user management
- User roles are stored in Firestore and determine dashboard access
- Email verification is required before users can access the app
- "Remember Me" functionality uses SharedPreferences for local storage
- Role-specific dashboards are placeholder implementations ready for future development

## Next Steps

1. **Firebase Configuration**: Complete Firebase setup with proper configuration files
2. **Role-specific Features**: Implement actual functionality for each user role
3. **Dashboard Development**: Create detailed dashboards for each user type
4. **Data Models**: Add models for budgets, tenders, projects, concerns, etc.
5. **UI/UX Enhancement**: Improve visual design and user experience

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test thoroughly
5. Submit a pull request

## License

This project is licensed under the MIT License.
