import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'screens/splash_screen.dart';
import 'screens/news_feed_screen.dart';
import 'screens/article_detail_screen.dart';
import 'screens/media_hub_screen.dart';
import 'screens/publish_report_screen.dart';
import 'screens/community_list_screen.dart';
import 'screens/raise_concern_screen.dart';
import 'screens/concern_management_screen.dart';
import 'screens/public_concerns_screen.dart';
import 'screens/budget_viewer_screen.dart';
import 'screens/tender_management_screen.dart';
import 'screens/login_screen.dart';
import 'screens/dashboard_screen.dart';
import 'screens/admin_dashboard_screen.dart';
import 'screens/finance_officer_dashboard_screen.dart';
import 'screens/procurement_officer_dashboard_screen.dart';
import 'screens/anticorruption_officer_dashboard_screen.dart';
import 'screens/public_user_dashboard_screen.dart';
import 'services/auth_service.dart';
import 'models/user_role.dart';
import 'utils/create_admin.dart';
import 'screens/admin_setup_screen.dart';

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
      home: const AppInitializer(),
      routes: {
        '/news': (context) => const NewsFeedScreen(),
        '/article': (context) => const ArticleDetailScreen(),
        '/media-hub': (context) => const MediaHubScreen(),
        '/publish': (context) => const PublishReportScreen(),
        '/communities': (context) => const CommunityListScreen(),
        '/raise-concern': (context) => const RaiseConcernScreen(),
        '/concern-management': (context) => const ConcernManagementScreen(),
        '/public-concerns': (context) => const PublicConcernsScreen(),
        '/budget-viewer': (context) => const BudgetViewerScreen(),
        '/tender-management': (context) => const TenderManagementScreen(),
        '/login': (context) => const LoginScreen(),
      },
    );
  }
}

class AppInitializer extends StatelessWidget {
  const AppInitializer({super.key});

  @override
  Widget build(BuildContext context) {
    // Always start with the splash screen - it will handle navigation
    return const SplashScreen();
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
                  case 'citizen':
                  case 'journalist':
                  case 'community_leader':
                  case 'researcher':
                  case 'ngo':
                    return const PublicUserDashboardScreen();
                  default:
                    return const DashboardScreen();
                }
              } else {
                return const DashboardScreen();
              }
            },
          );
        }

        // User is not signed in, check if admin exists
        return FutureBuilder<bool>(
          future: AdminCreator.adminExists(),
          builder: (context, adminSnapshot) {
            print('🔄 AuthWrapper: Checking admin existence...');
            print('📊 Admin snapshot state: ${adminSnapshot.connectionState}');
            print('📊 Admin snapshot hasData: ${adminSnapshot.hasData}');
            print('📊 Admin snapshot data: ${adminSnapshot.data}');
            
            if (adminSnapshot.connectionState == ConnectionState.waiting) {
              print('⏳ AuthWrapper: Waiting for admin check...');
              return const Scaffold(
                body: Center(
                  child: CircularProgressIndicator(),
                ),
              );
            }
            
            if (adminSnapshot.hasData && adminSnapshot.data == false) {
              // No admin exists, show admin setup screen
              print('🚨 AuthWrapper: No admin found, showing admin setup screen');
              return const AdminSetupScreen();
            } else {
              // Admin exists, show login screen
              print('✅ AuthWrapper: Admin exists, showing login screen');
              return const LoginScreen();
            }
          },
        );
      },
    );
  }
}

