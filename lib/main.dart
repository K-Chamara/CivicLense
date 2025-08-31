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
import 'screens/add_tender_screen.dart';
import 'screens/timeline_tracker_screen.dart';
import 'screens/ongoing_tenders_screen.dart';
import 'screens/public_dashboard_screen.dart';
import 'screens/notifications_screen.dart';
import 'screens/tender_management_screen.dart';
import 'screens/bidder_management_screen.dart';
import 'services/auth_service.dart';
import 'models/user_role.dart';

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
        '/add-tender': (context) => const AddTenderScreen(),
        '/timeline-tracker': (context) => const TimelineTrackerScreen(),
        '/ongoing-tenders': (context) => const OngoingTendersScreen(),
        '/public-dashboard-view': (context) => const PublicDashboardScreen(),
        '/notifications': (context) => const NotificationsScreen(),
        '/tender-management': (context) => const TenderManagementScreen(),
        '/bidder-management': (context) => const BidderManagementScreen(tenderId: '', tenderTitle: ''),
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
                switch (userRole.id) {
                  case 'admin':
                    return const AdminDashboardScreen();
                  case 'procurement_officer':
                    return const ProcurementOfficerDashboardScreen();
                  case 'finance_officer':
                    return const FinanceOfficerDashboardScreen();
                  case 'anticorruption_officer':
                    return const AntiCorruptionOfficerDashboardScreen();
                  default:
                    return const DashboardScreen();
                }
              } else {
                return const DashboardScreen();
              }
            },
          );
        }

        // User is not signed in, show onboarding
        return const OnboardingScreen();
      },
    );
  }


}
