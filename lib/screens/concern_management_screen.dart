import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/concern_models.dart';
import '../services/concern_management_service.dart';
import '../services/notification_service.dart';
import 'concern_detail_screen.dart';
import 'public_tender_viewer_screen.dart';
import '../l10n/app_localizations.dart';

class ConcernManagementScreen extends StatefulWidget {
  const ConcernManagementScreen({super.key});

  @override
  State<ConcernManagementScreen> createState() => _ConcernManagementScreenState();
}

class _ConcernManagementScreenState extends State<ConcernManagementScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  String? _currentUserId;
  String? _currentUserName;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
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
        _currentUserName = user.displayName ?? 'Officer';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.concernManagement),
        backgroundColor: Colors.purple,
        foregroundColor: Colors.white,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: [
            Tab(text: AppLocalizations.of(context)!.all, icon: const Icon(Icons.list)),
            Tab(text: AppLocalizations.of(context)!.pending, icon: const Icon(Icons.pending)),
            Tab(text: AppLocalizations.of(context)!.underReview, icon: const Icon(Icons.search)),
            Tab(text: AppLocalizations.of(context)!.priority, icon: const Icon(Icons.priority_high)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildConcernsList(ConcernManagementService.getConcernsForOfficer()),
          _buildConcernsList(ConcernManagementService.getConcernsByStatus(ConcernStatus.pending)),
          _buildConcernsList(ConcernManagementService.getConcernsByStatus(ConcernStatus.underReview)),
          _buildConcernsList(ConcernManagementService.getPriorityConcerns()),
        ],
      ),
      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }

  Widget _buildConcernsList(Stream<List<Concern>> concernsStream) {
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
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.inbox, size: 64, color: Colors.grey),
                SizedBox(height: 16),
                Text(
                  'No concerns found',
                  style: TextStyle(fontSize: 18, color: Colors.grey),
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
                    Icons.person,
                    concern.authorName,
                    Colors.blue,
                  ),
                  const SizedBox(width: 8),
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
                  if (concern.supportCount > 100)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.red),
                      ),
                      child: const Text(
                        'HIGH PRIORITY',
                        style: TextStyle(
                          color: Colors.red,
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
        text = AppLocalizations.of(context)!.pending;
        icon = Icons.pending;
        break;
      case ConcernStatus.underReview:
        color = Colors.blue;
        text = AppLocalizations.of(context)!.underReview;
        icon = Icons.search;
        break;
      case ConcernStatus.inProgress:
        color = Colors.purple;
        text = AppLocalizations.of(context)!.inProgress;
        icon = Icons.work;
        break;
      case ConcernStatus.resolved:
        color = Colors.green;
        text = AppLocalizations.of(context)!.resolved;
        icon = Icons.check_circle;
        break;
      case ConcernStatus.dismissed:
        color = Colors.grey;
        text = AppLocalizations.of(context)!.dismissed;
        icon = Icons.cancel;
        break;
      case ConcernStatus.escalated:
        color = Colors.red;
        text = AppLocalizations.of(context)!.escalated;
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
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ConcernDetailScreen(
          concern: concern,
          officerId: _currentUserId!,
          officerName: _currentUserName!,
        ),
      ),
    );
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
      items: [
        BottomNavigationBarItem(
          icon: const Icon(Icons.home),
          label: AppLocalizations.of(context)!.home,
        ),
        BottomNavigationBarItem(
          icon: const Icon(Icons.account_balance),
          label: AppLocalizations.of(context)!.budget,
        ),
        BottomNavigationBarItem(
          icon: const Icon(Icons.shopping_cart),
          label: AppLocalizations.of(context)!.tenders,
        ),
        BottomNavigationBarItem(
          icon: const Icon(Icons.dashboard),
          label: AppLocalizations.of(context)!.dashboard,
        ),
      ],
    );
  }
}