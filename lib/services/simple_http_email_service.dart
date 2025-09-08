import 'package:http/http.dart' as http;
import 'dart:convert';

class SimpleHttpEmailService {
  // Using a free email service API (like EmailJS but via HTTP)
  // This will work immediately without Firebase Functions setup
  
  static const String _emailApiUrl = 'https://api.emailjs.com/api/v1.0/email/send';
  static const String _serviceId = 'service_ak9qh9c';
  static const String _templateId = 'template_3cibf9m';
  static const String _userId = 'DKNJap6dcaU7Dy1A9';

  /// Send OTP email using HTTP API
  static Future<void> sendOtpEmail({
    required String email,
    required String otp,
    required String userRole,
  }) async {
    try {
      print('📧 Sending OTP email to $email via HTTP API...');
      
      final response = await http.post(
        Uri.parse(_emailApiUrl),
        headers: {
          'Content-Type': 'application/json',
        },
        body: json.encode({
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
        }),
      );

      print('📊 Response status: ${response.statusCode}');
      print('📊 Response body: ${response.body}');
      
      if (response.statusCode == 200) {
        print('✅ HTTP API: OTP email sent successfully to $email');
      } else {
        print('❌ HTTP API: Failed to send OTP email. Status: ${response.statusCode}');
        throw Exception('Failed to send OTP email via HTTP API');
      }
    } catch (e) {
      print('❌ HTTP API: Error sending OTP email: $e');
      rethrow;
    }
  }
}
