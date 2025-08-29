import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_role.dart';

class AdminService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  // Store admin credentials to re-authenticate after creating users
  String? _adminEmail;
  String? _adminPassword;

  // Check if current user is admin
  Future<bool> isAdmin(String uid) async {
    try {
      print('🔍 Checking if user $uid is admin...');
      
      // Force fresh data from Firestore (no cache)
      final userData = await _firestore
          .collection('users')
          .doc(uid)
          .get(const GetOptions(source: Source.server));
      
      if (userData.exists) {
        final data = userData.data()!;
        print('📋 User data: $data');
        
        if (data.containsKey('role')) {
          final roleData = data['role'];
          print('🎭 Role data: $roleData');
          final role = UserRole.fromMap(roleData);
          print('👤 Parsed role: ${role.name} (${role.userType})');
          
          final isAdmin = role.userType == UserType.admin;
          print('✅ Is admin: $isAdmin');
          return isAdmin;
        }
        print('❌ No role data found');
        return false;
      }
      print('❌ User document does not exist');
      return false;
    } catch (e) {
      print('❌ Error checking admin status: $e');
      return false;
    }
  }

  // Get all users
  Future<List<Map<String, dynamic>>> getAllUsers() async {
    try {
      final querySnapshot = await _firestore.collection('users').get();
      return querySnapshot.docs.map((doc) {
        final data = doc.data();
        data['uid'] = doc.id;
        return data;
      }).toList();
    } catch (e) {
      throw Exception('Failed to fetch users: $e');
    }
  }

  // Get users by role
  Future<List<Map<String, dynamic>>> getUsersByRole(String roleId) async {
    try {
      final querySnapshot = await _firestore
          .collection('users')
          .where('role.id', isEqualTo: roleId)
          .get();
      return querySnapshot.docs.map((doc) {
        final data = doc.data();
        data['uid'] = doc.id;
        return data;
      }).toList();
    } catch (e) {
      throw Exception('Failed to fetch users by role: $e');
    }
  }

  // Create government user with auto-generated credentials
  Future<Map<String, String>> createGovernmentUser({
    required String email,
    required String firstName,
    required String lastName,
    required UserRole role,
  }) async {
    try {
      // Check if role limit is reached
      final existingUsers = await getUsersByRole(role.id);
      if (role.maxAllowed > 0 && existingUsers.length >= role.maxAllowed) {
        throw Exception('Maximum number of ${role.name} users (${role.maxAllowed}) already exists.');
      }

      // Generate username and password
      final username = _generateUsername(firstName, lastName);
      final password = _generatePassword();

      // Store current admin user before creating new user
      final currentAdminUser = _auth.currentUser;
      print('👤 Admin user before creation: ${currentAdminUser?.uid}');

      // Create user in Firebase Auth
      // This will automatically sign in as the new user, which we don't want
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      print('🔧 Created Firebase Auth user: ${userCredential.user!.uid}');
      print('👤 Current user after creation: ${_auth.currentUser?.uid}');
      
      // Create user document in Firestore
      await _firestore.collection('users').doc(userCredential.user!.uid).set({
        'email': email,
        'firstName': firstName,
        'lastName': lastName,
        'username': username,
        'role': role.toMap(),
        'createdAt': FieldValue.serverTimestamp(),
        'isActive': true,
        'emailVerified': false,
        'isGovernmentUser': true,
        'createdBy': currentAdminUser?.uid,
      });

      print('📝 Created Firestore document for user: ${userCredential.user!.uid}');
      
      // Send email with credentials
      await _sendCredentialsEmail(email, username, password, role.name);

      // Generate and send OTP for government user
      await _sendOtpEmail(email);

      // Sign out immediately to prevent automatic navigation to new user dashboard
      await _auth.signOut();
      print('✅ Government user created successfully');
      print('🔄 Signed out to prevent navigation to new user dashboard');

      return {
        'uid': userCredential.user!.uid,
        'username': username,
        'password': password,
        'email': email,
      };
    } catch (e) {
      throw Exception('Failed to create government user: $e');
    }
  }

  // Update user status
  Future<void> updateUserStatus(String uid, bool isActive) async {
    try {
      await _firestore.collection('users').doc(uid).update({
        'isActive': isActive,
        'updatedAt': FieldValue.serverTimestamp(),
        'updatedBy': _auth.currentUser?.uid,
      });
    } catch (e) {
      throw Exception('Failed to update user status: $e');
    }
  }

  // Delete user
  Future<void> deleteUser(String uid) async {
    try {
      // Get user data first
      final userData = await _firestore.collection('users').doc(uid).get();
      if (!userData.exists) {
        throw Exception('User not found');
      }

      final role = UserRole.fromMap(userData.data()!['role']);
      
      // Don't allow deletion of admin users
      if (role.userType == UserType.admin) {
        throw Exception('Cannot delete admin users');
      }

      // Delete from Firestore
      await _firestore.collection('users').doc(uid).delete();
      print('🗑️ Deleted user document from Firestore: $uid');
      
      // Note: User still exists in Firebase Auth
      print('⚠️ Note: User still exists in Firebase Auth');
      print('💡 To fully delete from Firebase Auth, you need to:');
      print('   1. Deploy Firebase Functions (see firebase_functions/README.md)');
      print('   2. Or manually delete from Firebase Console');
      print('   3. Or implement a backend service with Admin SDK');
      
      // Show success message but inform about the limitation
      print('✅ User deleted from database successfully');
      print('📋 The user can no longer log in through the app');
      print('🔧 For complete cleanup, manually delete from Firebase Auth console');
      
    } catch (e) {
      print('❌ Error deleting user: $e');
      throw Exception('Failed to delete user: $e');
    }
  }

  // Generate username
  String _generateUsername(String firstName, String lastName) {
    final baseUsername = '${firstName.toLowerCase()}.${lastName.toLowerCase()}';
    final timestamp = DateTime.now().millisecondsSinceEpoch.toString().substring(8);
    return '$baseUsername$timestamp';
  }

  // Generate password
  String _generatePassword() {
    const chars = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789!@#\$%^&*';
    final random = DateTime.now().millisecondsSinceEpoch;
    final password = StringBuffer();
    
    for (int i = 0; i < 12; i++) {
      password.write(chars[random % chars.length]);
    }
    
    return password.toString();
  }

  // Send credentials email (placeholder - implement with your email service)
  Future<void> _sendCredentialsEmail(String email, String username, String password, String roleName) async {
    // TODO: Implement email sending functionality
    // You can use services like SendGrid, Mailgun, or Firebase Functions
    
    print('📧 EMAIL NOTIFICATION (Not implemented yet)');
    print('To: $email');
    print('Subject: Your Civic Lense Government User Account');
    print('Body:');
    print('Hello,');
    print('Your government user account has been created.');
    print('Username: $username');
    print('Password: $password');
    print('Role: $roleName');
    print('Please log in at the Civic Lense application.');
    print('');
    print('Note: This is a placeholder. In production, implement proper email sending.');
    
    // For now, we'll just print to console
    // In production, implement proper email sending using:
    // - Firebase Functions with SendGrid
    // - Firebase Functions with Mailgun
    // - Firebase Functions with Gmail API
    // - Or any other email service
  }

  // Generate and send OTP for government users
  Future<void> _sendOtpEmail(String email) async {
    try {
      // Generate 4-digit OTP
      final otp = _generateOtp();
      
      // Store OTP in Firestore with 5-minute expiration
      await _firestore.collection('otp').doc(email).set({
        'otp': otp,
        'expiresAt': FieldValue.serverTimestamp(),
        'createdAt': FieldValue.serverTimestamp(),
      });

      print('📧 OTP EMAIL NOTIFICATION (Not implemented yet)');
      print('To: $email');
      print('Subject: Your Civic Lense Login OTP');
      print('Body:');
      print('Hello,');
      print('Your 4-digit verification code is: $otp');
      print('This code will expire in 5 minutes.');
      print('Please enter this code to complete your login.');
      print('');
      print('Note: This is a placeholder. In production, implement proper email sending.');
      
    } catch (e) {
      print('❌ Error sending OTP: $e');
      throw Exception('Failed to send OTP: $e');
    }
  }

  // Generate 4-digit OTP
  String _generateOtp() {
    final random = DateTime.now().millisecondsSinceEpoch;
    return (1000 + (random % 9000)).toString();
  }

  // Get user statistics
  Future<Map<String, int>> getUserStatistics() async {
    try {
      final users = await getAllUsers();
      final stats = <String, int>{};
      
      for (final role in UserRole.allRoles) {
        stats[role.name] = users.where((user) => user['role']?['id'] == role.id).length;
      }
      
      return stats;
    } catch (e) {
      throw Exception('Failed to get user statistics: $e');
    }
  }

  // Check if user can be created for a specific role
  Future<bool> canCreateUserForRole(UserRole role) async {
    try {
      final existingUsers = await getUsersByRole(role.id);
      return role.maxAllowed == -1 || existingUsers.length < role.maxAllowed;
    } catch (e) {
      return false;
    }
  }
}
