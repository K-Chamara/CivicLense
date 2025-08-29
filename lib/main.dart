import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'screens/onboarding_screen.dart';
import 'screens/login_screen.dart';
import 'screens/dashboard_screen.dart';
import 'screens/admin_dashboard_screen.dart';
import 'screens/admin_setup_screen.dart';
import 'screens/otp_screen.dart';
import 'services/admin_service.dart';
import 'models/user_role.dart';
import 'services/auth_service.dart';
import 'utils/create_admin.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Firebase
  await Firebase.initializeApp();
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Civic Lense',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.blue,
          foregroundColor: Colors.white,
          elevation: 0,
        ),
      ),
      home: const AuthWrapper(),
      routes: {
        '/onboarding': (context) => const OnboardingScreen(),
        '/login': (context) => const LoginScreen(),
        '/dashboard': (context) => const DashboardScreen(),
        '/admin-setup': (context) => const AdminSetupScreen(),
        '/otp': (context) => const OtpScreen(email: '', password: ''),
      },
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
          return FutureBuilder<Widget>(
            future: _getDashboardForUser(snapshot.data!.uid),
            builder: (context, dashboardSnapshot) {
              if (dashboardSnapshot.connectionState == ConnectionState.waiting) {
                return const Scaffold(
                  body: Center(
                    child: CircularProgressIndicator(),
                  ),
                );
              }

              return dashboardSnapshot.data ?? const DashboardScreen();
            },
          );
        }

        // User is not signed in, check if admin exists
        return FutureBuilder<bool>(
          future: AdminCreator.adminExists(),
          builder: (context, adminSnapshot) {
            if (adminSnapshot.connectionState == ConnectionState.waiting) {
              return const Scaffold(
                body: Center(
                  child: CircularProgressIndicator(),
                ),
              );
            }

            if (adminSnapshot.hasData && adminSnapshot.data == true) {
              // Admin exists, show login screen
              return const LoginScreen();
            } else {
              // No admin exists, show admin setup
              return const AdminSetupScreen();
            }
          },
        );
      },
    );
  }

  Future<Widget> _getDashboardForUser(String uid) async {
    try {
      final adminService = AdminService();
      final isAdmin = await adminService.isAdmin(uid);
      
      if (isAdmin) {
        return const AdminDashboardScreen();
      }
      
      // Check if this is a government user
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .get();
      
      if (userDoc.exists) {
        final userData = userDoc.data()!;
        final role = userData['role'];
        if (role != null && role['userType'] == 'government') {
          // This is a government user, they should go through OTP flow
          // For now, return regular dashboard
          return const DashboardScreen();
        }
      }
      
      // For now, return regular dashboard for all other users
      // Later, you can add specific dashboards for government users
      return const DashboardScreen();
    } catch (e) {
      // If there's an error, return regular dashboard
      return const DashboardScreen();
    }
  }
}
