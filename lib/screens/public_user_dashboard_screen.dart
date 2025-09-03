import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../models/user_role.dart';

class PublicUserDashboardScreen extends StatefulWidget {
  const PublicUserDashboardScreen({super.key});

  @override
  State<PublicUserDashboardScreen> createState() => _PublicUserDashboardScreenState();
}

class _PublicUserDashboardScreenState extends State<PublicUserDashboardScreen> {
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
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: Text('${userRole?.name ?? 'Public User'} Dashboard'),
        backgroundColor: userRole?.color ?? Colors.blue,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _signOut,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Welcome Section
            _buildWelcomeCard(),
            const SizedBox(height: 24),

            // Role-specific content
            _buildRoleSpecificContent(),
            const SizedBox(height: 24),

            // Common Features
            _buildCommonFeatures(),
            const SizedBox(height: 24),

            // Recent Activities
            _buildRecentActivities(),
          ],
        ),
      ),
    );
  }

  Widget _buildWelcomeCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [userRole?.color ?? Colors.blue, (userRole?.color ?? Colors.blue).withOpacity(0.7)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: (userRole?.color ?? Colors.blue).withOpacity(0.3),
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
            child: Icon(
              userRole?.icon ?? Icons.person,
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
                  'Welcome, ${userData?['firstName'] ?? 'User'}!',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  userRole?.description ?? 'Track public spending and raise concerns',
                  style: const TextStyle(
                    fontSize: 16,
                    color: Colors.white,
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

  Widget _buildRoleSpecificContent() {
    switch (userRole?.id) {
      case 'citizen':
        return _buildCitizenContent();
      case 'journalist':
        return _buildJournalistContent();
      case 'community_leader':
        return _buildCommunityLeaderContent();
      case 'researcher':
        return _buildResearcherContent();
      case 'ngo':
        return _buildNGOContent();
      default:
        return _buildDefaultContent();
    }
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
          'Track Public Spending',
          'Monitor government budgets and expenditures',
          Icons.account_balance,
          Colors.blue,
          () => _showFeatureComingSoon('Track Public Spending'),
        ),
        _buildFeatureCard(
          'Raise Concerns',
          'Report issues and track their resolution',
          Icons.report_problem,
          Colors.orange,
          () => _showFeatureComingSoon('Raise Concerns'),
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

  Widget _buildJournalistContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Journalist Tools',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 16),
        _buildFeatureCard(
          'Publish Reports',
          'Create and publish investigative reports',
          Icons.article,
          Colors.green,
          () => Navigator.pushNamed(context, '/publish'),
        ),
        _buildFeatureCard(
          'Media Hub',
          'Access media resources and tools',
          Icons.media_bluetooth_on,
          Colors.purple,
          () => Navigator.pushNamed(context, '/media-hub'),
        ),
        _buildFeatureCard(
          'News Feed',
          'Curate and manage news content',
          Icons.feed,
          Colors.blue,
          () => Navigator.pushNamed(context, '/news'),
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
          'Manage community groups and initiatives',
          Icons.people,
          Colors.orange,
          () => _showFeatureComingSoon('Community Management'),
        ),
        _buildFeatureCard(
          'Organize Events',
          'Plan and coordinate community events',
          Icons.event,
          Colors.red,
          () => _showFeatureComingSoon('Organize Events'),
        ),
        _buildFeatureCard(
          'Engagement Tools',
          'Tools for community engagement',
          Icons.build,
          Colors.green,
          () => _showFeatureComingSoon('Engagement Tools'),
        ),
      ],
    );
  }

  Widget _buildResearcherContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Research Tools',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 16),
        _buildFeatureCard(
          'Research Data',
          'Access anonymized datasets for research',
          Icons.school,
          Colors.purple,
          () => _showFeatureComingSoon('Research Data'),
        ),
        _buildFeatureCard(
          'Generate Reports',
          'Create research reports and analytics',
          Icons.analytics,
          Colors.blue,
          () => _showFeatureComingSoon('Generate Reports'),
        ),
        _buildFeatureCard(
          'Academic Tools',
          'Research and analysis tools',
          Icons.science,
          Colors.green,
          () => _showFeatureComingSoon('Academic Tools'),
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
          'Manage NGO projects and contracts',
          Icons.business,
          Colors.red,
          () => _showFeatureComingSoon('Project Management'),
        ),
        _buildFeatureCard(
          'Contractor Tools',
          'Access contractor-specific tools',
          Icons.build,
          Colors.orange,
          () => _showFeatureComingSoon('Contractor Tools'),
        ),
        _buildFeatureCard(
          'Performance Tracking',
          'Track project performance and metrics',
          Icons.trending_up,
          Colors.green,
          () => _showFeatureComingSoon('Performance Tracking'),
        ),
      ],
    );
  }

  Widget _buildDefaultContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Public User Tools',
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
          'Raise Concerns',
          'Report issues and track their resolution',
          Icons.report_problem,
          Colors.orange,
          () => _showFeatureComingSoon('Raise Concerns'),
        ),
      ],
    );
  }

  Widget _buildCommonFeatures() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Common Features',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 16),
        _buildFeatureCard(
          'Public Spending Tracker',
          'Monitor government budgets and expenditures',
          Icons.account_balance,
          Colors.blue,
          () => _showFeatureComingSoon('Public Spending Tracker'),
        ),
        _buildFeatureCard(
          'Transparency Reports',
          'Access government transparency reports',
          Icons.visibility,
          Colors.green,
          () => _showFeatureComingSoon('Transparency Reports'),
        ),
        _buildFeatureCard(
          'Raise Concerns',
          'Report issues and track their resolution',
          Icons.report_problem,
          Colors.orange,
          () => _showFeatureComingSoon('Raise Concerns'),
        ),
        _buildFeatureCard(
          'Government Directory',
          'Find government officials and departments',
          Icons.people,
          Colors.purple,
          () => _showFeatureComingSoon('Government Directory'),
        ),
      ],
    );
  }

  Widget _buildFeatureCard(String title, String description, IconData icon, Color color, VoidCallback onTap) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
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
          padding: const EdgeInsets.all(16),
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
                'Concern submitted about road construction',
                '2 hours ago',
                Icons.report_problem,
                Colors.orange,
              ),
              _buildActivityItem(
                'Viewed Q4 budget report',
                '1 day ago',
                Icons.visibility,
                Colors.blue,
              ),
              _buildActivityItem(
                'Tracked government spending',
                '2 days ago',
                Icons.track_changes,
                Colors.green,
              ),
              _buildActivityItem(
                'Updated profile information',
                '1 week ago',
                Icons.person,
                Colors.purple,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildActivityItem(String title, String time, IconData icon, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w500,
                    fontSize: 14,
                  ),
                ),
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

  void _showFeatureComingSoon(String featureName) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$featureName feature coming soon!'),
        backgroundColor: userRole?.color ?? Colors.blue,
        duration: const Duration(seconds: 2),
      ),
    );
  }
}
