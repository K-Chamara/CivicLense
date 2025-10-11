const functions = require('firebase-functions');
const admin = require('firebase-admin');
const nodemailer = require('nodemailer');

// Import auto-prioritization functions
const { autoPrioritizeConcerns } = require('./huggingface_sentiment');

// Initialize Firebase Admin SDK
admin.initializeApp();

// Configure email transporter
const transporter = nodemailer.createTransporter({
  service: 'gmail', // You can change this to your preferred email service
  auth: {
    user: functions.config().email?.user || 'your-email@gmail.com',
    pass: functions.config().email?.password || 'your-app-password'
  }
});

exports.deleteUser = functions.https.onCall(async (data, context) => {
  try {
    // Check if the request is authenticated
    if (!context.auth) {
      throw new functions.https.HttpsError('unauthenticated', 'User must be authenticated');
    }

    const { uid } = data;
    
    if (!uid) {
      throw new functions.https.HttpsError('invalid-argument', 'User UID is required');
    }

    // Verify that the current user is an admin
    const adminUserDoc = await admin.firestore().collection('users').doc(context.auth.uid).get();
    if (!adminUserDoc.exists) {
      throw new functions.https.HttpsError('permission-denied', 'Admin user not found');
    }

    const adminUserData = adminUserDoc.data();
    if (adminUserData.role?.userType !== 'admin') {
      throw new functions.https.HttpsError('permission-denied', 'Only admins can delete users');
    }

    // Check if the user to be deleted is an admin
    const userToDeleteDoc = await admin.firestore().collection('users').doc(uid).get();
    if (userToDeleteDoc.exists) {
      const userToDeleteData = userToDeleteDoc.data();
      if (userToDeleteData.role?.userType === 'admin') {
        throw new functions.https.HttpsError('permission-denied', 'Cannot delete admin users');
      }
    }

    // Delete the user from Firebase Auth
    await admin.auth().deleteUser(uid);
    console.log(`User ${uid} deleted from Firebase Auth`);

    // Delete the user document from Firestore
    await admin.firestore().collection('users').doc(uid).delete();
    console.log(`User ${uid} deleted from Firestore`);

    return { success: true, message: 'User deleted successfully' };
  } catch (error) {
    console.error('Error deleting user:', error);
    throw new functions.https.HttpsError('internal', 'Failed to delete user: ' + error.message);
  }
});

exports.createGovernmentUser = functions.https.onCall(async (data, context) => {
  try {
    // Check if the request is authenticated
    if (!context.auth) {
      throw new functions.https.HttpsError('unauthenticated', 'User must be authenticated');
    }

    const { email, firstName, lastName, phoneNumber, role } = data;
    
    if (!email || !firstName || !lastName || !phoneNumber || !role) {
      throw new functions.https.HttpsError('invalid-argument', 'Email, firstName, lastName, phoneNumber, and role are required');
    }

    // Verify that the current user is an admin
    const adminUserDoc = await admin.firestore().collection('users').doc(context.auth.uid).get();
    if (!adminUserDoc.exists) {
      throw new functions.https.HttpsError('permission-denied', 'Admin user not found');
    }

    const adminUserData = adminUserDoc.data();
    if (adminUserData.role?.userType !== 'admin') {
      throw new functions.https.HttpsError('permission-denied', 'Only admins can create government users');
    }

    // Check if role limit is reached
    const existingUsers = await admin.firestore()
      .collection('users')
      .where('role.id', '==', role.id)
      .get();
    
    if (role.maxAllowed > 0 && existingUsers.size >= role.maxAllowed) {
      throw new functions.https.HttpsError('resource-exhausted', `Maximum number of ${role.name} users (${role.maxAllowed}) already exists.`);
    }

    // Generate username and password
    const username = generateUsername(firstName, lastName);
    const password = generatePassword();

    // Create user in Firebase Auth using Admin SDK
    const userRecord = await admin.auth().createUser({
      email: email,
      password: password,
      displayName: `${firstName} ${lastName}`,
    });

    console.log(`Created Firebase Auth user: ${userRecord.uid}`);

    // Create user document in Firestore
    await admin.firestore().collection('users').doc(userRecord.uid).set({
      email: email,
      firstName: firstName,
      lastName: lastName,
      phoneNumber: phoneNumber,
      username: username,
      role: role,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
      isActive: true,
      emailVerified: false,
      phoneVerified: false,
      isGovernmentUser: true,
      securityLevel: 'high',
      otpEnabled: true,
      createdBy: context.auth.uid,
    });

    console.log(`Created Firestore document for user: ${userRecord.uid}`);

    // Generate and store OTP for government user
    const otp = generateOtp();
    await admin.firestore().collection('otp').doc(email).set({
      otp: otp,
      expiresAt: admin.firestore.FieldValue.serverTimestamp(),
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    return {
      success: true,
      uid: userRecord.uid,
      username: username,
      password: password,
      email: email,
      phoneNumber: phoneNumber,
      message: 'Government user created successfully'
    };
  } catch (error) {
    console.error('Error creating government user:', error);
    throw new functions.https.HttpsError('internal', 'Failed to create government user: ' + error.message);
  }
});

// Helper functions
function generateUsername(firstName, lastName) {
  const baseUsername = `${firstName.toLowerCase()}.${lastName.toLowerCase()}`;
  const timestamp = Date.now().toString().substring(8);
  return `${baseUsername}${timestamp}`;
}

function generatePassword() {
  const chars = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789!@#$%^&*';
  let password = '';
  for (let i = 0; i < 12; i++) {
    password += chars.charAt(Math.floor(Math.random() * chars.length));
  }
  return password;
}

function generateOtp() {
  return Math.floor(1000 + Math.random() * 9000).toString();
}

// Send email OTP function
exports.sendEmailOtp = functions.https.onCall(async (data, context) => {
  try {
    const { email, otp, userRole } = data;
    
    if (!email || !otp) {
      throw new functions.https.HttpsError('invalid-argument', 'Email and OTP are required');
    }

    // Generate verification ID
    const verificationId = admin.firestore().collection('temp').doc().id;
    
    // Store OTP temporarily in Firestore (expires in 10 minutes)
    await admin.firestore().collection('email_otps').doc(verificationId).set({
      email: email,
      otp: otp,
      userRole: userRole,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
      expiresAt: new Date(Date.now() + 10 * 60 * 1000) // 10 minutes
    });

    // Email template
    const mailOptions = {
      from: functions.config().email?.user || 'your-email@gmail.com',
      to: email,
      subject: 'CivicLense - Government User Verification Code',
      html: `
        <div style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto;">
          <div style="background: linear-gradient(135deg, #1976d2, #42a5f5); padding: 20px; text-align: center;">
            <h1 style="color: white; margin: 0;">CivicLense</h1>
            <p style="color: white; margin: 5px 0 0 0;">Government Portal</p>
          </div>
          
          <div style="padding: 30px; background: #f8f9fa;">
            <h2 style="color: #333; margin-bottom: 20px;">Verification Code</h2>
            
            <p style="color: #666; line-height: 1.6;">
              Hello,<br><br>
              You are registering as a <strong>${userRole}</strong> in the CivicLense government portal.
              Please use the following verification code to complete your registration:
            </p>
            
            <div style="background: white; border: 2px solid #1976d2; border-radius: 8px; padding: 20px; text-align: center; margin: 20px 0;">
              <h1 style="color: #1976d2; font-size: 36px; margin: 0; letter-spacing: 8px;">${otp}</h1>
            </div>
            
            <p style="color: #666; line-height: 1.6;">
              This code will expire in <strong>10 minutes</strong>.<br>
              If you did not request this code, please ignore this email.
            </p>
            
            <div style="background: #fff3cd; border: 1px solid #ffeaa7; border-radius: 4px; padding: 15px; margin: 20px 0;">
              <p style="color: #856404; margin: 0; font-size: 14px;">
                <strong>Security Notice:</strong> Never share this verification code with anyone. 
                CivicLense staff will never ask for your verification code.
              </p>
            </div>
          </div>
          
          <div style="background: #f8f9fa; padding: 20px; text-align: center; border-top: 1px solid #dee2e6;">
            <p style="color: #6c757d; font-size: 12px; margin: 0;">
              © 2024 CivicLense. All rights reserved.<br>
              This is an automated message, please do not reply.
            </p>
          </div>
        </div>
      `
    };

    // Send email
    await transporter.sendMail(mailOptions);
    
    console.log(`Email OTP sent to ${email} for role ${userRole}`);
    
    return { 
      success: true, 
      verificationId: verificationId,
      message: 'Email OTP sent successfully' 
    };
    
  } catch (error) {
    console.error('Error sending email OTP:', error);
    throw new functions.https.HttpsError('internal', 'Failed to send email OTP');
  }
});

// Verify email OTP function
exports.verifyEmailOtp = functions.https.onCall(async (data, context) => {
  try {
    const { verificationId, otp } = data;
    
    if (!verificationId || !otp) {
      throw new functions.https.HttpsError('invalid-argument', 'Verification ID and OTP are required');
    }

    // Get OTP document
    const otpDoc = await admin.firestore().collection('email_otps').doc(verificationId).get();
    
    if (!otpDoc.exists) {
      throw new functions.https.HttpsError('not-found', 'Invalid verification ID');
    }
    
    const otpData = otpDoc.data();
    const now = new Date();
    const expiresAt = otpData.expiresAt.toDate();
    
    // Check if OTP has expired
    if (now > expiresAt) {
      // Delete expired OTP
      await admin.firestore().collection('email_otps').doc(verificationId).delete();
      throw new functions.https.HttpsError('deadline-exceeded', 'OTP has expired');
    }
    
    // Verify OTP
    if (otpData.otp !== otp) {
      throw new functions.https.HttpsError('invalid-argument', 'Invalid OTP');
    }
    
    // Delete OTP after successful verification
    await admin.firestore().collection('email_otps').doc(verificationId).delete();
    
    return { 
      success: true, 
      message: 'Email OTP verified successfully',
      email: otpData.email,
      userRole: otpData.userRole
    };
    
  } catch (error) {
    console.error('Error verifying email OTP:', error);
    throw new functions.https.HttpsError('internal', 'Failed to verify email OTP');
  }
});

// Reset password using OTP verification
exports.resetPasswordWithOtp = functions.https.onCall(async (data, context) => {
  try {
    const { email, newPassword, verificationId } = data;
    
    if (!email || !newPassword || !verificationId) {
      throw new functions.https.HttpsError('invalid-argument', 'Email, new password, and verification ID are required');
    }

    console.log(`Password reset requested for: ${email}`);

    // Verify that OTP was verified by checking password_reset_requests
    const resetRequestDoc = await admin.firestore()
      .collection('password_reset_requests')
      .doc(verificationId)
      .get();
    
    if (!resetRequestDoc.exists) {
      throw new functions.https.HttpsError('not-found', 'Password reset request not found or expired');
    }
    
    const resetData = resetRequestDoc.data();
    
    // Verify the email matches
    if (resetData.email !== email) {
      throw new functions.https.HttpsError('permission-denied', 'Email does not match reset request');
    }
    
    // Check if request has expired
    const expiresAt = resetData.expiresAt.toDate();
    if (new Date() > expiresAt) {
      // Delete expired request
      await admin.firestore().collection('password_reset_requests').doc(verificationId).delete();
      throw new functions.https.HttpsError('deadline-exceeded', 'Password reset request has expired');
    }
    
    // Verify OTP was confirmed
    if (!resetData.otpVerified) {
      throw new functions.https.HttpsError('failed-precondition', 'OTP not verified');
    }

    // Get user by email
    const userRecord = await admin.auth().getUserByEmail(email);
    console.log(`Found user: ${userRecord.uid}`);

    // Update password using Admin SDK
    await admin.auth().updateUser(userRecord.uid, {
      password: newPassword
    });
    console.log(`Password updated successfully for: ${email}`);

    // Delete the reset request
    await admin.firestore().collection('password_reset_requests').doc(verificationId).delete();
    console.log('Cleaned up password reset request');

    return { 
      success: true, 
      message: 'Password reset successfully' 
    };
    
  } catch (error) {
    console.error('Error resetting password:', error);
    
    if (error instanceof functions.https.HttpsError) {
      throw error;
    }
    
    throw new functions.https.HttpsError('internal', 'Failed to reset password: ' + error.message);
  }
});

// Export auto-prioritization function
exports.autoPrioritizeConcerns = autoPrioritizeConcerns;

// Send push notification via FCM
exports.sendPushNotification = functions.https.onCall(async (data, context) => {
  try {
    // Check if the request is authenticated
    if (!context.auth) {
      throw new functions.https.HttpsError('unauthenticated', 'User must be authenticated to send notifications');
    }

    const { token, title, body, data: notificationData } = data;
    
    if (!token || !title || !body) {
      throw new functions.https.HttpsError('invalid-argument', 'Token, title, and body are required');
    }

    console.log(`📤 Sending push notification to token: ${token.substring(0, 20)}...`);
    console.log(`   Title: ${title}`);
    console.log(`   Body: ${body}`);

    // Construct the message
    const message = {
      notification: {
        title: title,
        body: body,
      },
      data: notificationData || {},
      token: token,
      android: {
        priority: 'high',
        notification: {
          sound: 'default',
          clickAction: 'FLUTTER_NOTIFICATION_CLICK',
          channelId: 'concern_updates',
          priority: 'high',
        },
      },
      apns: {
        payload: {
          aps: {
            sound: 'default',
            badge: 1,
            contentAvailable: true,
          },
        },
      },
    };

    // Send the message via FCM
    const response = await admin.messaging().send(message);
    
    console.log('✅ Push notification sent successfully:', response);
    
    return { 
      success: true, 
      messageId: response,
      message: 'Push notification sent successfully' 
    };
    
  } catch (error) {
    console.error('❌ Error sending push notification:', error);
    
    // Return error but don't throw - notifications shouldn't break the app
    return {
      success: false,
      error: error.message || 'Unknown error occurred',
      message: 'Failed to send push notification'
    };
  }
});

// Send push notification to multiple users
exports.sendBulkPushNotifications = functions.https.onCall(async (data, context) => {
  try {
    // Check if the request is authenticated
    if (!context.auth) {
      throw new functions.https.HttpsError('unauthenticated', 'User must be authenticated');
    }

    const { userIds, title, body, data: notificationData } = data;
    
    if (!userIds || !Array.isArray(userIds) || userIds.length === 0) {
      throw new functions.https.HttpsError('invalid-argument', 'userIds array is required');
    }

    if (!title || !body) {
      throw new functions.https.HttpsError('invalid-argument', 'Title and body are required');
    }

    console.log(`📤 Sending bulk notifications to ${userIds.length} users`);

    // Get FCM tokens for all users
    const userDocs = await Promise.all(
      userIds.map(userId => admin.firestore().collection('users').doc(userId).get())
    );

    const tokens = userDocs
      .filter(doc => doc.exists && doc.data()?.fcmToken)
      .map(doc => doc.data().fcmToken);

    if (tokens.length === 0) {
      console.log('⚠️ No valid FCM tokens found');
      return {
        success: true,
        sent: 0,
        failed: 0,
        message: 'No users with valid FCM tokens'
      };
    }

    console.log(`📱 Found ${tokens.length} valid FCM tokens`);

    // Construct the multicast message
    const message = {
      notification: {
        title: title,
        body: body,
      },
      data: notificationData || {},
      tokens: tokens,
      android: {
        priority: 'high',
        notification: {
          sound: 'default',
          clickAction: 'FLUTTER_NOTIFICATION_CLICK',
          channelId: 'concern_updates',
          priority: 'high',
        },
      },
      apns: {
        payload: {
          aps: {
            sound: 'default',
            badge: 1,
          },
        },
      },
    };

    // Send multicast message
    const response = await admin.messaging().sendEachForMulticast(message);
    
    console.log(`✅ Bulk notification results: ${response.successCount} sent, ${response.failureCount} failed`);
    
    return { 
      success: true, 
      sent: response.successCount,
      failed: response.failureCount,
      message: `Sent ${response.successCount} notifications successfully`
    };
    
  } catch (error) {
    console.error('❌ Error sending bulk notifications:', error);
    
    return {
      success: false,
      error: error.message || 'Unknown error occurred',
      message: 'Failed to send bulk notifications'
    };
  }
});

// Firestore trigger: Send notification when concern status changes
exports.onConcernStatusChange = functions.firestore
  .document('concerns/{concernId}')
  .onUpdate(async (change, context) => {
    try {
      const concernId = context.params.concernId;
      const beforeData = change.before.data();
      const afterData = change.after.data();

      // Check if status changed
      if (beforeData.status === afterData.status) {
        return null;
      }

      console.log(`🔔 Concern status changed: ${concernId}`);
      console.log(`   Old status: ${beforeData.status}`);
      console.log(`   New status: ${afterData.status}`);

      // Get author's FCM token
      const authorId = afterData.authorId;
      const authorDoc = await admin.firestore().collection('users').doc(authorId).get();
      
      if (!authorDoc.exists || !authorDoc.data()?.fcmToken) {
        console.log('⚠️ Author has no FCM token');
        return null;
      }

      const fcmToken = authorDoc.data().fcmToken;
      const title = 'Concern Status Updated';
      const body = `Your concern "${afterData.title}" status changed to ${afterData.status}`;

      // Send push notification
      const message = {
        notification: {
          title: title,
          body: body,
        },
        data: {
          concernId: concernId,
          type: 'concern_status_change',
          oldStatus: beforeData.status,
          newStatus: afterData.status,
        },
        token: fcmToken,
        android: {
          priority: 'high',
          notification: {
            sound: 'default',
            channelId: 'concern_updates',
          },
        },
      };

      await admin.messaging().send(message);
      console.log('✅ Status change notification sent');

      return null;
    } catch (error) {
      console.error('❌ Error in concern status change trigger:', error);
      return null;
    }
  });

// Firestore trigger: Send notification when new comment is added
exports.onNewConcernComment = functions.firestore
  .document('concern_comments/{commentId}')
  .onCreate(async (snapshot, context) => {
    try {
      const commentData = snapshot.data();
      const concernId = commentData.concernId;

      console.log(`💬 New comment on concern: ${concernId}`);

      // Get concern to find the author
      const concernDoc = await admin.firestore().collection('concerns').doc(concernId).get();
      
      if (!concernDoc.exists) {
        console.log('⚠️ Concern not found');
        return null;
      }

      const concernData = concernDoc.data();
      const authorId = concernData.authorId;

      // Don't notify if the comment author is the concern author
      if (commentData.userId === authorId) {
        console.log('ℹ️ Comment author is concern author, skipping notification');
        return null;
      }

      // Get author's FCM token
      const authorDoc = await admin.firestore().collection('users').doc(authorId).get();
      
      if (!authorDoc.exists || !authorDoc.data()?.fcmToken) {
        console.log('⚠️ Author has no FCM token');
        return null;
      }

      const fcmToken = authorDoc.data().fcmToken;
      const commenterName = commentData.userName || 'An officer';
      const title = 'New Comment on Your Concern';
      const body = `${commenterName}: ${commentData.text.substring(0, 100)}${commentData.text.length > 100 ? '...' : ''}`;

      // Send push notification
      const message = {
        notification: {
          title: title,
          body: body,
        },
        data: {
          concernId: concernId,
          type: 'new_comment',
          commentId: snapshot.id,
        },
        token: fcmToken,
        android: {
          priority: 'high',
          notification: {
            sound: 'default',
            channelId: 'concern_updates',
          },
        },
      };

      await admin.messaging().send(message);
      console.log('✅ New comment notification sent');

      return null;
    } catch (error) {
      console.error('❌ Error in new comment trigger:', error);
      return null;
    }
  });

