import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/concern_models.dart';
import '../services/concern_management_service.dart';

class UserConcernTrackingScreen extends StatefulWidget {
  const UserConcernTrackingScreen({super.key});

  @override
  State<UserConcernTrackingScreen> createState() => _UserConcernTrackingScreenState();
}

class _UserConcernTrackingScreenState extends State<UserConcernTrackingScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  String? _currentUserId;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _getCurrentUser();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _getCurrentUser() async {
    final user = _auth.currentUser;
    if (user != null) {
      setState(() {
        _currentUserId = user.uid;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_currentUserId == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: const Text('My Concerns'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(text: 'All', icon: Icon(Icons.list)),
            Tab(text: 'Active', icon: Icon(Icons.pending)),
            Tab(text: 'Resolved', icon: Icon(Icons.check_circle)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildUserConcernsList(),
          _buildUserConcernsList(status: 'active'),
          _buildUserConcernsList(status: 'resolved'),
        ],
      ),
    );
  }

  Widget _buildUserConcernsList({String? status}) {
    Stream<List<Concern>> concernsStream;
    
    if (status == 'active') {
      concernsStream = _getUserConcernsByStatus([
        ConcernStatus.pending,
        ConcernStatus.underReview,
        ConcernStatus.inProgress,
      ]);
    } else if (status == 'resolved') {
      concernsStream = _getUserConcernsByStatus([
        ConcernStatus.resolved,
        ConcernStatus.dismissed,
      ]);
    } else {
      concernsStream = _getUserConcerns();
    }

    return StreamBuilder<List<Concern>>(
      stream: concernsStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error, size: 64, color: Colors.red),
                const SizedBox(height: 16),
                Text('Error: ${snapshot.error}'),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => setState(() {}),
                  child: const Text('Retry'),
                ),
              ],
            ),
          );
        }

        final concerns = snapshot.data ?? [];

        if (concerns.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  status == 'resolved' ? Icons.check_circle : Icons.inbox,
                  size: 64,
                  color: Colors.grey,
                ),
                const SizedBox(height: 16),
                Text(
                  status == 'resolved' 
                      ? 'No resolved concerns yet'
                      : 'No concerns found',
                  style: const TextStyle(fontSize: 18, color: Colors.grey),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: concerns.length,
          itemBuilder: (context, index) {
            final concern = concerns[index];
            return _buildConcernCard(concern);
          },
        );
      },
    );
  }

  Stream<List<Concern>> _getUserConcerns() {
    return ConcernManagementService.getConcernsByFilter(
      ConcernFilter(assignedOfficerId: _currentUserId),
    );
  }

  Stream<List<Concern>> _getUserConcernsByStatus(List<ConcernStatus> statuses) {
    // This would need to be implemented in the service
    // For now, we'll filter client-side
    return _getUserConcerns().map((concerns) => 
        concerns.where((concern) => statuses.contains(concern.status)).toList());
  }

  Widget _buildConcernCard(Concern concern) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () => _navigateToConcernDetail(concern),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      concern.title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  _buildStatusChip(concern.status),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                concern.description,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.grey,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  _buildInfoChip(
                    Icons.category,
                    concern.category.name.toUpperCase(),
                    Colors.green,
                  ),
                  const SizedBox(width: 8),
                  if (concern.supportCount > 0)
                    _buildInfoChip(
                      Icons.thumb_up,
                      '${concern.supportCount} supports',
                      Colors.orange,
                    ),
                  const SizedBox(width: 8),
                  _buildInfoChip(
                    Icons.comment,
                    '${concern.commentCount} comments',
                    Colors.blue,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(
                    Icons.access_time,
                    size: 16,
                    color: Colors.grey[600],
                  ),
                  const SizedBox(width: 4),
                  Text(
                    _formatDate(concern.createdAt),
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 12,
                    ),
                  ),
                  const Spacer(),
                  if (concern.assignedOfficerName != null)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.purple.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.purple),
                      ),
                      child: Text(
                        'Assigned to ${concern.assignedOfficerName}',
                        style: const TextStyle(
                          color: Colors.purple,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
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
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color),
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
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              color: color,
              fontSize: 10,
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

  void _navigateToConcernDetail(Concern concern) {
    // Navigate to concern detail screen for users
    // This would show the concern details, updates, and comments
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(concern.title),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Status: ${concern.status.name.toUpperCase()}'),
              const SizedBox(height: 8),
              Text('Description: ${concern.description}'),
              const SizedBox(height: 8),
              Text('Support Count: ${concern.supportCount}'),
              const SizedBox(height: 8),
              Text('Comments: ${concern.commentCount}'),
              if (concern.assignedOfficerName != null) ...[
                const SizedBox(height: 8),
                Text('Assigned Officer: ${concern.assignedOfficerName}'),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}
