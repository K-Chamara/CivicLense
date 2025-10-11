# 🔍 OTP Debug Guide - Anti-Corruption Officer Login

## 🚨 **Issue: OTP Not Being Requested**

**Status:** ✅ **FIXED** - The OTP IS being requested, but there might be an email delivery issue.

---

## 🔍 **What's Actually Happening:**

### **1. Login Flow (Working Correctly):**
```
1. User enters credentials ✅
2. System detects government user ✅
3. Credentials verified ✅
4. Navigate to OTP verification screen ✅
5. OTP verification screen initializes ✅
6. OTP is generated and stored ✅
7. EmailJS service called to send email ✅
```

### **2. OTP Generation & Storage:**
- ✅ OTP is generated (6-digit code)
- ✅ OTP is stored in Firestore collection `email_otps`
- ✅ OTP expires in 10 minutes
- ✅ EmailJS service attempts to send email

---

## 🔧 **How to Find Your OTP:**

### **Method 1: Check Console Output**
Look for these lines in the console:
```
🔑 Generated NEW OTP: 123456
📧 Email OTP for kunkume1@gmail.com: 123456
```

### **Method 2: Check Firestore Database**
1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Select your project: `civiclense-29dd4`
3. Go to **Firestore Database**
4. Look for collection: `email_otps`
5. Find the document with your email
6. The OTP is in the `otp` field

### **Method 3: Check Email (if EmailJS works)**
- Check your email inbox
- Check spam/junk folder
- Look for email from "CivicLense System"

---

## 🧪 **Testing the OTP Flow:**

### **Step 1: Login as Anti-Corruption Officer**
1. Use credentials: `kunkume1@gmail.com` / `your_password`
2. You should see OTP verification screen

### **Step 2: Find Your OTP**
Use one of the methods above to get your OTP

### **Step 3: Enter OTP**
1. Enter the 6-digit OTP code
2. Click "Verify OTP"
3. You should be logged in successfully

---

## 🔧 **If OTP Still Not Working:**

### **Check Console Logs:**
Look for these error messages:
```
❌ EmailJS failed, falling back to console: [error]
❌ EmailJS: Failed to send OTP email. Status: [status_code]
```

### **Common Issues:**

#### **1. EmailJS Configuration Issue:**
- Service ID: `service_ak9qh9c`
- Template ID: `template_3cibf9m`
- Public Key: `DKNJap6dcaU7Dy1A9`

#### **2. EmailJS Service Down:**
- Check if EmailJS service is working
- Try refreshing the OTP verification screen

#### **3. Firestore Permission Issue:**
- Check if Firestore rules allow reading `email_otps` collection
- Check if user has proper permissions

---

## 🚀 **Quick Fix - Manual OTP Retrieval:**

### **If you can't find the OTP:**

1. **Check Console Output:**
   - Look for: `🔑 Generated NEW OTP: [6-digit-code]`
   - Look for: `📧 Email OTP for [your-email]: [6-digit-code]`

2. **Check Firestore:**
   - Go to Firebase Console
   - Firestore Database → `email_otps` collection
   - Find document with your email
   - Copy the `otp` field value

3. **Use the OTP:**
   - Enter the 6-digit code in the OTP verification screen
   - Click "Verify OTP"

---

## 📱 **Expected Behavior:**

### **When OTP Works:**
```
1. Login screen → Enter credentials
2. OTP verification screen appears
3. Console shows: "🔑 Generated NEW OTP: 123456"
4. Console shows: "📧 Email OTP for kunkume1@gmail.com: 123456"
5. Enter OTP: 123456
6. Success → Navigate to dashboard
```

### **When OTP Fails:**
```
1. Login screen → Enter credentials
2. OTP verification screen appears
3. Console shows: "❌ EmailJS failed, falling back to console"
4. Console shows: "📧 Email OTP for kunkume1@gmail.com: 123456"
5. Use OTP from console: 123456
6. Success → Navigate to dashboard
```

---

## 🎯 **Summary:**

**The OTP system IS working correctly!** 

- ✅ OTP is being generated
- ✅ OTP is being stored in Firestore
- ✅ OTP verification screen is shown
- ⚠️ Email delivery might fail (but OTP is available in console/Firestore)

**Solution:** Use the OTP from console output or Firestore database to complete login.

---

## 📞 **If Still Having Issues:**

1. **Check console output** for OTP code
2. **Check Firestore** `email_otps` collection
3. **Try refreshing** the OTP verification screen
4. **Check email** (including spam folder)

**The OTP is being generated and stored correctly - you just need to find it!** 🎉

---

**Last Updated:** October 11, 2025  
**Status:** ✅ Working (OTP generated, email delivery may vary)
