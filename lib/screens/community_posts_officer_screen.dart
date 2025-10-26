import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/community_models.dart';
import '../services/gemini_service.dart';

class CommunityPostsOfficerScreen extends StatefulWidget {
  final Community community;

  const CommunityPostsOfficerScreen({
    super.key,
    required this.community,
  });

  @override
  State<CommunityPostsOfficerScreen> createState() => _CommunityPostsOfficerScreenState();
}

class _CommunityPostsOfficerScreenState extends State<CommunityPostsOfficerScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: Text('${widget.community.name} - Posts'),
        backgroundColor: Colors.purple,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: () => _showDeleteCommunityDialog(),
            tooltip: 'Delete Community',
          ),
        ],
      ),
      body: Column(
        children: [
          // Community Info Header
          _buildCommunityHeader(),
          
          // Search Bar
          _buildSearchBar(),
          
          // Posts List
          Expanded(
            child: _buildPostsList(),
          ),
        ],
      ),
    );
  }

  Widget _buildCommunityHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.white,
      child: Row(
        children: [
          // Community Image
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: Colors.purple.shade100,
            ),
            child: widget.community.imageUrl != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(
                      widget.community.imageUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Icon(
                          Icons.people,
                          color: Colors.purple.shade400,
                          size: 30,
                        );
                      },
                    ),
                  )
                : Icon(
                    Icons.people,
                    color: Colors.purple.shade400,
                    size: 30,
                  ),
          ),
          const SizedBox(width: 16),
          
          // Community Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.community.name,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  widget.community.description,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    _buildInfoChip(
                      Icons.people,
                      '${widget.community.memberCount} members',
                      Colors.blue,
                    ),
                    const SizedBox(width: 8),
                    _buildInfoChip(
                      Icons.public,
                      widget.community.privacy == 'public' ? 'Public' : 'Private',
                      widget.community.privacy == 'public' ? Colors.green : Colors.orange,
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

  Widget _buildInfoChip(IconData icon, String text, Color color) {
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

  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.white,
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'Search posts...',
          prefixIcon: const Icon(Icons.search, color: Colors.purple),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear, color: Colors.purple),
                  onPressed: () {
                    _searchController.clear();
                    setState(() {
                      _searchQuery = '';
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
          });
        },
      ),
    );
  }

  Widget _buildPostsList() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('community_posts')
          .where('communityId', isEqualTo: widget.community.id)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 64, color: Colors.red.shade400),
                const SizedBox(height: 16),
                Text(
                  'Error loading posts',
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.red.shade600,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Please try again later',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade500,
                  ),
                ),
              ],
            ),
          );
        }

        final posts = snapshot.data?.docs ?? [];
        
        // Sort posts by createdAt in descending order (newest first)
        posts.sort((a, b) {
          final aData = a.data() as Map<String, dynamic>;
          final bData = b.data() as Map<String, dynamic>;
          final aTime = aData['createdAt'] as Timestamp?;
          final bTime = bData['createdAt'] as Timestamp?;
          
          if (aTime == null && bTime == null) return 0;
          if (aTime == null) return 1;
          if (bTime == null) return -1;
          
          return bTime.compareTo(aTime); // Descending order
        });
        
        // Filter posts based on search query
        final filteredPosts = posts.where((post) {
          if (_searchQuery.isEmpty) return true;
          final postData = post.data() as Map<String, dynamic>;
          final content = postData['content']?.toString().toLowerCase() ?? '';
          final authorName = postData['authorName']?.toString().toLowerCase() ?? '';
          return content.contains(_searchQuery.toLowerCase()) || 
                 authorName.contains(_searchQuery.toLowerCase());
        }).toList();

        if (filteredPosts.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.content_paste_outlined, size: 64, color: Colors.grey.shade400),
                const SizedBox(height: 16),
                Text(
                  _searchQuery.isEmpty ? 'No posts found' : 'No posts match your search',
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _searchQuery.isEmpty 
                      ? 'Community posts will appear here'
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

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: filteredPosts.length,
          itemBuilder: (context, index) {
            final postData = filteredPosts[index].data() as Map<String, dynamic>;
            return _buildPostCard(postData, filteredPosts[index].id);
          },
        );
      },
    );
  }

  Widget _buildPostCard(Map<String, dynamic> postData, String postId) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: Colors.purple.shade100,
                  child: Text(
                    postData['authorName']?.toString().substring(0, 1).toUpperCase() ?? 'U',
                    style: TextStyle(
                      color: Colors.purple.shade700,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        postData['authorName'] ?? 'Unknown User',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      Text(
                        _formatDate((postData['createdAt'] as Timestamp).toDate()),
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                // Moderation Actions
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert, color: Colors.purple),
                  onSelected: (value) => _handlePostAction(value, postData, postId),
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'analyze',
                      child: ListTile(
                        leading: Icon(Icons.psychology, color: Colors.blue),
                        title: Text('AI Analyze'),
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'approve',
                      child: ListTile(
                        leading: Icon(Icons.check_circle, color: Colors.green),
                        title: Text('Approve'),
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'reject',
                      child: ListTile(
                        leading: Icon(Icons.cancel, color: Colors.red),
                        title: Text('Reject'),
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'delete',
                      child: ListTile(
                        leading: Icon(Icons.delete, color: Colors.red),
                        title: Text('Delete Post'),
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            
            const SizedBox(height: 12),
            
            Text(
              postData['content'] ?? '',
              style: const TextStyle(fontSize: 14),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
            
            if (postData['images'] != null && (postData['images'] as List).isNotEmpty) ...[
              const SizedBox(height: 12),
              SizedBox(
                height: 100,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: (postData['images'] as List).length,
                  itemBuilder: (context, index) {
                    return Container(
                      margin: const EdgeInsets.only(right: 8),
                      width: 100,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        image: DecorationImage(
                          image: NetworkImage((postData['images'] as List)[index]),
                          fit: BoxFit.cover,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
            
            const SizedBox(height: 12),
            
            // Post Stats
            Row(
              children: [
                Icon(Icons.favorite, size: 16, color: Colors.grey.shade600),
                const SizedBox(width: 4),
                Text(
                  '${postData['likes'] ?? 0}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
                const SizedBox(width: 16),
                Icon(Icons.comment, size: 16, color: Colors.grey.shade600),
                const SizedBox(width: 4),
                Text(
                  '${postData['comments'] ?? 0}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
                const Spacer(),
                // Moderation Status
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getModerationStatusColor(postData['moderationStatus']).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: _getModerationStatusColor(postData['moderationStatus']).withOpacity(0.3)),
                  ),
                  child: Text(
                    _getModerationStatusText(postData['moderationStatus']),
                    style: TextStyle(
                      fontSize: 12,
                      color: _getModerationStatusColor(postData['moderationStatus']),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color _getModerationStatusColor(String? status) {
    switch (status) {
      case 'approved':
        return Colors.green;
      case 'rejected':
        return Colors.red;
      case 'pending':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  String _getModerationStatusText(String? status) {
    switch (status) {
      case 'approved':
        return 'Approved';
      case 'rejected':
        return 'Rejected';
      case 'pending':
        return 'Pending';
      default:
        return 'Not Moderated';
    }
  }

  void _handlePostAction(String action, Map<String, dynamic> postData, String postId) {
    switch (action) {
      case 'analyze':
        _analyzePostContent(postData, postId);
        break;
      case 'approve':
        _approvePost(postId);
        break;
      case 'reject':
        _rejectPost(postId);
        break;
      case 'delete':
        _deletePost(postId);
        break;
    }
  }

  Future<void> _analyzePostContent(Map<String, dynamic> postData, String postId) async {
    try {
      final content = postData['content'] ?? '';
      if (content.isEmpty) {
        _showErrorSnackBar('No content to analyze');
        return;
      }

      // Show loading dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const AlertDialog(
          content: Row(
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 16),
              Text('Analyzing content with AI...'),
            ],
          ),
        ),
      );

      // Analyze content with Gemini AI
      final analysis = await GeminiService.analyzeContentModeration(content);
      
      // Close loading dialog
      if (mounted) Navigator.pop(context);
      
      // Show analysis results
      _showContentAnalysisDialog(analysis, postData, postId);
      
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // Close loading dialog
        _showErrorSnackBar('Error analyzing content: $e');
      }
    }
  }

  void _showContentAnalysisDialog(String analysis, Map<String, dynamic> postData, String postId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('AI Content Analysis'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Post Content:',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(postData['content'] ?? ''),
              const SizedBox(height: 16),
              Text(
                'AI Analysis:',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(analysis),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _rejectPost(postId);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Reject Post', style: TextStyle(color: Colors.white)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _approvePost(postId);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: const Text('Approve Post', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Future<void> _approvePost(String postId) async {
    try {
      await FirebaseFirestore.instance.collection('community_posts').doc(postId).update({
        'moderationStatus': 'approved',
        'moderatedAt': FieldValue.serverTimestamp(),
        'moderatedBy': FirebaseAuth.instance.currentUser?.uid,
      });
      _showSuccessSnackBar('Post approved successfully');
    } catch (e) {
      _showErrorSnackBar('Error approving post: $e');
    }
  }

  Future<void> _rejectPost(String postId) async {
    try {
      await FirebaseFirestore.instance.collection('community_posts').doc(postId).update({
        'moderationStatus': 'rejected',
        'moderatedAt': FieldValue.serverTimestamp(),
        'moderatedBy': FirebaseAuth.instance.currentUser?.uid,
      });
      _showSuccessSnackBar('Post rejected successfully');
    } catch (e) {
      _showErrorSnackBar('Error rejecting post: $e');
    }
  }

  Future<void> _deletePost(String postId) async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Post'),
        content: const Text('Are you sure you want to delete this post? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await FirebaseFirestore.instance.collection('community_posts').doc(postId).delete();
                _showSuccessSnackBar('Post deleted successfully');
              } catch (e) {
                _showErrorSnackBar('Error deleting post: $e');
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showDeleteCommunityDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Community'),
        content: Text(
          'Are you sure you want to delete "${widget.community.name}"? This action cannot be undone and will delete all posts and members.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await _deleteCommunity();
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteCommunity() async {
    try {
      // Delete community and all related data
      await FirebaseFirestore.instance.collection('communities').doc(widget.community.id).delete();
      
      // Delete community members
      final membersSnapshot = await FirebaseFirestore.instance
          .collection('community_members')
          .where('communityId', isEqualTo: widget.community.id)
          .get();
      
      for (final member in membersSnapshot.docs) {
        await member.reference.delete();
      }
      
      // Delete community posts
      final postsSnapshot = await FirebaseFirestore.instance
          .collection('community_posts')
          .where('communityId', isEqualTo: widget.community.id)
          .get();
      
      for (final post in postsSnapshot.docs) {
        await post.reference.delete();
      }
      
      _showSuccessSnackBar('Community "${widget.community.name}" deleted successfully');
      Navigator.pop(context); // Go back to community management screen
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
