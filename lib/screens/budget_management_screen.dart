import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/budget_models.dart';
import '../services/budget_service.dart';

class BudgetManagementScreen extends StatefulWidget {
  const BudgetManagementScreen({super.key});

  @override
  State<BudgetManagementScreen> createState() => _BudgetManagementScreenState();
}

class _BudgetManagementScreenState extends State<BudgetManagementScreen> {
  final BudgetService _budgetService = BudgetService();
  List<BudgetCategory> _categories = [];
  bool _isLoading = true;
  String _selectedTab = 'categories';

  @override
  void initState() {
    super.initState();
    _loadCategories();
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

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: const Color(0xFFF8F9FA),
        appBar: AppBar(
          title: const Text(
            'Budget Management',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          backgroundColor: Colors.purple,
          foregroundColor: Colors.white,
          elevation: 0,
          bottom: const TabBar(
            indicatorColor: Colors.white,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            tabs: [
              Tab(text: 'Categories'),
              Tab(text: 'Subcategories'),
              Tab(text: 'Expenses'),
            ],
          ),
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : TabBarView(
                children: [
                  _buildCategoriesTab(),
                  _buildSubcategoriesTab(),
                  _buildExpensesTab(),
                ],
              ),
        floatingActionButton: FloatingActionButton(
          onPressed: _showAddCategoryDialog,
          backgroundColor: Colors.purple,
          child: const Icon(Icons.add, color: Colors.white),
        ),
      ),
    );
  }

  Widget _buildCategoriesTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSummaryCards(),
          const SizedBox(height: 24),
          ..._categories.map((category) => _buildCategoryCard(category)),
        ],
      ),
    );
  }

  Widget _buildSummaryCards() {
    final totalBudget = _categories.fold(0.0, (sum, cat) => sum + cat.allocatedAmount);
    final totalSpent = _categories.fold(0.0, (sum, cat) => sum + cat.spentAmount);
    final totalRemaining = totalBudget - totalSpent;
    final utilization = totalBudget > 0 ? (totalSpent / totalBudget) * 100 : 0.0;

    return Row(
      children: [
        Expanded(
          child: _buildSummaryCard(
            'Total Budget',
            '₹${NumberFormat('#,##,##,##0').format(totalBudget)}',
            Icons.account_balance_wallet,
            Colors.blue,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildSummaryCard(
            'Total Spent',
            '₹${NumberFormat('#,##,##,##0').format(totalSpent)}',
            Icons.trending_down,
            Colors.orange,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildSummaryCard(
            'Remaining',
            '₹${NumberFormat('#,##,##,##0').format(totalRemaining)}',
            Icons.savings,
            Colors.green,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildSummaryCard(
            'Utilization',
            '${utilization.toStringAsFixed(1)}%',
            Icons.pie_chart,
            Colors.purple,
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
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
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: const TextStyle(
              fontSize: 12,
              color: Colors.grey,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryCard(BudgetCategory category) {
    final utilization = category.utilizationPercentage;
    final remaining = category.remainingAmount;
    
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 16,
                  height: 16,
                  decoration: BoxDecoration(
                    color: Color(int.parse(category.color.replaceAll('#', '0xFF'))),
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
                  onSelected: (value) => _handleCategoryAction(value, category),
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
                      value: 'add_subcategory',
                      child: Row(
                        children: [
                          Icon(Icons.add, size: 20),
                          SizedBox(width: 8),
                          Text('Add Subcategory'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'add_expense',
                      child: Row(
                        children: [
                          Icon(Icons.remove_circle, size: 20),
                          SizedBox(width: 8),
                          Text('Add Expense'),
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
              children: [
                Expanded(
                  child: _buildAmountInfo(
                    'Allocated',
                    '₹${NumberFormat('#,##,##,##0').format(category.allocatedAmount)}',
                    Colors.blue,
                  ),
                ),
                Expanded(
                  child: _buildAmountInfo(
                    'Spent',
                    '₹${NumberFormat('#,##,##,##0').format(category.spentAmount)}',
                    Colors.orange,
                  ),
                ),
                Expanded(
                  child: _buildAmountInfo(
                    'Remaining',
                    '₹${NumberFormat('#,##,##,##0').format(remaining)}',
                    remaining >= 0 ? Colors.green : Colors.red,
                  ),
                ),
                Expanded(
                  child: _buildAmountInfo(
                    'Utilization',
                    '${utilization.toStringAsFixed(1)}%',
                    utilization > 100 ? Colors.red : Colors.purple,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            LinearProgressIndicator(
              value: utilization / 100,
              backgroundColor: Colors.grey[300],
              valueColor: AlwaysStoppedAnimation<Color>(
                utilization > 100 ? Colors.red : Colors.purple,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAmountInfo(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildSubcategoriesTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Subcategories',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          ..._categories.expand((category) => 
            category.subcategories.map((sub) => _buildSubcategoryCard(category, sub))
          ),
        ],
      ),
    );
  }

  Widget _buildSubcategoryCard(BudgetCategory category, BudgetSubcategory subcategory) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: Color(int.parse(category.color.replaceAll('#', '0xFF'))),
            shape: BoxShape.circle,
          ),
        ),
        title: Text(subcategory.name),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Category: ${category.name}'),
            if (subcategory.description.isNotEmpty)
              Text(subcategory.description),
          ],
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '₹${NumberFormat('#,##,##,##0').format(subcategory.allocatedAmount)}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            Text(
              'Spent: ₹${NumberFormat('#,##,##,##0').format(subcategory.spentAmount)}',
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
          ],
        ),
        onTap: () => _showEditSubcategoryDialog(category, subcategory),
      ),
    );
  }

  Widget _buildExpensesTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Recent Expenses',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              ElevatedButton.icon(
                onPressed: _showAddExpenseDialog,
                icon: const Icon(Icons.add),
                label: const Text('Add Expense'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // This would show actual expense entries when implemented
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Center(
              child: Text(
                'Expense tracking will be implemented here',
                style: TextStyle(color: Colors.grey),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _handleCategoryAction(String action, BudgetCategory category) {
    switch (action) {
      case 'edit':
        _showEditCategoryDialog(category);
        break;
      case 'add_subcategory':
        _showAddSubcategoryDialog(category);
        break;
      case 'add_expense':
        _showAddExpenseToCategoryDialog(category);
        break;
      case 'delete':
        _showDeleteCategoryDialog(category);
        break;
    }
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
                  final category = BudgetCategory(
                    id: DateTime.now().millisecondsSinceEpoch.toString(),
                    name: nameController.text,
                    description: descriptionController.text,
                    allocatedAmount: double.parse(amountController.text),
                    spentAmount: 0.0,
                    color: selectedColor,
                    createdAt: DateTime.now(),
                  );
                  
                  try {
                    await _budgetService.createCategory(category);
                    Navigator.pop(context);
                    _loadCategories();
                    
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Category added successfully'),
                          backgroundColor: Colors.green,
                        ),
                      );
                    }
                  } catch (e) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Error adding category: $e'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
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
                  
                  try {
                    await _budgetService.updateCategory(updatedCategory);
                    Navigator.pop(context);
                    _loadCategories();
                    
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Category updated successfully'),
                          backgroundColor: Colors.green,
                        ),
                      );
                    }
                  } catch (e) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Error updating category: $e'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
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

  void _showAddSubcategoryDialog(BudgetCategory category) {
    final nameController = TextEditingController();
    final descriptionController = TextEditingController();
    final amountController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Subcategory'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Category: ${category.name}'),
            const SizedBox(height: 16),
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Subcategory Name *',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.subdirectory_arrow_right),
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
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (nameController.text.isNotEmpty && amountController.text.isNotEmpty) {
                final subcategory = BudgetSubcategory(
                  id: DateTime.now().millisecondsSinceEpoch.toString(),
                  name: nameController.text,
                  description: descriptionController.text,
                  allocatedAmount: double.parse(amountController.text),
                  spentAmount: 0.0,
                  categoryId: category.id,
                  color: '#4A90E2',
                  createdAt: DateTime.now(),
                );
                
                try {
                  await _budgetService.createSubcategory(subcategory);
                  Navigator.pop(context);
                  _loadCategories();
                  
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Subcategory added successfully'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Error adding subcategory: $e'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  void _showEditSubcategoryDialog(BudgetCategory category, BudgetSubcategory subcategory) {
    final nameController = TextEditingController(text: subcategory.name);
    final descriptionController = TextEditingController(text: subcategory.description);
    final amountController = TextEditingController(text: subcategory.allocatedAmount.toString());

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Subcategory'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Category: ${category.name}'),
            const SizedBox(height: 16),
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Subcategory Name *',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.subdirectory_arrow_right),
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
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (nameController.text.isNotEmpty && amountController.text.isNotEmpty) {
                final updatedSubcategory = BudgetSubcategory(
                  id: subcategory.id,
                  name: nameController.text,
                  description: descriptionController.text,
                  allocatedAmount: double.parse(amountController.text),
                  spentAmount: subcategory.spentAmount,
                  categoryId: subcategory.categoryId,
                  color: subcategory.color,
                  createdAt: subcategory.createdAt,
                );
                
                try {
                  await _budgetService.updateSubcategory(updatedSubcategory);
                  Navigator.pop(context);
                  _loadCategories();
                  
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Subcategory updated successfully'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Error updating subcategory: $e'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              }
            },
            child: const Text('Update'),
          ),
        ],
      ),
    );
  }

  void _showAddExpenseToCategoryDialog(BudgetCategory category) {
    final descriptionController = TextEditingController();
    final amountController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Expense'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Category: ${category.name}'),
            Text('Available: ₹${NumberFormat('#,##,##,##0').format(category.remainingAmount)}'),
            const SizedBox(height: 16),
            TextField(
              controller: descriptionController,
              decoration: const InputDecoration(
                labelText: 'Expense Description *',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.description),
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: amountController,
              decoration: const InputDecoration(
                labelText: 'Expense Amount *',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.currency_rupee),
                prefixText: '₹',
              ),
              keyboardType: TextInputType.number,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (descriptionController.text.isNotEmpty && amountController.text.isNotEmpty) {
                final expenseAmount = double.parse(amountController.text);
                
                if (expenseAmount > category.remainingAmount) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Expense amount exceeds remaining budget'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                  return;
                }
                
                try {
                  final updatedCategory = BudgetCategory(
                    id: category.id,
                    name: category.name,
                    description: category.description,
                    allocatedAmount: category.allocatedAmount,
                    spentAmount: category.spentAmount + expenseAmount,
                    color: category.color,
                    createdAt: category.createdAt,
                    subcategories: category.subcategories,
                  );
                  
                  await _budgetService.updateCategory(updatedCategory);
                  Navigator.pop(context);
                  _loadCategories();
                  
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Expense added successfully'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Error adding expense: $e'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              }
            },
            child: const Text('Add Expense'),
          ),
        ],
      ),
    );
  }

  void _showAddExpenseDialog() {
    // This would show a dialog to add expenses across categories
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Add expense functionality will be implemented here'),
        backgroundColor: Colors.blue,
      ),
    );
  }

  void _showDeleteCategoryDialog(BudgetCategory category) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Category'),
        content: Text(
          'Are you sure you want to delete "${category.name}"? '
          'This will also delete all associated subcategories and cannot be undone.',
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
                      content: Text('Category deleted successfully'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error deleting category: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
