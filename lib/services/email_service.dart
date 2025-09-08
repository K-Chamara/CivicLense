import 'package:http/http.dart' as http;
import 'dart:convert';

class EmailService {
  // EmailJS Configuration
  // You'll need to sign up at https://www.emailjs.com/ and get these values
  static const String _serviceId = 'service_ak9qh9c';
  static const String _templateId = 'template_3cibf9m';
  static const String _userId = 'DKNJap6dcaU7Dy1A9';
  
  // EmailJS API endpoint
  static const String _emailJsUrl = 'https://api.emailjs.com/api/v1.0/email/send';

  /// Send OTP email using EmailJS
  static Future<void> sendOtpEmail({
    required String email,
    required String otp,
    required String userRole,
  }) async {
    try {
      print('📧 Sending OTP email to $email via EmailJS...');
      print('🔧 Service ID: $_serviceId');
      print('🔧 Template ID: $_templateId');
      print('🔧 User ID: $_userId');
      
      final requestBody = {
        'service_id': _serviceId,
        'template_id': _templateId,
        'user_id': _userId,
        'template_params': {
          'to_email': email,
          'otp_code': otp,
          'user_role': userRole,
          'app_name': 'Civic Lense',
          'expiry_time': '10 minutes',
        },
      };
      
      print('📤 Request body: ${json.encode(requestBody)}');
      
      final response = await http.post(
        Uri.parse(_emailJsUrl),
        headers: {
          'Content-Type': 'application/json',
        },
        body: json.encode(requestBody),
      );

      print('📊 Response status: ${response.statusCode}');
      print('📊 Response body: ${response.body}');
      
      if (response.statusCode == 200) {
        print('✅ EmailJS: OTP email sent successfully to $email');
      } else {
        print('❌ EmailJS: Failed to send OTP email. Status: ${response.statusCode}');
        print('❌ EmailJS: Response body: ${response.body}');
        throw Exception('Failed to send OTP email via EmailJS');
      }
    } catch (e) {
      print('❌ EmailJS: Error sending OTP email: $e');
      rethrow;
    }
  }

  /// Check if EmailJS is configured
  static bool isConfigured() {
    return _serviceId != 'YOUR_EMAILJS_SERVICE_ID' &&
           _templateId != 'YOUR_EMAILJS_TEMPLATE_ID' &&
           _userId != 'YOUR_EMAILJS_USER_ID';
  }
}
