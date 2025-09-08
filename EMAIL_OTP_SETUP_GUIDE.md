# Email OTP Setup Guide

## Problem
Email OTP is not being sent to users during government user login/registration. The system is currently only printing OTP codes to the console.

## Root Cause
1. **Firebase Functions not configured with email credentials**
2. **Email service using console output instead of actual email sending**
3. **Missing email service configuration**

## Solution Steps

### Step 1: Configure Firebase Functions Email Service

1. **Set up Gmail App Password** (Recommended):
   ```bash
   # Navigate to Firebase Functions directory
   cd firebase_functions
   
   # Set Gmail credentials
   firebase functions:config:set gmail.email="your-email@gmail.com" gmail.password="your-app-password"
   ```

2. **Alternative: Use SendGrid**:
   ```bash
   firebase functions:config:set sendgrid.api_key="your-sendgrid-api-key"
   ```

3. **Deploy Firebase Functions**:
   ```bash
   firebase deploy --only functions
   ```

### Step 2: Gmail App Password Setup

1. Go to [Google Account Settings](https://myaccount.google.com/)
2. Navigate to **Security** → **2-Step Verification** (enable if not already)
3. Go to **App passwords**
4. Generate a new app password for "Mail"
5. Use this password in Firebase Functions config

### Step 3: Test Email Functionality

1. **Check Firebase Functions logs**:
   ```bash
   firebase functions:log
   ```

2. **Test the email function**:
   - Try logging in as a government user
   - Check console for OTP code (fallback)
   - Check your email inbox

### Step 4: Verify Configuration

The system will now:
1. ✅ Try to send email via Firebase Functions
2. ✅ Fall back to console output if email fails
3. ✅ Store OTP in Firestore for verification

## Current Status

- ✅ **Fixed**: Government auth service now calls Firebase Functions
- ✅ **Fixed**: Added proper error handling and fallback
- ⚠️ **Pending**: Configure Firebase Functions with email credentials
- ⚠️ **Pending**: Deploy Firebase Functions

## Testing

After setup, test the flow:
1. Login as government user
2. Check email for OTP
3. If email doesn't arrive, check console for OTP code
4. Use OTP to complete verification

## Troubleshooting

### Email not received:
1. Check spam folder
2. Verify Gmail app password is correct
3. Check Firebase Functions logs: `firebase functions:log`
4. Ensure Firebase Functions are deployed

### Firebase Functions errors:
1. Verify email credentials are set correctly
2. Check Firebase project configuration
3. Ensure proper permissions for the service account

## Next Steps

1. **Configure email credentials** in Firebase Functions
2. **Deploy Firebase Functions** with email configuration
3. **Test end-to-end** email OTP functionality
4. **Monitor logs** for any issues

---

**Note**: The system now has proper fallback to console output, so you can still test OTP functionality even if email is not configured yet.
