import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/auth_service.dart';
import '../services/budget_service.dart';
import '../models/user_role.dart';
import '../models/budget_models.dart';
import 'budget_dashboard_screen.dart';
import 'budget_analytics_screen.dart';
import 'add_transaction_screen.dart';
import 'expense_tracking_screen.dart';
import 'transaction_list_screen.dart';
import 'financial_reports_screen.dart';
import '../utils/generate_budget_data.dart';
import 'login_screen.dart';

class FinanceOfficerDashboardScreen extends StatefulWidget {
  const FinanceOfficerDashboardScreen({super.key});

  @override
  State<FinanceOfficerDashboardScreen> createState() => _FinanceOfficerDashboardScreenState();
}

class _FinanceOfficerDashboardScreenState extends State<FinanceOfficerDashboardScreen> {
  final AuthService _authService = AuthService();
  final BudgetService _budgetService = BudgetService();
  UserRole? userRole;
  Map<String, dynamic>? userData;
  bool isLoading = true;
  Map<String, dynamic>? budgetStats;
  Map<String, dynamic>? transactionStats;
  List<CategoryAnalytics> categoryAnalytics = [];
  String selectedCurrency = 'USD';

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final user = _authService.currentUser;
    if (user != null) {
      final role = await _authService.getUserRole(user.uid);
      final data = await _authService.getUserData(user.uid);
      
      // Load budget and transaction statistics
      try {
        final budgetStatsData = await _budgetService.getBudgetStatistics();
        final transactionStatsData = await _budgetService.getTransactionStatistics();
        final analytics = await _budgetService.getBudgetAnalytics();
        
        setState(() {
          userRole = role;
          userData = data;
          budgetStats = budgetStatsData;
          transactionStats = transactionStatsData;
          categoryAnalytics = analytics.categoryAnalytics;
          isLoading = false;
        });
      } catch (e) {
        print('Error loading budget/transaction stats: $e');
        setState(() {
          userRole = role;
          userData = data;
          isLoading = false;
        });
      }
    }
  }

  Future<void> _signOut() async {
    try {
      await _authService.signOut();
      if (mounted) {
        // Navigate to splash screen to maintain proper flow
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const LoginScreen()),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error signing out: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: const Text('Finance Officer Dashboard'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          _buildNotificationIcon(),
          IconButton(
            icon: const Icon(Icons.data_usage),
            onPressed: _generateSampleData,
            tooltip: 'Generate Sample Data',
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _signOut,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Welcome Section
            _buildWelcomeCard(),
            const SizedBox(height: 24),

            // Quick Stats
            _buildQuickStats(),
            const SizedBox(height: 24),

            // Main Features
            _buildMainFeatures(),
            const SizedBox(height: 24),

            // Recent Activities
            _buildRecentActivities(),
          ],
        ),
      ),
    );
  }

  Widget _buildWelcomeCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Colors.green, Colors.greenAccent],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.green.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.account_balance_wallet,
              color: Colors.white,
              size: 32,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Welcome, ${userData?['firstName'] ?? 'Finance Officer'}!',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Manage budgets, track expenses, and ensure financial transparency',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.white,
                    fontWeight: FontWeight.w300,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickStats() {
    final totalBudget = budgetStats?['totalAllocated'] ?? 0.0;
    final totalSpent = budgetStats?['totalSpent'] ?? 0.0;
    final remaining = budgetStats?['totalRemaining'] ?? 0.0;
    final totalIncome = transactionStats?['totalIncome'] ?? 0.0;
    final totalExpense = transactionStats?['totalExpense'] ?? 0.0;
    final netAmount = transactionStats?['netAmount'] ?? 0.0;
    
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      childAspectRatio: 1.5,
      children: [
        _buildStatCard(
          'Total Budget',
          _formatCurrency(totalBudget),
          Icons.account_balance,
          Colors.blue,
        ),
        _buildStatCard(
          'Total Spent',
          _formatCurrency(totalSpent),
          Icons.trending_down,
          Colors.orange,
        ),
        _buildStatCard(
          'Remaining',
          _formatCurrency(remaining),
          Icons.savings,
          remaining >= 0 ? Colors.green : Colors.red,
        ),
        _buildStatCard(
          'Net Income',
          _formatCurrency(netAmount),
          Icons.trending_up,
          netAmount >= 0 ? Colors.green : Colors.red,
        ),
      ],
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
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
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            color: color,
            size: 32,
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
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

  Widget _buildMainFeatures() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Financial Management Tools',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 16),
        _buildFeatureCard(
          'Budget Management',
          'Create, monitor, and adjust government budgets',
          Icons.account_balance_wallet,
          Colors.green,
          () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const BudgetDashboardScreen(),
            ),
          ),
        ),
        _buildFeatureCard(
          'Add Transaction',
          'Add new income or expense transactions',
          Icons.add_circle_outline,
          Colors.blue,
          () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const AddTransactionScreen(),
            ),
          ),
        ),
        _buildFeatureCard(
          'View Transactions',
          'View, edit, and manage all transactions',
          Icons.list_alt,
          Colors.teal,
          () => _showTransactionOptions(),
        ),
        _buildFeatureCard(
          'Expense Tracking',
          'Track expenses and monitor over-budget alerts',
          Icons.trending_up,
          Colors.orange,
          () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const ExpenseTrackingScreen(),
            ),
          ),
        ),
        _buildFeatureCard(
          'Financial Reports',
          'Generate comprehensive financial reports and statements',
          Icons.receipt_long,
          Colors.purple,
          () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const FinancialReportsScreen(),
            ),
          ),
        ),
        _buildFeatureCard(
          'Financial Analytics',
          'Advanced analytics and financial insights',
          Icons.analytics,
          Colors.indigo,
          () => _showFinancialAnalytics(),
        ),
      ],
    );
  }

  Widget _buildFeatureCard(String title, String description, IconData icon, Color color, VoidCallback onTap) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: color, size: 24),
        ),
        title: Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        subtitle: Text(
          description,
          style: const TextStyle(
            color: Colors.grey,
            fontSize: 14,
          ),
        ),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: onTap,
      ),
    );
  }

  Widget _buildRecentActivities() {
    final transactionCount = transactionStats?['transactionCount'] ?? 0;
    final totalIncome = transactionStats?['totalIncome'] ?? 0.0;
    final totalExpense = transactionStats?['totalExpense'] ?? 0.0;
    final spendingPercentage = budgetStats?['spendingPercentage'] ?? 0.0;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Financial Overview',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 16),
        Container(
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
              _buildActivityItem(
                'Total Transactions',
                '$transactionCount transactions recorded',
                Icons.receipt_long,
                Colors.blue,
              ),
              _buildActivityItem(
                'Total Income',
                '${_formatCurrency(totalIncome)} received',
                Icons.trending_up,
                Colors.green,
              ),
              _buildActivityItem(
                'Total Expenses',
                '${_formatCurrency(totalExpense)} spent',
                Icons.trending_down,
                Colors.orange,
              ),
              _buildActivityItem(
                'Budget Utilization',
                '${spendingPercentage.toStringAsFixed(1)}% of budget used',
                Icons.pie_chart,
                spendingPercentage > 80 ? Colors.red : Colors.purple,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildActivityItem(String title, String time, IconData icon, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w500,
                    fontSize: 14,
                  ),
                ),
                Text(
                  time,
                  style: const TextStyle(
                    color: Colors.grey,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showFeatureComingSoon(String featureName) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$featureName feature coming soon!'),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<void> _generateSampleData() async {
    try {
      await BudgetDataGenerator.generateSampleBudgetData();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Sample budget data generated successfully!'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error generating sample data: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  Widget _buildNotificationIcon() {
    final overBudgetCount = categoryAnalytics.where((category) => 
        category.spendingPercentage > 100).length;
    final warningCount = categoryAnalytics.where((category) => 
        category.spendingPercentage > 80 && category.spendingPercentage <= 100).length;
    final totalAlerts = overBudgetCount + warningCount;

    return Stack(
      children: [
        IconButton(
          icon: const Icon(Icons.notifications),
          onPressed: _showNotificationSelector,
          tooltip: 'Notifications',
        ),
        if (totalAlerts > 0)
          Positioned(
            right: 8,
            top: 8,
            child: Container(
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                color: overBudgetCount > 0 ? Colors.red : Colors.orange,
                borderRadius: BorderRadius.circular(10),
              ),
              constraints: const BoxConstraints(
                minWidth: 16,
                minHeight: 16,
              ),
              child: Text(
                '$totalAlerts',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
      ],
    );
  }

  void _showTransactionOptions() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Transaction Options'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.list_alt, color: Colors.teal),
              title: const Text('View All Transactions'),
              subtitle: const Text('Browse and manage transactions'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const TransactionListScreen(),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.currency_exchange, color: Colors.blue),
              title: const Text('Change Currency'),
              subtitle: const Text('Select display currency'),
              onTap: () {
                Navigator.pop(context);
                _showCurrencyDialog();
              },
            ),
          ],
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

  void _showFinancialAnalytics() {
    final totalBudget = budgetStats?['totalAllocated'] ?? 0.0;
    final totalSpent = budgetStats?['totalSpent'] ?? 0.0;
    final totalRemaining = budgetStats?['totalRemaining'] ?? 0.0;
    final spendingPercentage = totalBudget > 0 ? (totalSpent / totalBudget) * 100 : 0;
    
    final overBudgetCount = categoryAnalytics.where((category) => 
        category.spendingPercentage > 100).length;
    final warningCount = categoryAnalytics.where((category) => 
        category.spendingPercentage > 80 && category.spendingPercentage <= 100).length;
    final healthyCount = categoryAnalytics.where((category) => 
        category.spendingPercentage <= 80).length;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Financial Analytics'),
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Budget Overview
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Budget Overview',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _buildAnalyticsItem(
                            'Total Budget',
                            _formatCurrency(totalBudget),
                            Icons.account_balance,
                            Colors.blue,
                          ),
                        ),
                        Expanded(
                          child: _buildAnalyticsItem(
                            'Total Spent',
                            _formatCurrency(totalSpent),
                            Icons.trending_down,
                            Colors.orange,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: _buildAnalyticsItem(
                            'Remaining',
                            _formatCurrency(totalRemaining),
                            Icons.savings,
                            totalRemaining >= 0 ? Colors.green : Colors.red,
                          ),
                        ),
                        Expanded(
                          child: _buildAnalyticsItem(
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
              const SizedBox(height: 16),
              
              // Category Status
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Category Status',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _buildAnalyticsItem(
                            'Healthy',
                            '$healthyCount',
                            Icons.check_circle,
                            Colors.green,
                          ),
                        ),
                        Expanded(
                          child: _buildAnalyticsItem(
                            'Warning',
                            '$warningCount',
                            Icons.warning,
                            Colors.orange,
                          ),
                        ),
                        Expanded(
                          child: _buildAnalyticsItem(
                            'Over Budget',
                            '$overBudgetCount',
                            Icons.error,
                            Colors.red,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              
              // Quick Actions
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.purple.shade50,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Quick Actions',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ListTile(
                      leading: const Icon(Icons.trending_up, color: Colors.orange),
                      title: const Text('View Expense Tracking'),
                      subtitle: const Text('Monitor budget alerts'),
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const ExpenseTrackingScreen(),
                          ),
                        );
                      },
                    ),
                    ListTile(
                      leading: const Icon(Icons.analytics, color: Colors.indigo),
                      title: const Text('View Budget Analytics'),
                      subtitle: const Text('Detailed budget analysis'),
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const BudgetAnalyticsScreen(),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
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

  Widget _buildAnalyticsItem(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: color,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(
              color: Colors.grey,
              fontSize: 10,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  void _showNotificationSelector() {
    final overBudgetCount = categoryAnalytics.where((category) => 
        category.spendingPercentage > 100).length;
    final warningCount = categoryAnalytics.where((category) => 
        category.spendingPercentage > 80 && category.spendingPercentage <= 100).length;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Notifications'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (overBudgetCount > 0)
              ListTile(
                leading: const Icon(Icons.error, color: Colors.red),
                title: Text('Over Budget Categories ($overBudgetCount)'),
                subtitle: const Text('Categories exceeding budget limits'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const ExpenseTrackingScreen(),
                    ),
                  );
                },
              ),
            if (warningCount > 0)
              ListTile(
                leading: const Icon(Icons.warning, color: Colors.orange),
                title: Text('Budget Warnings ($warningCount)'),
                subtitle: const Text('Categories approaching budget limits'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const ExpenseTrackingScreen(),
                    ),
                  );
                },
              ),
            if (overBudgetCount == 0 && warningCount == 0)
              const ListTile(
                leading: Icon(Icons.check_circle, color: Colors.green),
                title: Text('All Good!'),
                subtitle: Text('No budget alerts at this time'),
              ),
          ],
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

  void _showCurrencyDialog() {
    final currencies = [
      {'code': 'USD', 'symbol': '\$', 'name': 'US Dollar'},
      {'code': 'EUR', 'symbol': '€', 'name': 'Euro'},
      {'code': 'GBP', 'symbol': '£', 'name': 'British Pound'},
      {'code': 'JPY', 'symbol': '¥', 'name': 'Japanese Yen'},
      {'code': 'CAD', 'symbol': 'C\$', 'name': 'Canadian Dollar'},
      {'code': 'AUD', 'symbol': 'A\$', 'name': 'Australian Dollar'},
      {'code': 'INR', 'symbol': '₹', 'name': 'Indian Rupee'},
      {'code': 'CNY', 'symbol': '¥', 'name': 'Chinese Yuan'},
      {'code': 'LKR', 'symbol': 'Rs', 'name': 'Sri Lankan Rupee'},
    ];

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Currency'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: currencies.length,
            itemBuilder: (context, index) {
              final currency = currencies[index];
              final isSelected = selectedCurrency == currency['code'];
              
              return ListTile(
                leading: Text(
                  currency['symbol'] as String,
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                title: Text(currency['name'] as String),
                subtitle: Text(currency['code'] as String),
                trailing: isSelected ? const Icon(Icons.check, color: Colors.green) : null,
                onTap: () {
                  setState(() {
                    selectedCurrency = currency['code'] as String;
                  });
                  Navigator.pop(context);
                },
              );
            },
          ),
        ),
      ),
    );
  }

  String _formatCurrency(double amount) {
    final currencySymbols = {
      'USD': '\$',
      'EUR': '€',
      'GBP': '£',
      'JPY': '¥',
      'CAD': 'C\$',
      'AUD': 'A\$',
      'INR': '₹',
      'CNY': '¥',
      'LKR': 'Rs',
    };
    
    final symbol = currencySymbols[selectedCurrency] ?? '\$';
    return '$symbol${NumberFormat('#,##,##,##0').format(amount)}';
  }
}
