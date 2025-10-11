import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'signup_screen.dart';
import 'forgot_password_screen.dart';
import '../services/auth_service.dart';
import '../widgets/custom_button.dart';
import '../widgets/custom_text_field.dart';
import 'government_otp_verification_screen.dart';
import '../models/user_role.dart';
import '../main.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _auth = FirebaseAuth.instance;
  bool _rememberMe = false;
  bool _isLoading = false;
  bool _obscurePassword = true;

  @override
  void initState() {
    super.initState();
    _loadSavedCredentials();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _loadSavedCredentials() async {
    final prefs = await SharedPreferences.getInstance();
    final savedEmail = prefs.getString('saved_email');
    final savedPassword = prefs.getString('saved_password');
    final rememberMe = prefs.getBool('remember_me') ?? false;

    print('📥 Loading saved credentials...');
    print('   Remember Me: $rememberMe');
    print('   Saved Email: $savedEmail');
    print('   Has Password: ${savedPassword != null}');

    if (rememberMe && savedEmail != null && savedPassword != null) {
      print('✅ Loading saved credentials for: $savedEmail');
      setState(() {
        _emailController.text = savedEmail;
        _passwordController.text = savedPassword;
        _rememberMe = true;
      });
    } else {
      print('ℹ️ No saved credentials to load');
    }
  }

  Future<void> _saveCredentials() async {
    final prefs = await SharedPreferences.getInstance();
    if (_rememberMe) {
      print('💾 Saving credentials for: ${_emailController.text}');
      await prefs.setString('saved_email', _emailController.text.trim());
      await prefs.setString('saved_password', _passwordController.text);
      await prefs.setBool('remember_me', true);
      print('✅ Credentials saved successfully');
    } else {
      print('🗑️ Clearing saved credentials');
      await prefs.remove('saved_email');
      await prefs.remove('saved_password');
      await prefs.setBool('remember_me', false);
    }
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final email = _emailController.text.trim();
      final password = _passwordController.text;
      
      print('🔐 Login attempt for: $email');
      print('   Remember Me checked: $_rememberMe');

      // Check if this is a government user before signing in
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .where('email', isEqualTo: email)
          .limit(1)
          .get();

      bool isGovernmentUser = false;
      UserRole? userRole;
      
      if (userDoc.docs.isNotEmpty) {
        final userData = userDoc.docs.first.data();
        final role = userData['role'];
        if (role != null) {
          userRole = UserRole.fromMap(role);
          // Check if user is a government user (admin, procurement, finance, anti-corruption)
          isGovernmentUser = userData['isGovernmentUser'] == true || 
                            userRole.userType == 'government' ||
                            userRole.id == 'admin' ||
                            userRole.id == 'procurement_officer' ||
                            userRole.id == 'finance_officer' ||
                            userRole.id == 'anti_corruption_officer';
        }
      }

      if (mounted) {
        if (isGovernmentUser && userRole != null) {
          // For government users, first verify credentials, then navigate to OTP verification
          print('🔐 Government user detected, verifying credentials first...');
          
          try {
            // First verify the credentials using AuthService
            await AuthService().signInWithEmailAndPassword(email, password);
            print('✅ Government user credentials verified successfully');
            
            // Save credentials if Remember Me is checked
            await _saveCredentials();
            print('📱 Navigating to OTP verification screen...');
            
            // Navigate to OTP verification screen
            // Use pushAndRemoveUntil to prevent AuthWrapper from interfering
            if (mounted) {
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(
                  builder: (context) => GovernmentOtpVerificationScreen(
                    email: email,
                    userRole: userRole!,
                    isLogin: true,
                    password: password,
                  ),
                ),
                (route) => false, // Remove all previous routes
              );
            }
          } catch (e) {
            // If credentials are invalid, show error and don't navigate to OTP screen
            print('❌ Government user credentials verification failed: $e');
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Invalid credentials: ${e.toString()}'),
                  backgroundColor: Colors.red,
                ),
              );
            }
            return; // Don't proceed to OTP screen
          }
        } else {
          // For regular users, sign in and let AuthWrapper handle routing
          try {
            await AuthService().signInWithEmailAndPassword(email, password);
            await _saveCredentials();
            
            // Show success message
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('✅ Login successful! Redirecting...'),
                  backgroundColor: Colors.green,
                  duration: Duration(seconds: 2),
                ),
              );
            }
            
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(
                builder: (context) => const AuthWrapper(),
              ),
            );
          } catch (e) {
            // Handle all login errors
            String message = 'Login failed. Please try again.';
            if (e is FirebaseAuthException) {
              switch (e.code) {
                case 'user-not-found':
                  message = 'No user found with this email address.';
                  break;
                case 'wrong-password':
                  message = 'Incorrect password.';
                  break;
                case 'invalid-email':
                  message = 'Please enter a valid email address.';
                  break;
                case 'user-disabled':
                  message = 'This account has been disabled.';
                  break;
                case 'account-deactivated':
                  message = 'Your account has been deactivated. Please contact the administrator for assistance.';
                  break;
                case 'too-many-requests':
                  message = 'Too many failed attempts. Please try again later.';
                  break;
                default:
                  message = 'Login error: ${e.message}';
              }
            }
            
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(message),
                  backgroundColor: Colors.red,
                ),
              );
            }
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('An unexpected error occurred.'),
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

  void _showResendVerificationDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Email Not Verified'),
        content: const Text(
            'Please check your email and click the verification link. Would you like to resend the verification email?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(context).pop();
              try {
                // First try to sign in to get the current user (this will check for deactivated accounts)
                await AuthService().signInWithEmailAndPassword(
                  _emailController.text.trim(),
                  _passwordController.text,
                );
                // Then send verification email
                await AuthService().sendEmailVerification();
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                          'Verification email sent! Please check your inbox.'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Failed to send verification email: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            child: const Text('Resend Email'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: MediaQuery.of(context).size.height -
                    MediaQuery.of(context).padding.top -
                    MediaQuery.of(context).padding.bottom -
                    48,
              ),
              child: IntrinsicHeight(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // App Logo/Title
                    Image.asset(
                      'assets/images/logo.png',
                      width: 80,
                      height: 80,
                      fit: BoxFit.contain,
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Civic Lense',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Transparency in Public Spending',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 48),

                    // Email Field
                    CustomTextField(
                      controller: _emailController,
                      labelText: 'Email',
                      prefixIcon: Icons.email,
                      keyboardType: TextInputType.emailAddress,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your email';
                        }
                        if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
                            .hasMatch(value)) {
                          return 'Please enter a valid email';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Password Field
                    CustomTextField(
                      controller: _passwordController,
                      labelText: 'Password',
                      prefixIcon: Icons.lock,
                      obscureText: _obscurePassword,
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword
                              ? Icons.visibility
                              : Icons.visibility_off,
                        ),
                        onPressed: () {
                          setState(() {
                            _obscurePassword = !_obscurePassword;
                          });
                        },
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your password';
                        }
                        if (value.length < 6) {
                          return 'Password must be at least 6 characters';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Remember Me and Forgot Password Row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Remember Me Checkbox
                        Row(
                          children: [
                            Checkbox(
                              value: _rememberMe,
                              onChanged: (value) {
                                setState(() {
                                  _rememberMe = value ?? false;
                                });
                              },
                            ),
                            const Text('Remember me'),
                          ],
                        ),
                        
                        // Forgot Password Link
                        TextButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const ForgotPasswordScreen(),
                              ),
                            );
                          },
                          child: Text(
                            'Forgot Password?',
                            style: TextStyle(
                              color: Colors.blue.shade700,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Login Button
                    CustomButton(
                      onPressed: _isLoading ? null : _login,
                      text: _isLoading ? 'Signing In...' : 'Sign In',
                      isLoading: _isLoading,
                    ),
                    const SizedBox(height: 24),

                    const SizedBox(height: 16),

                    // Sign Up Link
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text("Don't have an account? "),
                        TextButton(
                          onPressed: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (context) => const SignupScreen(),
                              ),
                            );
                          },
                          child: const Text(
                            'Sign Up',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.blue,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
