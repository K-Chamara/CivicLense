import 'package:flutter/material.dart';
import '../models/concern_models.dart';
import '../services/concern_management_service.dart';
import '../services/notification_service.dart';
import 'user_concern_tracking_screen.dart';
import 'public_tender_viewer_screen.dart';

class ConcernDetailScreen extends StatefulWidget {
  final Concern concern;
  final String officerId;
  final String officerName;

  const ConcernDetailScreen({
    super.key,
    required this.concern,
    required this.officerId,
    required this.officerName,
  });

  @override
  State<ConcernDetailScreen> createState() => _ConcernDetailScreenState();
}

class _ConcernDetailScreenState extends State<ConcernDetailScreen> {
  final TextEditingController _commentController = TextEditingController();
  bool _isUpdating = false;

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: const Text('Concern Details'),
        backgroundColor: Colors.purple,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) => _showStatusUpdateDialog(value),
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'underReview',
                child: Row(
                  children: [
                    Icon(Icons.search, color: Colors.blue),
                    SizedBox(width: 8),
                    Text('Mark as Under Review'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'inProgress',
                child: Row(
                  children: [
                    Icon(Icons.work, color: Colors.purple),
                    SizedBox(width: 8),
                    Text('Mark as In Progress'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'resolved',
                child: Row(
                  children: [
                    Icon(Icons.check_circle, color: Colors.green),
                    SizedBox(width: 8),
                    Text('Mark as Resolved'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'dismissed',
                child: Row(
                  children: [
                    Icon(Icons.cancel, color: Colors.grey),
                    SizedBox(width: 8),
                    Text('Dismiss'),
                  ],
                ),
              ),
            ],
            child: const Padding(
              padding: EdgeInsets.all(16),
              child: Icon(Icons.more_vert),
            ),
          ),
        ],
      ),
      body: _isUpdating
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Updating concern...'),
                ],
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildConcernHeader(),
                  const SizedBox(height: 16),
                  _buildConcernInfo(),
                  const SizedBox(height: 16),
                  _buildStatusSection(),
                  const SizedBox(height: 16),
                  _buildCommentsSection(),
                  const SizedBox(height: 16),
                  _buildUpdatesSection(),
                ],
              ),
            ),
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildBottomActionBar(),
          _buildBottomNavigationBar(),
        ],
      ),
    );
  }

  Widget _buildConcernHeader() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    widget.concern.title,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                _buildStatusChip(widget.concern.status),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              widget.concern.description,
              style: const TextStyle(fontSize: 16, height: 1.5),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _buildInfoChip(
                  Icons.person,
                  widget.concern.authorName,
                  Colors.blue,
                ),
                const SizedBox(width: 8),
                _buildInfoChip(
                  Icons.category,
                  widget.concern.category.name.toUpperCase(),
                  Colors.green,
                ),
                const SizedBox(width: 8),
                if (widget.concern.supportCount > 0)
                  _buildInfoChip(
                    Icons.thumb_up,
                    '${widget.concern.supportCount} supports',
                    Colors.orange,
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConcernInfo() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
            const SizedBox(height: 12),
            _buildInfoRow('Type', widget.concern.type.name.toUpperCase()),
            _buildInfoRow('Priority', widget.concern.priority.name.toUpperCase()),
            _buildInfoRow('Created', _formatDate(widget.concern.createdAt)),
            if (widget.concern.updatedAt != null)
              _buildInfoRow('Last Updated', _formatDate(widget.concern.updatedAt!)),
            if (widget.concern.assignedOfficerName != null)
              _buildInfoRow('Assigned Officer', widget.concern.assignedOfficerName!),
            if (widget.concern.tags.isNotEmpty)
              _buildInfoRow('Tags', widget.concern.tags.join(', ')),
          ],
        ),
      ),
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
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.grey,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusSection() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Current Status',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _buildStatusChip(widget.concern.status),
                const Spacer(),
                Text(
                  'Updated ${_formatDate(widget.concern.updatedAt ?? widget.concern.createdAt)}',
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
    );
  }

  Widget _buildCommentsSection() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Comments & Updates',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            StreamBuilder<List<ConcernComment>>(
              stream: ConcernManagementService.getConcernComments(widget.concern.id),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final comments = snapshot.data ?? [];
                if (comments.isEmpty) {
                  return const Text(
                    'No comments yet',
                    style: TextStyle(color: Colors.grey),
                  );
                }

                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: comments.length,
                  itemBuilder: (context, index) {
                    final comment = comments[index];
                    return _buildCommentItem(comment);
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCommentItem(ConcernComment comment) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: comment.isOfficial ? Colors.blue.withOpacity(0.1) : Colors.grey.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: comment.isOfficial ? Colors.blue : Colors.grey,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                comment.isOfficial ? Icons.security : Icons.person,
                size: 16,
                color: comment.isOfficial ? Colors.blue : Colors.grey,
              ),
              const SizedBox(width: 4),
              Text(
                comment.authorName,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: comment.isOfficial ? Colors.blue : Colors.grey[700],
                ),
              ),
              if (comment.isOfficial) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.blue,
                    borderRadius: BorderRadius.circular(4),
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
              const Spacer(),
              Text(
                _formatDate(comment.createdAt),
                style: const TextStyle(
                  color: Colors.grey,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            comment.content,
            style: const TextStyle(fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildUpdatesSection() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Activity Timeline',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            StreamBuilder<List<ConcernUpdate>>(
              stream: ConcernManagementService.getConcernUpdates(widget.concern.id),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final updates = snapshot.data ?? [];
                if (updates.isEmpty) {
                  return const Text(
                    'No updates yet',
                    style: TextStyle(color: Colors.grey),
                  );
                }

                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: updates.length,
                  itemBuilder: (context, index) {
                    final update = updates[index];
                    return _buildUpdateItem(update);
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUpdateItem(ConcernUpdate update) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.purple.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.purple, width: 1),
      ),
      child: Row(
        children: [
          const Icon(Icons.update, color: Colors.purple, size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  update.description,
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
                Text(
                  'by ${update.officerName} • ${_formatDate(update.createdAt)}',
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

  Widget _buildBottomActionBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey,
            blurRadius: 4,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _commentController,
              decoration: const InputDecoration(
                hintText: 'Add a comment...',
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
              maxLines: null,
            ),
          ),
          const SizedBox(width: 12),
          ElevatedButton.icon(
            onPressed: _isUpdating ? null : _addComment,
            icon: _isUpdating
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.send),
            label: const Text('Send'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.purple,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusChip(ConcernStatus status) {
    Color color;
    String text;
    IconData icon;

    switch (status) {
      case ConcernStatus.pending:
        color = Colors.orange;
        text = 'Pending';
        icon = Icons.pending;
        break;
      case ConcernStatus.underReview:
        color = Colors.blue;
        text = 'Under Review';
        icon = Icons.search;
        break;
      case ConcernStatus.inProgress:
        color = Colors.purple;
        text = 'In Progress';
        icon = Icons.work;
        break;
      case ConcernStatus.resolved:
        color = Colors.green;
        text = 'Resolved';
        icon = Icons.check_circle;
        break;
      case ConcernStatus.dismissed:
        color = Colors.grey;
        text = 'Dismissed';
        icon = Icons.cancel;
        break;
      case ConcernStatus.escalated:
        color = Colors.red;
        text = 'Escalated';
        icon = Icons.priority_high;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 6),
          Text(
            text,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.bold,
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
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
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

  void _showStatusUpdateDialog(String action) {
    final statusMap = {
      'underReview': ConcernStatus.underReview,
      'inProgress': ConcernStatus.inProgress,
      'resolved': ConcernStatus.resolved,
      'dismissed': ConcernStatus.dismissed,
    };

    final newStatus = statusMap[action];
    if (newStatus == null) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Update Status to ${newStatus.name.toUpperCase()}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Add a comment about this status change:'),
            const SizedBox(height: 12),
            TextField(
              controller: _commentController,
              decoration: const InputDecoration(
                hintText: 'Enter comment...',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
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
              _updateStatus(newStatus, _commentController.text);
            },
            child: const Text('Update'),
          ),
        ],
      ),
    );
  }

  Future<void> _updateStatus(ConcernStatus newStatus, String comment) async {
    setState(() => _isUpdating = true);

    try {
      await ConcernManagementService.updateConcernStatus(
        concernId: widget.concern.id,
        newStatus: newStatus,
        officerId: widget.officerId,
        officerName: widget.officerName,
        comment: comment.isNotEmpty ? comment : null,
      );

      // Send notification to user
      await NotificationService.notifyStatusChange(
        concernId: widget.concern.id,
        userId: widget.concern.authorId,
        oldStatus: widget.concern.status,
        newStatus: newStatus,
        comment: comment.isNotEmpty ? comment : null,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Status updated to ${newStatus.name}'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating status: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _isUpdating = false);
    }
  }

  Future<void> _addComment() async {
    final comment = _commentController.text.trim();
    if (comment.isEmpty) return;

    setState(() => _isUpdating = true);

    try {
      await ConcernManagementService.addOfficerComment(
        widget.concern.id,
        comment,
        widget.officerId,
        widget.officerName,
      );

      // Send notification to user
      await NotificationService.notifyOfficerComment(
        concernId: widget.concern.id,
        userId: widget.concern.authorId,
        comment: comment,
        officerName: widget.officerName,
      );

      _commentController.clear();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Comment added successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error adding comment: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _isUpdating = false);
    }
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
            Navigator.pushNamed(context, '/dashboard');
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
}