import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';
import '../services/admin_service.dart';
import 'dart:async'; // Added for Timer
import 'dart:math'; // Added for Random

class OtpScreen extends StatefulWidget {
  final String email;
  final String password;

  const OtpScreen({
    super.key,
    required this.email,
    required this.password,
  });

  @override
  State<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen> {
  final TextEditingController _otpController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  bool _isResending = false;
  int _resendCountdown = 60;

  @override
  void initState() {
    super.initState();
    _startResendCountdown();
  }

  void _startResendCountdown() {
    setState(() {
      _resendCountdown = 60;
    });
    
    Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          if (_resendCountdown > 0) {
            _resendCountdown--;
          } else {
            timer.cancel();
          }
        });
      } else {
        timer.cancel();
      }
    });
  }

  @override
  void dispose() {
    _otpController.dispose();
    super.dispose();
  }

  Future<void> _verifyOtp() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final otp = _otpController.text.trim();
      
      // Get OTP from Firestore
      final otpDoc = await FirebaseFirestore.instance
          .collection('otp')
          .doc(widget.email)
          .get();

      if (!otpDoc.exists) {
        throw Exception('OTP not found. Please request a new one.');
      }

      final otpData = otpDoc.data()!;
      final storedOtp = otpData['otp'] as String;
      final expiresAt = (otpData['expiresAt'] as Timestamp).toDate();

      // Check if OTP is expired
      if (DateTime.now().isAfter(expiresAt)) {
        throw Exception('OTP has expired. Please request a new one.');
      }

      // Verify OTP
      if (otp != storedOtp) {
        throw Exception('Invalid OTP. Please try again.');
      }

      // OTP is valid, proceed with login
      final authService = AuthService();
      await authService.signInWithEmailAndPassword(widget.email, widget.password);

      // Delete the used OTP
      await FirebaseFirestore.instance
          .collection('otp')
          .doc(widget.email)
          .delete();

      if (mounted) {
        // Navigate to appropriate dashboard
        Navigator.of(context).pushReplacementNamed('/');
      }

    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _resendOtp() async {
    setState(() {
      _isResending = true;
    });

    try {
      // Generate new OTP
      final otp = _generateOtp();
      
      // Store OTP in Firestore with 5-minute expiration
      await FirebaseFirestore.instance
          .collection('otp')
          .doc(widget.email)
          .set({
        'otp': otp,
        'expiresAt': Timestamp.fromDate(
          DateTime.now().add(const Duration(minutes: 5)),
        ),
        'createdAt': FieldValue.serverTimestamp(),
      });

      // Send OTP email (placeholder for now)
      print('📧 Sending OTP to ${widget.email}: $otp');
      // TODO: Implement actual email sending

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('New OTP sent to your email'),
            backgroundColor: Colors.green,
          ),
        );
        
        _startResendCountdown();
      }

    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error sending OTP: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isResending = false;
        });
      }
    }
  }

  String _generateOtp() {
    final random = Random();
    return (1000 + random.nextInt(9000)).toString(); // 4-digit OTP
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Enter OTP'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Icon(
                Icons.security,
                size: 80,
                color: Colors.blue,
              ),
              const SizedBox(height: 24),
              const Text(
                'Two-Factor Authentication',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Text(
                'A 4-digit verification code has been sent to:\n${widget.email}',
                style: const TextStyle(
                  fontSize: 16,
                  color: Colors.grey,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              TextFormField(
                controller: _otpController,
                keyboardType: TextInputType.number,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 8,
                ),
                decoration: const InputDecoration(
                  labelText: 'Enter 4-digit OTP',
                  border: OutlineInputBorder(),
                  counterText: '',
                ),
                maxLength: 4,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter the OTP';
                  }
                  if (value.length != 4) {
                    return 'OTP must be 4 digits';
                  }
                  if (!RegExp(r'^\d{4}$').hasMatch(value)) {
                    return 'OTP must contain only numbers';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _isLoading ? null : _verifyOtp,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Text(
                        'Verify OTP',
                        style: TextStyle(fontSize: 16),
                      ),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    "Didn't receive the code? ",
                    style: TextStyle(color: Colors.grey),
                  ),
                  if (_resendCountdown > 0)
                    Text(
                      'Resend in $_resendCountdown seconds',
                      style: const TextStyle(
                        color: Colors.grey,
                        fontWeight: FontWeight.bold,
                      ),
                    )
                  else
                    TextButton(
                      onPressed: _isResending ? null : _resendOtp,
                      child: _isResending
                          ? const SizedBox(
                              height: 16,
                              width: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text(
                              'Resend OTP',
                              style: TextStyle(
                                color: Colors.blue,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                ],
              ),
              const SizedBox(height: 32),
              TextButton(
                onPressed: () {
                  Navigator.of(context).pushReplacementNamed('/login');
                },
                child: const Text(
                  'Back to Login',
                  style: TextStyle(color: Colors.grey),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
