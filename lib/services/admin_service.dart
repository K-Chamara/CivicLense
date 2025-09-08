import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import '../models/user_role.dart';

class AdminService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  


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
  Future<Map<String, dynamic>> createGovernmentUser({
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

      // IMPORTANT: Use a separate Firebase app instance to prevent admin logout
      // This approach isolates the user creation process from the main auth session
      
      FirebaseApp? secondaryApp;
      FirebaseAuth? secondaryAuth;
      
      try {
        // Create a secondary Firebase app for user creation
        final appName = 'user-creation-${DateTime.now().millisecondsSinceEpoch}';
        secondaryApp = await Firebase.initializeApp(
          name: appName,
          options: Firebase.app().options,
        );
        
        // Get the secondary auth instance
        secondaryAuth = FirebaseAuth.instanceFor(app: secondaryApp);
        
        print('🔧 Created secondary Firebase app: $appName');
        
        // Create user document in Firestore FIRST
        final userData = {
          'firstName': firstName,
          'lastName': lastName,
          'email': email,
          'username': username,
          'role': role.toMap(),
          'isActive': true,
          'emailVerified': false,
          'isGovernmentUser': true,
          'securityLevel': 'high',
          'otpEnabled': true,
          'createdAt': FieldValue.serverTimestamp(),
          'createdBy': currentAdminUser?.uid,
        };

        // Create the user document in a temporary collection first
        final tempDocRef = _firestore.collection('temp_users').doc();
        await tempDocRef.set(userData);

        print('📝 Created temporary user document');

        // Create user in Firebase Auth using the secondary instance
        final userCredential = await secondaryAuth.createUserWithEmailAndPassword(
          email: email,
          password: password,
        );

        print('🔧 Created Firebase Auth user: ${userCredential.user!.uid}');

        // Move the document from temp collection to actual users collection
        final newUserDoc = _firestore.collection('users').doc(userCredential.user!.uid);
        await newUserDoc.set(userData);

        // Delete the temporary document
        await tempDocRef.delete();

        print('📝 Moved user document to permanent location');

        // Send email with credentials
        await _sendCredentialsEmail(email, username, password, role.name);

        // Generate and send OTP for government user
        await _sendOtpEmail(email);

        print('✅ Government user created successfully');

        return {
          'uid': userCredential.user!.uid,
          'username': username,
          'password': password,
          'email': email,
          'requiresReAuth': false, // No re-auth needed since admin session is preserved
        };
        
      } finally {
        // Clean up the secondary app
        if (secondaryApp != null) {
          try {
            await secondaryApp.delete();
            print('🧹 Cleaned up secondary Firebase app');
          } catch (e) {
            print('⚠️ Error cleaning up secondary app: $e');
          }
        }
      }
    } catch (e) {
      // Clean up any temporary documents on error
      try {
        final tempDocs = await _firestore.collection('temp_users').get();
        for (final doc in tempDocs.docs) {
          await doc.reference.delete();
        }
      } catch (cleanupError) {
        print('⚠️ Error cleaning up temporary documents: $cleanupError');
      }
      
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
        'expiresAt': Timestamp.fromDate(
          DateTime.now().add(const Duration(minutes: 5)),
        ),
        'createdAt': FieldValue.serverTimestamp(),
      });

      print('📧 OTP GENERATED FOR TESTING');
      print('To: $email');
      print('OTP Code: $otp');
      print('This code will expire in 5 minutes.');
      print('');
      print('⚠️ NOTE: Email sending is not implemented yet.');
      print('For testing, use the OTP code above to log in.');
      print('In production, implement proper email sending using:');
      print('- Firebase Functions with SendGrid');
      print('- Firebase Functions with Mailgun');
      print('- Firebase Functions with Gmail API');
      
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

  // Get OTP for testing purposes (for development only)
  Future<String?> getOtpForTesting(String email) async {
    try {
      final otpDoc = await _firestore.collection('otp').doc(email).get();
      if (otpDoc.exists) {
        final otpData = otpDoc.data()!;
        final expiresAt = (otpData['expiresAt'] as Timestamp).toDate();
        
        // Check if OTP is expired
        if (DateTime.now().isAfter(expiresAt)) {
          print('⚠️ OTP has expired for $email');
          return null;
        }
        
        return otpData['otp'] as String;
      }
      return null;
    } catch (e) {
      print('❌ Error getting OTP: $e');
      return null;
    }
  }

}
