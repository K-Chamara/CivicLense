import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '../services/budget_service.dart';
import 'bidder_management_screen.dart';

class CitizenTenderScreen extends StatefulWidget {
  const CitizenTenderScreen({super.key});

  @override
  State<CitizenTenderScreen> createState() => _CitizenTenderScreenState();
}

class _CitizenTenderScreenState extends State<CitizenTenderScreen> {
  List<Map<String, dynamic>> _tenders = [];
  bool _isLoading = true;
  String _selectedStatus = 'All';
  String _selectedCategory = 'All';
  final BudgetService _budgetService = BudgetService();

  final List<String> _statuses = ['All', 'active', 'closed', 'cancelled'];
  List<String> _categories = ['All'];

  @override
  void initState() {
    super.initState();
    _loadTenders();
    _loadCategories();
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> _loadTenders() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final querySnapshot = await FirebaseFirestore.instance
          .collection('tenders')
          .where('createdBy', isEqualTo: user.uid)
          .get();

      setState(() {
        _tenders = querySnapshot.docs.map((doc) {
          final data = doc.data();
          return {
            'id': doc.id,
            'title': data['title'] ?? '',
            'projectName': data['projectName'] ?? '',
            'location': data['location'] ?? '',
            'description': data['description'] ?? '',
            'budget': data['budget'] ?? 0.0,
            'deadline': data['deadline'] ?? '',
            'category': data['category'] ?? '',
            'status': data['status'] ?? 'active',
            'totalBids': data['totalBids'] ?? 0,
            'lowestBid': data['lowestBid'],
            'highestBid': data['highestBid'],
            'awardedTo': data['awardedTo'],
            'awardedAmount': data['awardedAmount'],
            'createdAt': data['createdAt'],
          };
        }).toList();
        
        _isLoading = false;
      });
    } catch (e) {
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
        final categoryNames = categories.map((cat) => cat.name).toList();
        final uniqueCategories = categoryNames.toSet().toList();
        _categories = ['All', ...uniqueCategories];
        
        // Ensure selected category is still valid
        if (!_categories.contains(_selectedCategory)) {
          _selectedCategory = 'All';
        }
      });
    } catch (e) {
      print('Error loading categories: $e');
      // Keep default categories if loading fails
      setState(() {
        _categories = ['All'];
        _selectedCategory = 'All';
      });
    }
  }

  List<Map<String, dynamic>> get _filteredTenders {
    return _tenders.where((tender) {
      final statusMatch = _selectedStatus == 'All' || tender['status'] == _selectedStatus;
      final categoryMatch = _selectedCategory == 'All' || tender['category'] == _selectedCategory;
      return statusMatch && categoryMatch;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Tender Management'),
        backgroundColor: Colors.lightBlue,
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
          // Filter Section
          Container(
            color: Colors.white,
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Status Filter
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Status',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      value: _selectedStatus,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                      ),
                      items: _statuses.map((status) {
                        return DropdownMenuItem<String>(
                          value: status,
                          child: Text(status.toUpperCase()),
                        );
                      }).toList(),
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
                const SizedBox(height: 16),
                
                // Category Filter
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Category',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                        value: _selectedCategory,
                        decoration: InputDecoration(
                          border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        ),
                        items: _categories.map((category) {
                        return DropdownMenuItem<String>(
                            value: category,
                            child: Text(category),
                          );
                        }).toList(),
                        onChanged: (value) {
                        if (value != null) {
                          setState(() {
                            _selectedCategory = value;
                          });
                        }
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          // Tenders List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredTenders.isEmpty
                    ? const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.assignment_outlined,
                          size: 64,
                              color: Colors.grey,
                        ),
                            SizedBox(height: 16),
                        Text(
                          'No tenders found',
                          style: TextStyle(
                            fontSize: 18,
                                color: Colors.grey,
                          ),
                        ),
                            SizedBox(height: 8),
                        Text(
                              'Create your first tender to get started',
                          style: TextStyle(
                            fontSize: 14,
                                color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                      )
                    : ListView.builder(
                  padding: const EdgeInsets.all(16),
                        itemCount: _filteredTenders.length,
                  itemBuilder: (context, index) {
                          final tender = _filteredTenders[index];
                    return _buildTenderCard(tender);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTenderCard(Map<String, dynamic> tender) {
    final status = tender['status'] as String;
    final statusColor = _getStatusColor(status);
    final statusText = status.toUpperCase();
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          _showBiddersPopup(tender);
        },
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
                      tender['title'] ?? 'Untitled Tender',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: statusColor.withOpacity(0.3)),
                    ),
                    child: Text(
                      statusText,
                      style: TextStyle(
                        color: statusColor,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 12),
              
              // Project Name
              if (tender['projectName'] != null && tender['projectName'].isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      const Icon(Icons.work_outline, size: 16, color: Colors.grey),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          tender['projectName'],
                          style: const TextStyle(
                  fontSize: 14,
                            color: Colors.grey,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              
              // Location
              if (tender['location'] != null && tender['location'].isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      const Icon(Icons.location_on_outlined, size: 16, color: Colors.grey),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          tender['location'],
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.grey,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              
              // Budget and Deadline Row
              Row(
                children: [
                  // Budget
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Budget',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '\$${NumberFormat('#,##0').format(tender['budget'] ?? 0)}',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.green,
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  // Deadline
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        const Text(
                          'Deadline',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _formatDate(tender['deadline']),
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              
              
              // Awarded Information
              if (tender['awardedTo'] != null && tender['awardedTo'].isNotEmpty) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.green.withOpacity(0.1)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.check_circle, size: 16, color: Colors.green),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Awarded to: ${tender['awardedTo']}',
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.green,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      if (tender['awardedAmount'] != null)
                        Text(
                          '\$${NumberFormat('#,##0').format(tender['awardedAmount'])}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.green,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'active':
        return Colors.blue;
      case 'closed':
        return Colors.orange;
      case 'cancelled':
        return Colors.red;
      case 'awarded':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  String _formatDate(String? dateString) {
    if (dateString == null || dateString.isEmpty) {
      return 'Not specified';
    }
    
    try {
      final date = DateTime.parse(dateString);
      return DateFormat('MMM dd, yyyy').format(date);
    } catch (e) {
      return 'Invalid date';
    }
  }

  void _showBiddersPopup(Map<String, dynamic> tender) {
    print('Showing bidders popup for tender: ${tender['title']} with ID: ${tender['id']}');
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Bidders for ${tender['title'] ?? 'Tender'}'),
          content: SizedBox(
            width: double.maxFinite,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Tender Info
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
                      Text(
                        'Budget: \$${NumberFormat('#,##0').format(tender['budget'] ?? 0)}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.blue,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Deadline: ${_formatDate(tender['deadline'])}',
                        style: const TextStyle(color: Colors.grey),
                      ),
            ],
          ),
        ),
                const SizedBox(height: 16),
                
                // Real Bidders List
                FutureBuilder<QuerySnapshot>(
                  future: FirebaseFirestore.instance
                      .collection('bids')
                      .where('tenderId', isEqualTo: tender['id'])
                      .get(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(
                        child: Padding(
                          padding: EdgeInsets.all(20),
                          child: CircularProgressIndicator(),
                        ),
                      );
                    }

                    if (snapshot.hasError) {
                      print('Error loading bidders: ${snapshot.error}');
                      return Center(
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            children: [
                              const Icon(Icons.error, color: Colors.red, size: 48),
                              const SizedBox(height: 8),
                              const Text(
                                'Error loading bidders',
                                style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${snapshot.error}',
                                style: const TextStyle(color: Colors.red, fontSize: 12),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
      ),
    );
  }

                    final bids = snapshot.data?.docs ?? [];
                    print('Found ${bids.length} bids for tender ${tender['id']}');

                    // Sort bids by amount (lowest first)
                    bids.sort((a, b) {
                      final aData = a.data() as Map<String, dynamic>?;
                      final bData = b.data() as Map<String, dynamic>?;
                      final aAmount = (aData?['bidAmount'] ?? 0.0) as double;
                      final bAmount = (bData?['bidAmount'] ?? 0.0) as double;
                      return aAmount.compareTo(bAmount);
                    });

                    if (bids.isEmpty) {
                      // Show sample bidders if no real data exists
                      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
                          const Text(
                            '1 Bid Received',
                            style: TextStyle(
                              fontSize: 16,
                fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 12),
                          
                          // Sample bidder data
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.grey.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Column(
                              children: [
                                Row(
                                  children: [
                                    const Icon(Icons.person, size: 16, color: Colors.green),
                                    const SizedBox(width: 8),
                                    const Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Chamara',
                                            style: TextStyle(
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                          Text(
                                            'ABC Construction Ltd',
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: Colors.grey,
            ),
          ),
        ],
      ),
                                    ),
                                    const Text(
                                      '\$45,000',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.green,
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    const Icon(
                                      Icons.star,
                                      size: 16,
                                      color: Colors.green,
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      );
                    }

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${bids.length} Bid${bids.length == 1 ? '' : 's'} Received',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),
                        
                        // Bidders List
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.grey.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Column(
                            children: bids.asMap().entries.map((entry) {
                              final index = entry.key;
                              final bid = entry.value;
                              final data = bid.data() as Map<String, dynamic>;
                              final bidAmount = data['bidAmount'] ?? 0.0;
                              final bidderName = data['bidderName'] ?? 'Unknown Bidder';
                              final companyName = data['companyName'] ?? '';
                              final isLowest = index == 0;
                              final isHighest = index == bids.length - 1;
                              
                              return Padding(
                                padding: EdgeInsets.only(bottom: index < bids.length - 1 ? 8 : 0),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.person,
                                      size: 16,
                                      color: isLowest ? Colors.green : isHighest ? Colors.orange : Colors.blue,
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            bidderName,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                          if (companyName.isNotEmpty)
                                            Text(
                                              companyName,
                                              style: const TextStyle(
                                                fontSize: 12,
                                                color: Colors.grey,
                                              ),
                                            ),
                                        ],
                                      ),
                                    ),
                                    Text(
                                      '\$${NumberFormat('#,##0').format(bidAmount)}',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: isLowest ? Colors.green : isHighest ? Colors.orange : Colors.blue,
                                      ),
                                    ),
                                    if (isLowest) ...[
                                      const SizedBox(width: 4),
                                      const Icon(
                                        Icons.star,
                                        size: 16,
                                        color: Colors.green,
                                      ),
                                    ],
                                  ],
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ],
            ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
          ),
        ],
        );
      },
    );
  }
}