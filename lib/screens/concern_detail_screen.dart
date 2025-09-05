import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/concern_models.dart';
import '../services/concern_service.dart';

class ConcernDetailScreen extends StatefulWidget {
  final Concern concern;

  const ConcernDetailScreen({super.key, required this.concern});

  @override
  State<ConcernDetailScreen> createState() => _ConcernDetailScreenState();
}

class _ConcernDetailScreenState extends State<ConcernDetailScreen>
    with TickerProviderStateMixin {
  final _concernService = ConcernService();
  late TabController _tabController;
  final _commentController = TextEditingController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _commentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Concern Details'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          PopupMenuButton<String>(
            onSelected: _handleMenuAction,
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'assign',
                child: ListTile(
                  leading: Icon(Icons.assignment_ind),
                  title: Text('Assign to Officer'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              const PopupMenuItem(
                value: 'priority',
                child: ListTile(
                  leading: Icon(Icons.priority_high),
                  title: Text('Change Priority'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              const PopupMenuItem(
                value: 'status',
                child: ListTile(
                  leading: Icon(Icons.update),
                  title: Text('Update Status'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              const PopupMenuItem(
                value: 'escalate',
                child: ListTile(
                  leading: Icon(Icons.trending_up),
                  title: Text('Escalate'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ],
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(text: 'Details', icon: Icon(Icons.info)),
            Tab(text: 'Comments', icon: Icon(Icons.comment)),
            Tab(text: 'Updates', icon: Icon(Icons.history)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildDetailsTab(),
          _buildCommentsTab(),
          _buildUpdatesTab(),
        ],
      ),
    );
  }

  Widget _buildDetailsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Card
          Card(
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      _buildPriorityChip(widget.concern.priority),
                      const SizedBox(width: 8),
                      _buildStatusChip(widget.concern.status),
                      const Spacer(),
                      _buildCategoryChip(widget.concern.category),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    widget.concern.title,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    widget.concern.description,
                    style: const TextStyle(fontSize: 16),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Metadata Card
          Card(
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Concern Information',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildInfoRow('Type', _getTypeDisplayName(widget.concern.type)),
                  _buildInfoRow('Author', widget.concern.isAnonymous ? 'Anonymous' : widget.concern.authorName),
                  _buildInfoRow('Created', _formatDate(widget.concern.createdAt)),
                  if (widget.concern.updatedAt != null)
                    _buildInfoRow('Last Updated', _formatDate(widget.concern.updatedAt!)),
                  if (widget.concern.assignedOfficerName != null)
                    _buildInfoRow('Assigned To', widget.concern.assignedOfficerName!),
                  if (widget.concern.tags.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    const Text(
                      'Tags:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Wrap(
                      spacing: 4,
                      runSpacing: 4,
                      children: widget.concern.tags.map((tag) => Chip(
                        label: Text(tag),
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        visualDensity: VisualDensity.compact,
                      )).toList(),
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Engagement Card
          Card(
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Public Engagement',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _buildEngagementItem(
                          Icons.thumb_up,
                          'Upvotes',
                          widget.concern.upvotes.toString(),
                          Colors.green,
                        ),
                      ),
                      Expanded(
                        child: _buildEngagementItem(
                          Icons.thumb_down,
                          'Downvotes',
                          widget.concern.downvotes.toString(),
                          Colors.red,
                        ),
                      ),
                      Expanded(
                        child: _buildEngagementItem(
                          Icons.comment,
                          'Comments',
                          widget.concern.commentCount.toString(),
                          Colors.blue,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCommentsTab() {
    return Column(
      children: [
        // Add Comment Section
        Container(
          padding: const EdgeInsets.all(16),
          color: Colors.grey.shade50,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Add Comment',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _commentController,
                decoration: const InputDecoration(
                  hintText: 'Add your comment...',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Checkbox(
                    value: false,
                    onChanged: (value) {
                      // Handle official comment checkbox
                    },
                  ),
                  const Text('Official Response'),
                  const Spacer(),
                  ElevatedButton(
                    onPressed: _isLoading ? null : _addComment,
                    child: _isLoading
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Post Comment'),
                  ),
                ],
              ),
            ],
          ),
        ),

        // Comments List
        Expanded(
          child: StreamBuilder<List<ConcernComment>>(
            stream: _concernService.getConcernComments(widget.concern.id),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (snapshot.hasError) {
                return Center(
                  child: Text('Error: ${snapshot.error}'),
                );
              }

              final comments = snapshot.data ?? [];

              if (comments.isEmpty) {
                return const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.comment_outlined, size: 64, color: Colors.grey),
                      SizedBox(height: 16),
                      Text(
                        'No comments yet',
                        style: TextStyle(fontSize: 18, color: Colors.grey),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Be the first to comment',
                        style: TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: comments.length,
                itemBuilder: (context, index) {
                  final comment = comments[index];
                  return _buildCommentCard(comment);
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildUpdatesTab() {
    return StreamBuilder<List<ConcernUpdate>>(
      stream: _concernService.getConcernUpdates(widget.concern.id),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Text('Error: ${snapshot.error}'),
          );
        }

        final updates = snapshot.data ?? [];

        if (updates.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.history, size: 64, color: Colors.grey),
                SizedBox(height: 16),
                Text(
                  'No updates yet',
                  style: TextStyle(fontSize: 18, color: Colors.grey),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: updates.length,
          itemBuilder: (context, index) {
            final update = updates[index];
            return _buildUpdateCard(update);
          },
        );
      },
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }

  Widget _buildEngagementItem(IconData icon, String label, String value, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.grey,
          ),
        ),
      ],
    );
  }

  Widget _buildCommentCard(ConcernComment comment) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 16,
                  backgroundColor: comment.isOfficial ? Colors.blue : Colors.grey,
                  child: Text(
                    comment.authorName[0].toUpperCase(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            comment.authorName,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          if (comment.isOfficial) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.blue,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Text(
                                'OFFICIAL',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      Text(
                        _formatDate(comment.createdAt),
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(comment.content),
          ],
        ),
      ),
    );
  }

  Widget _buildUpdateCard(ConcernUpdate update) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  _getUpdateIcon(update.action),
                  color: _getUpdateColor(update.action),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _getUpdateTitle(update.action),
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        'by ${update.officerName}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  _formatDate(update.createdAt),
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(update.description),
            if (update.changes.isNotEmpty) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: update.changes.entries.map((entry) {
                    return Text(
                      '${entry.key}: ${entry.value}',
                      style: const TextStyle(fontSize: 12),
                    );
                  }).toList(),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildPriorityChip(ConcernPriority priority) {
    Color color;
    switch (priority) {
      case ConcernPriority.low:
        color = Colors.green;
        break;
      case ConcernPriority.medium:
        color = Colors.orange;
        break;
      case ConcernPriority.high:
        color = Colors.red;
        break;
      case ConcernPriority.critical:
        color = Colors.purple;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        priority.name.toUpperCase(),
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
    );
  }

  Widget _buildStatusChip(ConcernStatus status) {
    Color color;
    switch (status) {
      case ConcernStatus.pending:
        color = Colors.orange;
        break;
      case ConcernStatus.underReview:
        color = Colors.blue;
        break;
      case ConcernStatus.inProgress:
        color = Colors.purple;
        break;
      case ConcernStatus.resolved:
        color = Colors.green;
        break;
      case ConcernStatus.dismissed:
        color = Colors.grey;
        break;
      case ConcernStatus.escalated:
        color = Colors.red;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        status.name.toUpperCase(),
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
    );
  }

  Widget _buildCategoryChip(ConcernCategory category) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.blue.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue.withOpacity(0.3)),
      ),
      child: Text(
        _getCategoryDisplayName(category),
        style: const TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: Colors.blue,
        ),
      ),
    );
  }

  String _getCategoryDisplayName(ConcernCategory category) {
    switch (category) {
      case ConcernCategory.budget:
        return 'BUDGET';
      case ConcernCategory.tender:
        return 'TENDER';
      case ConcernCategory.community:
        return 'COMMUNITY';
      case ConcernCategory.system:
        return 'SYSTEM';
      case ConcernCategory.corruption:
        return 'CORRUPTION';
      case ConcernCategory.transparency:
        return 'TRANSPARENCY';
      case ConcernCategory.other:
        return 'OTHER';
    }
  }

  String _getTypeDisplayName(ConcernType type) {
    switch (type) {
      case ConcernType.complaint:
        return 'Complaint';
      case ConcernType.suggestion:
        return 'Suggestion';
      case ConcernType.report:
        return 'Report';
      case ConcernType.question:
        return 'Question';
      case ConcernType.feedback:
        return 'Feedback';
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays > 0) {
      return '${difference.inDays} days ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hours ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} minutes ago';
    } else {
      return 'Just now';
    }
  }

  IconData _getUpdateIcon(String action) {
    switch (action) {
      case 'created':
        return Icons.add_circle;
      case 'status_update':
        return Icons.update;
      case 'assigned':
        return Icons.assignment_ind;
      case 'escalated':
        return Icons.trending_up;
      default:
        return Icons.info;
    }
  }

  Color _getUpdateColor(String action) {
    switch (action) {
      case 'created':
        return Colors.green;
      case 'status_update':
        return Colors.blue;
      case 'assigned':
        return Colors.orange;
      case 'escalated':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _getUpdateTitle(String action) {
    switch (action) {
      case 'created':
        return 'Concern Created';
      case 'status_update':
        return 'Status Updated';
      case 'assigned':
        return 'Concern Assigned';
      case 'escalated':
        return 'Concern Escalated';
      default:
        return 'Update';
    }
  }

  Future<void> _addComment() async {
    if (_commentController.text.trim().isEmpty) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      await _concernService.addComment(
        widget.concern.id,
        _commentController.text.trim(),
        user.uid,
        user.displayName ?? user.email?.split('@').first ?? 'User',
      );

      _commentController.clear();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error adding comment: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _handleMenuAction(String action) {
    switch (action) {
      case 'assign':
        _showAssignDialog();
        break;
      case 'priority':
        _showPriorityDialog();
        break;
      case 'status':
        _showStatusDialog();
        break;
      case 'escalate':
        _escalateConcern();
        break;
    }
  }

  void _showAssignDialog() {
    // Implement assignment dialog
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Assign Concern'),
        content: const Text('Assignment functionality will be implemented here.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Assign'),
          ),
        ],
      ),
    );
  }

  void _showPriorityDialog() {
    // Implement priority change dialog
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Change Priority'),
        content: const Text('Priority change functionality will be implemented here.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Update'),
          ),
        ],
      ),
    );
  }

  void _showStatusDialog() {
    // Implement status update dialog
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Update Status'),
        content: const Text('Status update functionality will be implemented here.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Update'),
          ),
        ],
      ),
    );
  }

  void _escalateConcern() {
    // Implement escalation functionality
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Escalate Concern'),
        content: const Text('This concern will be escalated to higher authorities.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Escalate'),
          ),
        ],
      ),
    );
  }
}
