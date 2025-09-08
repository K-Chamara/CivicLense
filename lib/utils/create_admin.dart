import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_role.dart';

class AdminCreator {
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Create the initial admin user
  static Future<void> createInitialAdmin({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
  }) async {
    try {
      // Create user in Firebase Auth
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Create admin user document in Firestore
      await _firestore.collection('users').doc(userCredential.user!.uid).set({
        'email': email,
        'firstName': firstName,
        'lastName': lastName,
        'role': UserRole.adminRole.toMap(),
        'createdAt': FieldValue.serverTimestamp(),
        'isActive': true,
        'emailVerified': true, // Admin users don't need email verification
        'isAdmin': true,
        'isGovernmentUser': true, // Admin is a government user and needs OTP verification
        'securityLevel': 'high', // Admin has high security level
        'otpEnabled': true, // Admin needs OTP verification
      });

      print('✅ Admin user created successfully!');
      print('Email: $email');
      print('Password: $password');
      print('UID: ${userCredential.user!.uid}');
      
    } catch (e) {
      print('❌ Error creating admin user: $e');
      rethrow;
    }
  }

  // Check if admin user exists
  static Future<bool> adminExists() async {
    try {
      print('🔍 Checking if admin exists...');
      
      // First, let's check if there are any users at all
      final allUsersSnapshot = await _firestore
          .collection('users')
          .limit(5)
          .get();
      
      print('📊 Total users in database: ${allUsersSnapshot.docs.length}');
      
      if (allUsersSnapshot.docs.isNotEmpty) {
        print('👥 Users found:');
        for (var doc in allUsersSnapshot.docs) {
          final data = doc.data();
          print('  - User ID: ${doc.id}');
          print('  - Email: ${data['email']}');
          print('  - Role: ${data['role']}');
          print('  - Is Admin: ${data['isAdmin']}');
        }
      }
      
      // Now check specifically for admin role
      final querySnapshot = await _firestore
          .collection('users')
          .where('role.id', isEqualTo: 'admin')
          .limit(1)
          .get();
      
      print('🎭 Admin query result: ${querySnapshot.docs.length} admins found');
      
      // Also try alternative queries
      final isAdminQuery = await _firestore
          .collection('users')
          .where('isAdmin', isEqualTo: true)
          .limit(1)
          .get();
      
      print('👑 isAdmin query result: ${isAdminQuery.docs.length} admins found');
      
      final result = querySnapshot.docs.isNotEmpty || isAdminQuery.docs.isNotEmpty;
      print('✅ Final admin exists result: $result');
      
      return result;
    } catch (e) {
      print('❌ Error checking admin existence: $e');
      return false;
    }
  }

  // Get admin user info
  static Future<Map<String, dynamic>?> getAdminInfo() async {
    try {
      final querySnapshot = await _firestore
          .collection('users')
          .where('role.id', isEqualTo: 'admin')
          .limit(1)
          .get();
      
      if (querySnapshot.docs.isNotEmpty) {
        final data = querySnapshot.docs.first.data();
        data['uid'] = querySnapshot.docs.first.id;
        return data;
      }
      
      return null;
    } catch (e) {
      print('Error getting admin info: $e');
      return null;
    }
  }
}
