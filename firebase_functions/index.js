const functions = require('firebase-functions');
const admin = require('firebase-admin');

// Initialize Firebase Admin SDK
admin.initializeApp();

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

    const { email, firstName, lastName, role } = data;
    
    if (!email || !firstName || !lastName || !role) {
      throw new functions.https.HttpsError('invalid-argument', 'Email, firstName, lastName, and role are required');
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
      username: username,
      role: role,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
      isActive: true,
      emailVerified: false,
      isGovernmentUser: true,
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

