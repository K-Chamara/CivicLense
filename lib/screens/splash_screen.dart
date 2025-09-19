import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../utils/onboarding_utils.dart';
import '../utils/create_admin.dart';
import 'onboarding_screen.dart';
import 'login_screen.dart';
import 'common_home_screen.dart';
import 'dashboard_screen.dart';
import 'admin_dashboard_screen.dart';
import 'admin_setup_screen.dart';
import 'otp_screen.dart';
import 'finance_officer_dashboard_screen.dart';
import 'procurement_officer_dashboard_screen.dart';
import 'anticorruption_officer_dashboard_screen.dart';
import 'public_user_dashboard_screen.dart';
import 'add_tender_screen.dart';
import 'timeline_tracker_screen.dart';
import 'ongoing_tenders_screen.dart';
import 'public_dashboard_screen.dart';
import 'notifications_screen.dart';
import 'publish_report_screen.dart';
import 'news_feed_screen.dart';
import 'article_detail_screen.dart';
import 'media_hub_screen.dart';
import 'tender_management_screen.dart';
import 'bidder_management_screen.dart';
import '../services/auth_service.dart';
import '../models/user_role.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _logoController;
  late AnimationController _textController;
  late AnimationController _fadeController;
  
  late Animation<double> _logoScaleAnimation;
  late Animation<double> _logoRotationAnimation;
  late Animation<double> _textSlideAnimation;
  late Animation<double> _textFadeAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    
    // Initialize animation controllers
    _logoController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );
    
    _textController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    // Logo animations
    _logoScaleAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _logoController,
      curve: Curves.elasticOut,
    ));

    _logoRotationAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _logoController,
      curve: Curves.easeInOut,
    ));

    // Text animations
    _textSlideAnimation = Tween<double>(
      begin: 50.0,
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: _textController,
      curve: Curves.easeOutBack,
    ));

    _textFadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _textController,
      curve: Curves.easeIn,
    ));

    // Fade out animation
    _fadeAnimation = Tween<double>(
      begin: 1.0,
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeIn,
    ));

    // Start animations
    _startAnimations();
  }

  void _startAnimations() async {
    // Start logo animation
    await _logoController.forward();
    
    // Start text animation after a short delay
    await Future.delayed(const Duration(milliseconds: 300));
    await _textController.forward();
    
    // Wait for a moment, then fade out and navigate
    await Future.delayed(const Duration(milliseconds: 2000));
    await _fadeController.forward();
    
    // Navigate to the appropriate screen
    _navigateToNextScreen();
  }

  void _navigateToNextScreen() async {
    print('🚀 SplashScreen: Starting navigation logic...');
    
    // ALWAYS check if admin exists first - this is critical for app functionality
    print('🔍 SplashScreen: Checking admin existence...');
    final adminExists = await AdminCreator.adminExists();
    print('👑 SplashScreen: Admin exists: $adminExists');
    
    Widget nextScreen;
    
    if (!adminExists) {
      // No admin exists - show admin setup screen (this takes priority)
      print('🚨 SplashScreen: No admin found, showing admin setup');
      nextScreen = const AdminSetupScreen();
    } else {
      // Admin exists - check if user has seen onboarding
      final hasSeenOnboarding = await OnboardingUtils.hasSeenOnboarding();
      print('📱 SplashScreen: Has seen onboarding: $hasSeenOnboarding');
      
      if (!hasSeenOnboarding) {
        // First time app installation - show onboarding
        print('🎯 SplashScreen: First time user, showing onboarding');
        nextScreen = const OnboardingScreen();
      } else {
        // App has been used before - go to auth wrapper
        print('✅ SplashScreen: Returning user, going to auth wrapper');
        nextScreen = const AuthWrapper();
      }
    }
    
    print('🎬 SplashScreen: Navigating to: ${nextScreen.runtimeType}');
    
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => nextScreen,
        transitionDuration: const Duration(milliseconds: 500),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(
            opacity: animation,
            child: child,
          );
        },
      ),
    );
  }

  @override
  void dispose() {
    _logoController.dispose();
    _textController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color(0xFF1E3A8A), // Deep blue
                Color(0xFF3B82F6), // Blue
                Color(0xFF60A5FA), // Light blue
              ],
            ),
          ),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Animated Logo
                AnimatedBuilder(
                  animation: _logoController,
                  builder: (context, child) {
                    return Transform.scale(
                      scale: _logoScaleAnimation.value,
                      child: Transform.rotate(
                        angle: _logoRotationAnimation.value * 0.1,
                        child: Container(
                          width: 120,
                          height: 120,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.white.withOpacity(0.3),
                                blurRadius: 20,
                                spreadRadius: 5,
                              ),
                            ],
                          ),
                          child: ClipOval(
                            child: Image.asset(
                              'assets/images/logo.png',
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
                
                const SizedBox(height: 40),
                
                // Animated Text
                AnimatedBuilder(
                  animation: _textController,
                  builder: (context, child) {
                    return Transform.translate(
                      offset: Offset(0, _textSlideAnimation.value),
                      child: Opacity(
                        opacity: _textFadeAnimation.value,
                        child: Column(
                          children: [
                            // Main title
                            ShaderMask(
                              shaderCallback: (bounds) => const LinearGradient(
                                colors: [Colors.white, Color(0xFFE0E7FF)],
                              ).createShader(bounds),
                              child: const Text(
                                'CIVIC LENSE',
                                style: TextStyle(
                                  fontSize: 32,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                  letterSpacing: 3,
                                ),
                              ),
                            ),
                            
                            const SizedBox(height: 8),
                            
                            // Subtitle
                            const Text(
                              'Transparency • Accountability • Progress',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.white70,
                                letterSpacing: 1,
                                fontWeight: FontWeight.w300,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
                
                const SizedBox(height: 60),
                
                // Loading indicator
                AnimatedBuilder(
                  animation: _textController,
                  builder: (context, child) {
                    return Opacity(
                      opacity: _textFadeAnimation.value,
                      child: const SizedBox(
                        width: 30,
                        height: 30,
                        child: CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          strokeWidth: 2,
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        if (snapshot.hasData && snapshot.data != null) {
          // User is signed in, check their role and show appropriate dashboard
          return FutureBuilder<UserRole?>(
            future: AuthService().getUserRole(snapshot.data!.uid),
            builder: (context, roleSnapshot) {
              if (roleSnapshot.connectionState == ConnectionState.waiting) {
                return const Scaffold(
                  body: Center(
                    child: CircularProgressIndicator(),
                  ),
                );
              }

              final userRole = roleSnapshot.data;
              
              if (userRole != null) {
                // Route all users to the common home page first
                return const CommonHomeScreen();
              } else {
                return const CommonHomeScreen();
              }
            },
          );
        }

        // User is not signed in, show login screen
        return const LoginScreen();
      },
    );
  }
}
