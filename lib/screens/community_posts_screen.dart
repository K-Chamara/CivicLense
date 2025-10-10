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

  @override
  void initState() {
    super.initState();
    _checkDeletePermission();
  }

  Future<void> _checkDeletePermission() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      print('🔍 Checking delete permission for user: ${user.uid}');
      print('🔍 Community ID: ${widget.community.id}');
      final canDelete = await _communityService.canDeleteCommunity(widget.community.id, user.uid);
      print('🔍 Can delete community: $canDelete');
      setState(() {
        _canDeleteCommunity = canDelete;
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
          // Always show the menu for testing - remove this condition later
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: _handleMenuAction,
            itemBuilder: (context) => [
              if (_canDeleteCommunity)
                const PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(Icons.delete, color: Colors.red),
                      SizedBox(width: 8),
                      Text('Delete Community'),
                    ],
                  ),
                )
              else
                const PopupMenuItem(
                  value: 'info',
                  child: Row(
                    children: [
                      Icon(Icons.info_outline),
                      SizedBox(width: 8),
                      Text('Community Info'),
                    ],
                  ),
                ),
            ],
          ),
        ],
      ),
      body: StreamBuilder<List<CommunityPost>>(
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
      ),
      floatingActionButton: FloatingActionButton(
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
      ),
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
                      return const Center(
                        child: Text('No comments yet'),
                      );
                    }

                    final comments = snapshot.data!;
                    return ListView.builder(
                      controller: scrollController,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: comments.length,
                      itemBuilder: (context, index) {
                        final comment = comments[index];
                        return _buildCommentItem(comment);
                      },
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

  void _handleMenuAction(String action) {
    if (action == 'delete') {
      _showDeleteConfirmation();
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
