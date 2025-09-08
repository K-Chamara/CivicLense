# 📧 Email Setup Guide for Civic Lense

This guide will help you set up email sending for OTP verification using EmailJS.

## 🚀 Quick Setup with EmailJS (Recommended)

### Step 1: Create EmailJS Account
1. Go to [https://www.emailjs.com/](https://www.emailjs.com/)
2. Sign up for a free account
3. Verify your email address

### Step 2: Add Email Service
1. In EmailJS dashboard, go to **Email Services**
2. Click **Add New Service**
3. Choose your email provider:
   - **Gmail** (recommended for testing)
   - **Outlook**
   - **Yahoo**
   - Or any SMTP service
4. Follow the setup instructions for your chosen provider
5. Note down your **Service ID**

### Step 3: Create Email Template
1. Go to **Email Templates**
2. Click **Create New Template**
3. Use this template:

```html
Subject: Your Civic Lense OTP for {{user_role}} Verification

Dear {{user_role}} User,

Your One-Time Password (OTP) for Civic Lense verification is:

<h2 style="color: #007bff; font-size: 24px; text-align: center; margin: 20px 0;">{{otp_code}}</h2>

<p><strong>Important:</strong></p>
<ul>
  <li>This OTP is valid for {{expiry_time}}</li>
  <li>Do not share this code with anyone</li>
  <li>If you didn't request this, please ignore this email</li>
</ul>

<p>Thank you for using {{app_name}}!</p>

<p>Best regards,<br>
The {{app_name}} Team</p>
```

4. Save the template and note down your **Template ID**

### Step 4: Get User ID
1. Go to **Account** → **General**
2. Copy your **Public Key** (this is your User ID)

### Step 5: Update Your App
1. Open `lib/services/email_service.dart`
2. Replace the placeholder values:

```dart
static const String _serviceId = 'YOUR_ACTUAL_SERVICE_ID';
static const String _templateId = 'YOUR_ACTUAL_TEMPLATE_ID';
static const String _userId = 'YOUR_ACTUAL_USER_ID';
```

### Step 6: Test Email Sending
1. Hot restart your app
2. Try logging in as admin
3. Check your email for the OTP
4. Check console logs for confirmation

## 🔧 Alternative: Firebase Functions (Advanced)

If you prefer using Firebase Functions for email sending:

### Step 1: Install Firebase CLI
```bash
npm install -g firebase-tools
```

### Step 2: Initialize Functions
```bash
cd firebase_functions
npm install
```

### Step 3: Deploy Functions
```bash
firebase deploy --only functions
```

### Step 4: Update Service
Uncomment the Firebase Functions code in `government_auth_service.dart`

## 📱 Testing

After setup, you should see:
- ✅ `Email sent successfully via EmailJS` in console
- 📧 OTP email in your inbox
- 🔍 OTP verification working

## 🆘 Troubleshooting

### EmailJS Issues:
- Check your service ID, template ID, and user ID
- Verify your email service is active
- Check EmailJS dashboard for error logs

### Gmail Setup:
- Enable 2-factor authentication
- Generate an App Password
- Use the App Password in EmailJS setup

### Still Not Working:
- Check console logs for specific error messages
- Verify internet connection
- Try with a different email provider

## 💡 Pro Tips

1. **Free Tier Limits**: EmailJS free tier allows 200 emails/month
2. **Rate Limiting**: Don't spam the resend button
3. **Testing**: Use your own email for testing
4. **Production**: Consider upgrading to paid plan for production use

## 🎯 Next Steps

Once email is working:
1. Test with different user roles
2. Customize email templates
3. Add email delivery tracking
4. Set up email analytics

---

**Need Help?** Check the EmailJS documentation or create an issue in the project repository.
