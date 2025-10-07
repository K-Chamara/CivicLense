import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/budget_models.dart';
import '../services/budget_service.dart';

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

class BudgetAllocationsViewScreen extends StatefulWidget {
  const BudgetAllocationsViewScreen({super.key});

  @override
  State<BudgetAllocationsViewScreen> createState() => _BudgetAllocationsViewScreenState();
}

class _BudgetAllocationsViewScreenState extends State<BudgetAllocationsViewScreen> with TickerProviderStateMixin {
  final BudgetService _budgetService = BudgetService();
  List<BudgetItemWithContext> _allItems = [];
  List<BudgetItemWithContext> _filteredItems = [];
  bool _isLoading = true;
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
      _categories = ['All', ...categories.map((cat) => cat.name)];
      
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
              // Error loading items for subcategory
            }
          }
        } catch (e) {
          // Error loading subcategories for category
        }
      }
      
      setState(() {
        _allItems = allItems;
        _filteredItems = allItems;
        _isLoading = false;
      });
      
      _fadeController.forward();
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading budget items: $e')),
        );
      }
    }
  }

  void _filterItems() {
    setState(() {
      if (_selectedCategory == 'All') {
        _filteredItems = _allItems.where((item) {
          final searchTerm = _searchController.text.toLowerCase();
          return item.item.name.toLowerCase().contains(searchTerm) ||
                 item.item.description.toLowerCase().contains(searchTerm) ||
                 item.category.name.toLowerCase().contains(searchTerm) ||
                 item.subcategory.name.toLowerCase().contains(searchTerm);
        }).toList();
      } else {
        _filteredItems = _allItems.where((item) {
          final matchesCategory = item.category.name == _selectedCategory;
          final searchTerm = _searchController.text.toLowerCase();
          final matchesSearch = item.item.name.toLowerCase().contains(searchTerm) ||
                               item.item.description.toLowerCase().contains(searchTerm) ||
                               item.category.name.toLowerCase().contains(searchTerm) ||
                               item.subcategory.name.toLowerCase().contains(searchTerm);
          return matchesCategory && matchesSearch;
        }).toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text(
          'Budget Allocations',
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
            icon: const Icon(Icons.refresh),
            onPressed: _refreshBudgetItems,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : FadeTransition(
              opacity: _fadeAnimation,
              child: Column(
                children: [
                  _buildSearchAndFilterSection(),
                  Expanded(
                    child: _filteredItems.isEmpty
                        ? _buildEmptyState()
                        : _buildBudgetItemsList(),
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
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Colors.blue),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
            onChanged: (value) => _filterItems(),
          ),
          const SizedBox(height: 12),
          // Category Filter
          DropdownButtonFormField<String>(
            initialValue: _selectedCategory,
            decoration: InputDecoration(
              labelText: 'Category',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Colors.blue),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
              _filterItems();
            },
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
            Icons.inbox_outlined,
            size: 80,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            'No budget items found',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Try adjusting your search or filter criteria',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBudgetItemsList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _filteredItems.length,
      itemBuilder: (context, index) {
        final itemWithContext = _filteredItems[index];
        return _buildBudgetItemCard(itemWithContext);
      },
    );
  }

  Widget _buildBudgetItemCard(BudgetItemWithContext itemWithContext) {
    final item = itemWithContext.item;
    final category = itemWithContext.category;
    final subcategory = itemWithContext.subcategory;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with category and subcategory
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: Colors.blue.shade200),
                  ),
                  child: Text(
                    category.name,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: Colors.blue.shade700,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: Colors.green.shade200),
                  ),
                  child: Text(
                    subcategory.name,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: Colors.green.shade700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            
            // Item name and description
            Text(
              item.name,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            if (item.description.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                item.description,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade600,
                  height: 1.4,
                ),
              ),
            ],
            const SizedBox(height: 16),
            
            // Financial information
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Allocated Amount',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        NumberFormat.currency(
                          locale: 'en_US',
                          symbol: '\$',
                          decimalDigits: 0,
                        ).format(item.allocatedAmount),
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                    ],
                  ),
                ),
                if (item.spentAmount > 0) ...[
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Spent Amount',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          NumberFormat.currency(
                            locale: 'en_US',
                            symbol: '\$',
                            decimalDigits: 0,
                          ).format(item.spentAmount),
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.orange,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
            
            // Progress bar if there's spending
            if (item.spentAmount > 0) ...[
              const SizedBox(height: 12),
              LinearProgressIndicator(
                value: (item.spentAmount / item.allocatedAmount).clamp(0.0, 1.0),
                backgroundColor: Colors.grey.shade200,
                valueColor: AlwaysStoppedAnimation<Color>(
                  (item.spentAmount / item.allocatedAmount) > 0.8
                      ? Colors.red
                      : (item.spentAmount / item.allocatedAmount) > 0.6
                          ? Colors.orange
                          : Colors.green,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${((item.spentAmount / item.allocatedAmount) * 100).toStringAsFixed(1)}% spent',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  Text(
                    '${NumberFormat.currency(locale: 'en_US', symbol: '\$', decimalDigits: 0).format(item.allocatedAmount - item.spentAmount)} remaining',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
