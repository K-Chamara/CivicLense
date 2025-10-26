import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/community_models.dart';
import '../services/community_service.dart';
import '../services/notification_service.dart';
import 'create_community_post_screen.dart';

class CommunityPostsScreen extends StatefulWidget {
  final Community community;

  const CommunityPostsScreen({super.key, required this.community});

  @override
  State<CommunityPostsScreen> createState() => _CommunityPostsScreenState();
}

class _CommunityPostsScreenState extends State<CommunityPostsScreen> {
  final CommunityService _communityService = CommunityService();
  bool _canDeleteCommunity = false;
  bool _isMember = false;
  bool _isCreator = false;

  @override
  void initState() {
    super.initState();
    _checkPermissions();
  }

  Future<void> _checkPermissions() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      print('🔍 Checking permissions for user: ${user.uid}');
      print('🔍 Community ID: ${widget.community.id}');
      
      // Check delete permission
      final canDelete = await _communityService.canDeleteCommunity(widget.community.id, user.uid);
      
      // Check membership
      final isMember = await _communityService.isUserMember(widget.community.id, user.uid);
      
      // Check if user is the creator
      final isCreator = widget.community.createdBy == user.uid;
      
      print('🔍 Can delete community: $canDelete');
      print('🔍 Is member: $isMember');
      print('🔍 Is creator: $isCreator');
      
      setState(() {
        _canDeleteCommunity = canDelete;
        _isMember = isMember;
        _isCreator = isCreator;
      });
    } else {
      print('🔍 No user logged in');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(
          '${widget.community.name} Posts',
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: Colors.blue,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: _handleMenuAction,
            itemBuilder: (context) {
              List<PopupMenuItem<String>> items = [];
              
              // Community creator - show disband option
              if (_isCreator && _canDeleteCommunity) {
                items.add(
                  const PopupMenuItem(
                    value: 'disband',
                    child: Row(
                      children: [
                        Icon(Icons.delete_forever, color: Colors.red),
                        SizedBox(width: 8),
                        Text('Disband Community', style: TextStyle(color: Colors.red)),
                      ],
                    ),
                  ),
                );
              }
              
              // Show leave option if user is a member but NOT the creator
              if (_isMember && !_isCreator) {
                items.add(
                  const PopupMenuItem(
                    value: 'leave',
                    child: Row(
                      children: [
                        Icon(Icons.exit_to_app, color: Colors.orange),
                        SizedBox(width: 8),
                        Text('Leave Community'),
                      ],
                    ),
                  ),
                );
              }
              
              // Always show community info
              items.add(
                const PopupMenuItem(
                  value: 'info',
                  child: Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.blue),
                      SizedBox(width: 8),
                      Text('Community Info'),
                    ],
                  ),
                ),
              );
              
              return items;
            },
          ),
        ],
      ),
      body: _isMember || _isCreator
          ? StreamBuilder<List<CommunityPost>>(
              stream: _communityService.getCommunityPosts(widget.community.id),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.error_outline,
                          size: 64,
                          color: Colors.red[300],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Error loading posts',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.red[700],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Exception: ${snapshot.error}',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.red[600],
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () {
                            setState(() {});
                          },
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  );
                }

                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.forum_outlined,
                          size: 64,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No posts yet',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Be the first to start a discussion!',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[500],
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  );
                }

                final posts = snapshot.data!;

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: posts.length,
                  itemBuilder: (context, index) {
                    final post = posts[index];
                    return _buildPostCard(post);
                  },
                );
              },
            )
          : _buildJoinCommunityScreen(),
      floatingActionButton: (_isMember || _isCreator)
          ? FloatingActionButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => CreateCommunityPostScreen(community: widget.community),
                  ),
                );
              },
              backgroundColor: Colors.blue,
              child: const Icon(Icons.add, color: Colors.white),
              tooltip: 'Create Post',
            )
          : null,
    );
  }

  Widget _buildPostCard(CommunityPost post) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Post Header
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: Colors.blue.withOpacity(0.1),
                  child: const Icon(Icons.person, color: Colors.blue),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        post.authorName,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        _formatDate(post.createdAt),
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                if (post.isPinned)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.orange.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.push_pin, size: 12, color: Colors.orange),
                        const SizedBox(width: 4),
                        const Text(
                          'Pinned',
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.orange,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            
            // Post Title
            if (post.title.isNotEmpty) ...[
              Text(
                post.title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 8),
            ],
            
            // Post Content
            Text(
              post.content,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[700],
                height: 1.4,
              ),
            ),
            const SizedBox(height: 12),
            
            // Images
            if (post.images.isNotEmpty) ...[
              Container(
                height: 200,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: post.images.length,
                  itemBuilder: (context, index) {
                    return Container(
                      width: 200,
                      margin: const EdgeInsets.only(right: 8),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        color: Colors.grey[200],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(
                          post.images[index],
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              color: Colors.grey[200],
                              child: const Icon(Icons.image, size: 50, color: Colors.grey),
                            );
                          },
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 12),
            ],
            
            // Tags
            if (post.tags.isNotEmpty) ...[
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: post.tags.map((tag) {
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '#$tag',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.blue[700],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 12),
            ],
            
            // Post Actions
            Row(
              children: [
                // Like Button
                InkWell(
                  onTap: () => _likePost(post),
                  borderRadius: BorderRadius.circular(20),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.thumb_up_outlined,
                          size: 18,
                          color: Colors.grey[600],
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${post.likes}',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                
                // Comment Button
                InkWell(
                  onTap: () => _showComments(post),
                  borderRadius: BorderRadius.circular(20),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.comment_outlined,
                          size: 18,
                          color: Colors.grey[600],
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${post.comments}',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                
                const Spacer(),
                
                // Share Indicator
                if (post.sharedFrom != null) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.share, size: 12, color: Colors.green),
                        const SizedBox(width: 4),
                        Text(
                          'Shared from ${post.sharedFromType}',
                          style: const TextStyle(
                            fontSize: 10,
                            color: Colors.green,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildJoinCommunityScreen() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Lock Icon
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(40),
              ),
              child: Icon(
                Icons.lock_outline,
                size: 40,
                color: Colors.blue.shade400,
              ),
            ),
            const SizedBox(height: 24),
            
            // Title
            Text(
              'Join ${widget.community.name}',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade800,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            
            // Description
            Text(
              'You need to join this community to view and participate in discussions.',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey.shade600,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            
            // Community Info Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.1),
                    spreadRadius: 1,
                    blurRadius: 5,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // Community Description
                  Text(
                    widget.community.description,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade700,
                      height: 1.4,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  
                  // Stats
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildStatItem(
                        '${widget.community.memberCount}',
                        'Members',
                        Icons.people,
                      ),
                      _buildStatItem(
                        '${widget.community.postCount}',
                        'Posts',
                        Icons.forum,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            
            // Join Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _joinCommunity,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Join Community',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            
            // Back Button
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Go Back',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String value, String label, IconData icon) {
    return Column(
      children: [
        Icon(
          icon,
          color: Colors.blue.shade400,
          size: 20,
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.grey.shade800,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade600,
          ),
        ),
      ],
    );
  }

  Future<void> _joinCommunity() async {
    try {
      final success = await _communityService.joinCommunity(widget.community.id);
      
      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Successfully joined ${widget.community.name}!'),
            backgroundColor: Colors.green,
          ),
        );
        
        // Refresh the screen to show posts
        _checkPermissions();
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to join community. Please try again.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error joining community: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);
    
    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }

  Future<void> _likePost(CommunityPost post) async {
    try {
      await _communityService.likePost(widget.community.id, post.id);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error liking post: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showComments(CommunityPost post) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (context, scrollController) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
          ),
          child: Column(
            children: [
              // Handle
              Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              
              // Header
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    const Text(
                      'Comments',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
              ),
              
              // Comments List
              Expanded(
                child: StreamBuilder<List<CommunityComment>>(
                  stream: _communityService.getPostComments(widget.community.id, post.id),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    if (!snapshot.hasData || snapshot.data!.isEmpty) {
                      return Column(
                        children: [
                          const Expanded(
                            child: Center(
                              child: Text('No comments yet'),
                            ),
                          ),
                          _buildCommentInput(post),
                        ],
                      );
                    }

                    final comments = snapshot.data!;
                    return Column(
                      children: [
                        Expanded(
                          child: ListView.builder(
                            controller: scrollController,
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            itemCount: comments.length,
                            itemBuilder: (context, index) {
                              final comment = comments[index];
                              return _buildCommentItem(comment);
                            },
                          ),
                        ),
                        _buildCommentInput(post),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCommentItem(CommunityComment comment) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: Colors.blue.withOpacity(0.1),
            child: const Icon(Icons.person, size: 16, color: Colors.blue),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      comment.authorName,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _formatDate(comment.createdAt),
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  comment.content,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[700],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCommentInput(CommunityPost post) {
    return _CommentInputWidget(
      post: post,
      communityService: _communityService,
    );
  }

  void _handleMenuAction(String action) {
    if (action == 'disband') {
      _showDisbandConfirmation();
    } else if (action == 'leave') {
      _showLeaveConfirmation();
    } else if (action == 'info') {
      _showPostsInfo();
    }
  }

  void _showDeleteConfirmation() {
    final reasonController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(
          'Delete Community',
          style: TextStyle(color: Colors.red),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Are you sure you want to delete "${widget.community.name}"?',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            const Text(
              'Please provide a reason for deletion:',
              style: TextStyle(fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: reasonController,
              maxLines: 3,
              decoration: const InputDecoration(
                hintText: 'Enter reason for deletion...',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red.withOpacity(0.3)),
              ),
              child: const Text(
                '⚠️ This action cannot be undone. All posts, comments, and member data will be permanently deleted.',
                style: TextStyle(
                  color: Colors.red,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: reasonController.text.trim().isEmpty 
                ? null 
                : () => _deleteCommunity(reasonController.text.trim()),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete Community'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteCommunity(String reason) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      // Show loading dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const AlertDialog(
          content: Row(
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 16),
              Text('Deleting community...'),
            ],
          ),
        ),
      );

      // Get all community members before deletion
      final membersQuery = await _communityService.firestore
          .collection('community_members')
          .where('communityId', isEqualTo: widget.community.id)
          .where('status', isEqualTo: 'active')
          .get();

      final memberIds = membersQuery.docs
          .map((doc) => doc.data()['userId'] as String)
          .toList();

      // Delete the community
      await _communityService.deleteCommunity(widget.community.id, user.uid);

      // Send push notifications to all members
      await _sendDeletionNotifications(memberIds, reason);

      // Close loading dialog
      if (mounted) Navigator.pop(context);

      // Show success message and navigate back
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ Community "${widget.community.name}" deleted successfully'),
            backgroundColor: Colors.green,
          ),
        );
        
        // Navigate back to community list
        Navigator.pop(context);
      }
    } catch (e) {
      // Close loading dialog
      if (mounted) Navigator.pop(context);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Error deleting community: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _sendDeletionNotifications(List<String> memberIds, String reason) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      // Get user data for notification
      final userDoc = await _communityService.firestore
          .collection('users')
          .doc(user.uid)
          .get();
      final userData = userDoc.data();
      final userName = '${userData?['firstName'] ?? ''} ${userData?['lastName'] ?? ''}'.trim();

      final notificationData = {
        'title': 'Community Deleted',
        'body': 'The community "${widget.community.name}" has been deleted by $userName. Reason: $reason',
        'data': {
          'type': 'community_deleted',
          'communityId': widget.community.id,
          'communityName': widget.community.name,
          'reason': reason,
          'deletedBy': userName,
        },
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      };

      // Send notifications to all members (excluding the deleter)
      final targetMembers = memberIds.where((id) => id != user.uid).toList();
      
      for (final memberId in targetMembers) {
        await NotificationService.sendNotificationToUser(
          memberId,
          notificationData['title'] as String,
          notificationData['body'] as String,
          notificationData['data'] as Map<String, dynamic>,
        );
      }

      print('✅ Sent deletion notifications to ${targetMembers.length} members');
    } catch (e) {
      print('❌ Error sending deletion notifications: $e');
    }
  }

  void _showDisbandConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.delete_forever, color: Colors.red[700]),
            const SizedBox(width: 12),
            const Text('Disband Community'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Are you sure you want to disband "${widget.community.name}"?',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red[200]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.warning, color: Colors.red[700], size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'This action will:',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.red[700],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '• Delete the community permanently\n'
                    '• Remove all posts and comments\n'
                    '• Remove all members from the community\n'
                    '• This action cannot be undone',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.red[600],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _disbandCommunity();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Disband Community'),
          ),
        ],
      ),
    );
  }

  void _showLeaveConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.exit_to_app, color: Colors.orange[700]),
            const SizedBox(width: 12),
            const Text('Leave Community'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Are you sure you want to leave "${widget.community.name}"?',
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange[200]!),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.orange[700], size: 20),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'You will lose access to all posts and discussions.',
                      style: TextStyle(fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => _leaveCommunity(),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
            ),
            child: const Text('Leave Community'),
          ),
        ],
      ),
    );
  }

  Future<void> _disbandCommunity() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      // Show loading dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const AlertDialog(
          content: Row(
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 16),
              Text('Disbanding community...'),
            ],
          ),
        ),
      );

      // Disband the community
      await _communityService.disbandCommunity(widget.community.id, user.uid);

      // Close loading dialog
      if (mounted) Navigator.pop(context);

      // Show success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ Community "${widget.community.name}" has been disbanded'),
            backgroundColor: Colors.green,
          ),
        );
      }

      // Navigate back to community list
      if (mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      // Close loading dialog
      if (mounted) Navigator.pop(context);

      // Show error message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Error disbanding community: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _leaveCommunity() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      // Close confirmation dialog
      Navigator.pop(context);

      // Show loading dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const AlertDialog(
          content: Row(
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 16),
              Text('Leaving community...'),
            ],
          ),
        ),
      );

      // Leave the community
      final success = await _communityService.leaveCommunity(widget.community.id);

      // Close loading dialog
      if (mounted) Navigator.pop(context);

      if (success) {
        // Show success message
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.check_circle, color: Colors.white),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text('You have left "${widget.community.name}"'),
                  ),
                ],
              ),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 3),
            ),
          );

          // Navigate back to community list
          Navigator.pop(context);
        }
      } else {
        // Show error message
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Row(
                children: [
                  Icon(Icons.error, color: Colors.white),
                  SizedBox(width: 12),
                  Text('Failed to leave community'),
                ],
              ),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      // Close loading dialog
      if (mounted) Navigator.pop(context);

      // Show error message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(child: Text('Error: $e')),
              ],
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showPostsInfo() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Community Posts'),
        content: const Text(
          'This is where community members share posts, discuss topics, and engage with each other. You can like posts, comment on them, and create your own posts to start discussions.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Got it'),
          ),
        ],
      ),
    );
  }
}

class _CommentInputWidget extends StatefulWidget {
  final CommunityPost post;
  final CommunityService communityService;

  const _CommentInputWidget({
    required this.post,
    required this.communityService,
  });

  @override
  State<_CommentInputWidget> createState() => _CommentInputWidgetState();
}

class _CommentInputWidgetState extends State<_CommentInputWidget> {
  final TextEditingController _commentController = TextEditingController();
  bool _isPosting = false;

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _postComment() async {
    if (_commentController.text.trim().isEmpty || _isPosting) return;

    setState(() {
      _isPosting = true;
    });

    try {
      await widget.communityService.createComment(
        postId: widget.post.id,
        content: _commentController.text.trim(),
      );

      // Clear the input field
      _commentController.clear();

      // Show success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Comment posted successfully!'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Error posting comment: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isPosting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        border: Border(
          top: BorderSide(color: Colors.grey[200]!),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _commentController,
              decoration: InputDecoration(
                hintText: 'Add a comment...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide: BorderSide(color: Colors.grey[300]!),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide: BorderSide(color: Colors.grey[300]!),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide: const BorderSide(color: Colors.blue),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                filled: true,
                fillColor: Colors.white,
              ),
              maxLines: null,
              textInputAction: TextInputAction.send,
              onSubmitted: (value) {
                if (value.trim().isNotEmpty && !_isPosting) {
                  _postComment();
                }
              },
              onChanged: (value) {
                setState(() {}); // Rebuild to update button state
              },
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            onPressed: _isPosting || _commentController.text.trim().isEmpty
                ? null
                : _postComment,
            icon: _isPosting
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.send, color: Colors.blue),
            style: IconButton.styleFrom(
              backgroundColor: Colors.blue.withOpacity(0.1),
              shape: const CircleBorder(),
            ),
          ),
        ],
      ),
    );
  }
}
