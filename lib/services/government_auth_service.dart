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
      print('📧 Match: ${_emailOtp == enteredOtp}');
      
      if (_emailOtp == enteredOtp) {
        print('✅ OTP verification successful!');
        return true;
      }
      print('❌ OTP verification failed!');
      return false;
    } catch (e) {
      print('❌ OTP verification error: $e');
      return false;
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
      // First, sign in with email and password
      final userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Get user data to verify role
      final userData = await getUserData(userCredential.user!.uid);
      if (userData == null) {
        throw Exception('User data not found');
      }

      final userRole = UserRole.fromMap(userData['role']);
      if (userRole.userType != UserType.government && userRole.userType != UserType.admin) {
        throw Exception('Access denied: Government users only');
      }

      // Send email OTP for verification
      await sendEmailOtp(email, userRole);

      // Verify email OTP
      final emailVerified = await verifyEmailOtp(emailOtp);

      if (!emailVerified) {
        await _auth.signOut();
        throw Exception('Invalid OTP code');
      }

      // Update last login timestamp
      await _firestore.collection('users').doc(userCredential.user!.uid).update({
        'lastLogin': FieldValue.serverTimestamp(),
        'isActive': true,
      });

      // Clear verification data
      _clearVerificationData();

      return userCredential;
    } catch (e) {
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
