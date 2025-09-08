# 🔥 Firebase Functions Setup for Email Sending

## Quick Setup Guide

### Step 1: Install Firebase CLI
```bash
npm install -g firebase-tools
```

### Step 2: Login to Firebase
```bash
firebase login
```

### Step 3: Initialize Functions (if not done)
```bash
cd firebase_functions
firebase init functions
```

### Step 4: Configure Gmail Credentials
```bash
firebase functions:config:set gmail.email="your-email@gmail.com" gmail.password="your-app-password"
```

**Note:** For Gmail, you need to:
1. Enable 2-factor authentication
2. Generate an App Password (not your regular password)
3. Use the App Password in the config

### Step 5: Deploy Functions
```bash
firebase deploy --only functions
```

### Step 6: Test
After deployment, your app will automatically use Firebase Functions for email sending!

## Alternative: Use Console Logging

If you don't want to set up Firebase Functions right now, the app will work perfectly with console logging. Just check the Flutter console for the OTP code.

## Troubleshooting

- **Gmail App Password**: Make sure you're using an App Password, not your regular Gmail password
- **Firebase Project**: Ensure you're logged into the correct Firebase project
- **Functions Region**: Make sure your functions are deployed to the correct region

## Current Status

✅ **OTP Generation** - Working  
✅ **OTP Verification** - Working  
✅ **Console Logging** - Working  
⏳ **Email Sending** - Needs Firebase Functions deployment
