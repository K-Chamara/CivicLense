import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'l10n/app_localizations.dart';
import 'services/settings_service.dart';
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
import 'screens/citizen_tender_screen.dart';
import 'screens/login_screen.dart';
import 'screens/common_home_screen.dart';
import 'screens/document_upload_screen.dart';
import 'screens/email_verification_screen.dart';
import 'services/user_service.dart';
import 'utils/create_admin.dart';
import 'screens/admin_setup_screen.dart';
import 'screens/settings_screen.dart';

// Global key to access the app state
final GlobalKey<_MyAppState> _appKey = GlobalKey<_MyAppState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  try {
    // Initialize Firebase with error handling
    await Firebase.initializeApp();
    print('🚀 Civic Lense App Starting...');
    print('📁 File uploads: Using Cloudinary (free)');
    print('🔥 Firebase: Successfully initialized');
  } catch (e) {
    print('❌ Firebase initialization failed: $e');
    print('🔄 App will continue with limited functionality');
  }
  
  runApp(MyApp(key: _appKey));
}

// Function to reload locale from anywhere in the app
void reloadAppLocale() {
  _appKey.currentState?.reloadLocale();
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  Locale? _currentLocale;

  @override
  void initState() {
    super.initState();
    _loadLocale();
  }

  Future<void> _loadLocale() async {
    final locale = await SettingsService.getLocale();
    if (mounted) {
      setState(() {
        _currentLocale = locale;
      });
    }
  }

  // Method to reload locale when settings change
  void reloadLocale() {
    _loadLocale();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Civic Lense',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.blue,
          foregroundColor: Colors.white,
          elevation: 0,
        ),
      ),
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('en', ''), // English
        Locale('si', ''), // Sinhala
        Locale('ta', ''), // Tamil
      ],
      locale: _currentLocale,
      initialRoute: '/',
      routes: {
        '/': (context) => const AppInitializer(),
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
        '/citizen-tender': (context) => const CitizenTenderScreen(),
        '/login': (context) => const LoginScreen(),
        '/common-home': (context) => const CommonHomeScreen(),
        '/public-dashboard': (context) => const CommonHomeScreen(), // Add missing route
        '/document-upload': (context) {
          final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
          return DocumentUploadScreen(
            userRole: args?['userRole'] ?? 'citizen',
            userId: args?['userId'] ?? '',
          );
        },
        '/settings': (context) => const SettingsScreen(),
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

  Future<Map<String, dynamic>> _checkUserStatus(String userId) async {
    try {
      print('🔍 _checkUserStatus: Starting check for user: $userId');
      final userService = UserService();
      final userData = await userService.getCurrentUserData();
      
      if (userData == null) {
        print('🔍 _checkUserStatus: No user data found, returning default');
        return {'role': 'citizen', 'needsUpload': false, 'isApproved': true, 'canLogin': false, 'emailVerified': false, 'hasDocuments': false};
      }

      print('🔍 _checkUserStatus: Raw user data: $userData');
      
      final role = userData['role'] ?? 'citizen';
      final status = userData['status'] ?? 'pending';
      final needsUpload = await userService.needsDocumentUpload(userId);
      final canLogin = await userService.canUserLogin(userId);
      final isApproved = status == 'approved';
      final emailVerified = userData['emailVerified'] ?? false;
      final hasDocuments = userData['documents'] != null && (userData['documents'] as List).isNotEmpty;

      print('🔍 _checkUserStatus: Final results:');
      print('🔍 - role: $role');
      print('🔍 - status: $status');
      print('🔍 - needsUpload: $needsUpload');
      print('🔍 - isApproved: $isApproved');
      print('🔍 - canLogin: $canLogin');
      print('🔍 - emailVerified: $emailVerified');
      print('🔍 - hasDocuments: $hasDocuments');

      return {
        'role': role,
        'needsUpload': needsUpload,
        'isApproved': isApproved,
        'canLogin': canLogin,
        'emailVerified': emailVerified,
        'hasDocuments': hasDocuments,
      };
    } catch (e) {
      print('❌ Error checking user status: $e');
      print('❌ Error stack trace: ${StackTrace.current}');
      // On error, allow login to proceed (don't lock users out)
      return {'role': 'citizen', 'needsUpload': false, 'isApproved': true, 'canLogin': true, 'emailVerified': false, 'hasDocuments': false};
    }
  }

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
          print('🔍 AuthWrapper: User is signed in: ${snapshot.data!.uid}');
          print('🔍 AuthWrapper: User email: ${snapshot.data!.email}');
          // User is signed in, check their role and document upload status
          return FutureBuilder<Map<String, dynamic>>(
            future: _checkUserStatus(snapshot.data!.uid),
            builder: (context, statusSnapshot) {
              if (statusSnapshot.connectionState == ConnectionState.waiting) {
                return const Scaffold(
                  body: Center(
                    child: CircularProgressIndicator(),
                  ),
                );
              }

              final userData = statusSnapshot.data;
              if (userData == null) {
                print('🔍 AuthWrapper: No user data found, going to CommonHomeScreen');
                return const CommonHomeScreen();
              }

              final userRole = userData['role'];
              final needsUpload = userData['needsUpload'] ?? false;
              final isApproved = userData['isApproved'] ?? false;
              final canLogin = userData['canLogin'] ?? false;
              
              print('🔍 AuthWrapper: User status check results:');
              print('🔍 - userRole: $userRole');
              print('🔍 - needsUpload: $needsUpload');
              print('🔍 - isApproved: $isApproved');
              print('🔍 - canLogin: $canLogin');

              // Extract role ID and userType from role object or string
              String roleId = 'citizen';
              String userType = 'public';
              if (userRole is String) {
                roleId = userRole;
              } else if (userRole is Map) {
                roleId = userRole['id'] ?? 'citizen';
                userType = userRole['userType'] ?? 'public';
              }

              // Check if user needs document upload or email verification
              print('🔍 AuthWrapper: Checking document upload requirement...');
              print('🔍 needsUpload: $needsUpload, roleId: $roleId');
              print('🔍 Condition check: needsUpload=$needsUpload, roleId=$roleId, userType=$userType');
              
              // Get additional user data from the status check result
              final emailVerified = userData['emailVerified'] ?? false;
              final hasDocuments = userData['hasDocuments'] ?? false;
              
              // If user needs document upload, redirect to upload page
              if (needsUpload && roleId != 'citizen' && roleId != 'admin' && userType != 'government') {
                print('📄 AuthWrapper: Redirecting to document upload screen');
                print('📄 AuthWrapper: User needs upload - roleId: $roleId, hasDocuments: $hasDocuments');
                return DocumentUploadScreen(
                  userRole: roleId,
                  userId: snapshot.data!.uid,
                );
              }
              
              // If user has uploaded documents but hasn't verified email, redirect to email verification
              if (hasDocuments && !emailVerified && roleId != 'citizen' && roleId != 'admin' && userType != 'government') {
                print('📧 AuthWrapper: Redirecting to email verification screen');
                print('📧 AuthWrapper: User has documents but needs email verification - hasDocuments: $hasDocuments, emailVerified: $emailVerified');
                return EmailVerificationScreen(
                  email: snapshot.data!.email ?? '',
                  userRole: roleId,
                  userId: snapshot.data!.uid,
                );
              }

              // If user cannot login (email not verified), sign them out and redirect to login
              // This check comes AFTER document upload check
              if (!canLogin) {
                FirebaseAuth.instance.signOut();
                return const LoginScreen();
              }
              
              print('🏠 AuthWrapper: Proceeding to CommonHomeScreen');

              // All users (approved and pending) can use the app
              // Pending users will get limited functionality in the CommonHomeScreen
              return const CommonHomeScreen();
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

