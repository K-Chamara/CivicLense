import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:async';
import 'login_screen.dart';
import 'document_upload_screen.dart';
import '../widgets/custom_button.dart';

class EmailVerificationScreen extends StatefulWidget {
  final String email;
  final String? userRole;
  final String? userId;

  const EmailVerificationScreen({
    super.key,
    required this.email,
    this.userRole,
    this.userId,
  });

  @override
  State<EmailVerificationScreen> createState() => _EmailVerificationScreenState();
}

class _EmailVerificationScreenState extends State<EmailVerificationScreen> {
  bool isEmailVerified = false;
  bool canResendEmail = false;
  Timer? timer;

  @override
  void initState() {
    super.initState();
    
    // Check if email is verified
    isEmailVerified = FirebaseAuth.instance.currentUser?.emailVerified ?? false;

    if (!isEmailVerified) {
      sendVerificationEmail();

      timer = Timer.periodic(
        const Duration(seconds: 3),
        (_) => checkEmailVerified(),
      );
    }
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  Future<void> checkEmailVerified() async {
    await FirebaseAuth.instance.currentUser?.reload();

    setState(() {
      isEmailVerified = FirebaseAuth.instance.currentUser?.emailVerified ?? false;
    });

    if (isEmailVerified) {
      timer?.cancel();
      
      // Update email verification status in Firestore
      if (widget.userId != null) {
        try {
          await FirebaseFirestore.instance
              .collection('users')
              .doc(widget.userId!)
              .update({
            'emailVerified': true,
          });
          print('✅ Updated email verification status in Firestore');
        } catch (e) {
          print('❌ Error updating email verification status: $e');
        }
      }
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Email verified successfully! You can now sign in.'),
            backgroundColor: Colors.green,
          ),
        );
        
        // Navigate based on user role after email verification
        if (widget.userRole != null && widget.userRole != 'citizen' && widget.userId != null) {
          // Non-citizen users go to document upload
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (context) => DocumentUploadScreen(
                userRole: widget.userRole!,
                userId: widget.userId!,
              ),
            ),
          );
        } else {
          // Citizen users go to login
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (context) => const LoginScreen(),
            ),
          );
        }
      }
    }
  }

  Future<void> sendVerificationEmail() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      await user?.sendEmailVerification();

      setState(() {
        canResendEmail = false;
      });

      await Future.delayed(const Duration(seconds: 60));
      setState(() {
        canResendEmail = true;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Email Verification'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Success Icon
            const Icon(
              Icons.mark_email_read,
              size: 100,
              color: Colors.green,
            ),
            const SizedBox(height: 32),

            // Title
            const Text(
              'Verify Your Email',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.blue,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),

            // Description
            Text(
              'We\'ve sent a verification email to:',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey.shade600,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),

            // Email
            Text(
              widget.email,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.blue,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),

            // Instructions
            const Text(
              'Please check your email and click the verification link to complete your registration.',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),

            // Resend Email Button
            if (!isEmailVerified)
              Column(
                children: [
                  CustomButton(
                    onPressed: canResendEmail ? sendVerificationEmail : null,
                    text: canResendEmail 
                        ? 'Resend Email' 
                        : 'Resend Email (${60 - (DateTime.now().millisecondsSinceEpoch % 60000 / 1000).round()}s)',
                    isLoading: false,
                  ),
                  const SizedBox(height: 16),
                ],
              ),

            // Continue Button
            CustomButton(
              onPressed: () {
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(
                    builder: (context) => const LoginScreen(),
                  ),
                );
              },
              text: 'Continue to Sign In',
              isLoading: false,
            ),
            const SizedBox(height: 16),

            // Back to Login
            TextButton(
              onPressed: () {
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(
                    builder: (context) => const LoginScreen(),
                  ),
                );
              },
              child: const Text(
                'Back to Sign In',
                style: TextStyle(
                  color: Colors.blue,
                  fontSize: 16,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}


