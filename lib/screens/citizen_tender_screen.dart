import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'raise_concern_screen.dart';
import 'common_home_screen.dart';
import 'budget_viewer_screen.dart';
import '../services/auth_service.dart';
import '../models/user_role.dart';
import 'enhanced_dashboard_screen.dart';
import 'admin_dashboard_screen.dart';
import 'finance_officer_dashboard_screen.dart';
import 'procurement_officer_dashboard_screen.dart';
import 'anticorruption_officer_dashboard_screen.dart';
import 'public_user_dashboard_screen.dart';

class CitizenTenderScreen extends StatefulWidget {
  const CitizenTenderScreen({super.key});

  @override
  State<CitizenTenderScreen> createState() => _CitizenTenderScreenState();
}

class _CitizenTenderScreenState extends State<CitizenTenderScreen> {
  String _selectedCategory = 'All';
  String _selectedStatus = 'All';
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();
  int _currentIndex = 2; // Tenders tab is selected
  final AuthService _authService = AuthService();

  final List<String> _categories = [
    'All', 'Infrastructure', 'IT Services', 'Office Supplies', 'Security Services',
    'Vehicle Maintenance', 'Healthcare', 'Education', 'Transportation', 'Utilities',
    'Construction', 'Consulting', 'Other'
  ];

  final List<String> _statuses = ['All', 'active', 'closed', 'awarded', 'cancelled'];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          'Government Tenders',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: Colors.blue,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.report_problem),
            onPressed: _raiseTenderConcern,
            tooltip: 'Raise Tender Concern',
          ),
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: _showInfoDialog,
            tooltip: 'About Tenders',
          ),
        ],
      ),
      body: Column(
        children: [
          // Search and Filter Section
          Container(
            color: Colors.white,
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Search Bar
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search tenders...',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _searchController.clear();
                              setState(() {
                                _searchQuery = '';
                              });
                            },
                          )
                        : null,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: Colors.grey[100],
                  ),
                  onChanged: (value) {
                    setState(() {
                      _searchQuery = value.toLowerCase();
                    });
                  },
                ),
                const SizedBox(height: 16),
                
                // Filter Row
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _selectedCategory,
                        decoration: InputDecoration(
                          labelText: 'Category',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        ),
                        items: _categories.map((category) {
                          return DropdownMenuItem(
                            value: category,
                            child: Text(category),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            _selectedCategory = value!;
                          });
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _selectedStatus,
                        decoration: InputDecoration(
                          labelText: 'Status',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        ),
                        items: _statuses.map((status) {
                          return DropdownMenuItem(
                            value: status,
                            child: Text(status.toUpperCase()),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            _selectedStatus = value!;
                          });
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          // Tenders List
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _getTendersStream(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.error_outline,
                          size: 64,
                          color: Colors.red[300],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Error loading tenders',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.red[700],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Exception: ${snapshot.error}',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.red[600],
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () {
                            setState(() {});
                          },
                          child: const Text('Retry'),
                        ),
                      ],
                ),
                  );
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.assignment_outlined,
                          size: 64,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No tenders found',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Try adjusting your filters or check back later',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[500],
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  );
                }

                final tenders = snapshot.data!.docs
                    .map((doc) => {
                          'id': doc.id,
                          ...doc.data() as Map<String, dynamic>,
                        })
                    .toList();

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: tenders.length,
                  itemBuilder: (context, index) {
                    final tender = tenders[index];
                    return _buildTenderCard(tender);
                  },
                );
              },
            ),
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }

  Widget _buildBottomNavigationBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) {
            setState(() {
              _currentIndex = index;
            });
            
            // Navigate based on selection
            switch (index) {
              case 0:
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => const CommonHomeScreen()),
                );
                break;
              case 1:
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => const BudgetViewerScreen()),
                );
                break;
              case 2:
                // Already on tenders page
                break;
              case 3:
                // Navigate to role-specific dashboard
                _navigateToDashboard();
                break;
            }
          },
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.white,
          selectedItemColor: Colors.blue,
          unselectedItemColor: Colors.grey.shade600,
          selectedFontSize: 12,
          unselectedFontSize: 12,
          elevation: 0,
          items: [
            BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined, size: 22),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.account_balance_outlined, size: 22),
              label: 'Budget',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.shopping_cart, size: 24),
              label: 'Tenders',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.dashboard_outlined, size: 22),
              label: 'Dashboard',
            ),
          ],
        ),
      ),
    );
  }

  /// Navigate to role-specific dashboard
  Future<void> _navigateToDashboard() async {
    try {
      final user = _authService.currentUser;
      if (user != null) {
        final userRole = await _authService.getUserRole(user.uid);
        final userData = await _authService.getUserData(user.uid);
        
        // Check if user is pending (not approved yet)
        final isPending = userData?['status'] == 'pending';
        
        Widget dashboard;
        
        if (isPending) {
          // Pending users get limited access with EnhancedDashboardScreen
          dashboard = const EnhancedDashboardScreen();
        } else {
          // Approved users get full access based on their role
          switch (userRole?.id) {
            case 'admin':
              dashboard = const AdminDashboardScreen();
              break;
            case 'finance_officer':
              dashboard = const FinanceOfficerDashboardScreen();
              break;
            case 'procurement_officer':
              dashboard = const ProcurementOfficerDashboardScreen();
              break;
            case 'anticorruption_officer':
              dashboard = const AntiCorruptionOfficerDashboardScreen();
              break;
            default:
              // Public users (citizen, journalist, community_leader, researcher, ngo)
              dashboard = const PublicUserDashboardScreen();
              break;
          }
        }
        
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => dashboard),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error navigating to dashboard: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Stream<QuerySnapshot> _getTendersStream() {
    Query query = FirebaseFirestore.instance.collection('tenders');

    // Apply status filter
    if (_selectedStatus != 'All') {
      query = query.where('status', isEqualTo: _selectedStatus);
    }

    // Apply category filter
    if (_selectedCategory != 'All') {
      query = query.where('category', isEqualTo: _selectedCategory);
    }

    // Order by creation date (newest first)
    query = query.orderBy('createdAt', descending: true);

    return query.snapshots();
  }

  Widget _buildTenderCard(Map<String, dynamic> tender) {
    final title = tender['title'] ?? 'Untitled Tender';
    final description = tender['description'] ?? 'No description available';
    final budget = tender['budget'] ?? 0.0;
    final deadline = tender['deadline'] ?? '';
    final status = tender['status'] ?? 'unknown';
    final category = tender['category'] ?? 'Other';
    final location = tender['location'] ?? 'Not specified';

    // Filter by search query
    if (_searchQuery.isNotEmpty) {
      final searchText = '${title.toLowerCase()} ${description.toLowerCase()} ${category.toLowerCase()}';
      if (!searchText.contains(_searchQuery)) {
        return const SizedBox.shrink();
      }
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _showTenderDetails(tender),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Row
              Row(
                children: [
                  Expanded(
                    child: Text(
                      title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                  _buildStatusChip(status),
                ],
              ),
              const SizedBox(height: 8),
              
              // Category and Location
              Row(
                children: [
                  Icon(Icons.category, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(
                    category,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Icon(Icons.location_on, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      location,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              
              // Description
              Text(
                description,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[700],
                  height: 1.4,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 12),
              
              // Budget and Deadline
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Budget',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[500],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Text(
                          _formatCurrency(budget),
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.green,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          'Deadline',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[500],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Text(
                          _formatDate(deadline),
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: _isDeadlineNear(deadline) ? Colors.red : Colors.grey[700],
                          ),
                        ),
                      ],
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

  Widget _buildStatusChip(String status) {
    Color color;
    switch (status.toLowerCase()) {
      case 'active':
        color = Colors.green;
        break;
      case 'closed':
        color = Colors.orange;
        break;
      case 'awarded':
        color = Colors.blue;
        break;
      case 'cancelled':
        color = Colors.red;
        break;
      default:
        color = Colors.grey;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
    );
  }

  String _formatCurrency(double amount) {
    if (amount >= 1000000) {
      return '\$${(amount / 1000000).toStringAsFixed(1)}M';
    } else if (amount >= 1000) {
      return '\$${(amount / 1000).toStringAsFixed(1)}K';
    } else {
      return '\$${amount.toStringAsFixed(0)}';
    }
  }

  String _formatDate(String dateString) {
    if (dateString.isEmpty) return 'Not specified';
    
    try {
      final date = DateTime.parse(dateString);
      return DateFormat('MMM dd, yyyy').format(date);
    } catch (e) {
      return dateString;
    }
  }

  bool _isDeadlineNear(String deadline) {
    if (deadline.isEmpty) return false;
    
    try {
      final deadlineDate = DateTime.parse(deadline);
      final now = DateTime.now();
      final difference = deadlineDate.difference(now).inDays;
      return difference <= 7 && difference >= 0; // Within 7 days
    } catch (e) {
      return false;
    }
  }

  void _showTenderDetails(Map<String, dynamic> tender) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(tender['title'] ?? 'Tender Details'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDetailRow('Description', tender['description'] ?? 'No description'),
              _buildDetailRow('Category', tender['category'] ?? 'Not specified'),
              _buildDetailRow('Location', tender['location'] ?? 'Not specified'),
              _buildDetailRow('Budget', _formatCurrency(tender['budget'] ?? 0.0)),
              _buildDetailRow('Deadline', _formatDate(tender['deadline'] ?? '')),
              _buildDetailRow('Status', (tender['status'] ?? 'unknown').toUpperCase()),
              if (tender['awardedTo'] != null)
                _buildDetailRow('Awarded To', tender['awardedTo']),
              if (tender['awardedAmount'] != null)
                _buildDetailRow('Awarded Amount', _formatCurrency(tender['awardedAmount'])),
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

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(color: Colors.black54),
            ),
          ),
        ],
      ),
    );
  }

  void _raiseTenderConcern() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const RaiseConcernScreen(
          preSelectedCategory: 'tender',
        ),
      ),
    );
  }

  void _showInfoDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('About Government Tenders'),
        content: const Text(
          'Government tenders are procurement opportunities where the government invites bids from qualified suppliers and contractors. Citizens can view these tenders to understand how public funds are being used for various projects and services.\n\n'
          'You can filter tenders by category and status, and search for specific tenders using keywords.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Got it'),
          ),
        ],
      ),
    );
  }
}
