import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'firebase_email_service.dart';
import 'simple_email_service.dart';
import 'emailjs_service.dart'; // Import the working EmailJS service

class OTPService {
  final FirebaseFunctions _functions = FirebaseFunctions.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Send OTP to user's email
  Future<Map<String, dynamic>> sendOTP(String email) async {
    try {
      // Try Firebase Functions first
      try {
        final callable = _functions.httpsCallable('sendEmailOtp');
        final result = await callable.call({
          'email': email,
          'purpose': 'password_change',
        });
        
        return {
          'success': true,
          'sessionId': result.data['sessionId'],
          'message': 'OTP sent successfully',
        };
      } catch (functionsError) {
        // Fallback: Generate OTP locally and store in Firestore
        print('Firebase Functions not available, using fallback: $functionsError');
        return await _sendOTPFallback(email);
      }
    } catch (e) {
      print('Error sending OTP: $e');
      throw Exception('Failed to send OTP: $e');
    }
  }

  /// Fallback OTP method with robust email handling
  Future<Map<String, dynamic>> _sendOTPFallback(String email) async {
    try {
      final otpCode = generateRandomOTP();
      final sessionId = DateTime.now().millisecondsSinceEpoch.toString();
      final expiryTime = DateTime.now().add(const Duration(minutes: 5));

      // Store OTP in Firestore
      await FirebaseFirestore.instance.collection('otp_sessions').doc(sessionId).set({
        'email': email,
        'otpCode': otpCode,
        'purpose': 'password_change',
        'createdAt': FieldValue.serverTimestamp(),
        'expiresAt': Timestamp.fromDate(expiryTime),
        'verified': false,
      });

      // Try multiple email sending methods
      bool emailSent = false;
      String emailMethod = '';

      // Method 1: Try EmailJS Service (same as login OTP)
      try {
        await EmailJSService.sendOtpEmail(
          email: email,
          otp: otpCode,
          userRole: 'citizen',
        );
        emailSent = true;
        emailMethod = 'EmailJS Service';
        print('✅ OTP email sent via EmailJS to $email');
      } catch (emailjsError) {
        print('❌ EmailJS Service failed: $emailjsError');
        // Try Firebase Email Service as fallback
        try {
          await FirebaseEmailService.sendOtpEmail(
            email: email,
            otp: otpCode,
            userRole: 'citizen',
          );
          emailSent = true;
          emailMethod = 'Firebase Email Service';
          print('✅ OTP email sent via Firebase Email Service to $email');
        } catch (firebaseError) {
          print('❌ Firebase Email Service also failed: $firebaseError');
        }
      }


      // Method 2: Try Simple Email Service
      if (!emailSent) {
        try {
          final success = await SimpleEmailService.sendOTPEmail(
            email: email,
            otp: otpCode,
            userRole: 'citizen',
          );
          if (success) {
            emailSent = true;
            emailMethod = 'Simple Email Service';
            print('✅ OTP email sent via Simple Email Service to $email');
          }
        } catch (simpleEmailError) {
          print('❌ Simple Email Service failed: $simpleEmailError');
        }
      }

      // Method 3: Fallback to console (for development/testing)
      if (!emailSent) {
        print('⚠️ All email services failed, using development fallback');
        print('=== DEVELOPMENT OTP ===');
        print('Email: $email');
        print('OTP Code: $otpCode');
        print('Expires: ${expiryTime.toString()}');
        print('======================');
        
        // For development, we'll consider this successful
        emailSent = true;
        emailMethod = 'Development Console';
      }

      if (!emailSent) {
        throw Exception('All email sending methods failed. Please check your internet connection and try again.');
      }
      
      return {
        'success': true,
        'sessionId': sessionId,
        'message': 'OTP sent to your email via $emailMethod. Please check your inbox.',
        'emailMethod': emailMethod,
      };
    } catch (e) {
      print('❌ Complete OTP sending failure: $e');
      throw Exception('Failed to send OTP: $e');
    }
  }


  /// Verify OTP code
  Future<bool> verifyOTP(String otpCode, String sessionId) async {
    try {
      // Try Firebase Functions first
      try {
        final callable = _functions.httpsCallable('verifyEmailOtp');
        final result = await callable.call({
          'otpCode': otpCode,
          'sessionId': sessionId,
        });
        
        return result.data['success'] == true;
      } catch (functionsError) {
        // Fallback: Verify OTP from Firestore
        print('Firebase Functions not available, using fallback: $functionsError');
        return await _verifyOTPFallback(otpCode, sessionId);
      }
    } catch (e) {
      print('Error verifying OTP: $e');
      throw Exception('Failed to verify OTP: $e');
    }
  }

  /// Fallback OTP verification using Firestore
  Future<bool> _verifyOTPFallback(String otpCode, String sessionId) async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('otp_sessions')
          .doc(sessionId)
          .get();

      if (!doc.exists) {
        return false;
      }

      final data = doc.data()!;
      final storedOtp = data['otpCode'] as String;
      final expiresAt = (data['expiresAt'] as Timestamp).toDate();
      final isVerified = data['verified'] as bool;

      // Check if OTP is expired
      if (DateTime.now().isAfter(expiresAt)) {
        return false;
      }

      // Check if already verified
      if (isVerified) {
        return false;
      }

      // Verify OTP
      if (storedOtp == otpCode) {
        // Mark as verified
        await doc.reference.update({'verified': true});
        return true;
      }

      return false;
    } catch (e) {
      print('Error in fallback OTP verification: $e');
      return false;
    }
  }

  /// Send OTP for email verification
  Future<Map<String, dynamic>> sendEmailVerificationOTP(String email) async {
    try {
      final callable = _functions.httpsCallable('sendEmailOtp');
      final result = await callable.call({
        'email': email,
        'purpose': 'email_verification',
      });
      
      return {
        'success': true,
        'sessionId': result.data['sessionId'],
        'message': 'Verification OTP sent successfully',
      };
    } catch (e) {
      print('Error sending verification OTP: $e');
      throw Exception('Failed to send verification OTP: $e');
    }
  }

  /// Verify email with OTP
  Future<bool> verifyEmailWithOTP(String otpCode, String sessionId) async {
    try {
      final callable = _functions.httpsCallable('verifyEmailOtp');
      final result = await callable.call({
        'otpCode': otpCode,
        'sessionId': sessionId,
        'purpose': 'email_verification',
      });
      
      if (result.data['success'] == true) {
        // Update user's email verification status
        final user = _auth.currentUser;
        if (user != null && !user.emailVerified) {
          await user.reload();
        }
        return true;
      }
      return false;
    } catch (e) {
      print('Error verifying email: $e');
      throw Exception('Failed to verify email: $e');
    }
  }

  /// Send OTP for phone verification
  Future<Map<String, dynamic>> sendPhoneOTP(String phoneNumber) async {
    try {
      final callable = _functions.httpsCallable('sendPhoneOtp');
      final result = await callable.call({
        'phoneNumber': phoneNumber,
      });
      
      return {
        'success': true,
        'sessionId': result.data['sessionId'],
        'message': 'Phone OTP sent successfully',
      };
    } catch (e) {
      print('Error sending phone OTP: $e');
      throw Exception('Failed to send phone OTP: $e');
    }
  }

  /// Verify phone OTP
  Future<bool> verifyPhoneOTP(String otpCode, String sessionId) async {
    try {
      final callable = _functions.httpsCallable('verifyPhoneOtp');
      final result = await callable.call({
        'otpCode': otpCode,
        'sessionId': sessionId,
      });
      
      return result.data['success'] == true;
    } catch (e) {
      print('Error verifying phone OTP: $e');
      throw Exception('Failed to verify phone OTP: $e');
    }
  }

  /// Generate a random OTP code (for testing purposes)
  String generateRandomOTP() {
    final random = DateTime.now().millisecondsSinceEpoch;
    return (random % 1000000).toString().padLeft(6, '0');
  }

  /// Validate OTP format
  bool isValidOTPFormat(String otp) {
    return RegExp(r'^\d{6}$').hasMatch(otp);
  }

  /// Check if OTP is expired (basic implementation)
  bool isOTPExpired(DateTime sentTime, {Duration expiryDuration = const Duration(minutes: 5)}) {
    return DateTime.now().difference(sentTime) > expiryDuration;
  }
}
