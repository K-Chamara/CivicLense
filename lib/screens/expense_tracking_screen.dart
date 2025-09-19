import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/budget_service.dart';
import '../models/budget_models.dart';

class ExpenseTrackingScreen extends StatefulWidget {
  const ExpenseTrackingScreen({super.key});

  @override
  State<ExpenseTrackingScreen> createState() => _ExpenseTrackingScreenState();
}

class _ExpenseTrackingScreenState extends State<ExpenseTrackingScreen> {
  final BudgetService _budgetService = BudgetService();
  List<CategoryAnalytics> _categoryAnalytics = [];
  List<Transaction> _recentTransactions = [];
  bool _isLoading = true;
  Map<String, dynamic>? _budgetStats;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      setState(() => _isLoading = true);
      
      final analytics = await _budgetService.getBudgetAnalytics();
      final transactions = await _budgetService.getTransactions();
      final stats = await _budgetService.getBudgetStatistics();
      
      setState(() {
        _categoryAnalytics = analytics.categoryAnalytics;
        _recentTransactions = transactions.take(10).toList();
        _budgetStats = stats;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading data: $e'),
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
        title: const Text('Expense Tracking'),
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
            tooltip: 'Refresh Data',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Over-budget Alerts Section
                  _buildOverBudgetAlerts(),
                  const SizedBox(height: 24),
                  
                  // Budget Overview
                  _buildBudgetOverview(),
                  const SizedBox(height: 24),
                  
                  // Category-wise Expense Tracking
                  _buildCategoryExpenseTracking(),
                  const SizedBox(height: 24),
                  
                  // Recent Transactions
                  _buildRecentTransactions(),
                ],
              ),
            ),
    );
  }

  Widget _buildOverBudgetAlerts() {
    final overBudgetCategories = _categoryAnalytics.where((category) {
      return category.spendingPercentage > 100;
    }).toList();

    final warningCategories = _categoryAnalytics.where((category) {
      return category.spendingPercentage > 80 && category.spendingPercentage <= 100;
    }).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.warning, color: Colors.red, size: 24),
            const SizedBox(width: 8),
            const Text(
              'Budget Alerts',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const Spacer(),
            if (overBudgetCategories.isNotEmpty || warningCategories.isNotEmpty)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: overBudgetCategories.isNotEmpty ? Colors.red : Colors.orange,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${overBudgetCategories.length + warningCategories.length}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 16),
        
        // Over-budget alerts
        if (overBudgetCategories.isNotEmpty) ...[
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.red.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.red.shade200),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.error, color: Colors.red.shade700, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'Over Budget Categories (${overBudgetCategories.length})',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.red.shade700,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                ...overBudgetCategories.map((category) => _buildAlertItem(
                  category,
                  Colors.red,
                  'Over Budget',
                )),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],
        
        // Warning alerts
        if (warningCategories.isNotEmpty) ...[
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.orange.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.orange.shade200),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.warning, color: Colors.orange.shade700, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'Budget Warning Categories (${warningCategories.length})',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.orange.shade700,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                ...warningCategories.map((category) => _buildAlertItem(
                  category,
                  Colors.orange,
                  'Warning',
                )),
              ],
            ),
          ),
        ],
        
        // No alerts message
        if (overBudgetCategories.isEmpty && warningCategories.isEmpty)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.green.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.green.shade200),
            ),
            child: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.green.shade700, size: 20),
                const SizedBox(width: 8),
                Text(
                  'All categories are within budget limits',
                  style: TextStyle(
                    fontWeight: FontWeight.w500,
                    color: Colors.green.shade700,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildAlertItem(CategoryAnalytics category, Color color, String alertType) {
    final overAmount = category.spentAmount - category.allocatedAmount;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 40,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  category.categoryName,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Allocated: \$${NumberFormat('#,##,##,##0').format(category.allocatedAmount)}',
                  style: const TextStyle(
                    color: Colors.grey,
                    fontSize: 12,
                  ),
                ),
                Text(
                  'Spent: \$${NumberFormat('#,##,##,##0').format(category.spentAmount)}',
                  style: const TextStyle(
                    color: Colors.grey,
                    fontSize: 12,
                  ),
                ),
                if (alertType == 'Over Budget')
                  Text(
                    'Over by: \$${NumberFormat('#,##,##,##0').format(overAmount)}',
                    style: TextStyle(
                      color: color,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${category.spendingPercentage.toStringAsFixed(1)}%',
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                alertType,
                style: TextStyle(
                  color: color,
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBudgetOverview() {
    final totalAllocated = _budgetStats?['totalAllocated'] ?? 0.0;
    final totalSpent = _budgetStats?['totalSpent'] ?? 0.0;
    final totalRemaining = _budgetStats?['totalRemaining'] ?? 0.0;
    final spendingPercentage = totalAllocated > 0 ? (totalSpent / totalAllocated) * 100 : 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Budget Overview',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(20),
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
              Row(
                children: [
                  Expanded(
                    child: _buildOverviewItem(
                      'Total Allocated',
                      '\$${NumberFormat('#,##,##,##0').format(totalAllocated)}',
                      Icons.account_balance,
                      Colors.blue,
                    ),
                  ),
                  Expanded(
                    child: _buildOverviewItem(
                      'Total Spent',
                      '\$${NumberFormat('#,##,##,##0').format(totalSpent)}',
                      Icons.trending_down,
                      Colors.orange,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _buildOverviewItem(
                      'Remaining',
                      '\$${NumberFormat('#,##,##,##0').format(totalRemaining)}',
                      Icons.savings,
                      totalRemaining >= 0 ? Colors.green : Colors.red,
                    ),
                  ),
                  Expanded(
                    child: _buildOverviewItem(
                      'Utilization',
                      '${spendingPercentage.toStringAsFixed(1)}%',
                      Icons.pie_chart,
                      spendingPercentage > 80 ? Colors.red : Colors.purple,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildOverviewItem(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
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

  Widget _buildCategoryExpenseTracking() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Category-wise Expense Tracking',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 16),
        ..._categoryAnalytics.map((category) => _buildCategoryCard(category)),
      ],
    );
  }

  Widget _buildCategoryCard(CategoryAnalytics category) {
    final isOverBudget = category.spendingPercentage > 100;
    final isWarning = category.spendingPercentage > 80 && category.spendingPercentage <= 100;
    
    Color cardColor = Colors.white;
    Color borderColor = Colors.grey.shade200;
    
    if (isOverBudget) {
      cardColor = Colors.red.shade50;
      borderColor = Colors.red.shade200;
    } else if (isWarning) {
      cardColor = Colors.orange.shade50;
      borderColor = Colors.orange.shade200;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  category.categoryName,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: isOverBudget 
                      ? Colors.red.withOpacity(0.1)
                      : isWarning 
                          ? Colors.orange.withOpacity(0.1)
                          : Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${category.spendingPercentage.toStringAsFixed(1)}%',
                  style: TextStyle(
                    color: isOverBudget 
                        ? Colors.red
                        : isWarning 
                            ? Colors.orange
                            : Colors.green,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Allocated: \$${NumberFormat('#,##,##,##0').format(category.allocatedAmount)}',
                      style: const TextStyle(
                        color: Colors.grey,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Spent: \$${NumberFormat('#,##,##,##0').format(category.spentAmount)}',
                      style: const TextStyle(
                        color: Colors.grey,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Remaining: \$${NumberFormat('#,##,##,##0').format(category.allocatedAmount - category.spentAmount)}',
                      style: TextStyle(
                        color: (category.allocatedAmount - category.spentAmount) >= 0 
                            ? Colors.green 
                            : Colors.red,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              if (isOverBudget || isWarning)
                Icon(
                  isOverBudget ? Icons.error : Icons.warning,
                  color: isOverBudget ? Colors.red : Colors.orange,
                  size: 24,
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRecentTransactions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Recent Transactions',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 16),
        Container(
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
          child: _recentTransactions.isEmpty
              ? const Padding(
                  padding: EdgeInsets.all(32),
                  child: Center(
                    child: Text(
                      'No recent transactions found',
                      style: TextStyle(
                        color: Colors.grey,
                        fontSize: 16,
                      ),
                    ),
                  ),
                )
              : Column(
                  children: _recentTransactions.map((transaction) => _buildTransactionItem(transaction)).toList(),
                ),
        ),
      ],
    );
  }

  Widget _buildTransactionItem(Transaction transaction) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: Colors.grey.shade200,
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: transaction.type == 'income' 
                  ? Colors.green.withOpacity(0.1)
                  : Colors.red.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              transaction.type == 'income' ? Icons.trending_up : Icons.trending_down,
              color: transaction.type == 'income' ? Colors.green : Colors.red,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  transaction.description,
                  style: const TextStyle(
                    fontWeight: FontWeight.w500,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${transaction.categoryName}${transaction.subcategoryName != null ? ' - ${transaction.subcategoryName}' : ''}',
                  style: const TextStyle(
                    color: Colors.grey,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  DateFormat('MMM dd, yyyy').format(transaction.date),
                  style: const TextStyle(
                    color: Colors.grey,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                transaction.formattedAmount,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: transaction.type == 'income' ? Colors.green : Colors.red,
                ),
              ),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: transaction.type == 'income' 
                      ? Colors.green.withOpacity(0.1)
                      : Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  transaction.type.toUpperCase(),
                  style: TextStyle(
                    color: transaction.type == 'income' ? Colors.green : Colors.red,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
