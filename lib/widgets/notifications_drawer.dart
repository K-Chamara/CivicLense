import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/concern_notification_service.dart';

class NotificationsDrawer extends StatefulWidget {
  const NotificationsDrawer({super.key});

  @override
  State<NotificationsDrawer> createState() => _NotificationsDrawerState();
}

class _NotificationsDrawerState extends State<NotificationsDrawer>
    with SingleTickerProviderStateMixin {
  final ConcernNotificationService _notificationService = ConcernNotificationService();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  late AnimationController _controller;
  late Animation<Offset> _offsetAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 300));
    _offsetAnimation = Tween<Offset>(begin: const Offset(1.0, 0.0), end: Offset.zero)
        .animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = _auth.currentUser;
    return Material(
      color: Colors.black54,
      child: SafeArea(
        child: Stack(
          children: [
            GestureDetector(onTap: () => Navigator.pop(context)),
            SlideTransition(
              position: _offsetAnimation,
              child: Align(
                alignment: Alignment.centerRight,
                child: Container(
                  width: MediaQuery.of(context).size.width * 0.88,
                  height: double.infinity,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 12, offset: Offset(-4, 0))],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildHeader(context),
                      const Divider(height: 1),
                      Expanded(
                        child: user == null
                            ? _buildEmpty('Please sign in to view notifications')
                            : StreamBuilder<List<Map<String, dynamic>>>(
                                stream: _notificationService.getUserNotifications(user.uid),
                                builder: (context, snapshot) {
                                  if (snapshot.connectionState == ConnectionState.waiting) {
                                    return const Center(child: CircularProgressIndicator());
                                  }
                                  final notifications = snapshot.data ?? [];
                                  if (notifications.isEmpty) {
                                    return _buildEmpty('No notifications yet');
                                  }
                                  return ListView.separated(
                                    padding: const EdgeInsets.all(12),
                                    itemBuilder: (context, index) {
                                      final n = notifications[index];
                                      return _buildNotificationTile(n);
                                    },
                                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                                    itemCount: notifications.length,
                                  );
                                },
                              ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      color: Colors.blue,
      child: Row(
        children: [
          const Icon(Icons.notifications, color: Colors.white),
          const SizedBox(width: 8),
          const Expanded(
            child: Text('Notifications', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
          ),
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.close, color: Colors.white),
          ),
        ],
      ),
    );
  }

  Widget _buildEmpty(String text) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.notifications_off, color: Colors.grey[400], size: 48),
          const SizedBox(height: 8),
          Text(text, style: TextStyle(color: Colors.grey[600])),
        ],
      ),
    );
  }

  Widget _buildNotificationTile(Map<String, dynamic> n) {
    final String type = (n['type'] ?? '').toString();
    final String title = (n['title'] ?? '').toString();
    final String body = (n['body'] ?? '').toString();
    final bool isRead = (n['isRead'] ?? false) as bool;
    final Timestamp? ts = n['createdAt'] as Timestamp?;
    final String time = ts != null ? _formatTime(ts.toDate()) : '';

    IconData icon;
    Color color;
    switch (type) {
      case 'concern_support':
        icon = Icons.thumb_up_alt_outlined;
        color = Colors.green;
        break;
      case 'concern_comment':
        icon = Icons.mode_comment_outlined;
        color = Colors.blue;
        break;
      case 'concern_update':
        icon = Icons.verified_outlined;
        color = Colors.orange;
        break;
      case 'community_post':
        icon = Icons.groups_outlined;
        color = Colors.purple;
        break;
      default:
        icon = Icons.notifications_none;
        color = Colors.grey;
    }

    return Material(
      color: isRead ? Colors.white : Colors.blue.withOpacity(0.04),
      borderRadius: BorderRadius.circular(12),
      child: ListTile(
        leading: CircleAvatar(backgroundColor: color.withOpacity(0.15), child: Icon(icon, color: color)),
        title: Text(title.isNotEmpty ? title : _fallbackTitle(type), style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (body.isNotEmpty) Text(body),
            if (time.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(time, style: const TextStyle(fontSize: 12, color: Colors.grey)),
              ),
          ],
        ),
        onTap: () async {
          final id = (n['id'] ?? '') as String;
          if (id.isNotEmpty) {
            await _notificationService.markNotificationAsRead(id);
          }
        },
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Colors.grey[200]!)),
      ),
    );
  }

  String _formatTime(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }

  String _fallbackTitle(String type) {
    switch (type) {
      case 'concern_support':
        return 'Someone supported your concern';
      case 'concern_comment':
        return 'New comment on your concern';
      case 'concern_update':
        return 'Concern status updated';
      case 'community_post':
        return 'New post in your community';
      default:
        return 'Notification';
    }
  }
}


