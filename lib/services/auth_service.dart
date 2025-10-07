import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_role.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Get current user
  User? get currentUser => _auth.currentUser;

  // Sign in with email and password
  Future<UserCredential> signInWithEmailAndPassword(
    String email,
    String password,
  ) async {
    try {
      final userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Check if user document exists in Firestore
      final userDoc = await _firestore.collection('users').doc(userCredential.user!.uid).get();
      
      if (!userDoc.exists) {
        // Create the user document if it doesn't exist
        await _firestore.collection('users').doc(userCredential.user!.uid).set({
          'email': email,
          'firstName': 'Unknown',
          'lastName': 'User',
          'role': {
            'id': 'citizen',
            'name': 'Citizen/Taxpayer',
            'description': 'Track public spending and raise concerns',
            'color': '#2196F3',
          },
          'createdAt': FieldValue.serverTimestamp(),
          'isActive': true,
          'emailVerified': userCredential.user!.emailVerified,
        });
      } else {
        // Update email verification status if needed
        if (userCredential.user!.emailVerified && !userDoc.data()!['emailVerified']) {
          await _firestore.collection('users').doc(userCredential.user!.uid).update({
            'emailVerified': true,
          });
        }
      }

      // Check if email is verified (skip for admin users)
      final userData = userDoc.exists ? userDoc.data()! : null;
      final isAdmin = userData != null && 
                     userData['role'] != null && 
                     UserRole.fromMap(userData['role']).userType == UserType.admin;
      
      if (!userCredential.user!.emailVerified && !isAdmin) {
        throw FirebaseAuthException(
          code: 'email-not-verified',
          message: 'Please verify your email before signing in.',
        );
      }

      return userCredential;
    } catch (e) {
      rethrow;
    }
  }

  // Create user with email and password
  Future<UserCredential> createUserWithEmailAndPassword(
    String email,
    String password,
    String firstName,
    String lastName,
    UserRole role,
  ) async {
    try {
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Create user document in Firestore
      await _createUserDocument(
        userCredential.user!.uid,
        email,
        firstName,
        lastName,
        role,
      );

      return userCredential;
    } catch (e) {
      rethrow;
    }
  }

  // Create user document in Firestore
  Future<void> _createUserDocument(
    String uid,
    String email,
    String firstName,
    String lastName,
    UserRole role,
  ) async {
    try {
      // Determine if user needs document upload based on role
      final needsUpload = role.id != 'citizen' && role.id != 'admin';
      
      await _firestore.collection('users').doc(uid).set({
        'email': email,
        'firstName': firstName,
        'lastName': lastName,
        'role': role.toMap(), // Store full role object for proper login handling
        'status': needsUpload ? 'pending' : 'approved', // Set status based on role
        'createdAt': FieldValue.serverTimestamp(),
        'isActive': true,
        'emailVerified': false,
      });
    } catch (e) {
      // If Firestore fails, delete the Firebase Auth user
      await _auth.currentUser?.delete();
      rethrow;
    }
  }

  // Get user data from Firestore
  Future<Map<String, dynamic>?> getUserData(String uid) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      return doc.data();
    } catch (e) {
      return null;
    }
  }

  // Update user data
  Future<void> updateUserData(String uid, Map<String, dynamic> data) async {
    try {
      await _firestore.collection('users').doc(uid).update(data);
    } catch (e) {
      rethrow;
    }
  }

  // Verify password without email verification check (for government users)
  Future<UserCredential> verifyPasswordOnly(
    String email,
    String password,
  ) async {
    try {
      final userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      // Sign out immediately after verification to prevent staying logged in
      await _auth.signOut();
      
      return userCredential;
    } catch (e) {
      rethrow;
    }
  }

  // Sign out
  Future<void> signOut() async {
    try {
      await _auth.signOut();
    } catch (e) {
      rethrow;
    }
  }

  // Send password reset email
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } catch (e) {
      rethrow;
    }
  }

  // Send email verification
  Future<void> sendEmailVerification() async {
    try {
      await _auth.currentUser?.sendEmailVerification();
    } catch (e) {
      rethrow;
    }
  }

  // Check if user is authenticated
  bool get isAuthenticated => _auth.currentUser != null;

  // Get user role
  Future<UserRole?> getUserRole(String uid) async {
    try {
      final userData = await getUserData(uid);
      if (userData != null && userData['role'] != null) {
        // Handle both string role ID and role object
        if (userData['role'] is String) {
          // Find role by ID
          final roleId = userData['role'] as String;
          return UserRole.allRoles.firstWhere(
            (role) => role.id == roleId,
            orElse: () => UserRole.allRoles.firstWhere((role) => role.id == 'citizen'),
          );
        } else {
          // Handle role object
          return UserRole.fromMap(userData['role']);
        }
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  // Stream of auth state changes
  Stream<User?> get authStateChanges => _auth.authStateChanges();
}


