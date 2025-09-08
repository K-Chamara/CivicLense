import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/government_auth_service.dart';
import '../models/user_role.dart';
import '../main.dart';

class GovernmentOtpVerificationScreen extends StatefulWidget {
  final String email;
  final UserRole userRole;
  final bool isLogin;
  final String? password; // Only for registration
  final String? firstName; // Only for registration
  final String? lastName; // Only for registration

  const GovernmentOtpVerificationScreen({
    super.key,
    required this.email,
    required this.userRole,
    required this.isLogin,
    this.password,
    this.firstName,
    this.lastName,
  });

  @override
  State<GovernmentOtpVerificationScreen> createState() => _GovernmentOtpVerificationScreenState();
}

class _GovernmentOtpVerificationScreenState extends State<GovernmentOtpVerificationScreen> {
  final GovernmentAuthService _authService = GovernmentAuthService();
  final TextEditingController _emailOtpController = TextEditingController();
  final FocusNode _emailOtpFocus = FocusNode();

  bool _isLoading = false;
  bool _emailOtpSent = false;
  int _emailResendCountdown = 0;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _sendInitialOtps();
  }

  @override
  void dispose() {
    _emailOtpController.dispose();
    _emailOtpFocus.dispose();
    super.dispose();
  }

  Future<void> _sendInitialOtps() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Send email OTP
      await _authService.sendEmailOtp(widget.email, widget.userRole);
      setState(() {
        _emailOtpSent = true;
        _emailResendCountdown = 60;
      });
      _startEmailCountdown();

      _showSuccessMessage('OTP code sent to your email');
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to send OTP code: ${e.toString()}';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _startEmailCountdown() {
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted && _emailResendCountdown > 0) {
        setState(() {
          _emailResendCountdown--;
        });
        _startEmailCountdown();
      }
    });
  }


  Future<void> _resendEmailOtp() async {
    if (_emailResendCountdown > 0) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await _authService.resendEmailOtp(widget.email, widget.userRole);
      setState(() {
        _emailResendCountdown = 60;
      });
      _startEmailCountdown();
      _showSuccessMessage('Email OTP resent successfully');
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to resend email OTP: ${e.toString()}';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }


  Future<void> _verifyOtps() async {
    if (_emailOtpController.text.length != 4) {
      setState(() {
        _errorMessage = 'Please enter a valid 4-digit OTP code';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      if (widget.isLogin) {
        // Login flow
        await _authService.governmentUserLogin(
          email: widget.email,
          password: widget.password!,
          emailOtp: _emailOtpController.text,
        );
      } else {
        // Registration flow
        await _authService.completeGovernmentUserRegistration(
          email: widget.email,
          password: widget.password!,
          firstName: widget.firstName!,
          lastName: widget.lastName!,
          role: widget.userRole,
          emailOtp: _emailOtpController.text,
        );
      }

      _showSuccessMessage('Verification successful! Welcome ${widget.userRole.name}');
      
      // Navigate to appropriate dashboard
      _navigateToDashboard();
    } catch (e) {
      setState(() {
        _errorMessage = 'Verification failed: ${e.toString()}';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _navigateToDashboard() {
    // Navigation will be handled by the main app's AuthWrapper
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (context) => const AuthWrapper(),
      ),
    );
  }

  void _showSuccessMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        // Handle back button press
        if (widget.isLogin) {
          // For login, go back to login screen
          Navigator.of(context).pushReplacementNamed('/login');
        } else {
          // For registration, go back to registration screen
          Navigator.of(context).pop();
        }
        return false; // Prevent default back behavior
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text('${widget.userRole.name} Verification'),
          backgroundColor: widget.userRole.color,
          foregroundColor: Colors.white,
          elevation: 0,
        ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              widget.userRole.color.withOpacity(0.1),
              Colors.white,
            ],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: widget.userRole.color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: widget.userRole.color.withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: Column(
                    children: [
                      Icon(
                        widget.userRole.icon,
                        size: 48,
                        color: widget.userRole.color,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Government User Verification',
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: widget.userRole.color,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Please verify your identity using the OTP code sent to your registered email address.',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.grey[600],
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 32),

                // Email OTP Section
                _buildOtpSection(
                  title: 'Email Verification',
                  subtitle: 'Enter the 4-digit code sent to\n${widget.email}',
                  controller: _emailOtpController,
                  focusNode: _emailOtpFocus,
                  maxLength: 4,
                  isSent: _emailOtpSent,
                  resendCountdown: _emailResendCountdown,
                  onResend: _resendEmailOtp,
                  icon: Icons.email,
                  color: Colors.blue,
                ),

                const SizedBox(height: 32),

                // Error Message
                if (_errorMessage != null)
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.red.withOpacity(0.3)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.error, color: Colors.red, size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _errorMessage!,
                            style: const TextStyle(color: Colors.red),
                          ),
                        ),
                      ],
                    ),
                  ),

                const SizedBox(height: 24),

                // Verify Button
                ElevatedButton(
                  onPressed: _isLoading ? null : _verifyOtps,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: widget.userRole.color,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 2,
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
                      : Text(
                          'Verify & ${widget.isLogin ? 'Login' : 'Complete Registration'}',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),

                const SizedBox(height: 16),

                // Back Button
                TextButton(
                  onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
                  child: Text(
                    'Back to ${widget.isLogin ? 'Login' : 'Registration'}',
                    style: TextStyle(
                      color: widget.userRole.color,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
    );
  }

  Widget _buildOtpSection({
    required String title,
    required String subtitle,
    required TextEditingController controller,
    required FocusNode focusNode,
    required int maxLength,
    required bool isSent,
    required int resendCountdown,
    required VoidCallback onResend,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.withOpacity(0.3)),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 24),
              const SizedBox(width: 8),
              Text(
                title,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              const Spacer(),
              if (isSent)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    'Sent',
                    style: TextStyle(
                      color: Colors.green,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: controller,
            focusNode: focusNode,
            keyboardType: TextInputType.number,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(maxLength),
            ],
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              letterSpacing: 8,
            ),
            decoration: InputDecoration(
              hintText: '0' * maxLength,
              hintStyle: TextStyle(
                color: Colors.grey.withOpacity(0.3),
                letterSpacing: 8,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: color.withOpacity(0.5)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: color, width: 2),
              ),
              contentPadding: const EdgeInsets.symmetric(vertical: 16),
            ),
            onChanged: (value) {
              if (value.length == maxLength) {
                // Auto-submit when OTP is complete
                _verifyOtps();
              }
            },
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Didn\'t receive the code?',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.grey[600],
                ),
              ),
              TextButton(
                onPressed: resendCountdown > 0 ? null : onResend,
                child: Text(
                  resendCountdown > 0
                      ? 'Resend in ${resendCountdown}s'
                      : 'Resend Code',
                  style: TextStyle(
                    color: resendCountdown > 0 ? Colors.grey : color,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
