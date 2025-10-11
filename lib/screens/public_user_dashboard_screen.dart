import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/news_service.dart';
import '../services/media_hub_service.dart';
import '../models/user_role.dart';
import '../models/report.dart';
import 'enhanced_dashboard_screen.dart';
import 'login_screen.dart';
import 'raise_concern_screen.dart';
import 'article_detail_screen.dart';

class PublicUserDashboardScreen extends StatefulWidget {
  const PublicUserDashboardScreen({super.key});

  @override
  State<PublicUserDashboardScreen> createState() => _PublicUserDashboardScreenState();
}

class _PublicUserDashboardScreenState extends State<PublicUserDashboardScreen> {
  final AuthService _authService = AuthService();
  final NewsService _newsService = NewsService();
  final MediaHubService _mediaHubService = MediaHubService();
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
    // Use the enhanced dashboard for public users
    return const EnhancedDashboardScreen();
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
          'Tender Management',
          'View and monitor government tenders',
          Icons.shopping_cart,
          Colors.orange,
          () => Navigator.pushNamed(context, '/tender-management'),
        ),
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
          () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const RaiseConcernScreen(),
            ),
          ),
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
        // Media & Journalism Hub Section
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
                    Text(
                      'Welcome, ${userData?['name'] ?? 'Journalist'}',
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Media & Journalism Hub',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.white,
                        fontWeight: FontWeight.w500,
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

        // Recent Articles Section
        const Text(
          'Recent Articles',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 16),
        _buildRecentArticlesSection(),
        const SizedBox(height: 24),

        // Recent Saved Articles Section
        const Text(
          'Recent Saved Articles',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 16),
        _buildRecentSavedArticlesSection(),
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
          'Tender Management',
          'View and monitor government tenders',
          Icons.shopping_cart,
          Colors.orange,
          () => Navigator.pushNamed(context, '/tender-management'),
        ),
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
          'Tender Management',
          'View and monitor government tenders',
          Icons.shopping_cart,
          Colors.orange,
          () => Navigator.pushNamed(context, '/tender-management'),
        ),
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
          'Tender Management',
          'View and monitor government tenders',
          Icons.shopping_cart,
          Colors.orange,
          () => Navigator.pushNamed(context, '/tender-management'),
        ),
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
          'Tender Management',
          'View and monitor government tenders',
          Icons.shopping_cart,
          Colors.orange,
          () => Navigator.pushNamed(context, '/tender-management'),
        ),
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
          () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const RaiseConcernScreen(),
            ),
          ),
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
          () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const RaiseConcernScreen(),
            ),
          ),
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
                child: StreamBuilder<int>(
                  stream: _newsService.streamUserArticleCount(),
                  builder: (context, snapshot) {
                    final count = snapshot.data ?? 0;
                    return _buildStatItem('Articles Published', count.toString(), Icons.article, Colors.green);
                  },
                ),
              ),
              Expanded(
                child: StreamBuilder<int>(
                  stream: _mediaHubService.streamSavedArticlesCount(),
                  builder: (context, snapshot) {
                    final count = snapshot.data ?? 0;
                    return _buildStatItem('Articles Saved', count.toString(), Icons.bookmark, Colors.purple);
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
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
      ),
    );
  }

  Widget _buildJournalistToolCard(String title, String description, IconData icon, Color color, VoidCallback onTap, {bool isPrimary = false}) {
    return Container(
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
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: color, size: 24),
                ),
                const SizedBox(height: 12),
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
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
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
