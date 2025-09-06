import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'bidder_management_screen.dart';
import '../services/budget_service.dart';

class TenderManagementScreen extends StatefulWidget {
  const TenderManagementScreen({super.key});

  @override
  State<TenderManagementScreen> createState() => _TenderManagementScreenState();
}

class _TenderManagementScreenState extends State<TenderManagementScreen> {
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

  List<Map<String, dynamic>> get _filteredTenders {
    return _tenders.where((tender) {
      final statusMatch = _selectedStatus == 'All' || tender['status'] == _selectedStatus;
      final categoryMatch = _selectedCategory == 'All' || tender['category'] == _selectedCategory;
      return statusMatch && categoryMatch;
    }).toList();
  }

  String _formatBudget(double budget) {
    if (budget >= 1000000) {
      return '\$${(budget / 1000000).toStringAsFixed(1)}M';
    } else if (budget >= 1000) {
      return '\$${(budget / 1000).toStringAsFixed(1)}K';
    } else {
      return '\$${budget.toStringAsFixed(0)}';
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'active':
        return Colors.green;
      case 'closed':
        return Colors.orange;
      case 'awarded':
        return Colors.blue;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  void _showTenderDetails(Map<String, dynamic> tender) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => TenderDetailsSheet(
        tender: tender,
        onStatusChanged: () => _loadTenders(),
      ),
    );
  }

  void _editTender(Map<String, dynamic> tender) {
    // Navigate to edit tender screen or show edit dialog
    // For now, show a placeholder message
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Edit functionality for "${tender['title']}" will be implemented soon'),
        backgroundColor: Colors.blue,
      ),
    );
  }

  Widget _buildSearchAndFilterSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.white,
      child: Column(
        children: [
          // Status Filter Chips
          Container(
            height: 40,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _statuses.length,
              itemBuilder: (context, index) {
                final status = _statuses[index];
                final isSelected = status == _selectedStatus;
                
                return Container(
                  margin: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(status.toUpperCase()),
                    selected: isSelected,
                    onSelected: (selected) {
                      setState(() {
                        _selectedStatus = status;
                      });
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
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Search and Filter Section
                _buildSearchAndFilterSection(),
                
                // Results count
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    children: [
                      Text(
                        '${_filteredTenders.length} tenders found',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey,
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.refresh),
                        onPressed: _loadTenders,
                        tooltip: 'Refresh',
                      ),
                    ],
                  ),
                ),
                
                // Tenders list
                Expanded(
                  child: _filteredTenders.isEmpty
                      ? const Center(
                          child: Text(
                            'No tenders found',
                            style: TextStyle(fontSize: 18, color: Colors.grey),
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _filteredTenders.length,
                          itemBuilder: (context, index) {
                            final tender = _filteredTenders[index];
                            return Card(
                              margin: const EdgeInsets.only(bottom: 12),
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
                                      Row(
                                        children: [
                                          Expanded(
                                            child: Text(
                                              tender['title'],
                                              style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 16,
                                              ),
                                            ),
                                          ),
                                          PopupMenuButton<String>(
                                            icon: const Icon(Icons.more_vert),
                                            onSelected: (value) {
                                              if (value == 'details') {
                                                _showTenderDetails(tender);
                                              } else if (value == 'bidders') {
                                                Navigator.push(
                                                  context,
                                                  MaterialPageRoute(
                                                    builder: (context) => BidderManagementScreen(
                                                      tenderId: tender['id'],
                                                      tenderTitle: tender['title'],
                                                    ),
                                                  ),
                                                ).then((_) => _loadTenders());
                                              } else if (value == 'edit') {
                                                _editTender(tender);
                                              }
                                            },
                                            itemBuilder: (context) => [
                                              const PopupMenuItem(
                                                value: 'details',
                                                child: Row(
                                                  children: [
                                                    Icon(Icons.info_outline),
                                                    SizedBox(width: 8),
                                                    Text('View Details'),
                                                  ],
                                                ),
                                              ),
                                              PopupMenuItem(
                                                value: 'edit',
                                                enabled: tender['status'] != 'cancelled' && tender['status'] != 'closed',
                                                child: Row(
                                                  children: [
                                                    Icon(
                                                      Icons.edit,
                                                      color: (tender['status'] == 'cancelled' || tender['status'] == 'closed')
                                                          ? Colors.grey
                                                          : null,
                                                    ),
                                                    const SizedBox(width: 8),
                                                    Text(
                                                      'Edit',
                                                      style: TextStyle(
                                                        color: (tender['status'] == 'cancelled' || tender['status'] == 'closed')
                                                            ? Colors.grey
                                                            : null,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              const PopupMenuItem(
                                                value: 'bidders',
                                                child: Row(
                                                  children: [
                                                    Icon(Icons.people),
                                                    SizedBox(width: 8),
                                                    Text('Manage Bidders'),
                                                  ],
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        'Description: ${tender['description']}',
                                        style: const TextStyle(color: Colors.grey),
                                      ),
                                      Text(
                                        'Location: ${tender['location']}',
                                        style: const TextStyle(color: Colors.grey),
                                      ),
                                      Text(
                                        'Budget: ${_formatBudget(tender['budget'])}',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w500,
                                          color: Colors.blue,
                                        ),
                                      ),
                                      Text(
                                        'Deadline: ${tender['deadline']}',
                                        style: const TextStyle(color: Colors.grey),
                                      ),
                                      // Show winning bidder info for closed/awarded tenders
                                      if ((tender['status'] == 'closed' || tender['status'] == 'awarded') && tender['awardedTo'] != null) ...[
                                        const SizedBox(height: 8),
                                        Container(
                                          padding: const EdgeInsets.all(12),
                                          decoration: BoxDecoration(
                                            color: Colors.green.withOpacity(0.1),
                                            borderRadius: BorderRadius.circular(8),
                                            border: Border.all(color: Colors.green.withOpacity(0.3)),
                                          ),
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Row(
                                                children: [
                                                  Icon(
                                                    Icons.emoji_events,
                                                    color: Colors.green[700],
                                                    size: 20,
                                                  ),
                                                  const SizedBox(width: 8),
                                                  Text(
                                                    'Winning Bidder',
                                                    style: TextStyle(
                                                      fontWeight: FontWeight.bold,
                                                      color: Colors.green[700],
                                                      fontSize: 14,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                'Name: ${tender['awardedTo']}',
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.w500,
                                                  color: Colors.black87,
                                                ),
                                              ),
                                              Text(
                                                'Amount: ${_formatBudget(tender['awardedAmount'] ?? 0.0)}',
                                                style: TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.green[700],
                                                  fontSize: 16,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ] else if (tender['status'] == 'closed' && tender['awardedTo'] == null) ...[
                                        const SizedBox(height: 8),
                                        Container(
                                          padding: const EdgeInsets.all(12),
                                          decoration: BoxDecoration(
                                            color: Colors.orange.withOpacity(0.1),
                                            borderRadius: BorderRadius.circular(8),
                                            border: Border.all(color: Colors.orange.withOpacity(0.3)),
                                          ),
                                          child: Row(
                                            children: [
                                              Icon(
                                                Icons.info_outline,
                                                color: Colors.orange[700],
                                                size: 20,
                                              ),
                                              const SizedBox(width: 8),
                                              Text(
                                                'Tender closed - No winner awarded',
                                                style: TextStyle(
                                                  fontWeight: FontWeight.w500,
                                                  color: Colors.orange[700],
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                      const SizedBox(height: 12),
                                      Row(
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 8,
                                              vertical: 4,
                                            ),
                                            decoration: BoxDecoration(
                                              color: _getStatusColor(tender['status']).withOpacity(0.1),
                                              borderRadius: BorderRadius.circular(12),
                                              border: Border.all(
                                                color: _getStatusColor(tender['status']),
                                              ),
                                            ),
                                            child: Text(
                                              tender['status'].toUpperCase(),
                                              style: TextStyle(
                                                color: _getStatusColor(tender['status']),
                                                fontSize: 12,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 8,
                                              vertical: 4,
                                            ),
                                            decoration: BoxDecoration(
                                              color: Colors.blue.withOpacity(0.1),
                                              borderRadius: BorderRadius.circular(12),
                                              border: Border.all(color: Colors.blue),
                                            ),
                                            child: Text(
                                              '${tender['totalBids']} Bids',
                                              style: const TextStyle(
                                                color: Colors.blue,
                                                fontSize: 12,
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
                          },
                        ),
                ),
              ],
            ),
    );
  }
}

class TenderDetailsSheet extends StatefulWidget {
  final Map<String, dynamic> tender;
  final VoidCallback onStatusChanged;

  const TenderDetailsSheet({
    super.key,
    required this.tender,
    required this.onStatusChanged,
  });

  @override
  State<TenderDetailsSheet> createState() => _TenderDetailsSheetState();
}

class _TenderDetailsSheetState extends State<TenderDetailsSheet> {
     String _selectedStatus = '';
   String _projectName = '';
   List<Map<String, dynamic>> _bidders = [];
   bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Handle awarded status - don't allow changing from awarded
    final tenderStatus = widget.tender['status'];
    if (tenderStatus == 'awarded') {
      _selectedStatus = 'closed'; // Default to closed for awarded tenders
    } else {
      _selectedStatus = tenderStatus;
    }
    _projectName = widget.tender['projectName'] ?? '';
    _loadBidders();
  }

  Future<void> _loadBidders() async {
    try {
      final bidsSnapshot = await FirebaseFirestore.instance
          .collection('bids')
          .where('tenderId', isEqualTo: widget.tender['id'])
          .get();

             setState(() {
         _bidders = bidsSnapshot.docs.map((doc) {
           final data = doc.data();
           return {
             'id': doc.id,
             'bidderName': data['bidderName'] ?? '',
             'bidAmount': data['bidAmount'] ?? 0.0,
             'status': data['status'] ?? 'pending',
           };
         }).toList();
         
         // Sort bidders: awarded first, then by bid amount (lowest first)
         _bidders.sort((a, b) {
           if (a['status'] == 'awarded' && b['status'] != 'awarded') return -1;
           if (a['status'] != 'awarded' && b['status'] == 'awarded') return 1;
           return (a['bidAmount'] as double).compareTo(b['bidAmount'] as double);
         });
       });
    } catch (e) {
      print('Error loading bidders: $e');
    }
  }

     Future<void> _awardBidder(Map<String, dynamic> bidder) async {
     try {
       // Update the bid status to awarded
       await FirebaseFirestore.instance
           .collection('bids')
           .doc(bidder['id'])
           .update({
         'status': 'awarded',
         'awardedAt': FieldValue.serverTimestamp(),
       });

       // Update the tender with awarded information
       await FirebaseFirestore.instance
           .collection('tenders')
           .doc(widget.tender['id'])
           .update({
         'awardedTo': bidder['bidderName'],
         'awardedAmount': bidder['bidAmount'],
         'awardedDate': FieldValue.serverTimestamp(),
         'status': 'awarded',
         'updatedAt': FieldValue.serverTimestamp(),
       });

       // Reload bidders to reflect the changes
       await _loadBidders();

       if (mounted) {
         ScaffoldMessenger.of(context).showSnackBar(
           SnackBar(
             content: Text('${bidder['bidderName']} has been awarded the tender'),
             backgroundColor: Colors.green,
           ),
         );
         widget.onStatusChanged();
       }
     } catch (e) {
       if (mounted) {
         ScaffoldMessenger.of(context).showSnackBar(
           SnackBar(
             content: Text('Error awarding bidder: $e'),
             backgroundColor: Colors.red,
           ),
         );
       }
     }
   }

   Future<void> _updateTenderStatus() async {
     if (_selectedStatus.isEmpty) return;

     setState(() {
       _isLoading = true;
     });

     try {
       final tenderRef = FirebaseFirestore.instance
           .collection('tenders')
           .doc(widget.tender['id']);

       final updateData = <String, dynamic>{
         'status': _selectedStatus,
         'updatedAt': FieldValue.serverTimestamp(),
       };

       

       // If status is 'closed' and project name is provided, create a project
       if (_selectedStatus == 'closed' && _projectName.isNotEmpty) {
         updateData['projectName'] = _projectName;
         
         // Create a project entry
         await FirebaseFirestore.instance.collection('projects').add({
           'projectName': _projectName,
           'tenderId': widget.tender['id'],
           'tenderTitle': widget.tender['title'],
           'budget': widget.tender['budget'],
           'category': widget.tender['category'],
           'location': widget.tender['location'],
           'status': 'active',
           'createdAt': FieldValue.serverTimestamp(),
           'createdBy': FirebaseAuth.instance.currentUser?.uid,
         });
       }

       await tenderRef.update(updateData);

       if (mounted) {
         ScaffoldMessenger.of(context).showSnackBar(
           SnackBar(
             content: Text('Tender status updated to ${_selectedStatus.toUpperCase()}'),
             backgroundColor: Colors.green,
           ),
         );
         widget.onStatusChanged();
         Navigator.pop(context);
       }
     } catch (e) {
       if (mounted) {
         ScaffoldMessenger.of(context).showSnackBar(
           SnackBar(
             content: Text('Error updating tender: $e'),
             backgroundColor: Colors.red,
           ),
         );
       }
     } finally {
       setState(() {
         _isLoading = false;
       });
     }
   }

           String _formatBudget(double budget) {
        if (budget >= 1000000) {
          return '\$${(budget / 1000000).toStringAsFixed(1)}M';
        } else if (budget >= 1000) {
          return '\$${(budget / 1000).toStringAsFixed(1)}K';
        } else {
          return '\$${budget.toStringAsFixed(0)}';
        }
      }

      Widget _buildBidderTrailing(Map<String, dynamic> bidder) {
        // Check if any bidder has been awarded
        final hasAwardedBidder = _bidders.any((b) => b['status'] == 'awarded');
        
        if (bidder['status'] == 'awarded') {
          // Show WIN badge for awarded bidder
          return Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 8,
              vertical: 4,
            ),
            decoration: BoxDecoration(
              color: Colors.green.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Text(
              'WIN',
              style: TextStyle(
                color: Colors.green,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          );
        } else if (hasAwardedBidder) {
          // If another bidder is awarded, show nothing for this bidder
          return const SizedBox.shrink();
        } else {
          // Show Award button if no bidder is awarded yet
          return ElevatedButton(
            onPressed: () => _awardBidder(bidder),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              minimumSize: const Size(0, 32),
            ),
            child: const Text('Award', style: TextStyle(fontSize: 12)),
          );
        }
      }

      @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.8,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Handle bar
          Container(
            margin: const EdgeInsets.only(top: 8),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          
          // Header
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                const Text(
                  'Tender Details',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          
          // Content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Tender Information
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.tender['title'],
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text('Description: ${widget.tender['description']}'),
                          Text('Location: ${widget.tender['location']}'),
                          Text('Budget: ${_formatBudget(widget.tender['budget'])}'),
                          Text('Deadline: ${widget.tender['deadline']}'),
                          Text('Category: ${widget.tender['category']}'),
                          Text('Current Status: ${widget.tender['status'].toUpperCase()}'),
                        ],
                      ),
                    ),
                  ),
                  
                                     const SizedBox(height: 16),
                   
                   // Status Update Section - Only show if tender is not closed
                  if (widget.tender['status'] != 'closed') ...[
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Update Status',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 12),
                            
                            // Status Dropdown
                            DropdownButtonFormField<String>(
                              value: _selectedStatus,
                              decoration: const InputDecoration(
                                labelText: 'New Status',
                                border: OutlineInputBorder(),
                              ),
                              items: ['active', 'closed', 'cancelled'].map((status) {
                                return DropdownMenuItem<String>(
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
                            
                            const SizedBox(height: 16),
                            
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: _isLoading ? null : _updateTenderStatus,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.orange,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                ),
                                child: _isLoading
                                    ? const CircularProgressIndicator(color: Colors.white)
                                    : const Text('Update Status'),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                  
                  const SizedBox(height: 16),
                  
                  // Bidders Section
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Text(
                                'Bidders',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const Spacer(),
                              TextButton(
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => BidderManagementScreen(
                                        tenderId: widget.tender['id'],
                                        tenderTitle: widget.tender['title'],
                                      ),
                                    ),
                                  ).then((_) {
                                    _loadBidders();
                                    widget.onStatusChanged();
                                  });
                                },
                                child: const Text('Manage Bidders'),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                                                     if (_bidders.isEmpty)
                             const Text(
                               'No bidders yet',
                               style: TextStyle(color: Colors.grey),
                             )
                           else
                             ...(_bidders.map((bidder) => Card(
                               margin: const EdgeInsets.only(bottom: 8),
                               child: ListTile(
                                 title: Text(bidder['bidderName']),
                                 subtitle: Text(_formatBudget(bidder['bidAmount'])),
                                                                   trailing: _buildBidderTrailing(bidder),
                               ),
                             )).toList()),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
