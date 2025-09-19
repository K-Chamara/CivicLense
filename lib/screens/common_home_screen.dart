import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/auth_service.dart';
import '../models/user_role.dart';
import 'login_screen.dart';
import 'budget_viewer_screen.dart';
import 'citizen_tender_screen.dart';
import 'raise_concern_screen.dart';
import 'public_concerns_screen.dart';
import 'enhanced_dashboard_screen.dart';
import 'admin_dashboard_screen.dart';
import 'finance_officer_dashboard_screen.dart';
import 'procurement_officer_dashboard_screen.dart';
import 'anticorruption_officer_dashboard_screen.dart';
import 'public_user_dashboard_screen.dart';
import 'admin_approval_screen.dart';

class CommonHomeScreen extends StatefulWidget {
  const CommonHomeScreen({super.key});

  @override
  State<CommonHomeScreen> createState() => _CommonHomeScreenState();
}

class _CommonHomeScreenState extends State<CommonHomeScreen>
    with TickerProviderStateMixin {
  final AuthService _authService = AuthService();
  UserRole? userRole;
  Map<String, dynamic>? userData;
  bool isLoading = true;
  bool showPendingScreen = true;
  bool hasChosenLimitedAccess = false;
  
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
            child: _buildStatCard(
              'Active Tenders',
              '24',
              Icons.shopping_cart,
              Colors.orange,
              '+12% this month',
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: _buildStatCard(
              'Budget Allocated',
              '\$2.4M',
              Icons.account_balance_wallet,
              Colors.green,
              'Across 8 sectors',
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: _buildStatCard(
              'Projects',
              '12',
              Icons.construction,
              Colors.purple,
              'In progress',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color, String subtitle) {
    return Container(
      height: 160, // Fixed height for all cards
      width: double.infinity, // Ensure full width
      padding: const EdgeInsets.all(12),
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
              Icon(Icons.trending_up, color: Colors.green, size: 14),
            ],
          ),
          // Content area with fixed heights
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Value with fixed height
                Container(
                  height: 30,
                  child: Text(
                    value,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                ),
                // Title with fixed height
                Container(
                  height: 20,
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.grey,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                // Subtitle with fixed height
                Container(
                  height: 32,
                  child: Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.grey.shade600,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
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
                    MaterialPageRoute(builder: (context) => const CitizenTenderScreen()),
                  ),
                ),
              ),
              const SizedBox(width: 16),
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
        return _buildBudgetPage();
      case 2:
        return _buildTendersPage();
      case 3:
        return _buildDashboardPage();
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
          const SizedBox(height: 32),

          // Role-specific Quick Actions
          _buildRoleSpecificActions(),
          const SizedBox(height: 32),

          // App Purpose & Transparency
          _buildAppPurposeSection(),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildBudgetPage() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Budget Header
          _buildPageHeader(
            'Budget Overview',
            'Track government spending and budget allocations',
            Icons.account_balance,
            Colors.blue,
          ),
          const SizedBox(height: 24),

          // Budget Stats
          _buildBudgetStats(),
          const SizedBox(height: 24),

          // Budget Categories
          _buildBudgetCategories(),
          const SizedBox(height: 24),

          // Quick Actions
          _buildBudgetQuickActions(),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildTendersPage() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Tenders Header
          _buildPageHeader(
            'Active Tenders',
            'View current procurement opportunities',
            Icons.shopping_cart,
            Colors.orange,
          ),
          const SizedBox(height: 24),

          // Tender Stats
          _buildTenderStats(),
          const SizedBox(height: 24),

          // Recent Tenders
          _buildRecentTenders(),
          const SizedBox(height: 24),

          // Quick Actions
          _buildTenderQuickActions(),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildDashboardPage() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Dashboard Header
          _buildPageHeader(
            'My Dashboard',
            'Access your personalized dashboard',
            Icons.dashboard,
            userRole?.color ?? Colors.purple,
          ),
          const SizedBox(height: 24),

          // Dashboard Content
          _buildDashboardContent(),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildPageHeader(String title, String subtitle, IconData icon, Color color) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [color, color.withOpacity(0.8)],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: Colors.white, size: 32),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 16,
                    color: Colors.white70,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBudgetStats() {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            'Total Budget',
            '\$2.4M',
            Icons.account_balance_wallet,
            Colors.blue,
            'Allocated this year',
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildStatCard(
            'Spent',
            '\$1.8M',
            Icons.trending_up,
            Colors.green,
            '75% utilized',
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildStatCard(
            'Remaining',
            '\$600K',
            Icons.savings,
            Colors.orange,
            '25% left',
          ),
        ),
      ],
    );
  }

  Widget _buildBudgetCategories() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Budget Categories',
          style: TextStyle(
            fontSize: 20,
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
              _buildCategoryItem('Infrastructure', '\$1.2M', 80, Colors.blue),
              _buildCategoryItem('Education', '\$800K', 65, Colors.green),
              _buildCategoryItem('Healthcare', '\$400K', 45, Colors.red),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCategoryItem(String name, String amount, double percentage, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  amount,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
          Text(
            '${percentage.toInt()}%',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBudgetQuickActions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Quick Actions',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildActionCard(
                'View Details',
                Icons.visibility,
                Colors.blue,
                () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const BudgetViewerScreen()),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildActionCard(
                'Download Report',
                Icons.download,
                Colors.green,
                () => _showFeatureComingSoon('Download Report'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTenderStats() {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            'Active Tenders',
            '24',
            Icons.shopping_cart,
            Colors.orange,
            'Open for bidding',
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildStatCard(
            'Total Value',
            '\$1.5M',
            Icons.attach_money,
            Colors.green,
            'Combined value',
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildStatCard(
            'Deadlines',
            '8',
            Icons.schedule,
            Colors.red,
            'Closing soon',
          ),
        ),
      ],
    );
  }

  Widget _buildRecentTenders() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Recent Tenders',
          style: TextStyle(
            fontSize: 20,
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
              _buildTenderItem('Road Construction', '\$500K', '2 days left', Colors.blue),
              _buildTenderItem('School Building', '\$300K', '5 days left', Colors.green),
              _buildTenderItem('Water Supply', '\$250K', '1 week left', Colors.orange),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTenderItem(String title, String amount, String deadline, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  amount,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
          Text(
            deadline,
            style: TextStyle(
              fontSize: 12,
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTenderQuickActions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Quick Actions',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildActionCard(
                'View All Tenders',
                Icons.list,
                Colors.orange,
                () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const CitizenTenderScreen()),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildActionCard(
                'Apply for Tender',
                Icons.add,
                Colors.green,
                () => _showFeatureComingSoon('Apply for Tender'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDashboardContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Role-specific content based on user role
        _buildRoleSpecificContent(),
      ],
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
                    'Active Tenders',
                    '24',
                    Icons.shopping_cart,
                    Colors.orange,
                    '+12% this month',
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
                    'Budget Allocated',
                    '\$2.4M',
                    Icons.account_balance_wallet,
                    Colors.green,
                    'Across 8 sectors',
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
                    '12',
                    Icons.construction,
                    Colors.purple,
                    'In progress',
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
                  color: Colors.blue,
                  value: 40 * _chartAnimation.value,
                  title: '40%',
                  radius: 50,
                  titleStyle: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                PieChartSectionData(
                  color: Colors.green,
                  value: 30 * _chartAnimation.value,
                  title: '30%',
                  radius: 50,
                  titleStyle: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                PieChartSectionData(
                  color: Colors.orange,
                  value: 20 * _chartAnimation.value,
                  title: '20%',
                  radius: 50,
                  titleStyle: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                PieChartSectionData(
                  color: Colors.red,
                  value: 10 * _chartAnimation.value,
                  title: '10%',
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
              maxY: 100,
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
                          text = const Text('Jan', style: style);
                          break;
                        case 1:
                          text = const Text('Feb', style: style);
                          break;
                        case 2:
                          text = const Text('Mar', style: style);
                          break;
                        case 3:
                          text = const Text('Apr', style: style);
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
                      toY: 60 * _chartAnimation.value,
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
                  x: 1,
                  barRods: [
                    BarChartRodData(
                      toY: 80 * _chartAnimation.value,
                      color: Colors.green,
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
                      toY: 45 * _chartAnimation.value,
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
                  x: 3,
                  barRods: [
                    BarChartRodData(
                      toY: 90 * _chartAnimation.value,
                      color: Colors.purple,
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
                    FlSpot(0, 3 * _chartAnimation.value),
                    FlSpot(1, 5 * _chartAnimation.value),
                    FlSpot(2, 4 * _chartAnimation.value),
                    FlSpot(3, 7 * _chartAnimation.value),
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
