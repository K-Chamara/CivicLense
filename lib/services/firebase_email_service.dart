import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_core/firebase_core.dart';

class FirebaseEmailService {
  static final FirebaseFunctions _functions = FirebaseFunctions.instance;

  /// Send OTP email using Firebase Functions
  static Future<void> sendOtpEmail({
    required String email,
    required String otp,
    required String userRole,
  }) async {
    try {
      print('📧 Sending OTP email to $email via Firebase Functions...');
      
      final callable = _functions.httpsCallable('sendEmailOtp');
      
      final result = await callable.call({
        'email': email,
        'otp': otp,
        'userRole': userRole,
      });

      if (result.data['success'] == true) {
        print('✅ Firebase Functions: OTP email sent successfully to $email');
        print('🆔 Verification ID: ${result.data['verificationId']}');
      } else {
        print('❌ Firebase Functions: Failed to send OTP email');
        throw Exception('Failed to send OTP email via Firebase Functions');
      }
    } catch (e) {
      print('❌ Firebase Functions: Error sending OTP email: $e');
      rethrow;
    }
  }

  /// Verify OTP using Firebase Functions
  static Future<bool> verifyOtp({
    required String verificationId,
    required String otp,
  }) async {
    try {
      print('🔍 Verifying OTP via Firebase Functions...');
      
      final callable = _functions.httpsCallable('verifyEmailOtp');
      
      final result = await callable.call({
        'verificationId': verificationId,
        'otp': otp,
      });

      if (result.data['success'] == true) {
        print('✅ Firebase Functions: OTP verified successfully');
        return true;
      } else {
        print('❌ Firebase Functions: OTP verification failed');
        return false;
      }
    } catch (e) {
      print('❌ Firebase Functions: Error verifying OTP: $e');
      return false;
    }
  }
}
