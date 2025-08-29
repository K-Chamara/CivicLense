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

