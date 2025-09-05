import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/budget_models.dart';
import '../services/budget_service.dart';

class BudgetCategoryScreen extends StatefulWidget {
  const BudgetCategoryScreen({super.key});

  @override
  State<BudgetCategoryScreen> createState() => _BudgetCategoryScreenState();
}

class _BudgetCategoryScreenState extends State<BudgetCategoryScreen> with TickerProviderStateMixin {
  final BudgetService _budgetService = BudgetService();
  List<BudgetCategory> _categories = [];
  Map<String, CategoryGroupAnalytics> _groupedAnalytics = {};
  bool _isLoading = true;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadCategories();
    _loadGroupedData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadCategories() async {
    try {
      setState(() => _isLoading = true);
      final categories = await _budgetService.getCategories();
      setState(() {
        _categories = categories;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading categories: $e')),
        );
      }
    }
  }

  Future<void> _loadGroupedData() async {
    try {
      final groupedData = await _budgetService.getGroupedAnalytics();
      setState(() {
        _groupedAnalytics = groupedData;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading grouped data: $e')),
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
          'Budget Categories',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(text: 'Individual View'),
            Tab(text: 'Grouped View'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              _loadCategories();
              _loadGroupedData();
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                // Individual View Tab
                RefreshIndicator(
                  onRefresh: _loadCategories,
                  child: _categories.isEmpty
                      ? _buildEmptyState()
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _categories.length,
                          itemBuilder: (context, index) {
                            return _buildCategoryCard(_categories[index]);
                          },
                        ),
                ),
                // Grouped View Tab
                RefreshIndicator(
                  onRefresh: _loadGroupedData,
                  child: _buildGroupedView(),
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddCategoryDialog,
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.account_balance_wallet_outlined,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'No Budget Categories',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Create your first budget category to get started',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[500],
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _showAddCategoryDialog,
            icon: const Icon(Icons.add),
            label: const Text('Add Category'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryCard(BudgetCategory category) {
    final percentage = category.utilizationPercentage;
    final color = Color(int.parse(category.color.replaceAll('#', '0xFF')));

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
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
                        category.name,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (category.description.isNotEmpty)
                        Text(
                          category.description,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                    ],
                  ),
                ),
                PopupMenuButton<String>(
                  onSelected: (value) {
                    switch (value) {
                      case 'edit':
                        _showEditCategoryDialog(category);
                        break;
                      case 'delete':
                        _showDeleteConfirmation(category);
                        break;
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'edit',
                      child: Row(
                        children: [
                          Icon(Icons.edit, size: 20),
                          SizedBox(width: 8),
                          Text('Edit'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete, size: 20, color: Colors.red),
                          SizedBox(width: 8),
                          Text('Delete', style: TextStyle(color: Colors.red)),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Allocated',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                    Text(
                      '₹${NumberFormat('#,##,##,##0').format(category.allocatedAmount)}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'Spent',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                    Text(
                      '₹${NumberFormat('#,##,##,##0').format(category.spentAmount)}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      LinearProgressIndicator(
                        value: percentage / 100,
                        backgroundColor: Colors.grey[300],
                        valueColor: AlwaysStoppedAnimation<Color>(color),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${percentage.toStringAsFixed(1)}% utilized',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: percentage > 80 ? Colors.red[100] : Colors.green[100],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    percentage > 80 ? 'High' : percentage > 50 ? 'Medium' : 'Low',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: percentage > 80 ? Colors.red[700] : Colors.green[700],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Remaining: ₹${NumberFormat('#,##,##,##0').format(category.remainingAmount)}',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey[700],
                  ),
                ),
                Text(
                  'Created: ${DateFormat('MMM dd, yyyy').format(category.createdAt)}',
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

  void _showAddCategoryDialog() {
    final nameController = TextEditingController();
    final descriptionController = TextEditingController();
    final amountController = TextEditingController();
    String selectedColor = '#FF6B6B';

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Add Budget Category'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Category Name *',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.category),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: descriptionController,
                  decoration: const InputDecoration(
                    labelText: 'Description',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.description),
                  ),
                  maxLines: 2,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: amountController,
                  decoration: const InputDecoration(
                    labelText: 'Allocated Amount *',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.currency_rupee),
                    prefixText: '₹',
                  ),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Category Color'),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: [
                        '#FF6B6B', '#4ECDC4', '#45B7D1', '#96CEB4', '#FFEAA7',
                        '#DDA0DD', '#98D8C8', '#F7DC6F', '#BB8FCE', '#85C1E9'
                      ].map((color) => GestureDetector(
                        onTap: () => setState(() => selectedColor = color),
                        child: Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: Color(int.parse(color.replaceAll('#', '0xFF'))),
                            shape: BoxShape.circle,
                            border: selectedColor == color
                                ? Border.all(color: Colors.black, width: 3)
                                : null,
                          ),
                        ),
                      )).toList(),
                    ),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (nameController.text.isNotEmpty && amountController.text.isNotEmpty) {
                  try {
                    final category = BudgetCategory(
                      id: DateTime.now().millisecondsSinceEpoch.toString(),
                      name: nameController.text,
                      description: descriptionController.text,
                      allocatedAmount: double.parse(amountController.text),
                      spentAmount: 0.0,
                      color: selectedColor,
                      createdAt: DateTime.now(),
                    );
                    await _budgetService.createCategory(category);
                    Navigator.pop(context);
                    _loadCategories();
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Category created successfully!'),
                          backgroundColor: Colors.green,
                        ),
                      );
                    }
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error creating category: $e')),
                    );
                  }
                }
              },
              child: const Text('Add'),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditCategoryDialog(BudgetCategory category) {
    final nameController = TextEditingController(text: category.name);
    final descriptionController = TextEditingController(text: category.description);
    final amountController = TextEditingController(text: category.allocatedAmount.toString());
    String selectedColor = category.color;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Edit Budget Category'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Category Name *',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.category),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: descriptionController,
                  decoration: const InputDecoration(
                    labelText: 'Description',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.description),
                  ),
                  maxLines: 2,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: amountController,
                  decoration: const InputDecoration(
                    labelText: 'Allocated Amount *',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.currency_rupee),
                    prefixText: '₹',
                  ),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Category Color'),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: [
                        '#FF6B6B', '#4ECDC4', '#45B7D1', '#96CEB4', '#FFEAA7',
                        '#DDA0DD', '#98D8C8', '#F7DC6F', '#BB8FCE', '#85C1E9'
                      ].map((color) => GestureDetector(
                        onTap: () => setState(() => selectedColor = color),
                        child: Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: Color(int.parse(color.replaceAll('#', '0xFF'))),
                            shape: BoxShape.circle,
                            border: selectedColor == color
                                ? Border.all(color: Colors.black, width: 3)
                                : null,
                          ),
                        ),
                      )).toList(),
                    ),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (nameController.text.isNotEmpty && amountController.text.isNotEmpty) {
                  try {
                    final updatedCategory = BudgetCategory(
                      id: category.id,
                      name: nameController.text,
                      description: descriptionController.text,
                      allocatedAmount: double.parse(amountController.text),
                      spentAmount: category.spentAmount,
                      color: selectedColor,
                      createdAt: category.createdAt,
                      subcategories: category.subcategories,
                    );
                    await _budgetService.updateCategory(updatedCategory);
                    Navigator.pop(context);
                    _loadCategories();
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Category updated successfully!'),
                          backgroundColor: Colors.green,
                        ),
                      );
                    }
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error updating category: $e')),
                    );
                  }
                }
              },
              child: const Text('Update'),
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteConfirmation(BudgetCategory category) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Category'),
        content: Text(
          'Are you sure you want to delete "${category.name}"? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                await _budgetService.deleteCategory(category.id);
                Navigator.pop(context);
                _loadCategories();
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Category deleted successfully!'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              } catch (e) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Error deleting category: $e')),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  Widget _buildGroupedView() {
    if (_groupedAnalytics.isEmpty) {
      return const Center(
        child: Text(
          'No budget categories found',
          style: TextStyle(fontSize: 16, color: Colors.grey),
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Budget Categories (Grouped)',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 16),
          ..._groupedAnalytics.values.map((analytics) => _buildCategoryGroup(analytics)),
        ],
      ),
    );
  }

  Widget _buildCategoryGroup(CategoryGroupAnalytics analytics) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Category Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Color(int.parse(analytics.color.replaceAll('#', '0xFF'))).withOpacity(0.1),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: Color(int.parse(analytics.color.replaceAll('#', '0xFF'))),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        analytics.categoryName,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${analytics.individualEntries.length} entries',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '₹${NumberFormat('#,##,##,##0').format(analytics.totalSpent)} / ₹${NumberFormat('#,##,##,##0').format(analytics.totalAllocated)}',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${analytics.utilizationPercentage.toStringAsFixed(1)}% utilized',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          // Progress Bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: LinearProgressIndicator(
              value: analytics.utilizationPercentage / 100,
              backgroundColor: Colors.grey[300],
              valueColor: AlwaysStoppedAnimation<Color>(
                Color(int.parse(analytics.color.replaceAll('#', '0xFF'))),
              ),
            ),
          ),
          
          // Individual Entries
          ...analytics.individualEntries.map((entry) => _buildIndividualEntry(entry)),
        ],
      ),
    );
  }

  Widget _buildIndividualEntry(BudgetEntry entry) {
    final percentage = (entry.spentAmount / entry.allocatedAmount) * 100;
    
    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      entry.itemName.isNotEmpty ? entry.itemName : 'No item name',
                      style: const TextStyle(
                        fontWeight: FontWeight.w500,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'ID: ${entry.id}',
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.grey[500],
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '₹${NumberFormat('#,##,##,##0').format(entry.spentAmount)} / ₹${NumberFormat('#,##,##,##0').format(entry.allocatedAmount)}',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${percentage.toStringAsFixed(1)}%',
                    style: TextStyle(
                      fontSize: 12,
                      color: percentage > 80 ? Colors.red : percentage > 60 ? Colors.orange : Colors.green,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: percentage / 100,
            backgroundColor: Colors.grey[300],
            valueColor: AlwaysStoppedAnimation<Color>(
              percentage > 80 ? Colors.red : percentage > 60 ? Colors.orange : Colors.green,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Remaining: ₹${NumberFormat('#,##,##,##0').format(entry.remainingAmount)}',
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }
}
