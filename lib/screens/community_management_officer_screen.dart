import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/community_models.dart';
import '../services/community_service.dart';
import '../services/gemini_service.dart';
import 'community_posts_officer_screen.dart';

class CommunityManagementOfficerScreen extends StatefulWidget {
  const CommunityManagementOfficerScreen({super.key});

  @override
  State<CommunityManagementOfficerScreen> createState() => _CommunityManagementOfficerScreenState();
}

class _CommunityManagementOfficerScreenState extends State<CommunityManagementOfficerScreen>
    with TickerProviderStateMixin {
  final CommunityService _communityService = CommunityService();
  final TextEditingController _searchController = TextEditingController();
  
  List<Community> _communities = [];
  List<Community> _filteredCommunities = [];
  bool _isLoading = false;
  String _searchQuery = '';
  
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    
    _loadCommunities();
    _animationController.forward();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadCommunities() async {
    setState(() => _isLoading = true);
    try {
      _communityService.getCommunities().listen((communities) {
        if (mounted) {
          setState(() {
            _communities = communities;
            _filterCommunities();
            _isLoading = false;
          });
        }
      });
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        _showErrorSnackBar('Error loading communities: $e');
      }
    }
  }

  void _filterCommunities() {
    if (_searchQuery.isEmpty) {
      _filteredCommunities = _communities;
    } else {
      _filteredCommunities = _communities.where((community) =>
        community.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
        community.description.toLowerCase().contains(_searchQuery.toLowerCase())
      ).toList();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: const Text('Community Management'),
        backgroundColor: Colors.purple,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: Column(
          children: [
            // Search Bar
            _buildSearchBar(),
            
            // Communities List
            Expanded(
              child: _buildAllCommunitiesTab(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.white,
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'Search communities...',
          prefixIcon: const Icon(Icons.search, color: Colors.purple),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear, color: Colors.purple),
                  onPressed: () {
                    _searchController.clear();
                    setState(() {
                      _searchQuery = '';
                      _filterCommunities();
                    });
                  },
                )
              : null,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Colors.purple, width: 2),
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
        onChanged: (value) {
          setState(() {
            _searchQuery = value;
            _filterCommunities();
          });
        },
      ),
    );
  }

  Widget _buildAllCommunitiesTab() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_filteredCommunities.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.people_outline, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              _searchQuery.isEmpty ? 'No communities found' : 'No communities match your search',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _searchQuery.isEmpty 
                  ? 'Communities will appear here when created'
                  : 'Try adjusting your search terms',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade500,
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadCommunities,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _filteredCommunities.length,
        itemBuilder: (context, index) {
          final community = _filteredCommunities[index];
          return _buildCommunityCard(community);
        },
      ),
    );
  }


  Widget _buildCommunityCard(Community community) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () => _navigateToCommunityPosts(community),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
            Row(
              children: [
                // Community Image
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    color: Colors.purple.shade100,
                  ),
                  child: community.imageUrl != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(
                            community.imageUrl!,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Icon(
                                Icons.people,
                                color: Colors.purple.shade400,
                                size: 24,
                              );
                            },
                          ),
                        )
                      : Icon(
                          Icons.people,
                          color: Colors.purple.shade400,
                          size: 24,
                        ),
                ),
                const SizedBox(width: 12),
                
                // Community Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        community.name,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        community.description,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade600,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                
                // Actions
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert),
                  onSelected: (value) => _handleCommunityAction(value, community),
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'view',
                      child: ListTile(
                        leading: Icon(Icons.visibility),
                        title: Text('View Posts'),
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'moderate',
                      child: ListTile(
                        leading: Icon(Icons.content_paste_search),
                        title: Text('Review Content'),
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'delete',
                      child: ListTile(
                        leading: Icon(Icons.delete, color: Colors.red),
                        title: Text('Delete Community', style: TextStyle(color: Colors.red)),
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            
            const SizedBox(height: 12),
            
            // Community Stats
            Row(
              children: [
                _buildStatChip(
                  Icons.people,
                  '${community.memberCount} members',
                  Colors.blue,
                ),
                const SizedBox(width: 8),
                _buildStatChip(
                  Icons.public,
                  community.privacy == 'public' ? 'Public' : 'Private',
                  community.privacy == 'public' ? Colors.green : Colors.orange,
                ),
                const SizedBox(width: 8),
                _buildStatChip(
                  Icons.calendar_today,
                  _formatDate(community.createdAt),
                  Colors.grey,
                ),
              ],
            ),
          ],
        ),
      ),
      ),
    );
  }

  Widget _buildStatChip(IconData icon, String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              fontSize: 12,
              color: color,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }


  void _handleCommunityAction(String action, Community community) {
    switch (action) {
      case 'view':
        _navigateToCommunityPosts(community);
        break;
      case 'delete':
        _showDeleteCommunityDialog(community);
        break;
    }
  }

  void _navigateToCommunityPosts(Community community) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CommunityPostsOfficerScreen(community: community),
      ),
    );
  }

  void _showDeleteCommunityDialog(Community community) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Community'),
        content: Text(
          'Are you sure you want to delete "${community.name}"? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteCommunity(community);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteCommunity(Community community) async {
    try {
      // Delete community and all related data
      await FirebaseFirestore.instance.collection('communities').doc(community.id).delete();
      
      // Delete community members
      final membersSnapshot = await FirebaseFirestore.instance
          .collection('community_members')
          .where('communityId', isEqualTo: community.id)
          .get();
      
      for (final member in membersSnapshot.docs) {
        await member.reference.delete();
      }
      
      // Delete community posts
      final postsSnapshot = await FirebaseFirestore.instance
          .collection('community_posts')
          .where('communityId', isEqualTo: community.id)
          .get();
      
      for (final post in postsSnapshot.docs) {
        await post.reference.delete();
      }
      
      _showSuccessSnackBar('Community "${community.name}" deleted successfully');
    } catch (e) {
      _showErrorSnackBar('Error deleting community: $e');
    }
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

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
      ),
    );
  }
}
