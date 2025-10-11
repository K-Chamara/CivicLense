import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/news_service.dart';
import '../services/media_hub_service.dart';
import '../models/user_role.dart';
import '../models/report.dart';
import 'login_screen.dart';
import 'budget_viewer_screen.dart';
import 'citizen_tender_screen.dart';
import 'raise_concern_screen.dart';
import 'concern_management_screen.dart';
import 'public_concerns_screen.dart';
import 'user_concern_tracking_screen.dart';
import 'settings_screen.dart';
import 'public_tender_viewer_screen.dart';
import 'admin_dashboard_screen.dart';
import 'finance_officer_dashboard_screen.dart';
import 'procurement_officer_dashboard_screen.dart';
import 'anticorruption_officer_dashboard_screen.dart';
import 'public_user_dashboard_screen.dart';
import 'budget_allocations_view_screen.dart';
import 'reports_analytics_screen.dart';
import 'article_detail_screen.dart';

class EnhancedDashboardScreen extends StatefulWidget {
  const EnhancedDashboardScreen({super.key});

  @override
  State<EnhancedDashboardScreen> createState() => _EnhancedDashboardScreenState();
}

class _EnhancedDashboardScreenState extends State<EnhancedDashboardScreen>
    with TickerProviderStateMixin {
  final AuthService _authService = AuthService();
  final NewsService _newsService = NewsService();
  final MediaHubService _mediaHubService = MediaHubService();
  UserRole? userRole;
  Map<String, dynamic>? userData;
  bool isLoading = true;
  
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 600),
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
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutCubic,
    ));
    
    _loadUserData();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
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

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      drawer: _buildNavigationDrawer(),
      appBar: _buildAppBar(),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: SlideTransition(
          position: _slideAnimation,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Pending Status Banner (if user is pending)
                if (userData?['status'] == 'pending') ...[
                  _buildPendingStatusBanner(),
                  const SizedBox(height: 16),
                ],
                
                // For journalists, only show journalist-specific content
                if (userRole?.id == 'journalist') ...[
                  _buildJournalistContent(),
                ] else ...[
                  // Welcome Section
                  _buildWelcomeSection(),
                  const SizedBox(height: 24),
                  // Quick Stats Cards
                  _buildQuickStatsCards(),
                  const SizedBox(height: 24),

                  // Tender & Budget Overview
                  _buildTenderBudgetOverview(),
                  const SizedBox(height: 24),

                  // Budget Allocations Section
                  _buildBudgetAllocationsSection(),
                  const SizedBox(height: 24),

                  // Role-specific Quick Actions
                  _buildQuickActions(),
                  const SizedBox(height: 24),

                  // Recent Activities
                  _buildRecentActivities(),
                  const SizedBox(height: 24),

                  // Role-specific Content
                  _buildRoleSpecificContent(),
                ],
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: _buildBottomNavigationBar(),
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
              userRole?.icon ?? Icons.dashboard,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Civic Lense',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  userRole?.name ?? 'Dashboard',
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
            icon: const Icon(Icons.logout, size: 20),
            onPressed: _signOut,
            tooltip: 'Sign Out',
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
                  icon: Icons.dashboard,
                  title: 'Dashboard',
                  onTap: () => Navigator.pop(context),
                ),
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
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const BudgetAllocationsViewScreen()),
                    );
                  },
                ),
                _buildDrawerItem(
                  icon: Icons.shopping_cart,
                  title: 'Tenders',
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const PublicTenderViewerScreen()),
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
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const ReportsAnalyticsScreen()),
                    );
                  },
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
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const SettingsScreen(),
                    ),
                  ),
                ),
                const Divider(),
                _buildDrawerItem(
                  icon: Icons.logout,
                  title: 'Sign Out',
                  onTap: () {
                    Navigator.pop(context);
                    _signOut();
                  },
                ),
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

  Widget _buildWelcomeSection() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blue, Colors.blue.shade700],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withOpacity(0.3),
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
                  userRole?.description ?? 'Track public spending and ensure transparency',
                  style: const TextStyle(
                    fontSize: 16,
                    color: Colors.white70,
                    fontWeight: FontWeight.w300,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickStatsCards() {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            'Active Tenders',
            '24',
            Icons.shopping_cart,
            Colors.orange,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildStatCard(
            'Budget Allocated',
            '\$2.4M',
            Icons.account_balance_wallet,
            Colors.green,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildStatCard(
            'Projects',
            '12',
            Icons.construction,
            Colors.purple,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(20),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              Icon(Icons.trending_up, color: Colors.green, size: 16),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: const TextStyle(
              fontSize: 12,
              color: Colors.grey,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTenderBudgetOverview() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Tender & Budget Overview',
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
              child: _buildOverviewCard(
                'Recent Tenders',
                [
                  'Road Construction - \$50L',
                  'School Building - \$30L',
                  'Water Supply - \$25L',
                ],
                Icons.shopping_cart,
                Colors.orange,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildOverviewCard(
                'Budget Categories',
                [
                  'Infrastructure - \$1.2M',
                  'Education - \$800K',
                  'Healthcare - \$400K',
                ],
                Icons.pie_chart,
                Colors.blue,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildBudgetAllocationsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Budget Allocations',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const BudgetAllocationsViewScreen()),
                );
              },
              child: const Text(
                'View All',
                style: TextStyle(
                  color: Colors.blue,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(20),
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
          child: Column(
            children: [
              _buildAllocationItem(
                'Infrastructure Development',
                'Roads, bridges, public buildings, and utilities',
                '\$12,00,00,000',
                '1',
                '1',
                Colors.blue,
                'Active',
              ),
              const Divider(height: 24),
              _buildAllocationItem(
                'School Development',
                'We are focusing on government school projects',
                '\$10,00,000',
                '1',
                '1',
                Colors.teal,
                'Active',
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAllocationItem(
    String title,
    String description,
    String budget,
    String subcategories,
    String items,
    Color color,
    String status,
  ) {
    return Row(
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
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  _buildAllocationMetric('Total Budget', budget, Colors.blue),
                  const SizedBox(width: 16),
                  _buildAllocationMetric('Subcategories', subcategories, Colors.orange),
                  const SizedBox(width: 16),
                  _buildAllocationMetric('Total Items', items, Colors.green),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    height: 8,
                    width: 100,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: FractionallySizedBox(
                      alignment: Alignment.centerLeft,
                      widthFactor: 0.3,
                      child: Container(
                        decoration: BoxDecoration(
                          color: color,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      status,
                      style: const TextStyle(
                        fontSize: 10,
                        color: Colors.green,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAllocationMetric(String label, String value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 10,
            color: Colors.grey,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildOverviewCard(String title, List<String> items, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(20),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...items.map((item) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    item,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.black87,
                    ),
                  ),
                ),
              ],
            ),
          )).toList(),
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
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
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 1.5,
          children: [
            _buildActionCard(
              'View Tenders',
              Icons.shopping_cart,
              Colors.orange,
              () => _showFeatureComingSoon('View Tenders'),
            ),
            _buildActionCard(
              'Budget Reports',
              Icons.analytics,
              Colors.blue,
              () => _showFeatureComingSoon('Budget Reports'),
            ),
            _buildActionCard(
              'Raise Concern',
              Icons.report_problem,
              Colors.red,
              () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const RaiseConcernScreen(),
                ),
              ),
            ),
            _buildActionCard(
              'Track Projects',
              Icons.track_changes,
              Colors.green,
              () => _showFeatureComingSoon('Track Projects'),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionCard(String title, IconData icon, Color color, VoidCallback onTap) {
    return Container(
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
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: color, size: 24),
                ),
                const SizedBox(height: 12),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRecentActivities() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Recent Activities',
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
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.1),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            children: [
              _buildActivityItem(
                'New tender published for road construction',
                '2 hours ago',
                Icons.shopping_cart,
                Colors.orange,
              ),
              _buildActivityItem(
                'Budget allocation updated for Q4',
                '1 day ago',
                Icons.account_balance_wallet,
                Colors.blue,
              ),
              _buildActivityItem(
                'Project milestone completed',
                '2 days ago',
                Icons.check_circle,
                Colors.green,
              ),
              _buildActivityItem(
                'Concern raised about water supply',
                '3 days ago',
                Icons.report_problem,
                Colors.red,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildActivityItem(String title, String time, IconData icon, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 16),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w500,
                    fontSize: 14,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  time,
                  style: const TextStyle(
                    color: Colors.grey,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRoleSpecificContent() {
    // Check if user is pending (not approved) - show citizen content with limited access
    final status = userData?['status'] ?? 'pending';
    final isApproved = status == 'approved';
    
    // If user is not approved and not a citizen/admin, show citizen content (limited access)
    if (!isApproved && userRole?.id != 'citizen' && userRole?.id != 'admin') {
      return _buildPendingUserContent();
    }
    
    // Show full role-specific dashboard content for approved users
    switch (userRole?.id) {
      case 'admin':
        return _buildFullAdminDashboard();
      case 'finance_officer':
        return _buildFullFinanceOfficerDashboard();
      case 'procurement_officer':
        return _buildFullProcurementOfficerDashboard();
      case 'anticorruption_officer':
        return _buildFullAntiCorruptionOfficerDashboard();
      case 'citizen':
        return _buildCitizenContent();
      case 'journalist':
        return _buildJournalistContent();
      case 'researcher':
        return _buildResearcherContent();
      case 'community_leader':
        return _buildCommunityLeaderContent();
      case 'ngo':
        return _buildNGOContent();
      default:
        return _buildDefaultContent();
    }
  }

  Widget _buildPendingUserContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Pending approval notice
        Container(
          padding: const EdgeInsets.all(16),
          margin: const EdgeInsets.only(bottom: 20),
          decoration: BoxDecoration(
            color: Colors.orange.withOpacity(0.1),
            border: Border.all(color: Colors.orange, width: 1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Icon(
                Icons.pending_actions,
                color: Colors.orange,
                size: 24,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Account Pending Approval',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.orange[800],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Your account is being reviewed. You currently have limited access with citizen-level features. Full access will be granted once approved by an administrator.',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.orange[700],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        
        // Show citizen content for pending users
        _buildCitizenContent(),
      ],
    );
  }

  Widget _buildAdminContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Admin Tools',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 16),
        _buildFeatureCard(
          'User Management',
          'Manage all users and their roles',
          Icons.people,
          Colors.purple,
          () => _showFeatureComingSoon('User Management'),
        ),
        _buildFeatureCard(
          'System Analytics',
          'View system-wide analytics and reports',
          Icons.analytics,
          Colors.blue,
          () => _showFeatureComingSoon('System Analytics'),
        ),
      ],
    );
  }

  Widget _buildFinanceOfficerContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Finance Officer Tools',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 16),
        _buildFeatureCard(
          'Budget Management',
          'Create and manage government budgets',
          Icons.account_balance_wallet,
          Colors.green,
          () => _showFeatureComingSoon('Budget Management'),
        ),
        _buildFeatureCard(
          'Financial Reports',
          'Generate financial reports and statements',
          Icons.receipt_long,
          Colors.blue,
          () => _showFeatureComingSoon('Financial Reports'),
        ),
      ],
    );
  }

  Widget _buildProcurementOfficerContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Procurement Officer Tools',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 16),
        _buildFeatureCard(
          'Tender Management',
          'Create and manage government tenders',
          Icons.shopping_cart,
          Colors.orange,
          () => _showFeatureComingSoon('Tender Management'),
        ),
        _buildFeatureCard(
          'Vendor Management',
          'Manage vendor relationships and contracts',
          Icons.business,
          Colors.blue,
          () => _showFeatureComingSoon('Vendor Management'),
        ),
      ],
    );
  }

  Widget _buildAntiCorruptionOfficerContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Anti-Corruption Officer Tools',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 16),
        _buildFeatureCard(
          'Concern Management',
          'Review and manage public concerns',
          Icons.report_problem,
          Colors.red,
          () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const ConcernManagementScreen(),
            ),
          ),
        ),
        _buildFeatureCard(
          'Investigation Tools',
          'Tools for corruption investigations',
          Icons.search,
          Colors.orange,
          () => _showFeatureComingSoon('Investigation Tools'),
        ),
      ],
    );
  }

  Widget _buildCitizenContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Citizen Tools',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 16),
        _buildFeatureCard(
          'Government Budget',
          'Explore how your tax money is allocated and spent',
          Icons.account_balance,
          Colors.blue,
          () => Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const BudgetViewerScreen()),
          ),
        ),
        _buildFeatureCard(
          'Government Tenders',
          'View active tenders and procurement opportunities',
          Icons.assignment,
          Colors.purple,
          () => Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const CitizenTenderScreen()),
          ),
        ),
        _buildFeatureCard(
          'News & Media',
          'Read latest news articles and engage with content',
          Icons.article,
          Colors.orange,
          () => Navigator.pushNamed(context, '/news'),
        ),
        _buildFeatureCard(
          'Track Public Spending',
          'Monitor government budgets and expenditures',
          Icons.track_changes,
          Colors.green,
          () => _showFeatureComingSoon('Track Public Spending'),
        ),
        _buildFeatureCard(
          'Raise Concerns',
          'Report issues and track their resolution',
          Icons.report_problem,
          Colors.orange,
          () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const RaiseConcernScreen(),
            ),
          ),
        ),
        _buildFeatureCard(
          'View Public Concerns',
          'See what others are concerned about and show support',
          Icons.people_alt,
          Colors.purple,
          () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const PublicConcernsScreen(),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildJournalistContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Enhanced Media & Journalism Hub Section
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                const Color(0xFF1E3A8A), // Deep blue
                const Color(0xFF3B82F6), // Blue
                const Color(0xFF06B6D4), // Cyan
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              stops: const [0.0, 0.5, 1.0],
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF1E3A8A).withOpacity(0.25),
                blurRadius: 20,
                offset: const Offset(0, 8),
                spreadRadius: 0,
              ),
              BoxShadow(
                color: const Color(0xFF06B6D4).withOpacity(0.15),
                blurRadius: 40,
                offset: const Offset(0, 16),
                spreadRadius: -10,
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.25),
                    width: 1.5,
                  ),
                ),
                child: const Icon(
                  Icons.article_outlined,
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
                      'Welcome back, ${userData?['name'] ?? 'Journalist'}',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Media & Journalism Hub',
                      style: TextStyle(
                        fontSize: 18,
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Your professional workspace for investigative reporting',
                      style: TextStyle(
                        fontSize: 15,
                        color: Colors.white.withOpacity(0.9),
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.2),
                    width: 1,
                  ),
                ),
                child: const Icon(
                  Icons.trending_up,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 28),

        // Quick Stats Section
        _buildJournalistStats(),
        const SizedBox(height: 28),

        // Main Tools Section
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF3B82F6).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.build_outlined,
                color: Color(0xFF3B82F6),
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            const Text(
              'Core Tools',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1F2937),
                letterSpacing: -0.3,
              ),
            ),
          ],
        ),
        const SizedBox(height: 18),
        
        // Primary Tools Grid
        Row(
          children: [
            Expanded(
              child: _buildJournalistToolCard(
                'Publish Article',
                'Create and publish investigative reports',
                Icons.edit_document,
                const Color(0xFF10B981), // Emerald
                () => Navigator.pushNamed(context, '/publish'),
                isPrimary: true,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildJournalistToolCard(
                'Media Hub',
                'Save and organize articles',
                Icons.bookmark_add,
                const Color(0xFF8B5CF6), // Purple
                () => Navigator.pushNamed(context, '/media-hub'),
                isPrimary: true,
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        
        Row(
          children: [
            Expanded(
              child: _buildJournalistToolCard(
                'News Feed',
                'Browse latest articles',
                Icons.feed,
                const Color(0xFF3B82F6), // Blue
                () => Navigator.pushNamed(context, '/news'),
                isPrimary: true,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildJournalistToolCard(
                'Tender Watch',
                'Monitor government tenders',
                Icons.shopping_cart,
                const Color(0xFFF59E0B), // Amber
                () => Navigator.pushNamed(context, '/tender-management'),
                isPrimary: true,
              ),
            ),
          ],
        ),
        const SizedBox(height: 28),

        // Recent Articles Section
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF10B981).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.article_outlined,
                color: Color(0xFF10B981),
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            const Text(
              'Recent Articles',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1F2937),
                letterSpacing: -0.3,
              ),
            ),
          ],
        ),
        const SizedBox(height: 18),
        _buildRecentArticlesSection(),
        const SizedBox(height: 28),

        // Recent Saved Articles Section
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF8B5CF6).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.bookmark_outline,
                color: Color(0xFF8B5CF6),
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            const Text(
              'Recent Saved Articles',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1F2937),
                letterSpacing: -0.3,
              ),
            ),
          ],
        ),
        const SizedBox(height: 18),
        _buildRecentSavedArticlesSection(),
      ],
    );
  }

  Widget _buildResearcherContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Researcher Tools',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 16),
        _buildFeatureCard(
          'Data Analysis',
          'Analyze government data and trends',
          Icons.analytics,
          Colors.blue,
          () => _showFeatureComingSoon('Data Analysis'),
        ),
        _buildFeatureCard(
          'Research Reports',
          'Create and publish research findings',
          Icons.science,
          Colors.green,
          () => _showFeatureComingSoon('Research Reports'),
        ),
        _buildFeatureCard(
          'Budget Research',
          'Deep dive into budget allocations and spending',
          Icons.account_balance,
          Colors.purple,
          () => Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const BudgetViewerScreen()),
          ),
        ),
      ],
    );
  }

  Widget _buildCommunityLeaderContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Community Leader Tools',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 16),
        _buildFeatureCard(
          'Community Management',
          'Manage community groups and discussions',
          Icons.groups,
          Colors.blue,
          () => _showFeatureComingSoon('Community Management'),
        ),
        _buildFeatureCard(
          'Public Concerns',
          'View and address community concerns',
          Icons.people_alt,
          Colors.orange,
          () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const PublicConcernsScreen(),
            ),
          ),
        ),
        _buildFeatureCard(
          'Community Posts',
          'Create and manage community posts',
          Icons.post_add,
          Colors.green,
          () => _showFeatureComingSoon('Community Posts'),
        ),
      ],
    );
  }

  Widget _buildNGOContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'NGO Tools',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 16),
        _buildFeatureCard(
          'Project Management',
          'Manage NGO projects and initiatives',
          Icons.work,
          Colors.blue,
          () => _showFeatureComingSoon('Project Management'),
        ),
        _buildFeatureCard(
          'Public Concerns',
          'View and respond to public concerns',
          Icons.people_alt,
          Colors.orange,
          () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const PublicConcernsScreen(),
            ),
          ),
        ),
        _buildFeatureCard(
          'Budget Monitoring',
          'Monitor government budget allocations',
          Icons.account_balance,
          Colors.purple,
          () => Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const BudgetViewerScreen()),
          ),
        ),
        _buildFeatureCard(
          'Reports & Analytics',
          'Generate reports on government spending',
          Icons.assessment,
          Colors.green,
          () => _showFeatureComingSoon('Reports & Analytics'),
        ),
      ],
    );
  }

  Widget _buildDefaultContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'General Tools',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 16),
        _buildFeatureCard(
          'Track Public Spending',
          'Monitor government budgets and expenditures',
          Icons.account_balance,
          Colors.blue,
          () => _showFeatureComingSoon('Track Public Spending'),
        ),
        _buildFeatureCard(
          'View Reports',
          'Access transparency reports and analytics',
          Icons.analytics,
          Colors.green,
          () => _showFeatureComingSoon('View Reports'),
        ),
      ],
    );
  }

  Widget _buildFeatureCard(String title, String description, IconData icon, Color color, VoidCallback onTap) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(20),
        leading: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: color, size: 24),
        ),
        title: Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        subtitle: Text(
          description,
          style: const TextStyle(
            color: Colors.grey,
            fontSize: 14,
          ),
        ),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: onTap,
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

  Widget _buildBottomNavigationBar() {
    return BottomNavigationBar(
      type: BottomNavigationBarType.fixed,
      backgroundColor: Colors.white,
      selectedItemColor: userRole?.color ?? Colors.blue,
      unselectedItemColor: Colors.grey,
      currentIndex: 3, // Dashboard is selected (index 3)
      onTap: (index) {
        switch (index) {
          case 0:
            Navigator.pushNamed(context, '/common-home');
            break;
          case 1:
            Navigator.pushNamed(context, '/budget-viewer');
            break;
          case 2:
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const PublicTenderViewerScreen()),
            );
            break;
          case 3:
            // Navigate to role-specific dashboard (same as hamburger menu)
            // This will take you to the full role-specific dashboard
            _navigateToRoleSpecificDashboard();
            break;
        }
      },
      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.home),
          label: 'Home',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.account_balance),
          label: 'Budget',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.shopping_cart),
          label: 'Tenders',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.dashboard),
          label: 'Dashboard',
        ),
      ],
    );
  }

  Widget _buildPendingStatusBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.orange.shade400, Colors.orange.shade600],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.orange.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.hourglass_empty,
              color: Colors.white,
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Account Pending Approval',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Your account is under review. You have limited access to citizen features until approved.',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Full Dashboard Content Methods
  Widget _buildFullAdminDashboard() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Welcome Section
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.blue, Colors.blue.shade700],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.blue.withOpacity(0.3),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.admin_panel_settings,
                      color: Colors.white,
                      size: 32,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Welcome, ${userData?['firstName'] ?? 'Admin'}!',
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'System Administrator Dashboard',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.white.withOpacity(0.9),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // Statistics Cards
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                'Total Users',
                '1,234',
                Icons.people,
                Colors.blue,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildStatCard(
                'Active Concerns',
                '45',
                Icons.report_problem,
                Colors.orange,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                'Budget Allocated',
                '\$2.5M',
                Icons.account_balance,
                Colors.green,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildStatCard(
                'Pending Approvals',
                '12',
                Icons.pending_actions,
                Colors.purple,
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),

        // Management Features
        const Text(
          'Management Features',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 16),
        _buildFeatureCard(
          'User Management',
          'Manage all users and their roles',
          Icons.people,
          Colors.purple,
          () => Navigator.pushNamed(context, '/user-management'),
        ),
        _buildFeatureCard(
          'System Analytics',
          'View system-wide analytics and reports',
          Icons.analytics,
          Colors.blue,
          () => Navigator.pushNamed(context, '/analytics'),
        ),
        _buildFeatureCard(
          'Budget Oversight',
          'Monitor and approve budget allocations',
          Icons.account_balance_wallet,
          Colors.green,
          () => Navigator.pushNamed(context, '/budget-oversight'),
        ),
        _buildFeatureCard(
          'Concern Management',
          'Review and manage public concerns',
          Icons.report_problem,
          Colors.orange,
          () => Navigator.pushNamed(context, '/concern-management'),
        ),
      ],
    );
  }

  Widget _buildFullFinanceOfficerDashboard() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Welcome Section
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.green, Colors.green.shade700],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.green.withOpacity(0.3),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.account_balance,
                      color: Colors.white,
                      size: 32,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Welcome, ${userData?['firstName'] ?? 'Finance Officer'}!',
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Finance Officer Dashboard',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.white.withOpacity(0.9),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // Quick Stats
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                'Total Budget',
                '\$5.2M',
                Icons.account_balance_wallet,
                Colors.green,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildStatCard(
                'Spent This Month',
                '\$1.8M',
                Icons.trending_down,
                Colors.orange,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                'Pending Approvals',
                '23',
                Icons.pending_actions,
                Colors.blue,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildStatCard(
                'Active Projects',
                '15',
                Icons.work,
                Colors.purple,
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),

        // Main Features
        const Text(
          'Financial Management',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 16),
        _buildFeatureCard(
          'Budget Management',
          'Manage and monitor government budgets',
          Icons.account_balance_wallet,
          Colors.green,
          () => Navigator.pushNamed(context, '/budget-management'),
        ),
        _buildFeatureCard(
          'Financial Reports',
          'Generate financial reports and statements',
          Icons.receipt_long,
          Colors.blue,
          () => Navigator.pushNamed(context, '/financial-reports'),
        ),
        _buildFeatureCard(
          'Expense Tracking',
          'Track and approve government expenses',
          Icons.trending_up,
          Colors.orange,
          () => Navigator.pushNamed(context, '/expense-tracking'),
        ),
        _buildFeatureCard(
          'Audit Management',
          'Manage financial audits and compliance',
          Icons.verified,
          Colors.purple,
          () => Navigator.pushNamed(context, '/audit-management'),
        ),
      ],
    );
  }

  Widget _buildFullProcurementOfficerDashboard() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Welcome Section
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.blue, Colors.blue.shade700],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.blue.withOpacity(0.3),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.shopping_cart,
                      color: Colors.white,
                      size: 32,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Welcome, ${userData?['firstName'] ?? 'Procurement Officer'}!',
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Procurement Officer Dashboard',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.white.withOpacity(0.9),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // Quick Stats
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                'Active Tenders',
                '28',
                Icons.shopping_cart,
                Colors.blue,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildStatCard(
                'Total Value',
                '\$3.2M',
                Icons.account_balance,
                Colors.green,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                'Pending Bids',
                '156',
                Icons.pending_actions,
                Colors.orange,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildStatCard(
                'Completed Projects',
                '42',
                Icons.check_circle,
                Colors.purple,
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),

        // Main Features
        const Text(
          'Procurement Management',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 16),
        _buildFeatureCard(
          'Tender Management',
          'Create and manage government tenders',
          Icons.shopping_cart,
          Colors.orange,
          () => Navigator.pushNamed(context, '/tender-management'),
        ),
        _buildFeatureCard(
          'Vendor Management',
          'Manage vendor relationships and contracts',
          Icons.business,
          Colors.blue,
          () => Navigator.pushNamed(context, '/vendor-management'),
        ),
        _buildFeatureCard(
          'Purchase Orders',
          'Create and track purchase orders',
          Icons.shopping_bag,
          Colors.green,
          () => Navigator.pushNamed(context, '/purchase-orders'),
        ),
        _buildFeatureCard(
          'Contract Management',
          'Manage procurement contracts',
          Icons.description,
          Colors.purple,
          () => Navigator.pushNamed(context, '/contract-management'),
        ),
      ],
    );
  }

  Widget _buildFullAntiCorruptionOfficerDashboard() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Welcome Section
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.purple, Colors.purple.shade700],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.purple.withOpacity(0.3),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.security,
                      color: Colors.white,
                      size: 32,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Welcome, ${userData?['firstName'] ?? 'Anti-Corruption Officer'}!',
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Anti-Corruption Officer Dashboard',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.white.withOpacity(0.9),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // Quick Stats
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                'Active Investigations',
                '12',
                Icons.search,
                Colors.purple,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildStatCard(
                'Resolved Cases',
                '89',
                Icons.check_circle,
                Colors.green,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                'Pending Reviews',
                '34',
                Icons.pending_actions,
                Colors.orange,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildStatCard(
                'Compliance Score',
                '94%',
                Icons.verified,
                Colors.blue,
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),

        // Main Features
        const Text(
          'Anti-Corruption Management',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 16),
        _buildFeatureCard(
          'Concern Management',
          'Review and manage public concerns',
          Icons.report_problem,
          Colors.red,
          () => Navigator.pushNamed(context, '/concern-management'),
        ),
        _buildFeatureCard(
          'Investigation Tools',
          'Tools for corruption investigations',
          Icons.search,
          Colors.orange,
          () => Navigator.pushNamed(context, '/investigation-tools'),
        ),
        _buildFeatureCard(
          'Compliance Monitoring',
          'Monitor compliance with anti-corruption policies',
          Icons.verified,
          Colors.green,
          () => Navigator.pushNamed(context, '/compliance-monitoring'),
        ),
        _buildFeatureCard(
          'Risk Assessment',
          'Assess and manage corruption risks',
          Icons.assessment,
          Colors.blue,
          () => Navigator.pushNamed(context, '/risk-assessment'),
        ),
      ],
    );
  }

  void _navigateToRoleSpecificDashboard() {
    // Navigate to role-specific dashboard (same logic as hamburger menu)
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

  Widget _buildJournalistStats() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 8),
            spreadRadius: 0,
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
            spreadRadius: 0,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF3B82F6).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.analytics_outlined,
                  color: Color(0xFF3B82F6),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Your Activity',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1F2937),
                  letterSpacing: -0.3,
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: StreamBuilder<int>(
                  stream: _newsService.streamUserArticleCount(),
                  builder: (context, snapshot) {
                    final count = snapshot.data ?? 0;
                    return _buildStatItem(
                      'Articles Published', 
                      count.toString(), 
                      Icons.edit_document,
                      const Color(0xFF10B981), // Emerald
                      const Color(0xFFECFDF5), // Light emerald
                    );
                  },
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: StreamBuilder<int>(
                  stream: _mediaHubService.streamSavedArticlesCount(),
                  builder: (context, snapshot) {
                    final count = snapshot.data ?? 0;
                    return _buildStatItem(
                      'Articles Saved', 
                      count.toString(), 
                      Icons.bookmark_add,
                      const Color(0xFF8B5CF6), // Purple
                      const Color(0xFFF3E8FF), // Light purple
                    );
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon, Color color, [Color? backgroundColor]) {
    final bgColor = backgroundColor ?? color.withOpacity(0.1);
    
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: color.withOpacity(0.2),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
            spreadRadius: 0,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: 22,
                ),
              ),
              const Spacer(),
              Text(
                value,
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: color,
                  letterSpacing: -0.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            label,
            style: TextStyle(
              fontSize: 15,
              color: Colors.grey.shade700,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildJournalistToolCard(String title, String description, IconData icon, Color color, VoidCallback onTap, {bool isPrimary = false}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 8),
            spreadRadius: 0,
          ),
          BoxShadow(
            color: color.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
            spreadRadius: 0,
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: color.withOpacity(0.2),
                          width: 1,
                        ),
                      ),
                      child: Icon(icon, color: color, size: 26),
                    ),
                    const Spacer(),
                    Icon(
                      Icons.arrow_forward_ios,
                      color: color.withOpacity(0.6),
                      size: 16,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1F2937),
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w500,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRecentArticlesSection() {
    return StreamBuilder<List<ReportArticle>>(
      stream: _newsService.streamRecentUserArticles(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: const Center(
              child: Text(
                'No articles published yet',
                style: TextStyle(color: Colors.grey),
              ),
            ),
          );
        }

        return Column(
          children: snapshot.data!.map((article) => _buildArticleCard(article)).toList(),
        );
      },
    );
  }

  Widget _buildRecentSavedArticlesSection() {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: _mediaHubService.streamRecentSavedArticles(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: const Center(
              child: Text(
                'No saved articles yet',
                style: TextStyle(color: Colors.grey),
              ),
            ),
          );
        }

        return Column(
          children: snapshot.data!.map((article) => _buildSavedArticleCard(article)).toList(),
        );
      },
    );
  }

  Widget _buildArticleCard(ReportArticle article) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => Navigator.pushNamed(
            context,
            '/article',
            arguments: article.id,
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.article, color: Colors.green),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        article.title,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Published ${_formatDate(article.createdAt)}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSavedArticleCard(Map<String, dynamic> article) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => Navigator.pushNamed(
            context,
            '/article',
            arguments: article['id'],
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: Colors.purple.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.bookmark, color: Colors.purple),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        article['title'] ?? 'Untitled',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Saved ${_formatDate(article['savedAt'])}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _formatDate(dynamic date) {
    if (date == null) return 'Unknown';
    
    try {
      DateTime dateTime;
      if (date is DateTime) {
        dateTime = date;
      } else if (date.toString().contains('Timestamp')) {
        // Handle Firestore Timestamp
        dateTime = DateTime.fromMillisecondsSinceEpoch(date.millisecondsSinceEpoch);
      } else {
        dateTime = DateTime.parse(date.toString());
      }
      
      final now = DateTime.now();
      final difference = now.difference(dateTime);
      
      if (difference.inDays > 0) {
        return '${difference.inDays} day${difference.inDays == 1 ? '' : 's'} ago';
      } else if (difference.inHours > 0) {
        return '${difference.inHours} hour${difference.inHours == 1 ? '' : 's'} ago';
      } else if (difference.inMinutes > 0) {
        return '${difference.inMinutes} minute${difference.inMinutes == 1 ? '' : 's'} ago';
      } else {
        return 'Just now';
      }
    } catch (e) {
      return 'Unknown';
    }
  }

}
