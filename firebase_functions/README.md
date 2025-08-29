# Firebase Functions for Civic Lense

This directory contains Firebase Functions for the Civic Lense application.

## Functions

### deleteUser
Deletes a user from both Firebase Authentication and Firestore. Only admins can call this function.

## Setup Instructions

1. **Install Firebase CLI** (if not already installed):
   ```bash
   npm install -g firebase-tools
   ```

2. **Login to Firebase**:
   ```bash
   firebase login
   ```

3. **Initialize Firebase Functions** (if not already done):
   ```bash
   firebase init functions
   ```

4. **Install dependencies**:
   ```bash
   cd firebase_functions
   npm install
   ```

5. **Deploy the functions**:
   ```bash
   firebase deploy --only functions
   ```

## Security Rules

The `deleteUser` function includes the following security checks:
- Only authenticated users can call the function
- Only users with admin role can delete other users
- Admin users cannot be deleted
- The function verifies the user's role in Firestore before allowing deletion

## Testing

You can test the function locally using the Firebase emulator:
```bash
firebase emulators:start --only functions
```

## Error Handling

The function returns appropriate error messages for:
- Unauthenticated requests
- Missing user UID
- Non-admin users trying to delete users
- Attempts to delete admin users
- General deletion failures

## Usage in Flutter

The Flutter app calls this function using:
```dart
final functions = FirebaseFunctions.instance;
final callable = functions.httpsCallable('deleteUser');
final result = await callable.call({'uid': userUid});
```

