import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';
import '../services/budget_service.dart';
import '../models/user_role.dart';
import 'login_screen.dart';
import 'budget_viewer_screen.dart';
import 'citizen_tender_screen.dart';
import 'public_tender_viewer_screen.dart';
import 'ongoing_tenders_screen.dart';
import 'raise_concern_screen.dart';
import 'public_concerns_screen.dart';
import 'user_concern_tracking_screen.dart';
import 'enhanced_dashboard_screen.dart';
import 'admin_dashboard_screen.dart';
import 'finance_officer_dashboard_screen.dart';
import 'procurement_officer_dashboard_screen.dart';
import 'anticorruption_officer_dashboard_screen.dart';
import 'public_user_dashboard_screen.dart';
import 'admin_approval_screen.dart';
import 'transparency_dashboard_screen.dart';

class CommonHomeScreen extends StatefulWidget {
  const CommonHomeScreen({super.key});

  @override
  State<CommonHomeScreen> createState() => _CommonHomeScreenState();
}

class _CommonHomeScreenState extends State<CommonHomeScreen>
    with TickerProviderStateMixin {
  final AuthService _authService = AuthService();
  final BudgetService _budgetService = BudgetService();
  UserRole? userRole;
  Map<String, dynamic>? userData;
  bool isLoading = true;
  bool showPendingScreen = true;
  bool hasChosenLimitedAccess = false;
  
  // Dashboard statistics
  int allocationsCount = 0;
  int activeTendersCount = 0;
  int projectsCount = 0;
  
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late AnimationController _scaleController;
  late AnimationController _rotationController;
  late AnimationController _pulseController;
  late AnimationController _chartController;
  
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _rotationAnimation;
  late Animation<double> _pulseAnimation;
  late Animation<double> _chartAnimation;

  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _loadUserData();
    _checkPendingScreenPreference();
    _loadDashboardData();
  }

  void _initializeAnimations() {
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _rotationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );
    _chartController = AnimationController(
      duration: const Duration(milliseconds: 1800),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    ));
    
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.5),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutCubic,
    ));
    
    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _scaleController,
      curve: Curves.elasticOut,
    ));
    
    _rotationAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _rotationController,
      curve: Curves.easeInOut,
    ));
    
    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.1,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));
    
    _chartAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _chartController,
      curve: Curves.easeOutCubic,
    ));
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    _scaleController.dispose();
    _rotationController.dispose();
    _pulseController.dispose();
    _chartController.dispose();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    final user = _authService.currentUser;
    if (user != null) {
      final role = await _authService.getUserRole(user.uid);
      final data = await _authService.getUserData(user.uid);
      
      setState(() {
        userRole = role;
        userData = data;
        isLoading = false;
      });
      
      // Start animations after data loads
      _fadeController.forward();
      _slideController.forward();
      _scaleController.forward();
      _rotationController.forward();
      _pulseController.repeat(reverse: true);
      _chartController.forward();
    }
  }

  void _checkPendingScreenPreference() async {
    final prefs = await SharedPreferences.getInstance();
    final hasChosen = prefs.getBool('hasChosenLimitedAccess') ?? false;
    if (mounted) {
      setState(() {
        hasChosenLimitedAccess = hasChosen;
      });
    }
  }

  Future<void> _loadDashboardData() async {
    print('Loading home page dashboard data...');
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        print('No user found, returning');
        return;
      }
      print('User found: ${user.uid}');

      // Load ALL tenders in the database
      final tendersQuery = await FirebaseFirestore.instance
          .collection('tenders')
          .get();

      final tenders = tendersQuery.docs.map((doc) => doc.data()).toList();
      print('Found ${tenders.length} tenders');
      
      // Load ALL projects in the database
      final projectsQuery = await FirebaseFirestore.instance
          .collection('projects')
          .get();

      final projects = projectsQuery.docs.map((doc) => doc.data()).toList();
      print('Found ${projects.length} projects');

      // Calculate statistics (same logic as PO Dashboard)
      activeTendersCount = tenders.length; // All tenders in DB
      projectsCount = projects.length; // Projects should show actual projects in DB
      
      // TEMPORARY TEST: Force some values to see if UI updates
      print('BEFORE calculations:');
      print('tenders.length: ${tenders.length}');
      print('projects.length: ${projects.length}');
      
      // If we have data but counts are 0, there might be an issue
      if (tenders.length > 0 && activeTendersCount == 0) {
        print('WARNING: Found tenders but activeTendersCount is 0');
        activeTendersCount = tenders.length;
      }
      if (tenders.length > 0 && projectsCount == 0) {
        print('WARNING: Found tenders but projectsCount is 0');
        projectsCount = tenders.length;
      }
      
      // Load allocations count using BudgetService (same as PO Dashboard)
      try {
        int totalBudgetItems = 0;
        
        // Use the same method as PO Dashboard and BudgetItemsOverviewScreen
        final categories = await _budgetService.getBudgetCategories();
        print('Found ${categories.length} budget categories');
        
        for (final category in categories) {
          try {
            final subcategories = await _budgetService.getBudgetSubcategories(category.id);
            print('Category ${category.id} has ${subcategories.length} subcategories');
            
            for (final subcategory in subcategories) {
              try {
                final items = await _budgetService.getBudgetItems(category.id, subcategory.id);
                print('Subcategory ${subcategory.id} has ${items.length} items');
                totalBudgetItems += items.length;
              } catch (e) {
                print('Error loading items for subcategory ${subcategory.id}: $e');
              }
            }
          } catch (e) {
            print('Error loading subcategories for category ${category.id}: $e');
          }
        }
        
        allocationsCount = totalBudgetItems;
        print('Allocations count loaded using BudgetService: $allocationsCount');
      } catch (e) {
        print('Error loading allocations count with BudgetService: $e');
        allocationsCount = 0;
      }
      
      print('Home page dashboard statistics loaded:');
      print('Allocations: $allocationsCount');
      print('Active Tenders: $activeTendersCount');
      print('Projects: $projectsCount');
      
      // Update the UI
      if (mounted) {
        setState(() {
          // Force UI update with real data
        });
      }
    } catch (e) {
      print('Error loading home page dashboard data: $e');
    }
  }

  Future<void> _signOut() async {
    try {
      await _authService.signOut();
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const LoginScreen()),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error signing out: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _navigateToDashboard() {
    // Navigate to role-specific dashboard
    Widget dashboard;
    
    // Check if user is pending (not approved yet)
    final isPending = userData?['status'] == 'pending';
    
    if (isPending) {
      // Pending users get limited access with EnhancedDashboardScreen
      dashboard = const EnhancedDashboardScreen();
    } else {
      // Approved users get full access based on their role
      switch (userRole?.id) {
        case 'admin':
          dashboard = const AdminDashboardScreen();
          break;
        case 'finance_officer':
          dashboard = const FinanceOfficerDashboardScreen();
          break;
        case 'procurement_officer':
          dashboard = const ProcurementOfficerDashboardScreen();
          break;
        case 'anticorruption_officer':
          dashboard = const AntiCorruptionOfficerDashboardScreen();
          break;
        case 'citizen':
        case 'journalist':
        case 'community_leader':
        case 'researcher':
        case 'ngo':
          dashboard = const PublicUserDashboardScreen();
          break;
        default:
          dashboard = const EnhancedDashboardScreen();
      }
    }
    
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => dashboard),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.blue.shade600),
              ),
              const SizedBox(height: 24),
              Text(
                'Loading your dashboard...',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Check if user is pending approval - show pending screen first
    // Only show if user hasn't already chosen to continue with limited access
    if (userData != null && userData!['status'] == 'pending' && showPendingScreen && !hasChosenLimitedAccess) {
      return _buildPendingApprovalScreen();
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      drawer: _buildNavigationDrawer(),
      appBar: _buildAppBar(),
      bottomNavigationBar: _buildBottomNavigationBar(),
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: _buildCurrentPage(),
        ),
      ),
    );
  }


  Widget _buildWelcomeHero() {
    return ScaleTransition(
      scale: _scaleAnimation,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.blue.shade600,
              Colors.blue.shade800,
              Colors.indigo.shade700,
            ],
          ),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.blue.withOpacity(0.3),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(
                    userRole?.icon ?? Icons.person,
                    color: Colors.white,
                    size: 32,
                  ),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Welcome back, ${userData?['firstName'] ?? 'User'}!',
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        userRole?.name ?? 'Civic Lense User',
                        style: const TextStyle(
                          fontSize: 16,
                          color: Colors.white70,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Text(
              'Track public spending, ensure transparency, and hold government accountable.',
              style: const TextStyle(
                fontSize: 16,
                color: Colors.white70,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white.withOpacity(0.3)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.visibility, color: Colors.white, size: 20),
                  const SizedBox(width: 8),
                  const Text(
                    'Transparency First',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickStats() {
    return SlideTransition(
      position: _slideAnimation,
      child: Row(
        children: [
          Expanded(
            flex: 1,
            child: _buildStatCard(
              'Allocations',
              allocationsCount.toString(),
              Icons.account_balance_wallet,
              Colors.orange,
              'Budget items',
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 1,
            child: _buildStatCard(
              'Active Tenders',
              activeTendersCount.toString(),
              Icons.assignment,
              Colors.blue,
              'In progress',
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 1,
            child: _buildStatCard(
              'Projects',
              projectsCount.toString(),
              Icons.work,
              Colors.green,
              'Ongoing',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color, String subtitle) {
    return Container(
      height: 140,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.08),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Top row with icon and trend indicator
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 18),
              ),
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Icon(Icons.trending_up, color: Colors.green, size: 12),
              ),
            ],
          ),
          // Content area
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Value
              Text(
                value,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              const SizedBox(height: 4),
              // Title
              Text(
                title,
                style: const TextStyle(
                  fontSize: 13,
                  color: Colors.grey,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 2),
              // Subtitle
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.grey.shade600,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMainNavigationCards() {
    return SlideTransition(
      position: _slideAnimation,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Quick Access',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _buildNavigationCard(
                  'My Dashboard',
                  'Access your personalized dashboard',
                  Icons.dashboard,
                  Colors.blue,
                  _navigateToDashboard,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildNavigationCard(
                  'Budget Overview',
                  'Explore government budgets',
                  Icons.account_balance,
                  Colors.green,
                  () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const BudgetViewerScreen()),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildNavigationCard(
                  'Active Tenders',
                  'View current procurement opportunities',
                  Icons.shopping_cart,
                  Colors.orange,
                  () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const PublicTenderViewerScreen()),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildNavigationCard(
                  'Track Projects',
                  'View and track awarded projects',
                  Icons.work,
                  Colors.purple,
                  () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const OngoingTendersScreen()),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildNavigationCard(
                  'Raise Concern',
                  'Report issues and track resolution',
                  Icons.report_problem,
                  Colors.red,
                  () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const RaiseConcernScreen()),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildNavigationCard(
                  'Public Concerns',
                  'View community concerns and issues',
                  Icons.people_alt,
                  Colors.teal,
                  () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const PublicConcernsScreen()),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildNavigationCard(String title, String subtitle, IconData icon, Color color, VoidCallback onTap) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: color, size: 24),
                ),
                const SizedBox(height: 16),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Text(
                      'Explore',
                      style: TextStyle(
                        fontSize: 12,
                        color: color,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(Icons.arrow_forward, color: color, size: 14),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRecentHighlights() {
    return SlideTransition(
      position: _slideAnimation,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Recent Highlights',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                _buildHighlightItem(
                  'New tender published for road construction',
                  '2 hours ago',
                  Icons.shopping_cart,
                  Colors.orange,
                ),
                const Divider(height: 24),
                _buildHighlightItem(
                  'Budget allocation updated for Q4',
                  '1 day ago',
                  Icons.account_balance_wallet,
                  Colors.blue,
                ),
                const Divider(height: 24),
                _buildHighlightItem(
                  'Project milestone completed',
                  '2 days ago',
                  Icons.check_circle,
                  Colors.green,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHighlightItem(String title, String time, IconData icon, Color color) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                time,
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildRoleSpecificActions() {
    return SlideTransition(
      position: _slideAnimation,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${userRole?.name ?? 'Your'} Quick Actions',
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 16),
          _buildRoleSpecificContent(),
        ],
      ),
    );
  }

  Widget _buildRoleSpecificContent() {
    switch (userRole?.id) {
      case 'admin':
        return _buildAdminActions();
      case 'finance_officer':
        return _buildFinanceOfficerActions();
      case 'procurement_officer':
        return _buildProcurementOfficerActions();
      case 'anticorruption_officer':
        return _buildAntiCorruptionOfficerActions();
      case 'citizen':
        return _buildCitizenActions();
      case 'journalist':
        return _buildJournalistActions();
      default:
        return _buildDefaultActions();
    }
  }

  Widget _buildAdminActions() {
    return Column(
      children: [
        _buildActionCard('User Management', Icons.people, Colors.purple, () => _navigateToDashboard()),
        _buildActionCard('System Analytics', Icons.analytics, Colors.blue, () => _navigateToDashboard()),
      ],
    );
  }

  Widget _buildFinanceOfficerActions() {
    return Column(
      children: [
        _buildActionCard('Budget Management', Icons.account_balance_wallet, Colors.green, () => _navigateToDashboard()),
        _buildActionCard('Financial Reports', Icons.receipt_long, Colors.blue, () => _navigateToDashboard()),
      ],
    );
  }

  Widget _buildProcurementOfficerActions() {
    return Column(
      children: [
        _buildActionCard('Tender Management', Icons.shopping_cart, Colors.orange, () => _navigateToDashboard()),
        _buildActionCard('Vendor Management', Icons.business, Colors.blue, () => _navigateToDashboard()),
      ],
    );
  }

  Widget _buildAntiCorruptionOfficerActions() {
    return Column(
      children: [
        _buildActionCard('Concern Management', Icons.report_problem, Colors.red, () => Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const PublicConcernsScreen()),
        )),
        _buildActionCard('Investigation Tools', Icons.search, Colors.orange, () => _navigateToDashboard()),
      ],
    );
  }

  Widget _buildCitizenActions() {
    return Column(
      children: [
        _buildActionCard('Track Public Spending', Icons.track_changes, Colors.green, () => Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const BudgetViewerScreen()),
        )),
        _buildActionCard('Transparency Dashboard', Icons.visibility, Colors.blue, () => Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const TransparencyDashboardScreen()),
        )),
        _buildActionCard('View Public Concerns', Icons.people_alt, Colors.purple, () => Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const PublicConcernsScreen()),
        )),
      ],
    );
  }

  Widget _buildJournalistActions() {
    return Column(
      children: [
        _buildActionCard('Publish Reports', Icons.article, Colors.green, () => Navigator.pushNamed(context, '/publish')),
        _buildActionCard('Media Hub', Icons.media_bluetooth_on, Colors.purple, () => Navigator.pushNamed(context, '/media-hub')),
      ],
    );
  }

  Widget _buildDefaultActions() {
    return Column(
      children: [
        _buildActionCard('Track Public Spending', Icons.account_balance, Colors.blue, () => Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const BudgetViewerScreen()),
        )),
        _buildActionCard('Transparency Dashboard', Icons.visibility, Colors.purple, () => Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const TransparencyDashboardScreen()),
        )),
        _buildActionCard('View Reports', Icons.analytics, Colors.green, () => _showFeatureComingSoon('View Reports')),
      ],
    );
  }

  Widget _buildActionCard(String title, IconData icon, Color color, VoidCallback onTap) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: color, size: 20),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                ),
                Icon(Icons.arrow_forward_ios, color: Colors.grey.shade400, size: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAppPurposeSection() {
    return SlideTransition(
      position: _slideAnimation,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.grey.shade50,
              Colors.blue.shade50,
            ],
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.blue.shade100),
        ),
        child: Column(
          children: [
            Icon(
              Icons.visibility,
              color: Colors.blue.shade600,
              size: 32,
            ),
            const SizedBox(height: 16),
            Text(
              'Transparency & Accountability',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade800,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Civic Lense empowers citizens to track public spending, monitor government budgets, and ensure transparency in public administration.',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.blue,
      foregroundColor: Colors.white,
      elevation: 0,
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              userRole?.icon ?? Icons.home,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Civic Lense',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Home • ${userRole?.name ?? 'Dashboard'}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.white70,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        Container(
          margin: const EdgeInsets.only(right: 8),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: IconButton(
            icon: const Icon(Icons.notifications_outlined, size: 20),
            onPressed: () => _showFeatureComingSoon('Notifications'),
            tooltip: 'Notifications',
          ),
        ),
      ],
    );
  }

  Widget _buildNavigationDrawer() {
    return Drawer(
      backgroundColor: Colors.white,
      child: Column(
        children: [
          // Drawer Header
          Container(
            width: double.infinity,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Colors.blue, Color(0xFF1976D2)],
              ),
            ),
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CircleAvatar(
                      radius: 30,
                      backgroundColor: Colors.white.withOpacity(0.2),
                      child: Icon(
                        userRole?.icon ?? Icons.person,
                        color: Colors.white,
                        size: 30,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      '${userData?['firstName'] ?? 'User'} ${userData?['lastName'] ?? ''}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      userRole?.name ?? 'User',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          
          // Navigation Items
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                _buildDrawerItem(
                  icon: Icons.home,
                  title: 'Home',
                  onTap: () => Navigator.pop(context),
                ),
                _buildDrawerItem(
                  icon: Icons.dashboard,
                  title: 'My Dashboard',
                  onTap: () {
                    Navigator.pop(context);
                    _navigateToDashboard();
                  },
                ),
                // Admin-only approval option
                if (userRole?.userType == UserType.admin) ...[
                  _buildDrawerItem(
                    icon: Icons.approval,
                    title: 'User Approvals',
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const AdminApprovalScreen(),
                        ),
                      );
                    },
                  ),
                ],
                _buildDrawerItem(
                  icon: Icons.account_balance,
                  title: 'Budget Overview',
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const BudgetViewerScreen()),
                    );
                  },
                ),
                _buildDrawerItem(
                  icon: Icons.assignment,
                  title: 'Budget Allocations',
                  onTap: () {
                    Navigator.pop(context);
                    _showFeatureComingSoon('Budget Allocations');
                  },
                ),
                _buildDrawerItem(
                  icon: Icons.shopping_cart,
                  title: 'Tenders',
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const CitizenTenderScreen()),
                    );
                  },
                ),
                _buildDrawerItem(
                  icon: Icons.article,
                  title: 'News & Media',
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.pushNamed(context, '/news');
                  },
                ),
                _buildDrawerItem(
                  icon: Icons.forum,
                  title: 'Media Hub',
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.pushNamed(context, '/media-hub');
                  },
                ),
                _buildDrawerItem(
                  icon: Icons.people,
                  title: 'Communities',
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.pushNamed(context, '/communities');
                  },
                ),
                _buildDrawerItem(
                  icon: Icons.analytics,
                  title: 'Reports & Analytics',
                  onTap: () => _showFeatureComingSoon('Reports & Analytics'),
                ),
                _buildDrawerItem(
                  icon: Icons.report_problem,
                  title: 'Raise Concerns',
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const RaiseConcernScreen(),
                    ),
                  ),
                ),
                _buildDrawerItem(
                  icon: Icons.track_changes,
                  title: 'My Concerns',
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const UserConcernTrackingScreen(),
                    ),
                  ),
                ),
                _buildDrawerItem(
                  icon: Icons.people_alt,
                  title: 'View Public Concerns',
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const PublicConcernsScreen(),
                    ),
                  ),
                ),
                _buildDrawerItem(
                  icon: Icons.settings,
                  title: 'Settings',
                  onTap: () => _showFeatureComingSoon('Settings'),
                ),
                const Divider(),
                _buildDrawerItem(
                  icon: Icons.help,
                  title: 'Help & Support',
                  onTap: () => _showFeatureComingSoon('Help & Support'),
                ),
                _buildDrawerItem(
                  icon: Icons.info,
                  title: 'About',
                  onTap: () => _showFeatureComingSoon('About'),
                ),
                _buildDrawerItem(
                  icon: Icons.logout,
                  title: 'Sign Out',
                  onTap: () {
                    Navigator.pop(context);
                    _signOut();
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDrawerItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(
        icon,
        color: Colors.blue,
        size: 24,
      ),
      title: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
      ),
      onTap: onTap,
    );
  }

  Widget _buildBottomNavigationBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) {
            setState(() {
              _currentIndex = index;
            });
          },
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.white,
          selectedItemColor: Colors.blue,
          unselectedItemColor: Colors.grey.shade600,
          selectedFontSize: 12,
          unselectedFontSize: 12,
          elevation: 0,
          items: [
            BottomNavigationBarItem(
              icon: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: _currentIndex == 0 ? Colors.blue.withOpacity(0.1) : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  _currentIndex == 0 ? Icons.home : Icons.home_outlined,
                  size: _currentIndex == 0 ? 24 : 22,
                ),
              ),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: _currentIndex == 1 ? Colors.blue.withOpacity(0.1) : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  _currentIndex == 1 ? Icons.account_balance : Icons.account_balance_outlined,
                  size: _currentIndex == 1 ? 24 : 22,
                ),
              ),
              label: 'Budget',
            ),
            BottomNavigationBarItem(
              icon: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: _currentIndex == 2 ? Colors.blue.withOpacity(0.1) : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  _currentIndex == 2 ? Icons.shopping_cart : Icons.shopping_cart_outlined,
                  size: _currentIndex == 2 ? 24 : 22,
                ),
              ),
              label: 'Tenders',
            ),
            BottomNavigationBarItem(
              icon: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: _currentIndex == 3 ? Colors.blue.withOpacity(0.1) : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  _currentIndex == 3 ? Icons.dashboard : Icons.dashboard_outlined,
                  size: _currentIndex == 3 ? 24 : 22,
                ),
              ),
              label: 'Dashboard',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCurrentPage() {
    switch (_currentIndex) {
      case 0:
        return _buildHomePage();
      case 1:
        // Navigate to Budget Viewer Screen
        WidgetsBinding.instance.addPostFrameCallback((_) {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const BudgetViewerScreen()),
          );
          // Reset to home page after navigation
          setState(() {
            _currentIndex = 0;
          });
        });
        return _buildHomePage();
      case 2:
        // Navigate to Public Tender Viewer Screen
        WidgetsBinding.instance.addPostFrameCallback((_) {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const PublicTenderViewerScreen()),
          );
          // Reset to home page after navigation
          setState(() {
            _currentIndex = 0;
          });
        });
        return _buildHomePage();
      case 3:
        // Navigate to Dashboard
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _navigateToDashboard();
          // Reset to home page after navigation
          setState(() {
            _currentIndex = 0;
          });
        });
        return _buildHomePage();
      default:
        return _buildHomePage();
    }
  }

  Widget _buildHomePage() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Welcome Hero Section
          _buildWelcomeHero(),
          const SizedBox(height: 32),

          // Quick Stats with Animations
          _buildAnimatedQuickStats(),
          const SizedBox(height: 32),

          // Interactive Charts Section
          _buildInteractiveCharts(),
          const SizedBox(height: 32),

          // Main Navigation Cards
          _buildMainNavigationCards(),
          const SizedBox(height: 32),

          // Recent Highlights
          _buildRecentHighlights(),
          const SizedBox(height: 20),
        ],
      ),
    );
  }



  Widget _buildAnimatedQuickStats() {
    return SlideTransition(
      position: _slideAnimation,
      child: Row(
        children: [
          Expanded(
            child: AnimatedBuilder(
              animation: _pulseAnimation,
              builder: (context, child) {
                return Transform.scale(
                  scale: _pulseAnimation.value,
                  child: _buildStatCard(
                    'Allocations',
                    allocationsCount.toString(),
                    Icons.account_balance_wallet,
                    Colors.orange,
                    'Budget items',
                  ),
                );
              },
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: AnimatedBuilder(
              animation: _pulseAnimation,
              builder: (context, child) {
                return Transform.scale(
                  scale: _pulseAnimation.value * 0.95,
                  child: _buildStatCard(
                    'Active Tenders',
                    activeTendersCount.toString(),
                    Icons.assignment,
                    Colors.blue,
                    'In progress',
                  ),
                );
              },
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: AnimatedBuilder(
              animation: _pulseAnimation,
              builder: (context, child) {
                return Transform.scale(
                  scale: _pulseAnimation.value * 0.9,
                  child: _buildStatCard(
                    'Projects',
                    projectsCount.toString(),
                    Icons.work,
                    Colors.green,
                    'Ongoing',
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInteractiveCharts() {
    return SlideTransition(
      position: _slideAnimation,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Analytics Dashboard',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildPieChart(),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildBarChart(),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildLineChart(),
        ],
      ),
    );
  }

  Widget _buildPieChart() {
    // Calculate total for percentage calculations
    final total = allocationsCount + activeTendersCount + projectsCount;
    final allocationsPercent = total > 0 ? (allocationsCount / total * 100) : 0;
    final tendersPercent = total > 0 ? (activeTendersCount / total * 100) : 0;
    final projectsPercent = total > 0 ? (projectsCount / total * 100) : 0;
    
    return Container(
      height: 200,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: AnimatedBuilder(
        animation: _chartAnimation,
        builder: (context, child) {
          return PieChart(
            PieChartData(
              sections: [
                PieChartSectionData(
                  color: Colors.orange,
                  value: allocationsPercent * _chartAnimation.value,
                  title: '${allocationsPercent.toInt()}%',
                  radius: 50,
                  titleStyle: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                PieChartSectionData(
                  color: Colors.blue,
                  value: tendersPercent * _chartAnimation.value,
                  title: '${tendersPercent.toInt()}%',
                  radius: 50,
                  titleStyle: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                PieChartSectionData(
                  color: Colors.green,
                  value: projectsPercent * _chartAnimation.value,
                  title: '${projectsPercent.toInt()}%',
                  radius: 50,
                  titleStyle: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
              sectionsSpace: 2,
              centerSpaceRadius: 40,
            ),
          );
        },
      ),
    );
  }

  Widget _buildBarChart() {
    return Container(
      height: 200,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: AnimatedBuilder(
        animation: _chartAnimation,
        builder: (context, child) {
          return BarChart(
            BarChartData(
              alignment: BarChartAlignment.spaceAround,
              maxY: [allocationsCount, activeTendersCount, projectsCount].reduce((a, b) => a > b ? a : b).toDouble(),
              barTouchData: BarTouchData(enabled: false),
              titlesData: FlTitlesData(
                show: true,
                rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (double value, TitleMeta meta) {
                      const style = TextStyle(color: Colors.grey, fontSize: 10);
                      Widget text;
                      switch (value.toInt()) {
                        case 0:
                          text = const Text('Allocations', style: style);
                          break;
                        case 1:
                          text = const Text('Tenders', style: style);
                          break;
                        case 2:
                          text = const Text('Projects', style: style);
                          break;
                        default:
                          text = const Text('', style: style);
                          break;
                      }
                      return SideTitleWidget(axisSide: meta.axisSide, child: text);
                    },
                  ),
                ),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 40,
                    getTitlesWidget: (double value, TitleMeta meta) {
                      return Text(
                        value.toInt().toString(),
                        style: const TextStyle(color: Colors.grey, fontSize: 10),
                      );
                    },
                  ),
                ),
              ),
              borderData: FlBorderData(show: false),
              barGroups: [
                BarChartGroupData(
                  x: 0,
                  barRods: [
                    BarChartRodData(
                      toY: (allocationsCount * _chartAnimation.value).toDouble(),
                      color: Colors.orange,
                      width: 20,
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(4),
                        topRight: Radius.circular(4),
                      ),
                    ),
                  ],
                ),
                BarChartGroupData(
                  x: 1,
                  barRods: [
                    BarChartRodData(
                      toY: (activeTendersCount * _chartAnimation.value).toDouble(),
                      color: Colors.blue,
                      width: 20,
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(4),
                        topRight: Radius.circular(4),
                      ),
                    ),
                  ],
                ),
                BarChartGroupData(
                  x: 2,
                  barRods: [
                    BarChartRodData(
                      toY: (projectsCount * _chartAnimation.value).toDouble(),
                      color: Colors.green,
                      width: 20,
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(4),
                        topRight: Radius.circular(4),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildLineChart() {
    return Container(
      height: 200,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: AnimatedBuilder(
        animation: _chartAnimation,
        builder: (context, child) {
          return LineChart(
            LineChartData(
              gridData: FlGridData(show: true),
              titlesData: FlTitlesData(
                show: true,
                rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (double value, TitleMeta meta) {
                      const style = TextStyle(color: Colors.grey, fontSize: 10);
                      Widget text;
                      switch (value.toInt()) {
                        case 0:
                          text = const Text('Week 1', style: style);
                          break;
                        case 1:
                          text = const Text('Week 2', style: style);
                          break;
                        case 2:
                          text = const Text('Week 3', style: style);
                          break;
                        case 3:
                          text = const Text('Week 4', style: style);
                          break;
                        default:
                          text = const Text('', style: style);
                          break;
                      }
                      return SideTitleWidget(axisSide: meta.axisSide, child: text);
                    },
                  ),
                ),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 40,
                    getTitlesWidget: (double value, TitleMeta meta) {
                      return Text(
                        value.toInt().toString(),
                        style: const TextStyle(color: Colors.grey, fontSize: 10),
                      );
                    },
                  ),
                ),
              ),
              borderData: FlBorderData(show: true),
              lineBarsData: [
                LineChartBarData(
                  spots: [
                    FlSpot(0, (allocationsCount * _chartAnimation.value).toDouble()),
                    FlSpot(1, (activeTendersCount * _chartAnimation.value).toDouble()),
                    FlSpot(2, (projectsCount * _chartAnimation.value).toDouble()),
                    FlSpot(3, ((allocationsCount + activeTendersCount + projectsCount) * _chartAnimation.value).toDouble()),
                  ],
                  isCurved: true,
                  color: Colors.blue,
                  barWidth: 3,
                  dotData: FlDotData(show: true),
                  belowBarData: BarAreaData(
                    show: true,
                    color: Colors.blue.withOpacity(0.1),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _showFeatureComingSoon(String featureName) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$featureName feature coming soon!'),
        backgroundColor: userRole?.color ?? Colors.blue,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Widget _buildPendingApprovalScreen() {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Account Pending Approval'),
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      bottomNavigationBar: _buildBottomNavigationBar(),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Pending Icon
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(40),
                ),
                child: Icon(
                  Icons.hourglass_empty,
                  size: 50,
                  color: Colors.orange.shade600,
                ),
              ),
              const SizedBox(height: 16),
              
              // Title
              Text(
                'Account Pending Approval',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey.shade800,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              
              // Description
              Text(
                'Your account is currently under review by our administrators. You will receive a notification once your account is approved.',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade600,
                  height: 1.4,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              
              // Status Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          color: Colors.orange.shade600,
                          size: 24,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Account Status',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey.shade800,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.orange.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            'PENDING',
                            style: TextStyle(
                              color: Colors.orange.shade700,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                        const Spacer(),
                        Text(
                          'Under Review',
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              
              // What you can do section
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.blue.withOpacity(0.2)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.lightbulb_outline,
                          color: Colors.blue.shade600,
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'What you can do while waiting:',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue.shade700,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    _buildPendingActionItem(
                      'View public information',
                      'Access budget data and public reports',
                      Icons.visibility,
                    ),
                    _buildPendingActionItem(
                      'Track government spending',
                      'Monitor public expenditure and allocations',
                      Icons.track_changes,
                    ),
                    _buildPendingActionItem(
                      'Read public concerns',
                      'View community issues and resolutions',
                      Icons.people_alt,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              
              // Action Buttons
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () async {
                        // Navigate to home screen with limited functionality
                        final prefs = await SharedPreferences.getInstance();
                        await prefs.setBool('hasChosenLimitedAccess', true);
                        setState(() {
                          showPendingScreen = false;
                          hasChosenLimitedAccess = true;
                        });
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Continue with Limited Access',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _signOut,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.grey.shade600,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Sign Out',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPendingActionItem(String title, String description, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(
            icon,
            color: Colors.blue.shade600,
            size: 14,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade800,
                  ),
                ),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
