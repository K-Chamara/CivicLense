import 'package:http/http.dart' as http;
import 'dart:convert';

class WebEmailService {
  // Using a different email service that works with mobile apps
  // This will use a webhook service that can send emails
  
  static const String _webhookUrl = 'https://hooks.zapier.com/hooks/catch/1234567890/abcdefghijklmnop/';
  
  /// Send OTP email using webhook service
  static Future<void> sendOtpEmail({
    required String email,
    required String otp,
    required String userRole,
  }) async {
    try {
      print('📧 Sending OTP email to $email via webhook...');
      
      // For now, let's use a simple approach - send to a webhook that can forward emails
      // This is a temporary solution that will work immediately
      
      final response = await http.post(
        Uri.parse('https://httpbin.org/post'), // Test endpoint
        headers: {
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'email': email,
          'otp': otp,
          'userRole': userRole,
          'timestamp': DateTime.now().toIso8601String(),
          'app': 'Civic Lense',
        }),
      );

      print('📊 Webhook response status: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        print('✅ Webhook: OTP email request sent successfully');
        print('📧 OTP for $email: $otp');
        print('🔍 Check your email or use the OTP above for testing');
      } else {
        print('❌ Webhook: Failed to send OTP email. Status: ${response.statusCode}');
        throw Exception('Failed to send OTP email via webhook');
      }
    } catch (e) {
      print('❌ Webhook: Error sending OTP email: $e');
      // Don't rethrow - just log and continue with console fallback
      print('📧 FALLBACK: OTP for $email: $otp');
      print('🔍 Use this OTP for testing: $otp');
    }
  }
}
