import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'project_details_screen.dart';
import '../services/budget_service.dart';
import '../services/project_service.dart';

class OngoingTendersScreen extends StatefulWidget {
  const OngoingTendersScreen({super.key});

  @override
  State<OngoingTendersScreen> createState() => _OngoingTendersScreenState();
}

class _OngoingTendersScreenState extends State<OngoingTendersScreen> {
  String _selectedCategory = 'All';
  String _budgetRange = 'All';
  List<Map<String, dynamic>> _projects = [];
  List<Map<String, dynamic>> _filteredProjects = [];
  bool _isLoading = true;
  final BudgetService _budgetService = BudgetService();
  Set<String> _trackedProjects = {}; // Track which projects are being tracked by the user

  List<String> _categories = ['All'];

  final List<String> _budgetRanges = [
    'All',
    'Under \$10K',
    '\$10K - \$50K',
    '\$50K - \$100K',
    '\$100K - \$500K',
    'Above \$500K'
  ];

  @override
  void initState() {
    super.initState();
    _loadProjects();
    _loadCategories();
    _loadTrackedProjects();
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> _loadTrackedProjects() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final trackedProjectsSnapshot = await FirebaseFirestore.instance
          .collection('tracked_projects')
          .where('userId', isEqualTo: user.uid)
          .get();

      setState(() {
        _trackedProjects = trackedProjectsSnapshot.docs
            .map((doc) => doc.data()['projectId'] as String)
            .toSet();
      });

      print('📌 Loaded ${_trackedProjects.length} tracked projects');
    } catch (e) {
      print('Error loading tracked projects: $e');
    }
  }

  Future<void> _loadProjects() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      print('📊 Loading projects from new projects table...');
      
      // Use ProjectService to get all projects
      final projects = await ProjectService.getAllProjects();
      
      print('Found ${projects.length} projects in database');
      
      final List<Map<String, dynamic>> allProjects = [];

      for (final project in projects) {
        print('Project ${project['id']}: ${project['projectName']} - Status: ${project['projectStatus']}');
        
        // Safely access nested data with proper type checking
        Map<String, dynamic>? winningBidder;
        Map<String, dynamic>? sourceTender;
        
        try {
          final winningBidderData = project['winningBidder'];
          if (winningBidderData is Map<String, dynamic>) {
            winningBidder = winningBidderData;
          } else if (winningBidderData is String) {
            // Handle case where winningBidder might be stored as a string
            winningBidder = {'name': winningBidderData};
          }
        } catch (e) {
          print('⚠️ Error accessing winningBidder: $e');
          winningBidder = null;
        }
        
        try {
          final sourceTenderData = project['sourceTender'];
          if (sourceTenderData is Map<String, dynamic>) {
            sourceTender = sourceTenderData;
          }
        } catch (e) {
          print('⚠️ Error accessing sourceTender: $e');
          sourceTender = null;
        }
        
        allProjects.add({
          'id': project['id'],
          'title': project['projectName'] ?? '',
          'projectName': project['projectName'] ?? '',
          'projectLocation': project['projectLocation'] ?? '',
          'description': project['projectDescription'] ?? 'Project converted from tender',
          'budget': _safeDouble(project['projectBudget']),
          'originalBudget': _safeDouble(project['originalTenderBudget']),
          'winningBidder': winningBidder?['name'] ?? '',
          'hasWinningBidder': project['hasWinningBidder'] ?? false,
          'tenderId': sourceTender?['tenderId'] ?? '',
          'deadline': project['expectedCompletionDate'] ?? '',
          'handoverDate': project['handoverDate'] ?? '',
          'category': project['projectCategory'] ?? '',
          'region': project['projectLocation'] ?? 'Central',
          'status': project['projectStatus'] ?? 'ongoing',
          'totalBids': 0,
          'createdAt': project['createdAt'],
          'type': 'project',
          // Additional project-specific fields
          'projectId': project['projectId'],
          'projectPhase': project['projectPhase'],
          'completionPercentage': _safeInt(project['completionPercentage']),
          'priority': project['priority'],
          'riskLevel': project['riskLevel'],
        });
      }
      
      print('📊 Total projects loaded: ${allProjects.length}');

      setState(() {
        _projects = allProjects;
        
        // Sort by creation date (newest first)
        _projects.sort((a, b) {
          final aDate = a['createdAt'] as Timestamp?;
          final bDate = b['createdAt'] as Timestamp?;
          if (aDate == null && bDate == null) return 0;
          if (aDate == null) return 1;
          if (bDate == null) return -1;
          return bDate.compareTo(aDate);
        });
        
        _applyFilters();
        _isLoading = false;
      });
    } catch (e) {
      print('❌ Error loading projects: $e');
      print('❌ Error type: ${e.runtimeType}');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading projects: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _loadCategories() async {
    try {
      // Get all categories from budget service (same as Budget Overview)
      final categories = await _budgetService.getBudgetCategories();
      setState(() {
        _categories = ['All', ...categories.map((cat) => cat.name).toList()];
      });
    } catch (e) {
      print('Error loading categories: $e');
      // Keep default categories if loading fails
      setState(() {
        _categories = ['All'];
      });
    }
  }

  Future<void> _createTestProject() async {
    try {
      print('🧪 Creating test project...');
      
      // Show loading indicator
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Creating test project...'),
            duration: Duration(seconds: 2),
          ),
        );
      }
      
      // Create test project
      final projectId = await ProjectService.createTestProject();
      
      print('✅ Test project created with ID: $projectId');
      
      // Reload projects to show the new test project
      await _loadProjects();
      await _loadTrackedProjects();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Test project created successfully!'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      print('❌ Error creating test project: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Error creating test project: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  // Helper methods for safe type conversion
  double _safeDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }

  int _safeInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

  // Check if a project should show NEW indicator
  // Shows NEW only for projects with null status (newly created from tenders)
  bool _shouldShowNewIndicator(Map<String, dynamic> project) {
    try {
      final status = project['status'];
      
      // Show NEW only if status is null (newly created from tender, not yet set)
      if (status == null) {
        return true;
      }
      
      // Don't show NEW for any project with a set status (ongoing, done, delayed)
      return false;
    } catch (e) {
      print('Error checking if project should show NEW indicator: $e');
      return false;
    }
  }

  void _applyFilters() {
    setState(() {
      _filteredProjects = _projects.where((project) {
        // Category filter
        final matchesCategory = _selectedCategory == 'All' || project['category'] == _selectedCategory;

        // Budget range filter
        bool matchesBudget = true;
        if (_budgetRange != 'All') {
          final budget = project['budget'] as double;
          switch (_budgetRange) {
            case 'Under \$10K':
              matchesBudget = budget < 10000;
              break;
            case '\$10K - \$50K':
              matchesBudget = budget >= 10000 && budget < 50000;
              break;
            case '\$50K - \$100K':
              matchesBudget = budget >= 50000 && budget < 100000;
              break;
            case '\$100K - \$500K':
              matchesBudget = budget >= 100000 && budget < 500000;
              break;
            case 'Above \$500K':
              matchesBudget = budget >= 500000;
              break;
          }
        }

        return matchesCategory && matchesBudget;
      }).toList();
    });
  }

  String _formatBudget(double budget) {
    if (budget >= 1000000) {
      return '${(budget / 1000000).toStringAsFixed(1)}M';
    } else if (budget >= 1000) {
      return '${(budget / 1000).toStringAsFixed(1)}K';
    } else {
      return budget.toStringAsFixed(0);
    }
  }

  String _getDaysRemaining(String deadline) {
    try {
      final deadlineDate = DateTime.parse(deadline);
      final now = DateTime.now();
      final difference = deadlineDate.difference(now).inDays;
      
      if (difference < 0) {
        return 'Expired';
      } else if (difference == 0) {
        return 'Today';
      } else if (difference == 1) {
        return 'Tomorrow';
      } else {
        return '$difference days left';
      }
    } catch (e) {
      return 'Invalid date';
    }
  }

  Color _getStatusColor(String deadline) {
    try {
      final deadlineDate = DateTime.parse(deadline);
      final now = DateTime.now();
      final difference = deadlineDate.difference(now).inDays;
      
      if (difference < 0) {
        return Colors.red;
      } else if (difference <= 3) {
        return Colors.orange;
      } else if (difference <= 7) {
        return Colors.yellow[700]!;
      } else {
        return Colors.green;
      }
    } catch (e) {
      return Colors.grey;
    }
  }

  Widget _buildSearchAndFilterSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.white,
      child: Column(
        children: [
          // Category Filter Chips
          Container(
            height: 40,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _categories.length,
              itemBuilder: (context, index) {
                final category = _categories[index];
                final isSelected = category == _selectedCategory;
                
                return Container(
                  margin: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(category),
                    selected: isSelected,
                    onSelected: (selected) {
                      setState(() {
                        _selectedCategory = category;
                      });
                      _applyFilters();
                    },
                    selectedColor: Colors.blue.withOpacity(0.2),
                    checkmarkColor: Colors.blue,
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.blue : Colors.grey[700],
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                );
              },
            ),
          ),
          
          const SizedBox(height: 8),
          
          // Budget Range Filter Chips
          Container(
            height: 40,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _budgetRanges.length,
              itemBuilder: (context, index) {
                final range = _budgetRanges[index];
                final isSelected = range == _budgetRange;
                
                return Container(
                  margin: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(range),
                    selected: isSelected,
                    onSelected: (selected) {
                      setState(() {
                        _budgetRange = range;
                      });
                      _applyFilters();
                    },
                    selectedColor: Colors.orange.withOpacity(0.2),
                    checkmarkColor: Colors.orange,
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.orange : Colors.grey[700],
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Active Projects'),
        backgroundColor: Colors.lightBlue,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () async {
              await _loadProjects();
              await _loadTrackedProjects();
            },
            tooltip: 'Refresh',
          ),
          IconButton(
            icon: const Icon(Icons.bug_report),
            onPressed: _createTestProject,
            tooltip: 'Create Test Project',
          ),
        ],
      ),
      body: Column(
        children: [
          // Search and Filter Section
          _buildSearchAndFilterSection(),
          
          // Results count and clear filters
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${_filteredProjects.length} projects found',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (_selectedCategory != 'All' || _budgetRange != 'All')
                  TextButton(
                    onPressed: () {
                      setState(() {
                        _selectedCategory = 'All';
                        _budgetRange = 'All';
                      });
                      _applyFilters();
                    },
                    child: const Text('Clear Filters'),
                  ),
              ],
            ),
          ),
          
          // Projects List
          Expanded(
            child: _filteredProjects.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.work_outline,
                          size: 64,
                          color: Colors.grey,
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'No projects found',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.grey,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Projects will appear here when tenders are closed with winning bidders.',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          onPressed: _createTestProject,
                          icon: const Icon(Icons.bug_report),
                          label: const Text('Create Test Project'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _filteredProjects.length,
                    itemBuilder: (context, index) {
                      final project = _filteredProjects[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 16),
                        child: Stack(
                          children: [
                            ListTile(
                          contentPadding: const EdgeInsets.all(16),
                          title: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  project['title'],
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                              ),
                              // Tracking tag
                              if (_trackedProjects.contains(project['id']))
                                Container(
                                  margin: const EdgeInsets.only(left: 8),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.green.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: Colors.green,
                                      width: 1,
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.notifications_active,
                                        size: 12,
                                        color: Colors.green,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        'TRACKING',
                                        style: TextStyle(
                                          color: Colors.green,
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                            ],
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 8),
                              if (project['type'] == 'project' && project['hasWinningBidder'] == true) ...[
                                Text(
                                  'Winning Bidder: ${project['winningBidder']}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                    color: Colors.blue,
                                  ),
                                ),
                                const SizedBox(height: 4),
                              ],
                              Text('Location: ${project['projectLocation']}'),
                              Text('Description: ${project['description']}'),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Text(
                                    project['hasWinningBidder'] == true 
                                        ? 'Winning Bid: ' 
                                        : project['type'] == 'project' 
                                            ? 'Project Budget: ' 
                                            : 'Tender Budget: ',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.green,
                                    ),
                                  ),
                                  Text(
                                    '\$${_formatBudget(project['budget'])}',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.green,
                                    ),
                                  ),
                                  if (project['type'] == 'tender') ...[
                                    const SizedBox(width: 16),
                                    Icon(
                                      Icons.people,
                                      color: Colors.blue,
                                      size: 16,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      '${project['totalBids']} bids',
                                      style: const TextStyle(
                                        color: Colors.blue,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                              const SizedBox(height: 8),
                              // Use Wrap instead of Row to prevent overflow
                              Wrap(
                                spacing: 8,
                                runSpacing: 4,
                                children: [
                                  if (project['handoverDate'] != null && project['handoverDate'].toString().isNotEmpty) ...[
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.green.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                          color: Colors.green,
                                        ),
                                      ),
                                      child: Text(
                                        'Deadline: ${project['handoverDate']}',
                                        style: const TextStyle(
                                          color: Colors.green,
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ],
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: project['type'] == 'project' 
                                          ? Colors.purple.withOpacity(0.1)
                                          : Colors.lightBlue.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: project['type'] == 'project' 
                                            ? Colors.purple 
                                            : Colors.lightBlue,
                                      ),
                                    ),
                                    child: Text(
                                      project['type'] == 'project' ? 'PROJECT' : project['category'],
                                      style: TextStyle(
                                        color: project['type'] == 'project' 
                                            ? Colors.purple 
                                            : Colors.lightBlue,
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  // Status indicator - only show if status is not null
                                  if (project['status'] != null)
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: _getStatusColorForCard(project['status']).withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                          color: _getStatusColorForCard(project['status']),
                                        ),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            _getStatusIconForCard(project['status']),
                                            size: 12,
                                            color: _getStatusColorForCard(project['status']),
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            _getStatusTextForCard(project['status']),
                                            style: TextStyle(
                                              color: _getStatusColorForCard(project['status']),
                                              fontSize: 12,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                ],
                              ),
                            ],
                          ),
                          trailing: PopupMenuButton<String>(
                            icon: const Icon(Icons.more_vert, size: 20),
                            onSelected: (value) {
                              if (value == 'status') {
                                _showStatusPopup(project);
                              } else if (value == 'details') {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => ProjectDetailsScreen(
                                      project: project,
                                    ),
                                  ),
                                );
                              } else if (value == 'edit') {
                                _showEditProjectPopup(project);
                              }
                            },
                            itemBuilder: (BuildContext context) => [
                              // Only show edit options for procurement officers
                              if (_isProcurementOfficer())
                                const PopupMenuItem<String>(
                                  value: 'status',
                                  child: Row(
                                    children: [
                                      Icon(Icons.flag, size: 16, color: Colors.blue),
                                      SizedBox(width: 8),
                                      Text('Project Status'),
                                    ],
                                  ),
                                ),
                              if (_isProcurementOfficer())
                                const PopupMenuItem<String>(
                                  value: 'edit',
                                  child: Row(
                                    children: [
                                      Icon(Icons.edit, size: 16, color: Colors.orange),
                                      SizedBox(width: 8),
                                      Text('Edit Project'),
                                    ],
                                  ),
                                ),
                              const PopupMenuItem<String>(
                                value: 'details',
                                child: Row(
                                  children: [
                                    Icon(Icons.info, size: 16, color: Colors.grey),
                                    SizedBox(width: 8),
                                    Text('View Details'),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => ProjectDetailsScreen(
                                  project: project,
                                ),
                              ),
                            );
                          },
                        ),
                            // NEW indicator in top-right corner
                            if (_shouldShowNewIndicator(project))
                              Positioned(
                                top: 8,
                                right: 8,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.red,
                                    borderRadius: BorderRadius.circular(8),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.2),
                                        blurRadius: 2,
                                        offset: const Offset(0, 1),
                                      ),
                                    ],
                                  ),
                                  child: const Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.new_releases,
                                        size: 10,
                                        color: Colors.white,
                                      ),
                                      SizedBox(width: 2),
                                      Text(
                                        'NEW',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  void _showStatusPopup(Map<String, dynamic> project) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Project Status - ${project['title']}'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Select the current status of this project:',
                style: TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 20),
              
              // Ongoing Option
              ListTile(
                leading: const Icon(Icons.play_circle, color: Colors.blue),
                title: const Text('Ongoing'),
                subtitle: const Text('Project is currently in progress'),
                onTap: () {
                  _updateProjectStatus(project, 'ongoing');
                  Navigator.of(context).pop();
                },
              ),
              
              // Done Option
              ListTile(
                leading: const Icon(Icons.check_circle, color: Colors.green),
                title: const Text('Done'),
                subtitle: const Text('Project has been completed'),
                onTap: () {
                  _updateProjectStatus(project, 'done');
                  Navigator.of(context).pop();
                },
              ),
              
              // Delayed Option
              ListTile(
                leading: const Icon(Icons.schedule, color: Colors.orange),
                title: const Text('Delayed'),
                subtitle: const Text('Project is behind schedule'),
                onTap: () {
                  _updateProjectStatus(project, 'delayed');
                  Navigator.of(context).pop();
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
          ],
        );
      },
    );
  }

  void _showEditProjectPopup(Map<String, dynamic> project) {
    // SECURITY CHECK: Only procurement officers can edit projects
    if (!_isProcurementOfficer()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Only procurement officers can edit projects'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return EditProjectDialog(
          project: project,
          onProjectUpdated: () async {
            await _loadProjects(); // Reload projects after edit
            await _loadTrackedProjects();
          },
        );
      },
    );
  }

  bool _isProcurementOfficer() {
    // TODO: Implement proper role checking
    // For now, return false to prevent all users from editing projects
    // Only procurement officers should be able to edit projects
    return false; // Citizens can only view and track projects
  }

  Future<void> _updateProjectStatus(Map<String, dynamic> project, String status) async {
    // SECURITY CHECK: Only procurement officers can update project status
    if (!_isProcurementOfficer()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Only procurement officers can update project status'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    try {
      bool updateSuccessful = false;
      String? errorMessage;

      // Only update in projects collection to avoid affecting tenders
      if (project['type'] == 'project') {
        try {
          await FirebaseFirestore.instance
              .collection('projects')
              .doc(project['id'])
              .update({
            'projectStatus': status,
            'status': status, // Also update the status field for consistency
            'statusUpdatedAt': FieldValue.serverTimestamp(),
            'statusUpdatedBy': FirebaseAuth.instance.currentUser?.uid,
          });
          updateSuccessful = true;
          print('✅ Project status updated in projects collection');
        } catch (e) {
          print('❌ Failed to update project status: $e');
          errorMessage = 'Failed to update project status: $e';
        }
      } else {
        // For tenders, only update if status is not 'done' to avoid affecting tender status
        if (status != 'done') {
          try {
            await FirebaseFirestore.instance
                .collection('tenders')
                .doc(project['id'])
                .update({
              'status': status,
              'statusUpdatedAt': FieldValue.serverTimestamp(),
              'statusUpdatedBy': FirebaseAuth.instance.currentUser?.uid,
            });
            updateSuccessful = true;
            print('✅ Tender status updated in tenders collection');
          } catch (e) {
            print('❌ Failed to update tender status: $e');
            errorMessage = 'Failed to update tender status: $e';
          }
        } else {
          // For tenders marked as 'done', create a project entry instead
          try {
            await FirebaseFirestore.instance
                .collection('projects')
                .add({
              'tenderId': project['id'],
              'tenderTitle': project['title'],
              'projectName': project['title'],
              'location': project['projectLocation'] ?? '',
              'description': project['description'] ?? '',
              'budget': project['budget'] ?? 0.0,
              'category': project['category'] ?? '',
              'status': 'done',
              'createdBy': FirebaseAuth.instance.currentUser?.uid,
              'createdAt': FieldValue.serverTimestamp(),
              'statusUpdatedAt': FieldValue.serverTimestamp(),
              'statusUpdatedBy': FirebaseAuth.instance.currentUser?.uid,
            });
            updateSuccessful = true;
            print('✅ Created project entry for completed tender');
          } catch (e) {
            print('❌ Failed to create project entry: $e');
            errorMessage = 'Failed to create project entry: $e';
          }
        }
      }

      if (updateSuccessful) {
        // Show success message
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Project status updated to ${status.toUpperCase()}'),
              backgroundColor: _getStatusColorForUpdate(status),
              duration: const Duration(seconds: 2),
            ),
          );
        }

        // Reload projects to reflect the change
        await _loadProjects();
        await _loadTrackedProjects();
      } else {
        // Show error message
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error updating project status: ${errorMessage ?? "Unknown error"}'),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 3),
            ),
          );
        }
      }
    } catch (e) {
      print('❌ Unexpected error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating project status: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  Color _getStatusColorForUpdate(String status) {
    switch (status.toLowerCase()) {
      case 'ongoing':
        return Colors.blue;
      case 'done':
        return Colors.green;
      case 'delayed':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  Color _getStatusColorForCard(String status) {
    switch (status?.toLowerCase() ?? 'ongoing') {
      case 'ongoing':
        return Colors.blue;
      case 'done':
        return Colors.green;
      case 'delayed':
        return Colors.orange;
      default:
        return Colors.blue;
    }
  }

  IconData _getStatusIconForCard(String status) {
    switch (status?.toLowerCase() ?? 'ongoing') {
      case 'ongoing':
        return Icons.play_circle;
      case 'done':
        return Icons.check_circle;
      case 'delayed':
        return Icons.schedule;
      default:
        return Icons.play_circle;
    }
  }

  String _getStatusTextForCard(String status) {
    switch (status?.toLowerCase() ?? 'ongoing') {
      case 'ongoing':
        return 'ONGOING';
      case 'done':
        return 'DONE';
      case 'delayed':
        return 'DELAYED';
      default:
        return 'ONGOING';
    }
  }

  String _mapTenderStatusToProjectStatus(String tenderStatus) {
    switch (tenderStatus.toLowerCase()) {
      case 'active':
      case 'open':
        return 'ongoing';
      case 'closed':
      case 'awarded':
        return 'ongoing'; // These are ongoing projects
      case 'cancelled':
        return 'delayed'; // Treat cancelled as delayed
      default:
        return 'ongoing';
    }
  }

  Future<String?> _findDocumentCollection(String documentId) async {
    try {
      // Check if document exists in projects collection
      final projectDoc = await FirebaseFirestore.instance
          .collection('projects')
          .doc(documentId)
          .get();
      
      if (projectDoc.exists) {
        return 'projects';
      }
    } catch (e) {
      // Document doesn't exist in projects collection
    }

    try {
      // Check if document exists in tenders collection
      final tenderDoc = await FirebaseFirestore.instance
          .collection('tenders')
          .doc(documentId)
          .get();
      
      if (tenderDoc.exists) {
        return 'tenders';
      }
    } catch (e) {
      // Document doesn't exist in tenders collection
    }

    return null; // Document not found in either collection
  }
}

class EditProjectDialog extends StatefulWidget {
  final Map<String, dynamic> project;
  final VoidCallback onProjectUpdated;

  const EditProjectDialog({
    super.key,
    required this.project,
    required this.onProjectUpdated,
  });

  @override
  State<EditProjectDialog> createState() => _EditProjectDialogState();
}

class _EditProjectDialogState extends State<EditProjectDialog> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _locationController = TextEditingController();
  final _budgetController = TextEditingController();
  final _categoryController = TextEditingController();
  final _handoverDateController = TextEditingController();
  
  bool _isLoading = false;
  String _selectedStatus = '';

  @override
  void initState() {
    super.initState();
    _titleController.text = widget.project['title'] ?? '';
    _locationController.text = widget.project['projectLocation'] ?? '';
    _budgetController.text = (widget.project['budget'] ?? 0.0).toString();
    _categoryController.text = widget.project['category'] ?? '';
    _handoverDateController.text = widget.project['handoverDate'] ?? '';
    _selectedStatus = widget.project['status'] ?? 'ongoing';
  }

  @override
  void dispose() {
    _titleController.dispose();
    _locationController.dispose();
    _budgetController.dispose();
    _categoryController.dispose();
    _handoverDateController.dispose();
    super.dispose();
  }

  bool _isProcurementOfficer() {
    // TODO: Implement proper role checking
    // For now, return false to prevent all users from editing projects
    // Only procurement officers should be able to edit projects
    return false; // Citizens can only view and track projects
  }

  Future<void> _updateProject() async {
    // SECURITY CHECK: Only procurement officers can update projects
    if (!_isProcurementOfficer()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Only procurement officers can update projects'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      // Update in projects collection if it's a project
      if (widget.project['type'] == 'project') {
        await FirebaseFirestore.instance
            .collection('projects')
            .doc(widget.project['id'])
            .update({
          'projectName': _titleController.text.trim(),
          'projectLocation': _locationController.text.trim(),
          'projectBudget': double.tryParse(_budgetController.text) ?? 0.0,
          'projectCategory': _categoryController.text.trim(),
          'handoverDate': _handoverDateController.text.trim(),
          'projectStatus': _selectedStatus,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      } else {
        // Update in tenders collection if it's a tender
        await FirebaseFirestore.instance
            .collection('tenders')
            .doc(widget.project['id'])
            .update({
          'title': _titleController.text.trim(),
          'location': _locationController.text.trim(),
          'budget': double.tryParse(_budgetController.text) ?? 0.0,
          'category': _categoryController.text.trim(),
          'handoverDate': _handoverDateController.text.trim(),
          'status': _selectedStatus,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Project updated successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        widget.onProjectUpdated();
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating project: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Edit Project'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Title
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Project Title',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter a project title';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Location
              TextFormField(
                controller: _locationController,
                decoration: const InputDecoration(
                  labelText: 'Location',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter a location';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Budget
              TextFormField(
                controller: _budgetController,
                decoration: const InputDecoration(
                  labelText: 'Budget',
                  border: OutlineInputBorder(),
                  prefixText: '\$',
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter a budget';
                  }
                  if (double.tryParse(value) == null) {
                    return 'Please enter a valid number';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Category
              TextFormField(
                controller: _categoryController,
                decoration: const InputDecoration(
                  labelText: 'Category',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter a category';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Handover Date
              TextFormField(
                controller: _handoverDateController,
                decoration: const InputDecoration(
                  labelText: 'Handover Date (YYYY-MM-DD)',
                  border: OutlineInputBorder(),
                  hintText: 'e.g., 2024-12-31',
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter a handover date';
                  }
                  // Basic date format validation
                  final dateRegex = RegExp(r'^\d{4}-\d{2}-\d{2}$');
                  if (!dateRegex.hasMatch(value.trim())) {
                    return 'Please enter date in YYYY-MM-DD format';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Status
              DropdownButtonFormField<String>(
                value: _selectedStatus.isNotEmpty && ['ongoing', 'done', 'delayed'].contains(_selectedStatus) ? _selectedStatus : null,
                decoration: const InputDecoration(
                  labelText: 'Status',
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem<String>(
                    value: 'ongoing',
                    child: Text('Ongoing'),
                  ),
                  DropdownMenuItem<String>(
                    value: 'done',
                    child: Text('Done'),
                  ),
                  DropdownMenuItem<String>(
                    value: 'delayed',
                    child: Text('Delayed'),
                  ),
                ],
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _selectedStatus = value;
                    });
                  }
                },
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _updateProject,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue,
            foregroundColor: Colors.white,
          ),
          child: _isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                )
              : const Text('Update'),
        ),
      ],
    );
  }
}
