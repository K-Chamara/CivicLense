import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_role.dart';
import 'emailjs_service.dart';

class GovernmentAuthService {
  // Singleton pattern
  static final GovernmentAuthService _instance = GovernmentAuthService._internal();
  factory GovernmentAuthService() => _instance;
  GovernmentAuthService._internal();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // OTP verification states
  String? _emailOtp;
  String? _emailVerificationId;
  UserRole? _pendingUserRole;

  // Get current user
  User? get currentUser => _auth.currentUser;

  // Send email OTP for government user verification
  Future<void> sendEmailOtp(String email, UserRole role) async {
    try {
      // Only generate a new OTP if one doesn't exist
      if (_emailOtp == null) {
        _emailOtp = _generateOtp();
        print('🔑 Generated NEW OTP: $_emailOtp');
      } else {
        print('🔑 Using EXISTING OTP: $_emailOtp');
      }
      
      // Store pending verification data
      _pendingUserRole = role;
      print('👤 Stored pending role: ${role.name}');
      
      // For now, we'll simulate the email OTP sending
      // In a real implementation, you would call your Firebase Function via HTTP
      // or use a service like SendGrid, Mailgun, etc.
      
      // Generate a verification ID
      _emailVerificationId = DateTime.now().millisecondsSinceEpoch.toString();
      
      // Store OTP in Firestore temporarily (expires in 10 minutes)
      await _firestore.collection('email_otps').doc(_emailVerificationId!).set({
        'email': email,
        'otp': _emailOtp,
        'userRole': role.name,
        'createdAt': FieldValue.serverTimestamp(),
        'expiresAt': DateTime.now().add(const Duration(minutes: 10)),
      });
      
      // Send email via EmailJS
      try {
        await EmailJSService.sendOtpEmail(
          email: email,
          otp: _emailOtp!,
          userRole: role.name,
        );
        print('✅ Email sent successfully via EmailJS');
      } catch (e) {
        print('❌ EmailJS failed, falling back to console: $e');
        print('📧 Email OTP for $email: $_emailOtp');
        print('🔍 You can also check Firestore collection "email_otps" for the OTP');
        print('⚠️ To fix email sending, configure EmailJS with your service credentials');
      }
      
    } catch (e) {
      rethrow;
    }
  }


  // Verify email OTP
  Future<bool> verifyEmailOtp(String enteredOtp) async {
    try {
      print('🔍 Verifying OTP:');
      print('📧 Stored OTP: $_emailOtp');
      print('📧 Entered OTP: $enteredOtp');
      
      // First check in-memory OTP (for backward compatibility)
      if (_emailOtp != null && _emailOtp == enteredOtp) {
        print('✅ OTP verification successful (in-memory)!');
        return true;
      }
      
      // If in-memory check fails, check Firestore
      if (_emailVerificationId != null) {
        final otpDoc = await _firestore.collection('email_otps').doc(_emailVerificationId!).get();
        if (otpDoc.exists) {
          final otpData = otpDoc.data()!;
          final storedOtp = otpData['otp'] as String;
          final expiresAt = (otpData['expiresAt'] as Timestamp).toDate();
          
          print('📧 Firestore OTP: $storedOtp');
          print('📧 Match: ${storedOtp == enteredOtp}');
          
          // Check if OTP is expired
          if (DateTime.now().isAfter(expiresAt)) {
            print('❌ OTP has expired!');
            return false;
          }
          
          if (storedOtp == enteredOtp) {
            print('✅ OTP verification successful (Firestore)!');
            // Clean up the OTP document after successful verification
            try {
              await _firestore.collection('email_otps').doc(_emailVerificationId!).delete();
              print('🧹 Cleaned up OTP document from Firestore');
            } catch (e) {
              print('⚠️ Failed to clean up OTP document: $e');
            }
            return true;
          }
        }
      }
      
      print('❌ OTP verification failed!');
      return false;
    } catch (e) {
      print('❌ OTP verification error: $e');
      return false;
    }
  }

  // Complete login with OTP verification only (for when user is already authenticated)
  Future<void> completeLoginWithOtp(String email, String emailOtp) async {
    try {
      print('🔐 Completing login with OTP for: $email');
      
      // Verify the OTP
      final emailVerified = await verifyEmailOtp(emailOtp);
      if (!emailVerified) {
        throw Exception('Invalid OTP code');
      }
      
      // Get current user (should already be signed in)
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }
      
      // Get user data to verify role and status
      final userData = await getUserData(user.uid);
      if (userData == null) {
        throw Exception('User data not found');
      }
      
      // Check if account is deactivated
      final isActive = userData['isActive'] ?? true;
      if (!isActive) {
        // Sign out the user immediately
        await _auth.signOut();
        
        // Throw a custom error for deactivated account
        throw FirebaseAuthException(
          code: 'account-deactivated',
          message: 'Your account has been deactivated. Please contact the administrator for assistance.',
        );
      }
      
      final userRole = UserRole.fromMap(userData['role']);
      if (userRole.userType != UserType.government && userRole.userType != UserType.admin) {
        throw Exception('Access denied: Government users only');
      }
      
      // Update last login timestamp and mark email as verified
      await _firestore.collection('users').doc(user.uid).update({
        'lastLogin': FieldValue.serverTimestamp(),
        'emailVerified': true,
      });
      
      // Clean up OTP data
      _emailOtp = null;
      _emailVerificationId = null;
      _pendingUserRole = null;
      
      print('✅ Login completed successfully with OTP verification');
    } catch (e) {
      print('❌ Error completing login with OTP: $e');
      rethrow;
    }
  }


  // Complete government user registration with email OTP verification
  Future<UserCredential> completeGovernmentUserRegistration({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
    required UserRole role,
    required String emailOtp,
  }) async {
    try {
      // Verify email OTP
      final emailVerified = await verifyEmailOtp(emailOtp);

      if (!emailVerified) {
        throw Exception('Invalid OTP code');
      }

      // Create user with email and password
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Update user profile
      await userCredential.user?.updateDisplayName('$firstName $lastName');

      // Create government user document in Firestore
      await _createGovernmentUserDocument(
        userCredential.user!.uid,
        email,
        firstName,
        lastName,
        role,
      );

      // Clear verification data
      _clearVerificationData();

      return userCredential;
    } catch (e) {
      // Clean up on failure
      await _auth.currentUser?.delete();
      rethrow;
    }
  }

  // Government user login with email OTP verification
  Future<UserCredential> governmentUserLogin({
    required String email,
    required String password,
    required String emailOtp,
  }) async {
    try {
      print('🔐 Attempting to sign in government user: $email');
      
      // First, sign in with email and password
      final userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      print('✅ Firebase Auth sign-in successful for: $email');

      // Get user data to verify role
      final userData = await getUserData(userCredential.user!.uid);
      if (userData == null) {
        throw Exception('User data not found');
      }

      // Check if account is deactivated
      final isActive = userData['isActive'] ?? true;
      if (!isActive) {
        // Sign out the user immediately
        await _auth.signOut();
        
        // Throw a custom error for deactivated account
        throw FirebaseAuthException(
          code: 'account-deactivated',
          message: 'Your account has been deactivated. Please contact the administrator for assistance.',
        );
      }

      final userRole = UserRole.fromMap(userData['role']);
      if (userRole.userType != UserType.government && userRole.userType != UserType.admin) {
        throw Exception('Access denied: Government users only');
      }

      // Verify email OTP (don't send a new one - use the existing OTP from login flow)
      final emailVerified = await verifyEmailOtp(emailOtp);

      if (!emailVerified) {
        await _auth.signOut();
        throw Exception('Invalid OTP code');
      }

      // Update last login timestamp and mark email as verified
      await _firestore.collection('users').doc(userCredential.user!.uid).update({
        'lastLogin': FieldValue.serverTimestamp(),
        'isActive': true,
        'emailVerified': true, // Mark email as verified after successful OTP verification
      });

      // Clear verification data
      _clearVerificationData();

      return userCredential;
    } on FirebaseAuthException catch (e) {
      print('❌ Firebase Auth error: ${e.code} - ${e.message}');
      String errorMessage = 'Authentication failed';
      
      switch (e.code) {
        case 'user-not-found':
          errorMessage = 'No government user found with this email address. Please contact your administrator.';
          break;
        case 'wrong-password':
          errorMessage = 'Incorrect password for government user.';
          break;
        case 'invalid-email':
          errorMessage = 'Please enter a valid email address.';
          break;
        case 'user-disabled':
          errorMessage = 'This government account has been disabled.';
          break;
        case 'too-many-requests':
          errorMessage = 'Too many failed attempts. Please try again later.';
          break;
        case 'invalid-credential':
          errorMessage = 'Invalid credentials. Please check your email and password.';
          break;
        default:
          errorMessage = 'Authentication error: ${e.message}';
      }
      
      throw Exception(errorMessage);
    } catch (e) {
      print('❌ Unexpected error during government user login: $e');
      rethrow;
    }
  }

  // Create government user document in Firestore
  Future<void> _createGovernmentUserDocument(
    String uid,
    String email,
    String firstName,
    String lastName,
    UserRole role,
  ) async {
    try {
      await _firestore.collection('users').doc(uid).set({
        'email': email,
        'firstName': firstName,
        'lastName': lastName,
        'role': role.toMap(),
        'userType': role.userType.toString().split('.').last,
        'createdAt': FieldValue.serverTimestamp(),
        'lastLogin': FieldValue.serverTimestamp(),
        'isActive': true,
        'emailVerified': true,
        'isGovernmentUser': true,
        'securityLevel': 'high',
        'otpEnabled': true,
      });
    } catch (e) {
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

  // Check if user is government user
  Future<bool> isGovernmentUser(String uid) async {
    try {
      final userData = await getUserData(uid);
      return userData?['isGovernmentUser'] == true;
    } catch (e) {
      return false;
    }
  }

  // Generate 4-digit OTP
  String _generateOtp() {
    final random = DateTime.now().millisecondsSinceEpoch;
    final otp = (random % 9000 + 1000).toString();
    return otp;
  }

  // Clear verification data
  void _clearVerificationData() {
    print('🧹 Clearing verification data:');
    print('📧 OTP before clear: $_emailOtp');
    print('🆔 Verification ID before clear: $_emailVerificationId');
    print('👤 Role before clear: ${_pendingUserRole?.name}');
    
    _emailOtp = null;
    _emailVerificationId = null;
    _pendingUserRole = null;
    
    print('✅ Verification data cleared');
  }

  // Resend email OTP
  Future<void> resendEmailOtp(String email, UserRole role) async {
    // Force generate a new OTP for resend
    _emailOtp = _generateOtp();
    print('🔄 Resending with NEW OTP: $_emailOtp');
    await sendEmailOtp(email, role);
  }


  // Sign out
  Future<void> signOut() async {
    try {
      _clearVerificationData();
      await _auth.signOut();
    } catch (e) {
      rethrow;
    }
  }

  // Check if user is authenticated
  bool get isAuthenticated => _auth.currentUser != null;

  // Stream of auth state changes
  Stream<User?> get authStateChanges => _auth.authStateChanges();

}
