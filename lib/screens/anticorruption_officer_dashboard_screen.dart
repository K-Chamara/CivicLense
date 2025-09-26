import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/concern_management_service.dart';
import '../services/notification_service.dart';
import '../models/user_role.dart';
import '../models/concern_models.dart';
import 'login_screen.dart';
import 'concern_management_screen.dart';
import 'user_concern_tracking_screen.dart';
import 'public_tender_viewer_screen.dart';

class AntiCorruptionOfficerDashboardScreen extends StatefulWidget {
  const AntiCorruptionOfficerDashboardScreen({super.key});

  @override
  State<AntiCorruptionOfficerDashboardScreen> createState() => _AntiCorruptionOfficerDashboardScreenState();
}

class _AntiCorruptionOfficerDashboardScreenState extends State<AntiCorruptionOfficerDashboardScreen> {
  final AuthService _authService = AuthService();
  UserRole? userRole;
  Map<String, dynamic>? userData;
  bool isLoading = true;
  Map<String, int> _stats = {
    'activeCases': 0,
    'resolved': 0,
    'underReview': 0,
    'priority': 0,
  };

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _loadStats();
    _initializeNotifications();
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

  Future<void> _loadStats() async {
    try {
      final stats = await ConcernManagementService.getConcernStats();
      setState(() {
        _stats = stats;
      });
    } catch (e) {
      print('Error loading stats: $e');
    }
  }

  Future<void> _initializeNotifications() async {
    try {
      await NotificationService.initializeNotifications();
      NotificationService.startConcernNotificationListener();
    } catch (e) {
      print('Error initializing notifications: $e');
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
    if (isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      drawer: _buildNavigationDrawer(),
      appBar: AppBar(
        title: const Text('Anti-corruption Officer Dashboard'),
        backgroundColor: Colors.purple,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Welcome Section
            _buildWelcomeCard(),
            const SizedBox(height: 24),

            // Quick Stats
            _buildQuickStats(),
            const SizedBox(height: 24),

            // Main Features
            _buildMainFeatures(),
            const SizedBox(height: 24),

            // Recent Concerns
            _buildRecentConcerns(),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }

  Widget _buildBottomNavigationBar() {
    return BottomNavigationBar(
      type: BottomNavigationBarType.fixed,
      backgroundColor: Colors.white,
      selectedItemColor: Colors.purple,
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
            // Already on dashboard
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

  Widget _buildWelcomeCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Colors.purple, Colors.purpleAccent],
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
      child: Row(
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
                  'Welcome, ${userData?['firstName'] ?? 'Anti-corruption Officer'}!',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Investigate concerns, ensure transparency, and combat corruption',
                  style: TextStyle(
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

  Widget _buildQuickStats() {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      childAspectRatio: 1.5,
      children: [
        _buildStatCard(
          'Active Cases',
          '${_stats['activeCases']}',
          Icons.assignment,
          Colors.red,
        ),
        _buildStatCard(
          'Resolved',
          '${_stats['resolved']}',
          Icons.check_circle,
          Colors.green,
        ),
        _buildStatCard(
          'Under Review',
          '${_stats['underReview']}',
          Icons.pending,
          Colors.orange,
        ),
        _buildStatCard(
          'Priority',
          '${_stats['priority']}',
          Icons.priority_high,
          Colors.purple,
        ),
      ],
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
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
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            color: color,
            size: 32,
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
            title,
            style: const TextStyle(
              fontSize: 12,
              color: Colors.grey,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildMainFeatures() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Anti-corruption Management Tools',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 16),
        _buildFeatureCard(
          'Concern Management',
          'Review and manage public concerns and complaints',
          Icons.report_problem,
          Colors.red,
          () => _navigateToConcernManagement(),
        ),
        _buildFeatureCard(
          'Investigation Tools',
          'Tools for corruption investigations and evidence collection',
          Icons.search,
          Colors.orange,
          () => _showFeatureComingSoon('Investigation Tools'),
        ),
        _buildFeatureCard(
          'Compliance Monitoring',
          'Monitor compliance with anti-corruption policies',
          Icons.security,
          Colors.purple,
          () => _showFeatureComingSoon('Compliance Monitoring'),
        ),
        _buildFeatureCard(
          'Reporting System',
          'Generate anti-corruption reports and analytics',
          Icons.assessment,
          Colors.blue,
          () => _showFeatureComingSoon('Reporting System'),
        ),
        _buildFeatureCard(
          'Case Management',
          'Manage investigation cases and track progress',
          Icons.folder,
          Colors.teal,
          () => _showFeatureComingSoon('Case Management'),
        ),
        _buildFeatureCard(
          'Whistleblower Portal',
          'Secure portal for whistleblower reports',
          Icons.security,
          Colors.indigo,
          () => _showFeatureComingSoon('Whistleblower Portal'),
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

  Widget _buildRecentConcerns() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Recent Concerns',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            TextButton(
              onPressed: _navigateToConcernManagement,
              child: const Text('View All'),
            ),
          ],
        ),
        const SizedBox(height: 16),
        StreamBuilder<List<Concern>>(
          stream: ConcernManagementService.getRecentConcerns(limit: 4),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              return Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text('Error loading concerns'),
              );
            }

            final concerns = snapshot.data ?? [];
            if (concerns.isEmpty) {
              return Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text('No recent concerns'),
              );
            }

            return Container(
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
                children: concerns.map((concern) => _buildConcernItem(
                  concern.title,
                  concern.status.name.toUpperCase(),
                  _formatDate(concern.createdAt),
                  _getStatusIcon(concern.status),
                  _getStatusColor(concern.status),
                )).toList(),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildConcernItem(String title, String status, String time, IconData icon, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
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
                const SizedBox(height: 4),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        status,
                        style: TextStyle(
                          color: color,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      time,
                      style: const TextStyle(
                        color: Colors.grey,
                        fontSize: 12,
                      ),
                    ),
                  ],
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
        backgroundColor: Colors.purple,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _navigateToConcernManagement() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const ConcernManagementScreen(),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }

  IconData _getStatusIcon(ConcernStatus status) {
    switch (status) {
      case ConcernStatus.pending:
        return Icons.pending;
      case ConcernStatus.underReview:
        return Icons.search;
      case ConcernStatus.inProgress:
        return Icons.work;
      case ConcernStatus.resolved:
        return Icons.check_circle;
      case ConcernStatus.dismissed:
        return Icons.cancel;
      case ConcernStatus.escalated:
        return Icons.priority_high;
    }
  }

  Color _getStatusColor(ConcernStatus status) {
    switch (status) {
      case ConcernStatus.pending:
        return Colors.orange;
      case ConcernStatus.underReview:
        return Colors.blue;
      case ConcernStatus.inProgress:
        return Colors.purple;
      case ConcernStatus.resolved:
        return Colors.green;
      case ConcernStatus.dismissed:
        return Colors.grey;
      case ConcernStatus.escalated:
        return Colors.red;
    }
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
                colors: [Colors.purple, Color(0xFF7B1FA2)],
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
                        userRole?.icon ?? Icons.security,
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
                      userRole?.name ?? 'Anti-Corruption Officer',
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
                  icon: Icons.report_problem,
                  title: 'Concern Management',
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const ConcernManagementScreen()),
                    );
                  },
                ),
                _buildDrawerItem(
                  icon: Icons.track_changes,
                  title: 'My Concerns',
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const UserConcernTrackingScreen()),
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
                  icon: Icons.people_alt,
                  title: 'Public Concerns',
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.pushNamed(context, '/public-concerns');
                  },
                ),
                _buildDrawerItem(
                  icon: Icons.analytics,
                  title: 'Reports & Analytics',
                  onTap: () => _showFeatureComingSoon('Reports & Analytics'),
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
      leading: Icon(icon, color: Colors.grey[700]),
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
}
