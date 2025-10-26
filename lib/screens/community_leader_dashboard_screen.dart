import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/auth_service.dart';
import '../services/community_service.dart';
import '../models/user_role.dart';
import '../models/community_models.dart';
import 'login_screen.dart';
import 'community_list_screen.dart';
import 'create_community_screen.dart';
import 'community_posts_screen.dart';

class CommunityLeaderDashboardScreen extends StatefulWidget {
  const CommunityLeaderDashboardScreen({super.key});

  @override
  State<CommunityLeaderDashboardScreen> createState() => _CommunityLeaderDashboardScreenState();
}

class _CommunityLeaderDashboardScreenState extends State<CommunityLeaderDashboardScreen> {
  final AuthService _authService = AuthService();
  final CommunityService _communityService = CommunityService();
  
  UserRole? userRole;
  Map<String, dynamic>? userData;
  bool isLoading = true;
  
  // Community statistics
  Map<String, int> _stats = {
    'totalCommunities': 0,
    'myCommunities': 0,
    'totalMembers': 0,
    'totalPosts': 0,
  };

  // Recent posts from owned communities
  List<CommunityPost> _recentPosts = [];

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _loadStats();
    _loadRecentPosts();
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
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      // Get total communities count
      final totalCommunitiesQuery = await FirebaseFirestore.instance
          .collection('communities')
          .where('isActive', isEqualTo: true)
          .get();
      
      // Get user's created communities count
      final myCommunitiesQuery = await FirebaseFirestore.instance
          .collection('communities')
          .where('createdBy', isEqualTo: user.uid)
          .where('isActive', isEqualTo: true)
          .get();

      // Calculate total members across all communities
      int totalMembers = 0;
      for (var doc in totalCommunitiesQuery.docs) {
        totalMembers += (doc.data()['memberCount'] ?? 0) as int;
      }

      // Get total posts count
      final postsQuery = await FirebaseFirestore.instance
          .collection('community_posts')
          .where('status', isEqualTo: 'active')
          .get();

      setState(() {
        _stats = {
          'totalCommunities': totalCommunitiesQuery.docs.length,
          'myCommunities': myCommunitiesQuery.docs.length,
          'totalMembers': totalMembers,
          'totalPosts': postsQuery.docs.length,
        };
      });
    } catch (e) {
      print('Error loading stats: $e');
    }
  }

  Future<void> _loadRecentPosts() async {
    try {
      final user = _authService.currentUser;
      if (user == null) return;

      // Get communities created by this user
      final myCommunitiesQuery = await FirebaseFirestore.instance
          .collection('communities')
          .where('createdBy', isEqualTo: user.uid)
          .where('isActive', isEqualTo: true)
          .get();

      if (myCommunitiesQuery.docs.isEmpty) {
        setState(() {
          _recentPosts = [];
        });
        return;
      }

      // Get community IDs
      final communityIds = myCommunitiesQuery.docs.map((doc) => doc.id).toList();

      // Get recent posts from these communities (last 10 posts)
      // Note: Using whereIn with orderBy might require composite index
      // Let's try without orderBy first and sort in memory
      final postsQuery = await FirebaseFirestore.instance
          .collection('community_posts')
          .where('communityId', whereIn: communityIds)
          .where('status', isEqualTo: 'active')
          .get();

      final posts = postsQuery.docs.map((doc) => CommunityPost.fromFirestore(doc)).toList();

      // Sort by creation date in descending order (newest first)
      posts.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      
      // Take only the first 10 posts
      final recentPosts = posts.take(10).toList();

      setState(() {
        _recentPosts = recentPosts;
      });
    } catch (e) {
      print('Error loading recent posts: $e');
      setState(() {
        _recentPosts = [];
      });
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
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text(
          'Community Leader Dashboard',
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: Colors.blue,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              _loadRecentPosts();
              _loadStats();
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _logout,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildWelcomeSection(),
            const SizedBox(height: 24),
            _buildStatsSection(),
            const SizedBox(height: 24),
            _buildQuickActionsSection(),
            const SizedBox(height: 24),
            _buildMyCommunitiesSection(),
            const SizedBox(height: 24),
            _buildRecentActivitySection(),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _createCommunity,
        backgroundColor: Colors.blue,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildWelcomeSection() {
    final firstName = userData?['firstName'] ?? 'Community Leader';
    final lastName = userData?['lastName'] ?? '';
    final fullName = '$firstName $lastName'.trim();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.blue.shade600,
            Colors.purple.shade600,
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withOpacity(0.3),
            blurRadius: 15,
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
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.people,
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
                      'Welcome back,',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.white.withOpacity(0.9),
                      ),
                    ),
                    Text(
                      fullName,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'Manage your communities and engage with members',
            style: TextStyle(
              fontSize: 14,
              color: Colors.white.withOpacity(0.9),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Community Statistics',
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
          childAspectRatio: 1.5,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          children: [
            _buildStatCard(
              'Total Communities',
              _stats['totalCommunities'].toString(),
              Icons.groups,
              Colors.blue,
            ),
            _buildStatCard(
              'My Communities',
              _stats['myCommunities'].toString(),
              Icons.group_add,
              Colors.green,
            ),
            _buildStatCard(
              'Total Members',
              _stats['totalMembers'].toString(),
              Icons.people_alt,
              Colors.orange,
            ),
            _buildStatCard(
              'Total Posts',
              _stats['totalPosts'].toString(),
              Icons.post_add,
              Colors.purple,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
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
                child: Icon(
                  icon,
                  color: color,
                  size: 20,
                ),
              ),
              const Spacer(),
              Text(
                value,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionsSection() {
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
                'Create Community',
                'Start a new community',
                Icons.add_circle,
                Colors.blue,
                _createCommunity,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildActionCard(
                'Browse Communities',
                'Explore all communities',
                Icons.explore,
                Colors.green,
                _browseCommunities,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionCard(String title, String subtitle, IconData icon, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: color,
                size: 24,
              ),
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
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMyCommunitiesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'My Communities',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            TextButton(
              onPressed: _browseCommunities,
              child: const Text(
                'View All',
                style: TextStyle(
                  color: Colors.blue,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        StreamBuilder<List<Community>>(
          stream: _communityService.getUserCreatedCommunities(FirebaseAuth.instance.currentUser!.uid),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(),
              );
            }

            if (snapshot.hasError) {
              return Center(
                child: Text(
                  'Error loading communities: ${snapshot.error}',
                  style: const TextStyle(color: Colors.red),
                ),
              );
            }

            final communities = snapshot.data ?? [];

            if (communities.isEmpty) {
              return Container(
                width: double.infinity,
                padding: const EdgeInsets.all(32),
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
                    Icon(
                      Icons.group_add_outlined,
                      size: 64,
                      color: Colors.grey.shade400,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No communities created yet',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Create your first community to get started',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade500,
                      ),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      onPressed: _createCommunity,
                      icon: const Icon(Icons.add),
                      label: const Text('Create Community'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      ),
                    ),
                  ],
                ),
              );
            }

            return ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: communities.length > 3 ? 3 : communities.length,
              itemBuilder: (context, index) {
                final community = communities[index];
                return _buildCommunityCard(community);
              },
            );
          },
        ),
      ],
    );
  }

  Widget _buildCommunityCard(Community community) {
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
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: Colors.blue.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            Icons.groups,
            color: Colors.blue,
            size: 24,
          ),
        ),
        title: Text(
          community.name,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              community.description,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(
                  Icons.people,
                  size: 16,
                  color: Colors.grey.shade500,
                ),
                const SizedBox(width: 4),
                Text(
                  '${community.memberCount} members',
                  style: TextStyle(
                    color: Colors.grey.shade500,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(width: 16),
                Icon(
                  Icons.category,
                  size: 16,
                  color: Colors.grey.shade500,
                ),
                const SizedBox(width: 4),
                Text(
                  community.categories.isNotEmpty ? community.categories.first : 'General',
                  style: TextStyle(
                    color: Colors.grey.shade500,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ],
        ),
        trailing: IconButton(
          icon: const Icon(Icons.arrow_forward_ios, size: 16),
          onPressed: () => _viewCommunity(community),
        ),
        onTap: () => _viewCommunity(community),
      ),
    );
  }

  Widget _buildRecentActivitySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Recent Activity',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 16),
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
          child: _recentPosts.isEmpty
              ? _buildEmptyRecentActivity()
              : _buildRecentPostsList(),
        ),
      ],
    );
  }

  Widget _buildEmptyRecentActivity() {
    return Column(
      children: [
        Icon(
          Icons.timeline,
          size: 48,
          color: Colors.grey.shade400,
        ),
        const SizedBox(height: 16),
        Text(
          'No recent activity',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.grey.shade600,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Activity from your communities will appear here',
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey.shade500,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildRecentPostsList() {
    return Column(
      children: _recentPosts.take(5).map((post) => _buildRecentPostItem(post)).toList(),
    );
  }

  Widget _buildRecentPostItem(CommunityPost post) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: Colors.blue.shade100,
            child: Icon(
              Icons.person,
              color: Colors.blue.shade700,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  post.authorName,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  post.content,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey.shade700,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  _formatTimeAgo(post.createdAt),
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade500,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: Colors.grey.shade400,
            ),
            onPressed: () => _viewPost(post),
          ),
        ],
      ),
    );
  }

  String _formatTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

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

  void _viewPost(CommunityPost post) async {
    // Get community details for navigation
    try {
      final communityDoc = await FirebaseFirestore.instance
          .collection('communities')
          .doc(post.communityId)
          .get();

      if (communityDoc.exists && mounted) {
        final community = Community.fromFirestore(communityDoc);
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => CommunityPostsScreen(community: community),
          ),
        );
      }
    } catch (e) {
      print('Error navigating to post: $e');
    }
  }

  void _createCommunity() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const CreateCommunityScreen(),
      ),
    );

    if (result != null) {
      _loadStats();
    }
  }

  void _browseCommunities() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const CommunityListScreen(),
      ),
    );
  }

  void _viewCommunity(Community community) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CommunityPostsScreen(community: community),
      ),
    );
  }

  void _logout() async {
    await _authService.signOut();
    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => const LoginScreen(),
        ),
      );
    }
  }
}
