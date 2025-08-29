import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';
import '../models/user_role.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final AuthService _authService = AuthService();
  UserRole? userRole;
  Map<String, dynamic>? userData;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
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
    }
  }

  Future<void> _signOut() async {
    try {
      await _authService.signOut();
      if (mounted) {
        Navigator.of(context).pushReplacementNamed('/login');
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
      appBar: AppBar(
        title: const Text('Civic Lense'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _signOut,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Welcome Section
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: userRole?.color.withOpacity(0.1) ?? Colors.blue.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            userRole?.icon ?? Icons.person,
                            color: userRole?.color ?? Colors.blue,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Welcome, ${userData?['firstName'] ?? 'User'}!',
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                userRole?.name ?? 'User',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: userRole?.color ?? Colors.blue,
                                  fontWeight: FontWeight.w500,
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
            ),
            const SizedBox(height: 24),

            // Role-specific content placeholder
            Text(
              'Your Dashboard',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 16),

            // Placeholder content based on role
            _buildRoleSpecificContent(),
          ],
        ),
      ),
    );
  }

  Widget _buildRoleSpecificContent() {
    // Check user type first
    if (userRole?.userType == UserType.government) {
      switch (userRole?.id) {
        case 'finance_officer':
          return _buildFinanceOfficerDashboard();
        case 'procurement_officer':
          return _buildProcurementOfficerDashboard();
        case 'anticorruption_officer':
          return _buildAntiCorruptionOfficerDashboard();
        default:
          return _buildDefaultDashboard();
      }
    } else {
      // Public users
      switch (userRole?.id) {
        case 'citizen':
          return _buildCitizenDashboard();
        case 'journalist':
          return _buildJournalistDashboard();
        case 'community_leader':
          return _buildCommunityLeaderDashboard();
        case 'researcher':
          return _buildResearcherDashboard();
        case 'ngo':
          return _buildNGODashboard();
        default:
          return _buildDefaultDashboard();
      }
    }
  }

  Widget _buildCitizenDashboard() {
    return Column(
      children: [
        _buildDashboardCard(
          'Track Public Spending',
          'Monitor government budgets and expenditures',
          Icons.account_balance,
          Colors.blue,
        ),
        _buildDashboardCard(
          'Raise Concerns',
          'Report issues and track their resolution',
          Icons.report_problem,
          Colors.orange,
        ),
        _buildDashboardCard(
          'View Reports',
          'Access transparency reports and analytics',
          Icons.analytics,
          Colors.green,
        ),
      ],
    );
  }

  Widget _buildJournalistDashboard() {
    return Column(
      children: [
        _buildDashboardCard(
          'Publish Reports',
          'Create and publish investigative reports',
          Icons.article,
          Colors.green,
        ),
        _buildDashboardCard(
          'Media Hub',
          'Access media resources and tools',
          Icons.media_bluetooth_on,
          Colors.purple,
        ),
        _buildDashboardCard(
          'News Feed',
          'Curate and manage news content',
          Icons.feed,
          Colors.blue,
        ),
      ],
    );
  }

  Widget _buildCommunityLeaderDashboard() {
    return Column(
      children: [
        _buildDashboardCard(
          'Community Management',
          'Manage community groups and initiatives',
          Icons.people,
          Colors.orange,
        ),
        _buildDashboardCard(
          'Organize Events',
          'Plan and coordinate community events',
          Icons.event,
          Colors.red,
        ),
                 _buildDashboardCard(
           'Engagement Tools',
           'Tools for community engagement',
           Icons.build,
           Colors.green,
         ),
      ],
    );
  }

  Widget _buildResearcherDashboard() {
    return Column(
      children: [
        _buildDashboardCard(
          'Research Data',
          'Access anonymized datasets for research',
          Icons.school,
          Colors.purple,
        ),
        _buildDashboardCard(
          'Generate Reports',
          'Create research reports and analytics',
          Icons.analytics,
          Colors.blue,
        ),
        _buildDashboardCard(
          'Academic Tools',
          'Research and analysis tools',
          Icons.science,
          Colors.green,
        ),
      ],
    );
  }

  Widget _buildNGODashboard() {
    return Column(
      children: [
        _buildDashboardCard(
          'Project Management',
          'Manage NGO projects and contracts',
          Icons.business,
          Colors.red,
        ),
        _buildDashboardCard(
          'Contractor Tools',
          'Access contractor-specific tools',
          Icons.build,
          Colors.orange,
        ),
        _buildDashboardCard(
          'Performance Tracking',
          'Track project performance and metrics',
          Icons.trending_up,
          Colors.green,
        ),
      ],
    );
  }

  // Government User Dashboards
  Widget _buildFinanceOfficerDashboard() {
    return Column(
      children: [
        _buildDashboardCard(
          'Budget Management',
          'Manage and monitor government budgets',
          Icons.account_balance_wallet,
          Colors.green,
        ),
        _buildDashboardCard(
          'Financial Reports',
          'Generate financial reports and statements',
          Icons.receipt_long,
          Colors.blue,
        ),
        _buildDashboardCard(
          'Expense Tracking',
          'Track and approve government expenses',
          Icons.trending_up,
          Colors.orange,
        ),
        _buildDashboardCard(
          'Audit Management',
          'Manage financial audits and compliance',
          Icons.verified,
          Colors.purple,
        ),
      ],
    );
  }

  Widget _buildProcurementOfficerDashboard() {
    return Column(
      children: [
        _buildDashboardCard(
          'Tender Management',
          'Create and manage government tenders',
          Icons.shopping_cart,
          Colors.orange,
        ),
        _buildDashboardCard(
          'Vendor Management',
          'Manage vendor relationships and contracts',
          Icons.business,
          Colors.blue,
        ),
        _buildDashboardCard(
          'Purchase Orders',
          'Create and track purchase orders',
          Icons.shopping_bag,
          Colors.green,
        ),
        _buildDashboardCard(
          'Contract Management',
          'Manage procurement contracts',
          Icons.description,
          Colors.purple,
        ),
      ],
    );
  }

  Widget _buildAntiCorruptionOfficerDashboard() {
    return Column(
      children: [
        _buildDashboardCard(
          'Concern Management',
          'Review and manage public concerns',
          Icons.report_problem,
          Colors.red,
        ),
        _buildDashboardCard(
          'Investigation Tools',
          'Tools for corruption investigations',
          Icons.search,
          Colors.orange,
        ),
        _buildDashboardCard(
          'Compliance Monitoring',
          'Monitor compliance with anti-corruption policies',
          Icons.security,
          Colors.purple,
        ),
        _buildDashboardCard(
          'Reporting System',
          'Generate anti-corruption reports',
          Icons.assessment,
          Colors.blue,
        ),
      ],
    );
  }

  Widget _buildDefaultDashboard() {
    return Column(
      children: [
        _buildDashboardCard(
          'Welcome to Civic Lense',
          'Your role-specific dashboard will be available soon',
          Icons.dashboard,
          Colors.blue,
        ),
      ],
    );
  }

  Widget _buildDashboardCard(String title, String description, IconData icon, Color color) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color),
        ),
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(description),
        trailing: const Icon(Icons.arrow_forward_ios),
        onTap: () {
          // TODO: Navigate to specific feature
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('$title feature coming soon!'),
              backgroundColor: color,
            ),
          );
        },
      ),
    );
  }
}
