import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'user_concern_tracking_screen.dart';

class TenderDetailScreen extends StatefulWidget {
  final Map<String, dynamic> tender;

  const TenderDetailScreen({super.key, required this.tender});

  @override
  State<TenderDetailScreen> createState() => _TenderDetailScreenState();
}

class _TenderDetailScreenState extends State<TenderDetailScreen> {
  List<Map<String, dynamic>> _bidders = [];
  bool _isLoadingBidders = true;

  @override
  void initState() {
    super.initState();
    _loadBidders();
  }

  Future<void> _loadBidders() async {
    try {
      setState(() {
        _isLoadingBidders = true;
      });

      final querySnapshot = await FirebaseFirestore.instance
          .collection('tenders')
          .doc(widget.tender['id'])
          .collection('bidders')
          .orderBy('bidAmount', descending: false) // Lowest bid first
          .get();

      setState(() {
        _bidders = querySnapshot.docs.map((doc) {
          final data = doc.data();
          return {
            'id': doc.id,
            'companyName': data['companyName'] ?? '',
            'bidAmount': data['bidAmount'] ?? 0.0,
            'submittedAt': data['submittedAt'],
            'contactEmail': data['contactEmail'] ?? '',
            'contactPhone': data['contactPhone'] ?? '',
            'proposal': data['proposal'] ?? '',
            'isWinning': data['isWinning'] ?? false,
          };
        }).toList();
        
        _isLoadingBidders = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingBidders = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading bidders: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: const Text('Tender Details'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: _shareTender,
            tooltip: 'Share',
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildTenderHeader(),
            _buildTenderInfo(),
            _buildBiddingSection(),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }

  Widget _buildTenderHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blue, Color(0xFF1976D2)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  widget.tender['title'],
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
              _buildStatusChip(widget.tender['status']),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            widget.tender['description'],
            style: const TextStyle(
              fontSize: 16,
              color: Colors.white70,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildHeaderItem(
                  Icons.attach_money,
                  'Budget',
                  _formatBudget(widget.tender['budget']),
                ),
              ),
              Expanded(
                child: _buildHeaderItem(
                  Icons.schedule,
                  'Deadline',
                  _formatDeadline(widget.tender['deadline']),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _buildHeaderItem(
                  Icons.category,
                  'Category',
                  widget.tender['category'],
                ),
              ),
              Expanded(
                child: _buildHeaderItem(
                  Icons.location_on,
                  'Location',
                  widget.tender['location'],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderItem(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, color: Colors.white70, size: 20),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 12,
                ),
              ),
              Text(
                value,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTenderInfo() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Tender Information',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          _buildInfoRow('Tender ID', widget.tender['id']),
          _buildInfoRow('Published Date', _formatDate(widget.tender['createdAt'])),
          _buildInfoRow('Total Bids', '${widget.tender['totalBids']}'),
          if (widget.tender['lowestBid'] != null)
            _buildInfoRow('Lowest Bid', _formatBudget(widget.tender['lowestBid'])),
          if (widget.tender['highestBid'] != null)
            _buildInfoRow('Highest Bid', _formatBudget(widget.tender['highestBid'])),
          if (widget.tender['status'] == 'awarded' && widget.tender['awardedTo'] != null) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
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
                        size: 24,
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'Awarded Tender',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  _buildInfoRow('Winner', widget.tender['awardedTo']),
                  if (widget.tender['awardedAmount'] != null)
                    _buildInfoRow('Awarded Amount', _formatBudget(widget.tender['awardedAmount'])),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: TextStyle(
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBiddingSection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                'Bidding Information',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              if (_bidders.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${_bidders.length} bid${_bidders.length == 1 ? '' : 's'}',
                    style: TextStyle(
                      color: Colors.blue[700],
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          
          if (_isLoadingBidders)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(20),
                child: CircularProgressIndicator(),
              ),
            )
          else if (_bidders.isEmpty)
            _buildNoBidsState()
          else
            _buildBiddersList(),
        ],
      ),
    );
  }

  Widget _buildNoBidsState() {
    return Center(
      child: Column(
        children: [
          Icon(
            Icons.people_outline,
            size: 48,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'No bids received yet',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Bidding is still open for this tender',
            style: TextStyle(
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBiddersList() {
    return Column(
      children: [
        // Top 3 Bidders Section
        if (_bidders.length >= 3) ...[
          const Text(
            'Top 3 Bidders',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.blue,
            ),
          ),
          const SizedBox(height: 12),
          ...List.generate(3, (index) {
            final bidder = _bidders[index];
            return _buildBidderCard(bidder, index + 1, isTopThree: true);
          }),
          if (_bidders.length > 3) ...[
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 16),
            const Text(
              'All Bidders',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
          ],
        ],
        
        // All Bidders
        ...List.generate(_bidders.length, (index) {
          final bidder = _bidders[index];
          final rank = index + 1;
          return _buildBidderCard(bidder, rank, isTopThree: _bidders.length >= 3 && index < 3);
        }),
      ],
    );
  }

  Widget _buildBidderCard(Map<String, dynamic> bidder, int rank, {required bool isTopThree}) {
    final isWinning = bidder['isWinning'] == true;
    final isLowest = rank == 1;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isWinning 
            ? Colors.green.withOpacity(0.1)
            : isLowest 
                ? Colors.blue.withOpacity(0.1)
                : Colors.grey.withOpacity(0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isWinning 
              ? Colors.green.withOpacity(0.3)
              : isLowest 
                  ? Colors.blue.withOpacity(0.3)
                  : Colors.grey.withOpacity(0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Rank Badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: isWinning 
                      ? Colors.green
                      : isLowest 
                          ? Colors.blue
                          : Colors.grey,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '#$rank',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              
              // Company Name
              Expanded(
                child: Text(
                  bidder['companyName'],
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: isWinning ? Colors.green[700] : null,
                  ),
                ),
              ),
              
              // Winning Badge
              if (isWinning)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.green,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.emoji_events, color: Colors.white, size: 16),
                      SizedBox(width: 4),
                      Text(
                        'Winner',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          
          // Bid Amount
          Row(
            children: [
              Icon(
                Icons.attach_money,
                color: isWinning ? Colors.green[700] : Colors.blue[700],
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Bid Amount: ',
                style: TextStyle(
                  color: Colors.grey[600],
                ),
              ),
              Text(
                _formatBudget(bidder['bidAmount']),
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: isWinning ? Colors.green[700] : Colors.blue[700],
                ),
              ),
            ],
          ),
          
          // Submitted Date
          if (bidder['submittedAt'] != null) ...[
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(
                  Icons.schedule,
                  color: Colors.grey[600],
                  size: 16,
                ),
                const SizedBox(width: 8),
                Text(
                  'Submitted: ${_formatDate(bidder['submittedAt'])}',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ],
          
          // Contact Info (if available)
          if (bidder['contactEmail'] != null || bidder['contactPhone'] != null) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(
                  Icons.contact_mail,
                  color: Colors.grey[600],
                  size: 16,
                ),
                const SizedBox(width: 8),
                if (bidder['contactEmail'] != null)
                  Text(
                    bidder['contactEmail'],
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 12,
                    ),
                  ),
                if (bidder['contactPhone'] != null) ...[
                  const SizedBox(width: 16),
                  Text(
                    bidder['contactPhone'],
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 12,
                    ),
                  ),
                ],
              ],
            ),
          ],
        ],
      ),
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
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.bold,
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

  String _formatDate(dynamic date) {
    if (date == null) return 'N/A';
    try {
      final dateTime = date is Timestamp ? date.toDate() : DateTime.parse(date.toString());
      return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
    } catch (e) {
      return 'Invalid date';
    }
  }

  void _shareTender() {
    // Implement share functionality
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Share functionality coming soon!'),
        backgroundColor: Colors.blue,
      ),
    );
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
            Navigator.pushNamed(context, '/dashboard');
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
}
