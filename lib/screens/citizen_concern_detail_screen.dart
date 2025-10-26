import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/concern_models.dart';
import '../services/concern_service.dart';
import '../l10n/app_localizations.dart';
import 'package:intl/intl.dart';

/// Read-only concern detail screen for citizens/taxpayers
/// Citizens can ONLY view concern details, comments, and support
/// They CANNOT change status or access investigation features
class CitizenConcernDetailScreen extends StatefulWidget {
  final Concern concern;

  const CitizenConcernDetailScreen({
    super.key,
    required this.concern,
  });

  @override
  State<CitizenConcernDetailScreen> createState() => _CitizenConcernDetailScreenState();
}

class _CitizenConcernDetailScreenState extends State<CitizenConcernDetailScreen> {
  final TextEditingController _commentController = TextEditingController();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final ConcernService _concernService = ConcernService();
  bool _isSupporting = false;
  bool _isLoadingSupport = false;

  @override
  void initState() {
    super.initState();
    _checkIfSupporting();
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _checkIfSupporting() async {
    final user = _auth.currentUser;
    if (user != null) {
      final isSupporting = await _concernService.isUserSupporting(
        widget.concern.id,
      );
      if (mounted) {
        setState(() {
          _isSupporting = isSupporting;
        });
      }
    }
  }

  Future<void> _toggleSupport() async {
    final user = _auth.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please login to support concerns'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() {
      _isLoadingSupport = true;
    });

    try {
      await _concernService.toggleSupport(widget.concern.id);

      setState(() {
        _isSupporting = !_isSupporting;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_isSupporting ? '✅ Support added!' : 'Support removed'),
            backgroundColor: _isSupporting ? Colors.green : Colors.grey,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingSupport = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text(l10n.concernDetails),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Card with Title and Status
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.blue.shade400,
                    Colors.blue.shade600,
                  ],
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.concern.title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      _buildStatusChip(widget.concern.status),
                      const SizedBox(width: 12),
                      _buildPriorityChip(widget.concern.priority),
                    ],
                  ),
                ],
              ),
            ),

            // Concern Details
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Description Card
                  _buildCard(
                    title: l10n.description,
                    child: Text(
                      widget.concern.description,
                      style: const TextStyle(fontSize: 16, height: 1.5),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Info Cards Row
                  Row(
                    children: [
                      Expanded(
                        child: _buildInfoCard(
                          icon: Icons.category,
                          label: l10n.category,
                          value: widget.concern.category.name,
                          color: Colors.purple,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildInfoCard(
                          icon: Icons.location_on,
                          label: l10n.location,
                          value: widget.concern.location ?? 'Not specified',
                          color: Colors.orange,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Support Card
                  _buildCard(
                    title: l10n.support,
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.thumb_up, color: Colors.blue, size: 32),
                                const SizedBox(width: 12),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '${widget.concern.supportCount} ${l10n.supporters}',
                                      style: const TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    Text(
                                      l10n.showYourSupport,
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            ElevatedButton.icon(
                              onPressed: _isLoadingSupport ? null : _toggleSupport,
                              icon: Icon(
                                _isSupporting ? Icons.thumb_up : Icons.thumb_up_outlined,
                              ),
                              label: Text(_isSupporting ? l10n.supported : l10n.support),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: _isSupporting ? Colors.blue : Colors.blue.shade50,
                                foregroundColor: _isSupporting ? Colors.white : Colors.blue,
                                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Comments Section
                  _buildCard(
                    title: 'Comments',
                    child: StreamBuilder<QuerySnapshot>(
                      stream: FirebaseFirestore.instance
                          .collection('concern_comments')
                          .where('concernId', isEqualTo: widget.concern.id)
                          .orderBy('createdAt', descending: true)
                          .snapshots(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return const Center(child: CircularProgressIndicator());
                        }

                        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                          return Center(
                            child: Padding(
                              padding: const EdgeInsets.all(20),
                              child: Text(
                                l10n.noCommentsYet,
                                style: TextStyle(color: Colors.grey[600]),
                              ),
                            ),
                          );
                        }

                        return Column(
                          children: snapshot.data!.docs.map((doc) {
                            final data = doc.data() as Map<String, dynamic>;
                            return _buildCommentItem(data);
                          }).toList(),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Add Comment Section (Citizens can comment)
                  _buildCard(
                    title: l10n.addComment,
                    child: Column(
                      children: [
                        TextField(
                          controller: _commentController,
                          maxLines: 3,
                          decoration: InputDecoration(
                            hintText: l10n.writeYourComment,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            filled: true,
                            fillColor: Colors.grey[50],
                          ),
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: _postComment,
                            icon: const Icon(Icons.send),
                            label: Text(l10n.postComment),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Timeline/Updates Section
                  _buildCard(
                    title: l10n.timeline,
                    child: StreamBuilder<QuerySnapshot>(
                      stream: FirebaseFirestore.instance
                          .collection('concern_updates')
                          .where('concernId', isEqualTo: widget.concern.id)
                          .orderBy('createdAt', descending: true)
                          .snapshots(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return const Center(child: CircularProgressIndicator());
                        }

                        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                          return Center(
                            child: Padding(
                              padding: const EdgeInsets.all(20),
                              child: Text(
                                l10n.noUpdatesYet,
                                style: TextStyle(color: Colors.grey[600]),
                              ),
                            ),
                          );
                        }

                        return Column(
                          children: snapshot.data!.docs.map((doc) {
                            final data = doc.data() as Map<String, dynamic>;
                            return _buildTimelineItem(data);
                          }).toList(),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCard({required String title, required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }

  Widget _buildInfoCard({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildStatusChip(ConcernStatus status) {
    Color color;
    String text;

    switch (status) {
      case ConcernStatus.pending:
        color = Colors.orange;
        text = 'Pending';
        break;
      case ConcernStatus.underReview:
        color = Colors.blue;
        text = 'Under Review';
        break;
      case ConcernStatus.inProgress:
        color = Colors.purple;
        text = 'In Progress';
        break;
      case ConcernStatus.resolved:
        color = Colors.green;
        text = 'Resolved';
        break;
      case ConcernStatus.dismissed:
        color = Colors.red;
        text = 'Dismissed';
        break;
      case ConcernStatus.escalated:
        color = Colors.deepOrange;
        text = 'Escalated';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color, width: 1.5),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      ),
    );
  }

  Widget _buildPriorityChip(ConcernPriority priority) {
    Color color;
    String text;

    switch (priority) {
      case ConcernPriority.low:
        color = Colors.green;
        text = 'Low Priority';
        break;
      case ConcernPriority.medium:
        color = Colors.orange;
        text = 'Medium Priority';
        break;
      case ConcernPriority.high:
        color = Colors.red;
        text = 'High Priority';
        break;
      case ConcernPriority.critical:
        color = Colors.purple;
        text = 'Critical';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.3),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white, width: 1.5),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      ),
    );
  }

  Widget _buildCommentItem(Map<String, dynamic> comment) {
    final timestamp = comment['createdAt'] as Timestamp?;
    final date = timestamp?.toDate();
    final formattedDate = date != null
        ? DateFormat('MMM dd, yyyy • hh:mm a').format(date)
        : 'Unknown date';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 16,
                backgroundColor: Colors.blue,
                child: Text(
                  (comment['authorName'] as String? ?? 'U').isNotEmpty 
                      ? (comment['authorName'] as String)[0].toUpperCase()
                      : 'U',
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      (comment['authorName'] as String? ?? 'Unknown').isNotEmpty 
                          ? comment['authorName'] 
                          : 'Unknown',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    Text(
                      comment['userRole'] ?? (comment['isOfficerComment'] == true 
                          ? 'Anti-Corruption Officer' 
                          : 'Citizen'),
                      style: TextStyle(
                        fontSize: 11,
                        color: comment['isOfficerComment'] == true 
                            ? Colors.blue[600] 
                            : Colors.grey[600],
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                    Text(
                      formattedDate,
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            comment['comment'] ?? '',
            style: const TextStyle(fontSize: 14, height: 1.4),
          ),
        ],
      ),
    );
  }

  Widget _buildTimelineItem(Map<String, dynamic> data) {
    final action = data['action'] ?? '';
    final description = data['description'] ?? '';
    final createdAt = data['createdAt'] != null 
        ? (data['createdAt'] as Timestamp).toDate()
        : DateTime.now();
    final officerName = data['officerName'] ?? 'Unknown Officer';
    final userRole = data['userRole'] ?? 'Officer';
    
    // Determine icon and color based on action
    IconData icon;
    Color color;
    
    switch (action.toLowerCase()) {
      case 'underreview':
        icon = Icons.search;
        color = Colors.blue;
        break;
      case 'inprogress':
        icon = Icons.work;
        color = Colors.purple;
        break;
      case 'resolved':
        icon = Icons.check_circle;
        color = Colors.green;
        break;
      case 'dismissed':
        icon = Icons.cancel;
        color = Colors.grey;
        break;
      case 'assigned':
        icon = Icons.person_add;
        color = Colors.indigo;
        break;
      default:
        icon = Icons.update;
        color = Colors.orange;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _formatActionName(action),
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: color,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'By: $officerName ($userRole)',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                    fontStyle: FontStyle.italic,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  DateFormat('MMM dd, yyyy • HH:mm').format(createdAt),
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
                if (description.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey[200]!),
                    ),
                    child: Text(
                      description,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatActionName(String action) {
    switch (action.toLowerCase()) {
      case 'underreview':
        return 'Under Review';
      case 'inprogress':
        return 'In Progress';
      case 'resolved':
        return 'Resolved';
      case 'dismissed':
        return 'Dismissed';
      case 'assigned':
        return 'Assigned';
      case 'created':
        return 'Created';
      case 'status_update':
        return 'Status Updated';
      default:
        // Fallback: convert camelCase to Title Case
        return action.replaceAllMapped(
          RegExp(r'([A-Z])'), 
          (match) => ' ${match.group(1)}'
        ).trim().split(' ').map((word) => 
          word.isNotEmpty ? word[0].toUpperCase() + word.substring(1).toLowerCase() : ''
        ).join(' ');
    }
  }

  Future<void> _postComment() async {
    final user = _auth.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please login to comment'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final comment = _commentController.text.trim();
    if (comment.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a comment'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    try {
      // Get user details from Firestore
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      
      String authorName = 'Anonymous';
      String userRole = 'Citizen';
      
      if (userDoc.exists) {
        final userData = userDoc.data() as Map<String, dynamic>;
        authorName = userData['firstName'] != null && userData['lastName'] != null
            ? '${userData['firstName']} ${userData['lastName']}'
            : userData['firstName'] ?? userData['email'] ?? user.email ?? 'Anonymous';
        
        // Get user role from user document
        if (userData['role'] != null) {
          final roleData = userData['role'] as Map<String, dynamic>;
          userRole = roleData['name'] ?? 'Citizen';
        }
      } else {
        // Fallback to Firebase Auth data
        authorName = user.displayName ?? user.email ?? 'Anonymous';
      }

      await FirebaseFirestore.instance.collection('concern_comments').add({
        'concernId': widget.concern.id,
        'authorId': user.uid,
        'authorName': authorName,
        'comment': comment,
        'createdAt': FieldValue.serverTimestamp(),
        'isOfficerComment': false,
        'userRole': userRole,
      });

      _commentController.clear();

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
            content: Text('Error posting comment: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

}

