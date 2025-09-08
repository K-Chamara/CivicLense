import 'package:http/http.dart' as http;
import 'dart:convert';

class GmailSmtpService {
  // Gmail SMTP Configuration
  // You'll need to generate an App Password from your Google Account
  static const String _smtpHost = 'smtp.gmail.com';
  static const int _smtpPort = 587;
  static const String _smtpUsername = 'YOUR_GMAIL_EMAIL@gmail.com';
  static const String _smtpPassword = 'YOUR_GMAIL_APP_PASSWORD'; // Use App Password, not regular password
  
  // This would typically be a backend endpoint that handles SMTP
  // For now, this is a placeholder structure
  static const String _backendUrl = 'YOUR_BACKEND_EMAIL_ENDPOINT';

  /// Send OTP email using Gmail SMTP (via backend)
  static Future<void> sendOtpEmail({
    required String toEmail,
    required String otp,
    required String userRole,
  }) async {
    try {
      print('📧 Sending OTP email to $toEmail via Gmail SMTP...');
      
      // This would be an HTTP call to your backend server
      // which then uses a library like Nodemailer to send the email
      final response = await http.post(
        Uri.parse(_backendUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer YOUR_API_KEY', // If you have API authentication
        },
        body: json.encode({
          'toEmail': toEmail,
          'otp': otp,
          'userRole': userRole,
          'subject': 'Your Civic Lense OTP for $userRole Verification',
          'htmlBody': _generateEmailHtml(otp, userRole),
          'smtpConfig': {
            'host': _smtpHost,
            'port': _smtpPort,
            'username': _smtpUsername,
            'password': _smtpPassword,
          },
        }),
      );

      if (response.statusCode == 200) {
        print('✅ Gmail SMTP: OTP email sent successfully to $toEmail');
      } else {
        print('❌ Gmail SMTP: Failed to send OTP email. Status: ${response.statusCode}');
        print('❌ Gmail SMTP: Response body: ${response.body}');
        throw Exception('Failed to send OTP email via Gmail SMTP');
      }
    } catch (e) {
      print('❌ Gmail SMTP: Error sending OTP email: $e');
      rethrow;
    }
  }

  /// Generate HTML email body
  static String _generateEmailHtml(String otp, String userRole) {
    return '''
    <!DOCTYPE html>
    <html>
    <head>
        <meta charset="utf-8">
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        <title>Civic Lense OTP</title>
        <style>
            body { font-family: Arial, sans-serif; line-height: 1.6; color: #333; }
            .container { max-width: 600px; margin: 0 auto; padding: 20px; }
            .header { background: #007bff; color: white; padding: 20px; text-align: center; }
            .content { padding: 20px; background: #f9f9f9; }
            .otp-code { font-size: 32px; font-weight: bold; color: #007bff; text-align: center; margin: 20px 0; padding: 20px; background: white; border-radius: 8px; }
            .footer { padding: 20px; text-align: center; color: #666; font-size: 14px; }
            .warning { background: #fff3cd; border: 1px solid #ffeaa7; padding: 15px; border-radius: 5px; margin: 15px 0; }
        </style>
    </head>
    <body>
        <div class="container">
            <div class="header">
                <h1>🔐 Civic Lense OTP Verification</h1>
            </div>
            <div class="content">
                <h2>Dear $userRole User,</h2>
                <p>Your One-Time Password (OTP) for Civic Lense verification is:</p>
                
                <div class="otp-code">$otp</div>
                
                <div class="warning">
                    <strong>⚠️ Important Security Information:</strong>
                    <ul>
                        <li>This OTP is valid for <strong>10 minutes</strong></li>
                        <li>Do not share this code with anyone</li>
                        <li>If you didn't request this verification, please ignore this email</li>
                    </ul>
                </div>
                
                <p>Thank you for using Civic Lense!</p>
            </div>
            <div class="footer">
                <p>This is an automated message from Civic Lense.<br>
                Please do not reply to this email.</p>
            </div>
        </div>
    </body>
    </html>
    ''';
  }

  /// Check if Gmail SMTP is configured
  static bool isConfigured() {
    return _smtpUsername != 'YOUR_GMAIL_EMAIL@gmail.com' &&
           _smtpPassword != 'YOUR_GMAIL_APP_PASSWORD' &&
           _backendUrl != 'YOUR_BACKEND_EMAIL_ENDPOINT';
  }
}
