# EmailJS Setup Guide for CivicLense

## Overview
EmailJS allows you to send emails directly from your Flutter app without needing a backend server. It's completely free and works client-side.

## Step 1: Create EmailJS Account

1. **Go to EmailJS website:** https://www.emailjs.com/
2. **Sign up for a free account** (no credit card required)
3. **Verify your email address**

## Step 2: Add Email Service

1. **Go to Email Services** in your EmailJS dashboard
2. **Click "Add New Service"**
3. **Choose Gmail** (or your preferred email provider)
4. **Connect your Gmail account:**
   - Use your Gmail: `wvadkchamara@gmail.com`
   - Use your App Password: `vaeeoffpulcufdht`
5. **Save the Service ID** (you'll need this)

## Step 3: Create Email Template

1. **Go to Email Templates** in your EmailJS dashboard
2. **Click "Create New Template"**
3. **Use this template:**

```
Subject: CivicLense OTP Verification - {{user_role}}

Hello,

You are logging in as a {{user_role}} in CivicLense.

Your One-Time Password (OTP) is: {{otp_code}}

This code will expire in 10 minutes.

If you did not request this code, please ignore this email.

Best regards,
CivicLense Team
```

4. **Save the Template ID** (you'll need this)

## Step 4: Get Your Keys

1. **Go to Account** → **General**
2. **Copy your Public Key** (you'll need this)

## Step 5: Update Your Flutter App

1. **Open:** `lib/services/emailjs_service.dart`
2. **Replace the placeholder values:**

```dart
static const String _serviceId = 'YOUR_SERVICE_ID'; // Replace with your Service ID
static const String _templateId = 'YOUR_TEMPLATE_ID'; // Replace with your Template ID  
static const String _publicKey = 'YOUR_PUBLIC_KEY'; // Replace with your Public Key
```

## Step 6: Test the Setup

1. **Run your Flutter app**
2. **Try logging in as a government user**
3. **Check your email for the OTP**
4. **If email doesn't arrive, check console for fallback OTP**

## Current Status

✅ **EmailJS package installed**
✅ **Service created and configured**
✅ **Government auth service updated**
⏳ **Waiting for your EmailJS credentials**

## Free Limits

- **200 emails per month** (free tier)
- **No credit card required**
- **Perfect for development and small apps**

## Troubleshooting

### Email not received:
1. Check spam folder
2. Verify EmailJS service is connected to Gmail
3. Check console for fallback OTP
4. Verify template variables match the code

### EmailJS errors:
1. Check your Service ID, Template ID, and Public Key
2. Ensure Gmail App Password is correct
3. Verify template variables are properly set

## Next Steps

1. **Set up EmailJS account** (5 minutes)
2. **Get your credentials** (Service ID, Template ID, Public Key)
3. **Update the service file** with your credentials
4. **Test email sending**

---

**Note:** The system has fallback to console output, so you can test OTP functionality even before configuring EmailJS.
