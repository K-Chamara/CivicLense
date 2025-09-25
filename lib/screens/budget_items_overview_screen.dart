import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/budget_models.dart';
import '../services/budget_service.dart';

class BudgetItemsOverviewScreen extends StatefulWidget {
  const BudgetItemsOverviewScreen({super.key});

  @override
  State<BudgetItemsOverviewScreen> createState() => _BudgetItemsOverviewScreenState();
}

class _BudgetItemsOverviewScreenState extends State<BudgetItemsOverviewScreen> with TickerProviderStateMixin {
  final BudgetService _budgetService = BudgetService();
  List<BudgetItemWithContext> _allItems = [];
  List<BudgetItemWithContext> _filteredItems = [];
  bool _isLoading = true;
  Set<String> _tenderCalledItems = {}; // Track items that have tenders called
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  final TextEditingController _searchController = TextEditingController();
  String _selectedCategory = 'All';
  List<String> _categories = ['All'];

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    ));
    _loadAllBudgetItems();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _refreshBudgetItems() async {
    await _loadAllBudgetItems();
  }

  Future<void> _loadAllBudgetItems() async {
    try {
      setState(() => _isLoading = true);
      
      // Get all categories
      final categories = await _budgetService.getBudgetCategories();
      _categories = ['All', ...categories.map((cat) => cat.name).toList()];
      
      List<BudgetItemWithContext> allItems = [];
      
      // For each category, get all subcategories and their items
      for (final category in categories) {
        try {
          final subcategories = await _budgetService.getBudgetSubcategories(category.id);
          
          for (final subcategory in subcategories) {
            try {
              final items = await _budgetService.getBudgetItems(category.id, subcategory.id);
              
              // Add context information to each item
              for (final item in items) {
                allItems.add(BudgetItemWithContext(
                  item: item,
                  category: category,
                  subcategory: subcategory,
                ));
              }
            } catch (e) {
              print('Error loading items for subcategory ${subcategory.id}: $e');
            }
          }
        } catch (e) {
          print('Error loading subcategories for category ${category.id}: $e');
        }
      }
      
      // Check which items already have tenders called
      await _checkExistingTenders(allItems);
      
      setState(() {
        _allItems = allItems;
        _filteredItems = allItems;
        _isLoading = false;
      });
      
      print('After loading, _tenderCalledItems contains: $_tenderCalledItems');
      _fadeController.forward();
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading budget items: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _checkExistingTenders(List<BudgetItemWithContext> items) async {
    try {
      // Clear existing tender called items
      _tenderCalledItems.clear();
      
      // Check for existing tenders for each budget item
      for (final itemWithContext in items) {
        // Check by title match
        final tenderQuery = await FirebaseFirestore.instance
            .collection('tenders')
            .where('title', isEqualTo: itemWithContext.item.name)
            .get();
        
        // Also check by sourceBudgetItem.itemId
        final sourceQuery = await FirebaseFirestore.instance
            .collection('tenders')
            .where('sourceBudgetItem.itemId', isEqualTo: itemWithContext.item.id)
            .get();
        
        // Check if any tender exists (regardless of status)
        if (tenderQuery.docs.isNotEmpty || sourceQuery.docs.isNotEmpty) {
          _tenderCalledItems.add(itemWithContext.item.id);
          print('Tender found for item: ${itemWithContext.item.name} (by title: ${tenderQuery.docs.isNotEmpty}, by source: ${sourceQuery.docs.isNotEmpty})');
        } else {
          print('No tender found for item: ${itemWithContext.item.name}');
        }
      }
      
      print('Total items with tenders: ${_tenderCalledItems.length}');
    } catch (e) {
      print('Error checking existing tenders: $e');
    }
  }

  void _filterItems() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredItems = _allItems.where((itemWithContext) {
        final matchesSearch = query.isEmpty ||
            itemWithContext.item.name.toLowerCase().contains(query) ||
            itemWithContext.item.description.toLowerCase().contains(query) ||
            itemWithContext.category.name.toLowerCase().contains(query) ||
            itemWithContext.subcategory.name.toLowerCase().contains(query);
        
        final matchesCategory = _selectedCategory == 'All' ||
            itemWithContext.category.name == _selectedCategory;
        
        return matchesSearch && matchesCategory;
      }).toList();
    });
  }

  Future<void> _createTenderFromBudgetItem(BudgetItemWithContext itemWithContext) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      // Create tender document with budget item data
      final tenderData = {
        'title': itemWithContext.item.name,
        'description': itemWithContext.item.description,
        'budget': itemWithContext.item.allocatedAmount,
        'deadline': DateTime.now().add(const Duration(days: 30)).toIso8601String().split('T')[0], // 30 days from now
        'category': itemWithContext.category.name,
        'status': 'active',
        'location': 'To be specified', // Default location
        'createdBy': user.uid,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'bids': [],
        'progress': 0.0,
        'totalBids': 0,
        'lowestBid': null,
        'highestBid': null,
        'awardedTo': null,
        'awardedAmount': null,
        'awardedDate': null,
        'sourceBudgetItem': {
          'itemId': itemWithContext.item.id,
          'categoryId': itemWithContext.category.id,
          'subcategoryId': itemWithContext.subcategory.id,
        },
      };

      await FirebaseFirestore.instance.collection('tenders').add(tenderData);

      // Mark this item as having a tender called
      setState(() {
        _tenderCalledItems.add(itemWithContext.item.id);
        print('Added ${itemWithContext.item.id} to _tenderCalledItems');
        print('Current _tenderCalledItems: $_tenderCalledItems');
      });

      // Refresh the data to ensure UI is updated
      await _refreshBudgetItems();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Tender created successfully for: ${itemWithContext.item.name}'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error creating tender: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text(
          'Budget Items Overview',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              print('Refresh button pressed');
              _loadAllBudgetItems();
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : FadeTransition(
              opacity: _fadeAnimation,
              child: Column(
                children: [
                  // Search and Filter Section
                  _buildSearchAndFilterSection(),
                  
                  // Items List
                  Expanded(
                    child: _filteredItems.isEmpty
                        ? _buildEmptyState()
                        : RefreshIndicator(
                            onRefresh: _loadAllBudgetItems,
                            child: ListView.builder(
                              padding: const EdgeInsets.all(16),
                              itemCount: _filteredItems.length,
                              itemBuilder: (context, index) {
                                return _buildItemCard(_filteredItems[index]);
                              },
                            ),
                          ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildSearchAndFilterSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.white,
      child: Column(
        children: [
          // Search Bar
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Search budget items...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _searchController.clear();
                        _filterItems();
                      },
                    )
                  : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey[300]!),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Colors.orange),
              ),
            ),
            onChanged: (value) => _filterItems(),
          ),
          
          const SizedBox(height: 12),
          
          // Category Filter
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
                      _filterItems();
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

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.attach_money_outlined,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            _allItems.isEmpty ? 'No Budget Items' : 'No Items Found',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _allItems.isEmpty 
                ? 'Create budget categories and items to get started'
                : 'Try adjusting your search or filter criteria',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[500],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildItemCard(BudgetItemWithContext itemWithContext) {
    final item = itemWithContext.item;
    final category = itemWithContext.category;
    final subcategory = itemWithContext.subcategory;
    final color = Color(int.parse(item.color.replaceAll('#', '0xFF')));
    final spendingPercentage = item.spendingPercentage;
    final spendingColor = BudgetFormatter.getSpendingColor(spendingPercentage);
    
    // Debug: Check if this item has a tender called
    final hasTenderCalled = _tenderCalledItems.contains(item.id);
    print('Building card for ${item.name}: hasTenderCalled = $hasTenderCalled');

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with category and subcategory info
            Row(
              children: [
                Container(
                  width: 12,
                  height: 12,
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
                        item.name,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Wrap(
                        spacing: 8,
                        runSpacing: 4,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: Color(int.parse(category.color.replaceAll('#', '0xFF'))).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              category.name,
                              style: TextStyle(
                                fontSize: 12,
                                color: Color(int.parse(category.color.replaceAll('#', '0xFF'))),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: Color(int.parse(subcategory.color.replaceAll('#', '0xFF'))).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              subcategory.name,
                              style: TextStyle(
                                fontSize: 12,
                                color: Color(int.parse(subcategory.color.replaceAll('#', '0xFF'))),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                      if (item.description.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          item.description,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                PopupMenuButton<String>(
                  onSelected: (value) {
                    switch (value) {
                      case 'view_details':
                        _showItemDetails(itemWithContext);
                        break;
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'view_details',
                      child: Row(
                        children: [
                          Icon(Icons.info_outline, size: 20),
                          SizedBox(width: 8),
                          Text('View Details'),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Allocated Amount with Call Tender Button
            Row(
              children: [
                Text(
                  'Allocated: ',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  '\$${NumberFormat('#,##,##,##0').format(item.allocatedAmount)}',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.orange,
                  ),
                ),
                const SizedBox(width: 12),
                hasTenderCalled
                    ? Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.green,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.check_circle,
                              color: Colors.white,
                              size: 16,
                            ),
                            SizedBox(width: 4),
                            Text(
                              'Tender Called',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      )
                    : ElevatedButton(
                        onPressed: () => _createTenderFromBudgetItem(itemWithContext),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text(
                          'Call Tender',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(
                  'Created: ${DateFormat('MMM dd, yyyy').format(item.createdAt)}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[500],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showItemDetails(BudgetItemWithContext itemWithContext) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(itemWithContext.item.name),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDetailRow('Category', itemWithContext.category.name),
              _buildDetailRow('Subcategory', itemWithContext.subcategory.name),
              if (itemWithContext.item.description.isNotEmpty)
                _buildDetailRow('Description', itemWithContext.item.description),
              _buildDetailRow('Allocated Amount', '\$${NumberFormat('#,##,##,##0').format(itemWithContext.item.allocatedAmount)}'),
              _buildDetailRow('Created Date', DateFormat('MMM dd, yyyy').format(itemWithContext.item.createdAt)),
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
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.grey,
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
}

// Helper class to hold budget item with its context
class BudgetItemWithContext {
  final BudgetItem item;
  final BudgetCategory category;
  final BudgetSubcategory subcategory;

  BudgetItemWithContext({
    required this.item,
    required this.category,
    required this.subcategory,
  });
}
