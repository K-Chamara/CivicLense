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
import 'screens/finance_officer_dashboard_screen.dart';
import 'screens/procurement_officer_dashboard_screen.dart';
import 'screens/anticorruption_officer_dashboard_screen.dart';
import 'screens/public_user_dashboard_screen.dart';
import 'services/admin_service.dart';
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
        '/finance-dashboard': (context) => const FinanceOfficerDashboardScreen(),
        '/procurement-dashboard': (context) => const ProcurementOfficerDashboardScreen(),
        '/anticorruption-dashboard': (context) => const AntiCorruptionOfficerDashboardScreen(),
        '/public-dashboard': (context) => const PublicUserDashboardScreen(),
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
      
      // Get user data from Firestore
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .get();
      
      if (userDoc.exists) {
        final userData = userDoc.data()!;
        final role = userData['role'];
        
        if (role != null) {
          final roleId = role['id'];
          
          // Route to specific dashboard based on role
          switch (roleId) {
            case 'finance_officer':
              return const FinanceOfficerDashboardScreen();
            case 'procurement_officer':
              return const ProcurementOfficerDashboardScreen();
            case 'anticorruption_officer':
              return const AntiCorruptionOfficerDashboardScreen();
            case 'citizen':
            case 'journalist':
            case 'community_leader':
            case 'researcher':
            case 'ngo':
              return const PublicUserDashboardScreen();
            default:
              // Fallback to regular dashboard for unknown roles
              return const DashboardScreen();
          }
        }
      }
      
      // Fallback to regular dashboard if no role found
      return const DashboardScreen();
    } catch (e) {
      // If there's an error, return regular dashboard
      return const DashboardScreen();
    }
  }
}
