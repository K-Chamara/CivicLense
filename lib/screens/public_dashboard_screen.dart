import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class PublicDashboardScreen extends StatefulWidget {
  const PublicDashboardScreen({super.key});

  @override
  State<PublicDashboardScreen> createState() => _PublicDashboardScreenState();
}

class _PublicDashboardScreenState extends State<PublicDashboardScreen> {
  List<Map<String, dynamic>> _tenders = [];
  List<Map<String, dynamic>> _filteredTenders = [];
  bool _isLoading = true;
  String _selectedCategory = 'All';
  String _selectedStatus = 'All';

  final List<String> _categories = [
    'All',
    'Infrastructure',
    'IT Services',
    'Office Supplies',
    'Security Services',
    'Vehicle Maintenance',
    'Healthcare',
    'Education',
    'Transportation',
    'Utilities',
    'Other'
  ];

  final List<String> _statuses = [
    'All',
    'Active',
    'In Progress',
    'Completed',
    'Delayed'
  ];

  @override
  void initState() {
    super.initState();
    _loadTenders();
  }

  Future<void> _loadTenders() async {
    try {
      final querySnapshot = await FirebaseFirestore.instance
          .collection('tenders')
          .get();

      setState(() {
        _tenders = querySnapshot.docs.map((doc) {
          final data = doc.data();
          return {
            'id': doc.id,
            'title': data['title'] ?? '',
            'description': data['description'] ?? '',
            'budget': data['budget'] ?? 0.0,
            'deadline': data['deadline'] ?? '',
            'category': data['category'] ?? '',
            'status': data['status'] ?? 'active',
            'progress': data['progress'] ?? 0.0,
            'createdAt': data['createdAt'],
            'region': data['region'] ?? 'Central',
          };
        }).toList();
        
        // Sort by createdAt in descending order (newest first)
        _tenders.sort((a, b) {
          final aCreatedAt = a['createdAt'] as Timestamp?;
          final bCreatedAt = b['createdAt'] as Timestamp?;
          if (aCreatedAt == null && bCreatedAt == null) return 0;
          if (aCreatedAt == null) return 1;
          if (bCreatedAt == null) return -1;
          return bCreatedAt.compareTo(aCreatedAt);
        });
        
        _filteredTenders = List.from(_tenders);
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading tenders: $e')),
        );
      }
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _applyFilters() {
    setState(() {
      _filteredTenders = _tenders.where((tender) {
        // Category filter
        if (_selectedCategory != 'All' && tender['category'] != _selectedCategory) {
          return false;
        }

        // Status filter
        if (_selectedStatus != 'All') {
          final status = tender['status'];
          final progress = tender['progress'] as double;
          final deadline = DateTime.tryParse(tender['deadline'] ?? '');
          final now = DateTime.now();

          switch (_selectedStatus) {
            case 'Active':
              if (status != 'active') return false;
              break;
            case 'In Progress':
              if (progress <= 0 || progress >= 100) return false;
              break;
            case 'Completed':
              if (progress < 100) return false;
              break;
            case 'Delayed':
              if (deadline == null || deadline.isAfter(now) || progress >= 100) return false;
              break;
          }
        }

        return true;
      }).toList();
    });
  }

  String _formatBudget(double budget) {
    if (budget >= 10000000) {
      return '₹${(budget / 10000000).toStringAsFixed(1)} Crores';
    } else if (budget >= 100000) {
      return '₹${(budget / 100000).toStringAsFixed(1)} Lakhs';
    } else {
      return '₹${budget.toStringAsFixed(0)}';
    }
  }

  Color _getStatusColor(String status, double progress, String deadline) {
    if (progress >= 100) return Colors.green;
    
    final deadlineDate = DateTime.tryParse(deadline);
    if (deadlineDate != null && deadlineDate.isBefore(DateTime.now())) {
      return Colors.red;
    }
    
    if (progress > 0) return Colors.orange;
    return Colors.blue;
  }

  String _getStatusText(String status, double progress, String deadline) {
    if (progress >= 100) return 'Completed';
    
    final deadlineDate = DateTime.tryParse(deadline);
    if (deadlineDate != null && deadlineDate.isBefore(DateTime.now())) {
      return 'Delayed';
    }
    
    if (progress > 0) return 'In Progress';
    return 'Active';
  }

  Map<String, dynamic> _calculateAnalytics() {
    if (_tenders.isEmpty) return {};

    final totalBudget = _tenders.fold<double>(0, (sum, tender) => sum + (tender['budget'] as double));
    final completedCount = _tenders.where((t) => (t['progress'] as double) >= 100).length;
    final delayedCount = _tenders.where((t) {
      final deadline = DateTime.tryParse(t['deadline'] ?? '');
      final progress = t['progress'] as double;
      return deadline != null && deadline.isBefore(DateTime.now()) && progress < 100;
    }).length;
    final avgProgress = _tenders.fold<double>(0, (sum, tender) => sum + (tender['progress'] as double)) / _tenders.length;

    return {
      'totalTenders': _tenders.length,
      'totalBudget': totalBudget,
      'completedCount': completedCount,
      'delayedCount': delayedCount,
      'avgProgress': avgProgress,
    };
  }

  @override
  Widget build(BuildContext context) {
    final analytics = _calculateAnalytics();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Public Dashboard'),
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadTenders,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Analytics Cards
                  _buildAnalyticsCards(analytics),
                  const SizedBox(height: 24),

                  // AI Insights
                  _buildAIInsights(analytics),
                  const SizedBox(height: 24),

                  // Filters
                  _buildFilters(),
                  const SizedBox(height: 16),

                  // Tenders List
                  _buildTendersList(),
                ],
              ),
            ),
    );
  }

  Widget _buildAnalyticsCards(Map<String, dynamic> analytics) {
    if (analytics.isEmpty) return const SizedBox.shrink();

    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      childAspectRatio: 1.5,
      children: [
        _buildAnalyticsCard(
          'Total Tenders',
          analytics['totalTenders'].toString(),
          Icons.assignment,
          Colors.blue,
        ),
        _buildAnalyticsCard(
          'Total Budget',
          _formatBudget(analytics['totalBudget']),
          Icons.attach_money,
          Colors.green,
        ),
        _buildAnalyticsCard(
          'Completed',
          '${analytics['completedCount']} (${((analytics['completedCount'] / analytics['totalTenders']) * 100).toStringAsFixed(1)}%)',
          Icons.check_circle,
          Colors.green,
        ),
        _buildAnalyticsCard(
          'Delayed',
          '${analytics['delayedCount']} (${((analytics['delayedCount'] / analytics['totalTenders']) * 100).toStringAsFixed(1)}%)',
          Icons.warning,
          Colors.red,
        ),
      ],
    );
  }

  Widget _buildAnalyticsCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: const TextStyle(
              fontSize: 12,
              color: Colors.grey,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildAIInsights(Map<String, dynamic> analytics) {
    if (analytics.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.psychology, color: Colors.orange),
              const SizedBox(width: 8),
              const Text(
                'AI Insights',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildInsightItem(
            'Project Completion Rate',
            '${((analytics['completedCount'] / analytics['totalTenders']) * 100).toStringAsFixed(1)}% of projects are completed',
            analytics['completedCount'] / analytics['totalTenders'] > 0.7 ? Colors.green : Colors.orange,
          ),
          _buildInsightItem(
            'Delay Risk',
            '${analytics['delayedCount']} projects are currently delayed',
            analytics['delayedCount'] > 0 ? Colors.red : Colors.green,
          ),
          _buildInsightItem(
            'Average Progress',
            '${analytics['avgProgress'].toStringAsFixed(1)}% average completion across all projects',
            analytics['avgProgress'] > 50 ? Colors.green : Colors.orange,
          ),
          _buildInsightItem(
            'Budget Utilization',
            'Total allocated budget: ${_formatBudget(analytics['totalBudget'])}',
            Colors.blue,
          ),
        ],
      ),
    );
  }

  Widget _buildInsightItem(String title, String description, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 8,
            height: 8,
            margin: const EdgeInsets.only(top: 6),
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                Text(
                  description,
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

  Widget _buildFilters() {
    return Row(
      children: [
        Expanded(
          child: DropdownButtonFormField<String>(
            value: _selectedCategory,
            decoration: const InputDecoration(
              labelText: 'Category',
              border: OutlineInputBorder(),
              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
            items: _categories.map((category) {
              return DropdownMenuItem<String>(
                value: category,
                child: Text(category),
              );
            }).toList(),
            onChanged: (value) {
              setState(() {
                _selectedCategory = value!;
              });
              _applyFilters();
            },
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: DropdownButtonFormField<String>(
            value: _selectedStatus,
            decoration: const InputDecoration(
              labelText: 'Status',
              border: OutlineInputBorder(),
              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
            items: _statuses.map((status) {
              return DropdownMenuItem<String>(
                value: status,
                child: Text(status),
              );
            }).toList(),
            onChanged: (value) {
              setState(() {
                _selectedStatus = value!;
              });
              _applyFilters();
            },
          ),
        ),
      ],
    );
  }

  Widget _buildTendersList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'All Tenders (${_filteredTenders.length})',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            TextButton(
              onPressed: () {
                setState(() {
                  _selectedCategory = 'All';
                  _selectedStatus = 'All';
                });
                _applyFilters();
              },
              child: const Text('Clear Filters'),
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (_filteredTenders.isEmpty)
          const Center(
            child: Column(
              children: [
                Icon(Icons.search_off, size: 64, color: Colors.grey),
                SizedBox(height: 16),
                Text(
                  'No tenders found',
                  style: TextStyle(fontSize: 18, color: Colors.grey),
                ),
              ],
            ),
          )
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _filteredTenders.length,
            itemBuilder: (context, index) {
              final tender = _filteredTenders[index];
              final statusColor = _getStatusColor(
                tender['status'],
                tender['progress'],
                tender['deadline'],
              );
              final statusText = _getStatusText(
                tender['status'],
                tender['progress'],
                tender['deadline'],
              );

              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  contentPadding: const EdgeInsets.all(16),
                  title: Text(
                    tender['title'],
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 8),
                      Text(
                        tender['description'],
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: Colors.grey),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(Icons.category, size: 16, color: Colors.orange),
                          const SizedBox(width: 4),
                          Text(tender['category']),
                          const SizedBox(width: 16),
                          Icon(Icons.location_on, size: 16, color: Colors.blue),
                          const SizedBox(width: 4),
                          Text(tender['region']),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Icons.attach_money, size: 16, color: Colors.green),
                          const SizedBox(width: 4),
                          Text(_formatBudget(tender['budget'])),
                          const SizedBox(width: 16),
                          Icon(Icons.circle, size: 16, color: statusColor),
                          const SizedBox(width: 4),
                          Text(
                            statusText,
                            style: TextStyle(color: statusColor),
                          ),
                        ],
                      ),
                      if (tender['progress'] > 0) ...[
                        const SizedBox(height: 8),
                        LinearProgressIndicator(
                          value: tender['progress'] / 100,
                          backgroundColor: Colors.grey[300],
                          valueColor: const AlwaysStoppedAnimation<Color>(Colors.orange),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Progress: ${tender['progress'].toStringAsFixed(1)}%',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              );
            },
          ),
      ],
    );
  }
}
