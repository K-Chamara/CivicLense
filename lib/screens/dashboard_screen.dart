import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';
import '../models/user_role.dart';
import 'enhanced_dashboard_screen.dart';
import 'login_screen.dart';

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
        // Navigate to splash screen to maintain proper flow
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
    // Use the enhanced dashboard for all users
    return const EnhancedDashboardScreen();
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
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header Section
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.teal.shade600, Colors.teal.shade400],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.teal.withOpacity(0.3),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.article,
                  color: Colors.white,
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Media & Journalism Hub',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Professional tools for investigative reporting',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white.withOpacity(0.9),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // Quick Stats Section
        _buildJournalistStats(),
        const SizedBox(height: 24),

        // Main Tools Section
        const Text(
          'Core Tools',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 16),
        
        // Primary Tools Grid
        Row(
          children: [
            Expanded(
              child: _buildJournalistToolCard(
                'Publish Article',
                'Create and publish investigative reports',
                Icons.edit_document,
                Colors.green,
                () => Navigator.pushNamed(context, '/publish'),
                isPrimary: true,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildJournalistToolCard(
                'Media Hub',
                'Save and organize articles',
                Icons.bookmark,
                Colors.purple,
                () => Navigator.pushNamed(context, '/media-hub'),
                isPrimary: true,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        
        Row(
          children: [
            Expanded(
              child: _buildJournalistToolCard(
                'News Feed',
                'Browse latest articles',
                Icons.feed,
                Colors.blue,
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
                Colors.orange,
                () => Navigator.pushNamed(context, '/tender-management'),
                isPrimary: true,
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),

        // Additional Resources Section
        const Text(
          'Resources & Tools',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 16),
        
        _buildJournalistResourceCard(
          'Research Database',
          'Access public records and data',
          Icons.search,
          Colors.indigo,
          () => _showComingSoon('Research Database'),
        ),
        const SizedBox(height: 12),
        
        _buildJournalistResourceCard(
          'Fact Checking Tools',
          'Verify information and sources',
          Icons.verified_user,
          Colors.red,
          () => _showComingSoon('Fact Checking Tools'),
        ),
        const SizedBox(height: 12),
        
        _buildJournalistResourceCard(
          'Source Management',
          'Organize contacts and sources',
          Icons.contacts,
          Colors.brown,
          () => _showComingSoon('Source Management'),
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

  Widget _buildDashboardCard(String title, String description, IconData icon, Color color, {VoidCallback? onTap}) {
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
        onTap: onTap ?? () {
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

  // Journalist-specific helper methods
  Widget _buildJournalistStats() {
    return Container(
      padding: const EdgeInsets.all(16),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Your Activity',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildStatItem('Articles Published', '12', Icons.article, Colors.green),
              ),
              Expanded(
                child: _buildStatItem('Articles Saved', '28', Icons.bookmark, Colors.purple),
              ),
              Expanded(
                child: _buildStatItem('Sources Tracked', '45', Icons.contacts, Colors.blue),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade600,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildJournalistToolCard(String title, String description, IconData icon, Color color, VoidCallback onTap, {bool isPrimary = false}) {
    return Container(
      height: isPrimary ? 120 : 100,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: isPrimary ? Border.all(color: color.withOpacity(0.2), width: 1) : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: color, size: 20),
                ),
                const SizedBox(height: 12),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: isPrimary ? 14 : 13,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 4),
                Expanded(
                  child: Text(
                    description,
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey.shade600,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildJournalistResourceCard(String title, String description, IconData icon, Color color, VoidCallback onTap) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
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
                  padding: const EdgeInsets.all(10),
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
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        description,
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'Coming Soon',
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.grey.shade600,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showComingSoon(String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$feature - Coming Soon!'),
        backgroundColor: Colors.teal,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }
}

