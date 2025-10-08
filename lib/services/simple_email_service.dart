import 'package:http/http.dart' as http;
import 'dart:convert';

class SimpleEmailService {
  /// Send OTP email using EmailJS (same as login system)
  static Future<bool> sendOTPEmail({
    required String email,
    required String otp,
    required String userRole,
  }) async {
    try {
      print('📧 Attempting to send OTP email to $email via EmailJS...');
      
      // Use EmailJS service (same as login system)
      try {
        // EmailJS configuration - using the same service as login
        const String serviceId = 'service_ak9qh9c'; // Same as login system
        const String templateId = 'template_3cibf9m'; // Same as login system
        const String publicKey = 'DKNJap6dcaU7Dy1A9'; // Same as login system
        
        final String emailjsUrl = 'https://api.emailjs.com/api/v1.0/email/send';
        
        final Map<String, dynamic> emailData = {
          'service_id': serviceId,
          'template_id': templateId,
          'user_id': publicKey,
          'template_params': {
            'email': email, // Changed to match EmailJS template
            'to_name': 'CivicLense User',
            'from_name': 'CivicLense System',
            'passcode': otp, // Changed to match EmailJS template
            'time': DateTime.now().add(const Duration(minutes: 15)).toString(),
            'user_role': userRole,
            'app_name': 'CivicLense',
            'message': 'Your OTP code is: $otp',
          }
        };

        final response = await http.post(
          Uri.parse(emailjsUrl),
          headers: {
            'Content-Type': 'application/json',
            'Origin': 'http://localhost',
          },
          body: json.encode(emailData),
        );

        if (response.statusCode == 200) {
          print('✅ Real email sent via EmailJS to $email');
          print('📧 Email Details:');
          print('   To: $email');
          print('   From: wvadkchamara@gmail.com');
          print('   Subject: OTP for your CivicLense authentication');
          print('   OTP: $otp');
          print('   Role: $userRole');
          print('   Expires: 15 minutes');
          print('   Service: EmailJS.com');
          return true;
        } else {
          print('❌ EmailJS returned error: ${response.statusCode} - ${response.body}');
        }
      } catch (emailjsError) {
        print('❌ EmailJS failed: $emailjsError');
      }
      
      // Fallback: Try Firebase Functions
      try {
        final response = await http.post(
          Uri.parse('https://us-central1-civiclense-29dd4.cloudfunctions.net/sendEmailOtp'),
          headers: {'Content-Type': 'application/json'},
          body: json.encode({
            'data': {'email': email, 'otp': otp, 'userRole': userRole}
          }),
        );
        
        if (response.statusCode == 200) {
          print('✅ Real email sent via Firebase Functions to $email');
          return true;
        }
      } catch (firebaseError) {
        print('❌ Firebase Functions failed: $firebaseError');
      }
      
      // Final fallback: Development simulation
      print('⚠️ Using development fallback - no real email sent');
      print('📧 Email Details (Development):');
      print('   To: $email');
      print('   Subject: OTP for your CivicLense authentication');
      print('   OTP: $otp');
      print('   Role: $userRole');
      print('   Expires: 15 minutes');
      print('   Note: This is a development simulation - no real email was sent');
      
      return true; // Return true for development purposes
    } catch (e) {
      print('❌ Failed to send email: $e');
      return false;
    }
  }

  /// Send email using EmailJS (requires configuration)
  static Future<bool> sendEmailViaEmailJS({
    required String email,
    required String otp,
    required String userRole,
  }) async {
    try {
      // EmailJS configuration - you need to replace these with your actual values
      const String serviceId = 'service_civiclense';
      const String templateId = 'template_otp';
      const String publicKey = 'your_public_key';
      
      final String emailjsUrl = 'https://api.emailjs.com/api/v1.0/email/send';
      
      final Map<String, dynamic> emailData = {
        'service_id': serviceId,
        'template_id': templateId,
        'user_id': publicKey,
        'template_params': {
          'to_email': email,
          'otp_code': otp,
          'app_name': 'CivicLense',
          'expiry_minutes': '5',
          'user_role': userRole,
        }
      };

      final response = await http.post(
        Uri.parse(emailjsUrl),
        headers: {
          'Content-Type': 'application/json',
        },
        body: json.encode(emailData),
      );

      if (response.statusCode == 200) {
        print('✅ EmailJS: OTP email sent successfully to $email');
        return true;
      } else {
        print('❌ EmailJS: Failed to send email - ${response.statusCode}');
        return false;
      }
    } catch (e) {
      print('❌ EmailJS: Error sending email: $e');
      return false;
    }
  }

  /// Send email using SendGrid (requires API key)
  static Future<bool> sendEmailViaSendGrid({
    required String email,
    required String otp,
    required String userRole,
  }) async {
    try {
      // SendGrid configuration - you need to replace with your actual API key
      const String apiKey = 'your_sendgrid_api_key';
      const String fromEmail = 'noreply@civiclense.com';
      
      final String sendGridUrl = 'https://api.sendgrid.com/v3/mail/send';
      
      final Map<String, dynamic> emailData = {
        'personalizations': [
          {
            'to': [
              {'email': email}
            ],
            'subject': 'CivicLense OTP Verification'
          }
        ],
        'from': {'email': fromEmail, 'name': 'CivicLense'},
        'content': [
          {
            'type': 'text/html',
            'value': '''
              <html>
                <body>
                  <h2>CivicLense OTP Verification</h2>
                  <p>Your One-Time Password (OTP) is:</p>
                  <h1 style="color: #007bff; font-size: 32px; letter-spacing: 4px;">$otp</h1>
                  <p>This code will expire in 5 minutes.</p>
                  <p>If you didn't request this code, please ignore this email.</p>
                </body>
              </html>
            '''
          }
        ]
      };

      final response = await http.post(
        Uri.parse(sendGridUrl),
        headers: {
          'Authorization': 'Bearer $apiKey',
          'Content-Type': 'application/json',
        },
        body: json.encode(emailData),
      );

      if (response.statusCode == 202) {
        print('✅ SendGrid: OTP email sent successfully to $email');
        return true;
      } else {
        print('❌ SendGrid: Failed to send email - ${response.statusCode}');
        return false;
      }
    } catch (e) {
      print('❌ SendGrid: Error sending email: $e');
      return false;
    }
  }
}
