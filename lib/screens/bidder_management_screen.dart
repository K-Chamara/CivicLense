import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/project_service.dart';

class BidderManagementScreen extends StatefulWidget {
  final String tenderId;
  final String tenderTitle;

  const BidderManagementScreen({
    super.key,
    required this.tenderId,
    required this.tenderTitle,
  });

  @override
  State<BidderManagementScreen> createState() => _BidderManagementScreenState();
}

class _BidderManagementScreenState extends State<BidderManagementScreen> {
  List<Map<String, dynamic>> _bids = [];
  bool _isLoading = true;
  final _formKey = GlobalKey<FormState>();
  final _bidderNameController = TextEditingController();
  final _bidderEmailController = TextEditingController();
  final _bidAmountController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadBids();
  }

  @override
  void dispose() {
    _bidderNameController.dispose();
    _bidderEmailController.dispose();
    _bidAmountController.dispose();
    super.dispose();
  }

  Future<void> _loadBids() async {
    try {
      print('Loading bids for tender ID: ${widget.tenderId}');
      final querySnapshot = await FirebaseFirestore.instance
          .collection('bids')
          .where('tenderId', isEqualTo: widget.tenderId)
          .get();

      setState(() {
        _bids = querySnapshot.docs.map((doc) {
          final data = doc.data();
          return {
            'id': doc.id,
            'bidderName': data['bidderName'] ?? '',
            'bidderEmail': data['bidderEmail'] ?? '',
            'bidAmount': data['bidAmount'] ?? 0.0,
            'proposal': data['proposal'] ?? '',
            'submittedAt': data['submittedAt'],
            'status': data['status'] ?? 'pending',
          };
        }).toList();
        
        print('Found ${_bids.length} bids for tender ${widget.tenderId}');
        
        // Sort by bid amount (lowest first)
        _bids.sort((a, b) => (a['bidAmount'] as double).compareTo(b['bidAmount'] as double));
        
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading bids: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _addNewBidder() async {
    if (!_formKey.currentState!.validate()) return;

    try {
      final bidAmount = double.tryParse(_bidAmountController.text.replaceAll(',', ''));
      if (bidAmount == null || bidAmount <= 0) {
        throw Exception('Invalid bid amount');
      }

      // Add new bid to Firestore
      await FirebaseFirestore.instance.collection('bids').add({
        'tenderId': widget.tenderId,
        'bidderName': _bidderNameController.text.trim(),
        'bidderEmail': _bidderEmailController.text.trim(),
        'bidAmount': bidAmount,
        'proposal': '',
        'status': 'pending',
        'submittedAt': FieldValue.serverTimestamp(),
      });

      // Update tender's total bids count
      await FirebaseFirestore.instance
          .collection('tenders')
          .doc(widget.tenderId)
          .update({
        'totalBids': FieldValue.increment(1),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Clear form
      _bidderNameController.clear();
      _bidderEmailController.clear();
      _bidAmountController.clear();

      // Reload bids
      await _loadBids();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('New bidder added successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context); // Close the dialog
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error adding bidder: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showAddBidderDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add New Bidder'),
        content: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: _bidderNameController,
                  decoration: const InputDecoration(
                    labelText: 'Bidder Name *',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter bidder name';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _bidderEmailController,
                  decoration: const InputDecoration(
                    labelText: 'Bidder Email *',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter bidder email';
                    }
                    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                      return 'Please enter a valid email';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _bidAmountController,
                  decoration: const InputDecoration(
                    labelText: 'Bid Amount (\$) *',
                    border: OutlineInputBorder(),
                    hintText: 'e.g., 5000000',
                  ),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter bid amount';
                    }
                    final amount = double.tryParse(value.replaceAll(',', ''));
                    if (amount == null || amount <= 0) {
                      return 'Please enter a valid amount';
                    }
                    return null;
                  },
                                 ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: _addNewBidder,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.lightBlue,
              foregroundColor: Colors.white,
            ),
            child: const Text('Add Bidder'),
          ),
        ],
      ),
    );
  }

  Future<void> _awardTender(String bidId, String bidderName, double bidAmount) async {
    try {
      // Update bid status
      await FirebaseFirestore.instance
          .collection('bids')
          .doc(bidId)
          .update({'status': 'awarded'});

      // Get tender data first
      final tenderDoc = await FirebaseFirestore.instance
          .collection('tenders')
          .doc(widget.tenderId)
          .get();
      
      if (!tenderDoc.exists) {
        throw Exception('Tender not found');
      }
      
      final tenderData = tenderDoc.data()!;

      // Update tender with award information and close it
      await FirebaseFirestore.instance
          .collection('tenders')
          .doc(widget.tenderId)
          .update({
        'status': 'closed', // Changed from 'awarded' to 'closed'
        'awardedTo': bidderName,
        'awardedAmount': bidAmount,
        'awardedDate': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Create project automatically from the closed tender
      await _createProjectFromTender(tenderData, bidderName, bidAmount);

      await _loadBids();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Tender awarded to $bidderName and project created automatically'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error awarding tender: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _createProjectFromTender(Map<String, dynamic> tenderData, String winningBidder, double winningBidAmount) async {
    try {
      // Use the new ProjectService to create project
      final projectId = await ProjectService.createProjectFromTender(
        tenderId: widget.tenderId,
        tenderData: tenderData,
        winningBidder: winningBidder,
        winningBidAmount: winningBidAmount,
      );
      
      print('✅ Project created successfully with ID: $projectId');
    } catch (e) {
      print('❌ Error creating project from tender: $e');
      // Don't throw error here to avoid breaking the tender awarding process
    }
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

  Widget _buildTrailingWidget(Map<String, dynamic> bid) {
    // Check if any bidder has been awarded
    final hasAwardedBidder = _bids.any((b) => b['status'] == 'awarded');
    
    if (bid['status'] == 'awarded') {
      // Show check icon for awarded bidder
      return const Icon(
        Icons.check_circle,
        color: Colors.green,
        size: 32,
      );
    } else if (hasAwardedBidder) {
      // Hide award button if another bidder is already awarded
      return const SizedBox.shrink();
    } else {
      // Show award button only if no bidder has been awarded yet
      return ElevatedButton(
        onPressed: () => _awardTender(
          bid['id'],
          bid['bidderName'],
          bid['bidAmount'],
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.green,
          foregroundColor: Colors.white,
        ),
        child: const Text('Award'),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Bidders - ${widget.tenderTitle}'),
        backgroundColor: Colors.lightBlue,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadBids,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _bids.isEmpty
              ? const Center(
                  child: Text(
                    'No bids received yet',
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _bids.length,
                  itemBuilder: (context, index) {
                    final bid = _bids[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 16),
                      child: ListTile(
                        contentPadding: const EdgeInsets.all(16),
                        title: Text(
                          bid['bidderName'],
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 8),
                            Text('Email: ${bid['bidderEmail']}'),
                                                          Text('Bid Amount: \$${_formatBudget(bid['bidAmount'])}'),
                            if (bid['proposal'].isNotEmpty)
                              Text('Proposal: ${bid['proposal']}'),
                            const SizedBox(height: 8),
                                                         if (bid['status'] == 'awarded')
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
                                 child: const Text(
                                   'WIN',
                                   style: TextStyle(
                                     color: Colors.green,
                                     fontSize: 12,
                                     fontWeight: FontWeight.bold,
                                   ),
                                 ),
                               ),
                          ],
                        ),
                                                 trailing: _buildTrailingWidget(bid),
                      ),
                    );
                  },
                ),
             floatingActionButton: _bids.any((b) => b['status'] == 'awarded')
           ? null // Hide FAB if any bidder is awarded
           : FloatingActionButton(
               onPressed: _showAddBidderDialog,
               backgroundColor: Colors.lightBlue,
               foregroundColor: Colors.white,
               child: const Icon(Icons.add),
             ),
    );
  }
}
