import 'package:http/http.dart' as http;
import 'dart:convert';

class EmailJSService {
  // EmailJS configuration
  static const String _serviceId = 'service_ak9qh9c'; // Your EmailJS Service ID
  static const String _templateId = 'template_3cibf9m'; // Your EmailJS Template ID
  static const String _publicKey = 'DKNJap6dcaU7Dy1A9'; // Your EmailJS Public Key
  static const String _emailjsUrl = 'https://api.emailjs.com/api/v1.0/email/send';

  /// Send OTP email using EmailJS via HTTP
  static Future<void> sendOtpEmail({
    required String email,
    required String otp,
    required String userRole,
  }) async {
    try {
      // Prepare the request body with correct EmailJS format
      final requestBody = {
        'service_id': _serviceId,
        'template_id': _templateId,
        'user_id': _publicKey,
        'template_params': {
          'email': email,  // Changed from 'to_email' to 'email' to match template
          'to_name': 'CivicLense User',
          'from_name': 'CivicLense System',
          'passcode': otp,  // Changed from 'otp' to 'passcode' to match template
          'time': DateTime.now().add(const Duration(minutes: 15)).toString(),
          'user_role': userRole,
          'app_name': 'CivicLense',
          'message': 'Your OTP code is: $otp',
        }
      };

      // Send HTTP request to EmailJS
      final response = await http.post(
        Uri.parse(_emailjsUrl),
        headers: {
          'Content-Type': 'application/json',
          'Origin': 'http://localhost',
        },
        body: json.encode(requestBody),
      );

      if (response.statusCode == 200) {
        print('✅ Email sent successfully via EmailJS to $email');
        print('📧 EmailJS Response: ${response.body}');
      } else {
        print('❌ EmailJS API Error Details:');
        print('   Status Code: ${response.statusCode}');
        print('   Response Body: ${response.body}');
        print('   Request Body: ${json.encode(requestBody)}');
        throw Exception('EmailJS API returned status code: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('❌ EmailJS failed: $e');
      // Fallback to console output
      print('📧 ===========================================');
      print('📧 CIVIC LENSE OTP VERIFICATION (FALLBACK)');
      print('📧 ===========================================');
      print('📧 Email: $email');
      print('📧 Role: $userRole');
      print('📧 OTP Code: $otp');
      print('📧 Valid for: 10 minutes');
      print('📧 ===========================================');
      print('📧 IMPORTANT: Use the OTP above for verification');
      print('📧 ===========================================');
      rethrow;
    }
  }

  /// Test EmailJS connection
  static Future<bool> testConnection() async {
    try {
      // Test with a simple request
      final response = await http.get(
        Uri.parse('https://api.emailjs.com/api/v1.0/email/send'),
        headers: {
          'Content-Type': 'application/json',
        },
      );
      print('✅ EmailJS connection test successful');
      return true;
    } catch (e) {
      print('❌ EmailJS connection failed: $e');
      return false;
    }
  }

  /// Test sending a sample OTP email
  static Future<void> testSendOtp() async {
    try {
      await sendOtpEmail(
        email: 'wvadkchamara@gmail.com',
        otp: '1234',
        userRole: 'Admin',
      );
      print('✅ Test email sent successfully!');
    } catch (e) {
      print('❌ Test email failed: $e');
    }
  }

  /// Test EmailJS with minimal parameters
  static Future<void> testMinimalEmail() async {
    try {
      final requestBody = {
        'service_id': _serviceId,
        'template_id': _templateId,
        'user_id': _publicKey,
        'template_params': {
          'email': 'wvadkchamara@gmail.com',  // Changed from 'to_email' to 'email'
          'to_name': 'Test User',
          'from_name': 'CivicLense System',
          'passcode': 'TEST123',  // Changed from 'otp' to 'passcode'
          'time': DateTime.now().add(const Duration(minutes: 15)).toString(),
          'user_role': 'Test',
          'app_name': 'CivicLense',
          'message': 'Your OTP code is: TEST123',
        }
      };

      final response = await http.post(
        Uri.parse(_emailjsUrl),
        headers: {
          'Content-Type': 'application/json',
          'Origin': 'http://localhost',
        },
        body: json.encode(requestBody),
      );

      print('📧 Test Response Status: ${response.statusCode}');
      print('📧 Test Response Body: ${response.body}');
      
      if (response.statusCode == 200) {
        print('✅ Minimal test email sent successfully!');
      } else {
        print('❌ Minimal test failed: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('❌ Minimal test error: $e');
    }
  }
}
