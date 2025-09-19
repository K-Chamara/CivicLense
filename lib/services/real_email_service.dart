import 'package:http/http.dart' as http;
import 'dart:convert';

class RealEmailService {
  // Using SendGrid API (free tier: 100 emails/day)
  // This will actually send real emails to the user
  
  static const String _sendGridApiKey = 'SG.your-api-key-here'; // You'll need to get this
  static const String _sendGridUrl = 'https://api.sendgrid.com/v3/mail/send';
  
  /// Send OTP email using SendGrid API
  static Future<void> sendOtpEmail({
    required String email,
    required String otp,
    required String userRole,
  }) async {
    try {
      print('📧 Sending OTP email to $email via SendGrid...');
      
      final response = await http.post(
        Uri.parse(_sendGridUrl),
        headers: {
          'Authorization': 'Bearer $_sendGridApiKey',
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'personalizations': [
            {
              'to': [
                {'email': email}
              ],
              'subject': 'Your Civic Lense OTP for ${userRole} Verification'
            }
          ],
          'from': {
            'email': 'noreply@civiclense.com',
            'name': 'Civic Lense'
          },
          'content': [
            {
              'type': 'text/html',
              'value': '''
                <div style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto;">
                  <h2 style="color: #007bff;">Civic Lense - OTP Verification</h2>
                  <p>Dear ${userRole} User,</p>
                  <p>Your One-Time Password (OTP) for Civic Lense verification is:</p>
                  <div style="background-color: #f8f9fa; padding: 20px; text-align: center; margin: 20px 0;">
                    <h1 style="color: #007bff; font-size: 32px; margin: 0;">$otp</h1>
                  </div>
                  <p>This OTP is valid for 10 minutes. Please do not share this code with anyone.</p>
                  <p>If you did not request this, please ignore this email.</p>
                  <hr style="margin: 20px 0;">
                  <p style="color: #6c757d; font-size: 12px;">
                    Thank you,<br>
                    The Civic Lense Team
                  </p>
                </div>
              '''
            }
          ]
        }),
      );

      print('📊 SendGrid response status: ${response.statusCode}');
      print('📊 SendGrid response body: ${response.body}');
      
      if (response.statusCode == 202) {
        print('✅ SendGrid: OTP email sent successfully to $email');
      } else {
        print('❌ SendGrid: Failed to send OTP email. Status: ${response.statusCode}');
        throw Exception('Failed to send OTP email via SendGrid');
      }
    } catch (e) {
      print('❌ SendGrid: Error sending OTP email: $e');
      rethrow;
    }
  }
}
