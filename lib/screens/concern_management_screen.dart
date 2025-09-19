import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/concern_models.dart';
import '../services/concern_service.dart';
import 'concern_detail_screen.dart';

class ConcernManagementScreen extends StatefulWidget {
  const ConcernManagementScreen({super.key});

  @override
  State<ConcernManagementScreen> createState() => _ConcernManagementScreenState();
}

class _ConcernManagementScreenState extends State<ConcernManagementScreen>
    with TickerProviderStateMixin {
  final _concernService = ConcernService();
  late TabController _tabController;
  
  ConcernFilter _currentFilter = ConcernFilter();
  String _searchQuery = '';
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Concern Management'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: _showSearchDialog,
          ),
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: _showFilterDialog,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(text: 'All', icon: Icon(Icons.list)),
            Tab(text: 'Most Supported', icon: Icon(Icons.trending_up)),
            Tab(text: 'Pending', icon: Icon(Icons.pending)),
            Tab(text: 'In Progress', icon: Icon(Icons.work)),
            Tab(text: 'Resolved', icon: Icon(Icons.check_circle)),
          ],
        ),
      ),
      body: Column(
        children: [
          // Statistics Cards
          _buildStatsSection(),
          
          // Concerns List
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildConcernsList(ConcernFilter()),
                _buildMostSupportedConcernsList(),
                _buildConcernsList(ConcernFilter(status: ConcernStatus.pending)),
                _buildConcernsList(ConcernFilter(status: ConcernStatus.inProgress)),
                _buildConcernsList(ConcernFilter(status: ConcernStatus.resolved)),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showQuickActionsDialog(),
        backgroundColor: Colors.blue,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildStatsSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.grey.shade50,
      child: StreamBuilder<ConcernStats>(
        stream: _getConcernStats(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData) {
            return const Center(child: Text('No statistics available'));
          }

          final stats = snapshot.data!;
          return Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  'Total',
                  stats.totalConcerns.toString(),
                  Colors.blue,
                  Icons.assignment,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildStatCard(
                  'Pending',
                  stats.pendingConcerns.toString(),
                  Colors.orange,
                  Icons.pending,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildStatCard(
                  'Critical',
                  stats.criticalConcerns.toString(),
                  Colors.red,
                  Icons.priority_high,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildStatCard(
                  'Resolved',
                  stats.resolvedConcerns.toString(),
                  Colors.green,
                  Icons.check_circle,
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildStatCard(String title, String value, Color color, IconData icon) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
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
              title,
              style: const TextStyle(
                fontSize: 12,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConcernsList(ConcernFilter filter) {
    return StreamBuilder<List<Concern>>(
      stream: _concernService.getConcerns(filter: filter),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error, size: 48, color: Colors.red),
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
                SizedBox(height: 8),
                Text(
                  'All concerns have been addressed',
                  style: TextStyle(color: Colors.grey),
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

  Widget _buildMostSupportedConcernsList() {
    return StreamBuilder<List<Concern>>(
      stream: _concernService.getPublicConcernsBySupport(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error, size: 48, color: Colors.red),
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
                Icon(Icons.trending_up, size: 64, color: Colors.grey),
                SizedBox(height: 16),
                Text(
                  'No supported concerns yet',
                  style: TextStyle(fontSize: 18, color: Colors.grey),
                ),
                SizedBox(height: 8),
                Text(
                  'Concerns with community support will appear here',
                  style: TextStyle(color: Colors.grey),
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
      child: InkWell(
        onTap: () => _openConcernDetail(concern),
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  _buildPriorityChip(concern.priority),
                  const SizedBox(width: 8),
                  _buildStatusChip(concern.status),
                  const Spacer(),
                  _buildCategoryChip(concern.category),
                ],
              ),
              const SizedBox(height: 12),

              // Title
              Text(
                concern.title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),

              // Description
              Text(
                concern.description,
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.grey,
                ),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 12),

              // Footer
              Row(
                children: [
                  Icon(Icons.person, size: 16, color: Colors.grey.shade600),
                  const SizedBox(width: 4),
                  Text(
                    concern.isAnonymous ? 'Anonymous' : concern.authorName,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Icon(Icons.access_time, size: 16, color: Colors.grey.shade600),
                  const SizedBox(width: 4),
                  Text(
                    _formatDate(concern.createdAt),
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const Spacer(),
                  // Support count
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: concern.supportCount > 0 ? Colors.green.shade50 : Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: concern.supportCount > 0 ? Colors.green : Colors.grey,
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.thumb_up,
                          size: 14,
                          color: concern.supportCount > 0 ? Colors.green : Colors.grey,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${concern.supportCount}',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: concern.supportCount > 0 ? Colors.green : Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  if (concern.assignedOfficerName != null) ...[
                    Icon(Icons.assignment_ind, size: 16, color: Colors.blue),
                    const SizedBox(width: 4),
                    Text(
                      concern.assignedOfficerName!,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.blue,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ],
              ),
              if (concern.tags.isNotEmpty) ...[
                const SizedBox(height: 8),
                Wrap(
                  spacing: 4,
                  runSpacing: 4,
                  children: concern.tags.take(3).map((tag) => Chip(
                    label: Text(
                      tag,
                      style: const TextStyle(fontSize: 10),
                    ),
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    visualDensity: VisualDensity.compact,
                  )).toList(),
                ),
              ],
            ],
          ),
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

  Stream<ConcernStats> _getConcernStats() {
    return Stream.periodic(const Duration(seconds: 30))
        .asyncMap((_) => _concernService.getConcernStats());
  }

  void _openConcernDetail(Concern concern) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ConcernDetailScreen(concern: concern),
      ),
    );
  }

  void _showSearchDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Search Concerns'),
        content: TextField(
          decoration: const InputDecoration(
            hintText: 'Search by title, description, or author',
            border: OutlineInputBorder(),
          ),
          onChanged: (value) {
            setState(() {
              _searchQuery = value;
            });
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // Implement search functionality
            },
            child: const Text('Search'),
          ),
        ],
      ),
    );
  }

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Filter Concerns'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Category filter
              DropdownButtonFormField<ConcernCategory?>(
                value: _currentFilter.category,
                decoration: const InputDecoration(
                  labelText: 'Category',
                  border: OutlineInputBorder(),
                ),
                items: [
                  const DropdownMenuItem<ConcernCategory?>(
                    value: null,
                    child: Text('All Categories'),
                  ),
                  ...ConcernCategory.values.map((category) => DropdownMenuItem(
                    value: category,
                    child: Text(_getCategoryDisplayName(category)),
                  )),
                ],
                onChanged: (value) {
                  setState(() {
                    _currentFilter = ConcernFilter(
                      category: value,
                      type: _currentFilter.type,
                      priority: _currentFilter.priority,
                      status: _currentFilter.status,
                    );
                  });
                },
              ),
              const SizedBox(height: 16),

              // Priority filter
              DropdownButtonFormField<ConcernPriority?>(
                value: _currentFilter.priority,
                decoration: const InputDecoration(
                  labelText: 'Priority',
                  border: OutlineInputBorder(),
                ),
                items: [
                  const DropdownMenuItem<ConcernPriority?>(
                    value: null,
                    child: Text('All Priorities'),
                  ),
                  ...ConcernPriority.values.map((priority) => DropdownMenuItem(
                    value: priority,
                    child: Text(priority.name.toUpperCase()),
                  )),
                ],
                onChanged: (value) {
                  setState(() {
                    _currentFilter = ConcernFilter(
                      category: _currentFilter.category,
                      type: _currentFilter.type,
                      priority: value,
                      status: _currentFilter.status,
                    );
                  });
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              setState(() {
                _currentFilter = ConcernFilter();
              });
              Navigator.pop(context);
            },
            child: const Text('Clear'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Apply'),
          ),
        ],
      ),
    );
  }

  void _showQuickActionsDialog() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Quick Actions',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.assignment_ind),
              title: const Text('Assign Concerns'),
              onTap: () {
                Navigator.pop(context);
                // Implement bulk assignment
              },
            ),
            ListTile(
              leading: const Icon(Icons.priority_high),
              title: const Text('Update Priorities'),
              onTap: () {
                Navigator.pop(context);
                // Implement bulk priority update
              },
            ),
            ListTile(
              leading: const Icon(Icons.analytics),
              title: const Text('View Analytics'),
              onTap: () {
                Navigator.pop(context);
                // Implement analytics view
              },
            ),
          ],
        ),
      ),
    );
  }
}
