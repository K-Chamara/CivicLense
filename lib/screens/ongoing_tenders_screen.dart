import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'project_details_screen.dart';

class OngoingTendersScreen extends StatefulWidget {
  const OngoingTendersScreen({super.key});

  @override
  State<OngoingTendersScreen> createState() => _OngoingTendersScreenState();
}

class _OngoingTendersScreenState extends State<OngoingTendersScreen> {
  String _selectedCategory = 'All';
  String _selectedRegion = 'All';
  String _budgetRange = 'All';
  List<Map<String, dynamic>> _projects = [];
  List<Map<String, dynamic>> _filteredProjects = [];

  final List<String> _categories = [
    'All', 'Infrastructure', 'IT Services', 'Office Supplies', 'Security Services',
    'Vehicle Maintenance', 'Healthcare', 'Education', 'Transportation', 'Utilities',
    'Construction', 'Consulting', 'Other'
  ];

  final List<String> _regions = [
    'All', 'Central', 'North', 'South', 'East', 'West', 'Northeast', 'Northwest', 'Southeast', 'Southwest'
  ];

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
  }

  Future<void> _loadProjects() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      // Load projects from projects collection (these are the converted projects)
      final projectsSnapshot = await FirebaseFirestore.instance
          .collection('projects')
          .where('createdBy', isEqualTo: user.uid)
          .get();

      // Load non-active tenders that haven't been converted to projects yet
      final tendersSnapshot = await FirebaseFirestore.instance
          .collection('tenders')
          .where('status', whereIn: ['closed', 'awarded', 'cancelled'])
          .get();

      final List<Map<String, dynamic>> allProjects = [];
      final Set<String> projectTenderIds = <String>{};

             // First, add projects and track their tender IDs
       for (final doc in projectsSnapshot.docs) {
         final data = doc.data();
         final tenderId = data['tenderId'] as String?;
         if (tenderId != null) {
           projectTenderIds.add(tenderId);
         }
         
                   // Get winning bidder information and tender description for this project
          String winningBidder = '';
          double winningBidAmount = 0.0;
          String tenderDescription = '';
          
          try {
            // Get tender description
            final tenderDoc = await FirebaseFirestore.instance
                .collection('tenders')
                .doc(tenderId)
                .get();
            
            if (tenderDoc.exists) {
              final tenderData = tenderDoc.data()!;
              tenderDescription = tenderData['description'] ?? '';
            }
            
            // Get winning bidder
            final bidsSnapshot = await FirebaseFirestore.instance
                .collection('bids')
                .where('tenderId', isEqualTo: tenderId)
                .where('status', isEqualTo: 'awarded')
                .limit(1)
                .get();
            
            if (bidsSnapshot.docs.isNotEmpty) {
              final bidData = bidsSnapshot.docs.first.data();
              winningBidder = bidData['bidderName'] ?? '';
              winningBidAmount = (bidData['bidAmount'] ?? 0.0).toDouble();
            }
          } catch (e) {
            print('Error loading winning bidder: $e');
          }
         
         allProjects.add({
           'id': doc.id,
           'title': data['tenderTitle'] ?? '',
           'projectName': data['projectName'] ?? '',
           'projectLocation': data['location'] ?? '',
           'description': tenderDescription.isNotEmpty ? tenderDescription : (data['description'] ?? 'Project converted from tender'),
           'budget': winningBidAmount > 0 ? winningBidAmount : (data['budget'] ?? 0.0),
           'winningBidder': winningBidder,
           'tenderId': tenderId,
           'deadline': '',
           'category': data['category'] ?? '',
           'region': data['location'] ?? 'Central',
           'status': data['status'] ?? 'active',
           'totalBids': 0,
           'createdAt': data['createdAt'],
           'type': 'project',
         });
       }

      // Then add tenders that haven't been converted to projects yet
      for (final doc in tendersSnapshot.docs) {
        final data = doc.data();
        final tenderId = doc.id;
        
        // Skip if this tender has already been converted to a project
        if (projectTenderIds.contains(tenderId)) {
          continue;
        }
        
        allProjects.add({
          'id': doc.id,
          'title': data['title'] ?? '',
          'projectName': data['projectName'] ?? '',
          'projectLocation': data['location'] ?? '',
          'description': data['description'] ?? '',
          'budget': data['budget'] ?? 0.0,
          'deadline': data['deadline'] ?? '',
          'category': data['category'] ?? '',
          'region': data['location'] ?? 'Central',
          'status': data['status'] ?? 'active',
          'totalBids': data['totalBids'] ?? 0,
          'createdAt': data['createdAt'],
          'type': 'tender',
        });
      }

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
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading projects: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _applyFilters() {
    setState(() {
      _filteredProjects = _projects.where((project) {
        // Category filter
        final matchesCategory = _selectedCategory == 'All' || project['category'] == _selectedCategory;

        // Region filter
        final matchesRegion = _selectedRegion == 'All' || project['region'] == _selectedRegion;

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

        return matchesCategory && matchesRegion && matchesBudget;
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
            body: Column(
        children: [
          // Search and Filters
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.grey[100],
            child: Column(
              children: [
                // Filter Dropdowns
                Column(
                  children: [
                    DropdownButtonFormField<String>(
                      value: _selectedCategory,
                      decoration: const InputDecoration(
                        labelText: 'Category',
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                      items: _categories.map((category) {
                        return DropdownMenuItem(
                          value: category,
                          child: Text(
                            category,
                            overflow: TextOverflow.ellipsis,
                          ),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedCategory = value!;
                        });
                        _applyFilters();
                      },
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      value: _selectedRegion,
                      decoration: const InputDecoration(
                        labelText: 'Region',
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                      items: _regions.map((region) {
                        return DropdownMenuItem(
                          value: region,
                          child: Text(region),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedRegion = value!;
                        });
                        _applyFilters();
                      },
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      value: _budgetRange,
                      decoration: const InputDecoration(
                        labelText: 'Budget Range',
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                      items: _budgetRanges.map((range) {
                        return DropdownMenuItem(
                          value: range,
                          child: Text(range),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _budgetRange = value!;
                        });
                        _applyFilters();
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
          
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
                if (_selectedCategory != 'All' || _selectedRegion != 'All' || _budgetRange != 'All')
                  TextButton(
                    onPressed: () {
                      setState(() {
                        _selectedCategory = 'All';
                        _selectedRegion = 'All';
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
                ? const Center(
                    child: Text(
                      'No projects found',
                      style: TextStyle(fontSize: 18, color: Colors.grey),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _filteredProjects.length,
                    itemBuilder: (context, index) {
                      final project = _filteredProjects[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 16),
                        child: ListTile(
                          contentPadding: const EdgeInsets.all(16),
                          title: Text(
                            project['title'],
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 8),
                                                             Text(project['type'] == 'project' 
                                   ? 'Winning Bidder: ${project['winningBidder']}' 
                                   : 'Project: ${project['projectName']}'),
                              Text('Location: ${project['projectLocation']}'),
                              Text('Description: ${project['description']}'),
                              const SizedBox(height: 8),
                                                             Row(
                                 children: [
                                   Text(
                                     'Budget: ',
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
                              Row(
                                children: [
                                  if (project['type'] == 'tender' && project['deadline'].isNotEmpty) ...[
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: _getStatusColor(project['deadline']).withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                          color: _getStatusColor(project['deadline']),
                                        ),
                                      ),
                                      child: Text(
                                        _getDaysRemaining(project['deadline']),
                                        style: TextStyle(
                                          color: _getStatusColor(project['deadline']),
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
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
                                ],
                              ),
                            ],
                          ),
                                                     trailing: const Icon(Icons.arrow_forward_ios, size: 16),
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
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
