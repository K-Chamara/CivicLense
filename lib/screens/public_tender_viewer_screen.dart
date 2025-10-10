import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'tender_detail_screen.dart';
import 'user_concern_tracking_screen.dart';
import '../services/auth_service.dart';
import '../models/user_role.dart';
import 'enhanced_dashboard_screen.dart';
import 'admin_dashboard_screen.dart';
import 'finance_officer_dashboard_screen.dart';
import 'procurement_officer_dashboard_screen.dart';
import 'anticorruption_officer_dashboard_screen.dart';
import 'public_user_dashboard_screen.dart';

class PublicTenderViewerScreen extends StatefulWidget {
  const PublicTenderViewerScreen({super.key});

  @override
  State<PublicTenderViewerScreen> createState() => _PublicTenderViewerScreenState();
}

class _PublicTenderViewerScreenState extends State<PublicTenderViewerScreen> {
  List<Map<String, dynamic>> _tenders = [];
  List<Map<String, dynamic>> _filteredTenders = [];
  bool _isLoading = true;
  String _selectedCategory = 'All';
  String _selectedStatus = 'All';
  String _searchQuery = '';

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
    'Closed',
    'Awarded',
    'Cancelled'
  ];

  @override
  void initState() {
    super.initState();
    _loadTenders();
  }

  Future<void> _loadTenders() async {
    try {
      setState(() {
        _isLoading = true;
      });

      final querySnapshot = await FirebaseFirestore.instance
          .collection('tenders')
          .orderBy('createdAt', descending: true)
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
            'location': data['location'] ?? '',
            'totalBids': data['totalBids'] ?? 0,
            'lowestBid': data['lowestBid'],
            'highestBid': data['highestBid'],
            'awardedTo': data['awardedTo'],
            'awardedAmount': data['awardedAmount'],
            'createdAt': data['createdAt'],
            'imageUrl': data['imageUrl'], // Include image URL
          };
        }).toList();
        
        _filteredTenders = _tenders;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading tenders: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _filterTenders() {
    setState(() {
      _filteredTenders = _tenders.where((tender) {
        final categoryMatch = _selectedCategory == 'All' || tender['category'] == _selectedCategory;
        final statusMatch = _selectedStatus == 'All' || tender['status'] == _selectedStatus;
        final searchMatch = _searchQuery.isEmpty || 
            tender['title'].toLowerCase().contains(_searchQuery.toLowerCase()) ||
            tender['description'].toLowerCase().contains(_searchQuery.toLowerCase());
        
        return categoryMatch && statusMatch && searchMatch;
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: const Text('Public Tenders'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadTenders,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: Column(
        children: [
          _buildFilters(),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredTenders.isEmpty
                    ? _buildEmptyState()
                    : _buildTenderList(),
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }

  Widget _buildFilters() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.white,
      child: Column(
        children: [
          // Search Bar
          TextField(
            decoration: InputDecoration(
              hintText: 'Search tenders...',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              filled: true,
              fillColor: Colors.grey[100],
            ),
            onChanged: (value) {
              setState(() {
                _searchQuery = value;
              });
              _filterTenders();
            },
          ),
          const SizedBox(height: 16),
          
          // Filter Row - Use single row with proper constraints
          Row(
            children: [
              Expanded(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(
                    minWidth: 0,
                    maxWidth: double.infinity,
                  ),
                  child: DropdownButtonFormField<String>(
                    value: _selectedCategory,
                    decoration: InputDecoration(
                      labelText: 'Category',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      isDense: true,
                      labelStyle: const TextStyle(fontSize: 11),
                    ),
                    style: const TextStyle(fontSize: 11),
                    items: _categories.map((category) {
                      return DropdownMenuItem<String>(
                        value: category,
                        child: Text(
                          category,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 11),
                        ),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedCategory = value!;
                      });
                      _filterTenders();
                    },
                  ),
                ),
              ),
              const SizedBox(width: 4),
              Expanded(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(
                    minWidth: 0,
                    maxWidth: double.infinity,
                  ),
                  child: DropdownButtonFormField<String>(
                    value: _selectedStatus,
                    decoration: InputDecoration(
                      labelText: 'Status',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      isDense: true,
                      labelStyle: const TextStyle(fontSize: 11),
                    ),
                    style: const TextStyle(fontSize: 11),
                    items: _statuses.map((status) {
                      return DropdownMenuItem<String>(
                        value: status,
                        child: Text(
                          status,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 11),
                        ),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedStatus = value!;
                      });
                      _filterTenders();
                    },
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search_off,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'No tenders found',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Try adjusting your filters or search terms',
            style: TextStyle(
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTenderList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _filteredTenders.length,
      itemBuilder: (context, index) {
        final tender = _filteredTenders[index];
        return _buildTenderCard(tender);
      },
    );
  }

  Widget _buildTenderCard(Map<String, dynamic> tender) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => TenderDetailScreen(tender: tender),
            ),
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Tender Image (if available) - Full width, no padding
            if (tender['imageUrl'] != null) ...[
              Container(
                width: double.infinity,
                height: 150,
                decoration: BoxDecoration(
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(12),
                    topRight: Radius.circular(12),
                  ),
                  image: DecorationImage(
                    image: NetworkImage(tender['imageUrl']),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ],
            
            // Content with padding
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header Row
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          tender['title'],
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      _buildStatusChip(tender['status']),
                    ],
                  ),
                  const SizedBox(height: 8),
                  
                  // Description
                  Text(
                    tender['description'],
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 14,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
              const SizedBox(height: 12),
              
              // Details Row
              Row(
                children: [
                  Expanded(
                    child: _buildDetailItem(
                      Icons.category,
                      tender['category'],
                      Colors.blue,
                    ),
                  ),
                  Expanded(
                    child: _buildDetailItem(
                      Icons.location_on,
                      tender['location'],
                      Colors.green,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              
              Row(
                children: [
                  Expanded(
                    child: _buildDetailItem(
                      Icons.attach_money,
                      _formatBudget(tender['budget']),
                      Colors.orange,
                    ),
                  ),
                  Expanded(
                    child: _buildDetailItem(
                      Icons.schedule,
                      _formatDeadline(tender['deadline']),
                      Colors.red,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              
              // Bidding Info
              if (tender['totalBids'] > 0) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.people,
                        color: Colors.blue[700],
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${tender['totalBids']} bid${tender['totalBids'] == 1 ? '' : 's'} received',
                        style: TextStyle(
                          color: Colors.blue[700],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const Spacer(),
                      if (tender['lowestBid'] != null)
                        Text(
                          'Lowest: ${_formatBudget(tender['lowestBid'])}',
                          style: TextStyle(
                            color: Colors.green[700],
                            fontSize: 12,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
              
              // Winning Bidder (if awarded)
              if (tender['status'] == 'awarded' && tender['awardedTo'] != null) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.green.withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.emoji_events,
                        color: Colors.green[700],
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Awarded to: ${tender['awardedTo']}',
                              style: TextStyle(
                                color: Colors.green[700],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            if (tender['awardedAmount'] != null)
                              Text(
                                'Amount: ${_formatBudget(tender['awardedAmount'])}',
                                style: TextStyle(
                                  color: Colors.green[600],
                                  fontSize: 12,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailItem(IconData icon, String text, Color color) {
    return Row(
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 4),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              color: color,
              fontSize: 12,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildStatusChip(String status) {
    Color color;
    String text;
    
    switch (status.toLowerCase()) {
      case 'active':
        color = Colors.green;
        text = 'Active';
        break;
      case 'closed':
        color = Colors.orange;
        text = 'Closed';
        break;
      case 'awarded':
        color = Colors.blue;
        text = 'Awarded';
        break;
      case 'cancelled':
        color = Colors.red;
        text = 'Cancelled';
        break;
      default:
        color = Colors.grey;
        text = status;
    }
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  String _formatBudget(dynamic amount) {
    if (amount == null) return 'N/A';
    final num = double.tryParse(amount.toString()) ?? 0.0;
    if (num >= 1000000) {
      return 'LKR ${(num / 1000000).toStringAsFixed(1)}M';
    } else if (num >= 1000) {
      return 'LKR ${(num / 1000).toStringAsFixed(1)}K';
    } else {
      return 'LKR ${num.toStringAsFixed(0)}';
    }
  }

  String _formatDeadline(String deadline) {
    if (deadline.isEmpty) return 'No deadline';
    try {
      final date = DateTime.parse(deadline);
      final now = DateTime.now();
      final difference = date.difference(now).inDays;
      
      if (difference < 0) {
        return 'Expired';
      } else if (difference == 0) {
        return 'Due today';
      } else if (difference == 1) {
        return 'Due tomorrow';
      } else {
        return '$difference days left';
      }
    } catch (e) {
      return 'Invalid date';
    }
  }

  Widget _buildBottomNavigationBar() {
    return BottomNavigationBar(
      type: BottomNavigationBarType.fixed,
      backgroundColor: Colors.white,
      selectedItemColor: Colors.blue,
      unselectedItemColor: Colors.grey,
      currentIndex: 2, // Tenders is selected (index 2)
      onTap: (index) {
        switch (index) {
          case 0:
            Navigator.pushNamed(context, '/common-home');
            break;
          case 1:
            Navigator.pushNamed(context, '/budget-viewer');
            break;
          case 2:
            // Already on tenders
            break;
          case 3:
            _navigateToDashboard();
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

  Future<void> _navigateToDashboard() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final authService = AuthService();
        final userRole = await authService.getUserRole(user.uid);
        final userData = await authService.getUserData(user.uid);
        
        // Check if user is pending (not approved yet)
        final isPending = userData?['status'] == 'pending';
        
        Widget dashboard;
        
        if (isPending) {
          // Show pending status screen
          dashboard = const EnhancedDashboardScreen();
        } else {
          // Navigate to role-specific dashboard
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
      print('Error navigating to dashboard: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error navigating to dashboard'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
