import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/budget_service.dart';

class ReportsAnalyticsScreen extends StatefulWidget {
  const ReportsAnalyticsScreen({super.key});

  @override
  State<ReportsAnalyticsScreen> createState() => _ReportsAnalyticsScreenState();
}

class _ReportsAnalyticsScreenState extends State<ReportsAnalyticsScreen>
    with TickerProviderStateMixin {
  final BudgetService _budgetService = BudgetService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  // Analytics Data
  Map<String, dynamic> _budgetAnalytics = {};
  Map<String, dynamic> _tenderAnalytics = {};
  Map<String, dynamic> _projectAnalytics = {};
  Map<String, dynamic> _concernAnalytics = {};
  Map<String, dynamic> _mediaAnalytics = {};
  
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _loadAnalyticsData();
  }

  void _initializeAnimations() {
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _slideController = AnimationController(
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
    
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutCubic,
    ));
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  Future<void> _loadAnalyticsData() async {
    try {
      setState(() => _isLoading = true);
      
      // Load all analytics data in parallel
      await Future.wait([
        _loadBudgetAnalytics(),
        _loadTenderAnalytics(),
        _loadProjectAnalytics(),
        _loadConcernAnalytics(),
        _loadMediaAnalytics(),
      ]);
      
      setState(() => _isLoading = false);
      
      // Start animations
      _fadeController.forward();
      _slideController.forward();
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading analytics: $e')),
        );
      }
    }
  }

  Future<void> _loadBudgetAnalytics() async {
    try {
      final categories = await _budgetService.getBudgetCategories();
      double totalAllocated = 0;
      double totalSpent = 0;
      int totalItems = 0;
      
      for (final category in categories) {
        totalAllocated += category.allocatedAmount;
        totalSpent += category.spentAmount;
        totalItems += category.subcategories.length;
      }
      
      _budgetAnalytics = {
        'totalAllocated': totalAllocated.toDouble(),
        'totalSpent': totalSpent.toDouble(),
        'remaining': (totalAllocated - totalSpent).toDouble(),
        'spendingPercentage': totalAllocated > 0 ? (totalSpent / totalAllocated) * 100 : 0.0,
        'totalCategories': categories.length,
        'totalItems': totalItems,
      };
    } catch (e) {
      _budgetAnalytics = {
        'totalAllocated': 0.0,
        'totalSpent': 0.0,
        'remaining': 0.0,
        'spendingPercentage': 0.0,
        'totalCategories': 0,
        'totalItems': 0,
      };
    }
  }

  Future<void> _loadTenderAnalytics() async {
    try {
      final tendersSnapshot = await _firestore.collection('tenders').get();
      final tenders = tendersSnapshot.docs;
      
      print('📊 Loading tender analytics: ${tenders.length} tenders found');
      
      int activeTenders = 0;
      int completedTenders = 0;
      int pendingTenders = 0;
      double totalTenderValue = 0;
      
      for (final tender in tenders) {
        final data = tender.data();
        final status = data['status'] ?? 'pending';
        final value = (data['estimatedValue'] ?? 0).toDouble();
        
        totalTenderValue += value;
        
        switch (status.toLowerCase()) {
          case 'active':
            activeTenders++;
            break;
          case 'completed':
            completedTenders++;
            break;
          case 'pending':
            pendingTenders++;
            break;
        }
      }
      
      _tenderAnalytics = {
        'totalTenders': tenders.length,
        'activeTenders': activeTenders,
        'completedTenders': completedTenders,
        'pendingTenders': pendingTenders,
        'totalValue': totalTenderValue.toDouble(),
        'averageValue': tenders.isNotEmpty ? totalTenderValue / tenders.length : 0.0,
      };
      
      print('📊 Tender analytics loaded: ${_tenderAnalytics['totalTenders']} total tenders');
    } catch (e) {
      print('❌ Error loading tender analytics: $e');
      _tenderAnalytics = {
        'totalTenders': 0,
        'activeTenders': 0,
        'completedTenders': 0,
        'pendingTenders': 0,
        'totalValue': 0.0,
        'averageValue': 0.0,
      };
    }
  }

  Future<void> _loadProjectAnalytics() async {
    try {
      final projectsSnapshot = await _firestore.collection('projects').get();
      final projects = projectsSnapshot.docs;
      
      print('📊 Loading project analytics: ${projects.length} projects found');
      
      int activeProjects = 0;
      int completedProjects = 0;
      int pendingProjects = 0;
      double totalProjectValue = 0;
      
      for (final project in projects) {
        final data = project.data();
        final status = data['status'] ?? 'pending';
        final value = (data['budget'] ?? 0).toDouble();
        
        totalProjectValue += value;
        
        switch (status.toLowerCase()) {
          case 'active':
            activeProjects++;
            break;
          case 'completed':
            completedProjects++;
            break;
          case 'pending':
            pendingProjects++;
            break;
        }
      }
      
      _projectAnalytics = {
        'totalProjects': projects.length,
        'activeProjects': activeProjects,
        'completedProjects': completedProjects,
        'pendingProjects': pendingProjects,
        'totalValue': totalProjectValue.toDouble(),
        'averageValue': projects.isNotEmpty ? totalProjectValue / projects.length : 0.0,
      };
      
      print('📊 Project analytics loaded: ${_projectAnalytics['totalProjects']} total projects');
    } catch (e) {
      print('❌ Error loading project analytics: $e');
      _projectAnalytics = {
        'totalProjects': 0,
        'activeProjects': 0,
        'completedProjects': 0,
        'pendingProjects': 0,
        'totalValue': 0.0,
        'averageValue': 0.0,
      };
    }
  }

  Future<void> _loadConcernAnalytics() async {
    try {
      final concernsSnapshot = await _firestore.collection('concerns').get();
      final concerns = concernsSnapshot.docs;
      
      print('📊 Loading concern analytics: ${concerns.length} concerns found');
      
      int newConcerns = 0;
      int inProgressConcerns = 0;
      int resolvedConcerns = 0;
      int closedConcerns = 0;
      
      for (final concern in concerns) {
        final data = concern.data();
        final status = data['status'] ?? 'new';
        
        switch (status.toLowerCase()) {
          case 'new':
            newConcerns++;
            break;
          case 'in_progress':
            inProgressConcerns++;
            break;
          case 'resolved':
            resolvedConcerns++;
            break;
          case 'closed':
            closedConcerns++;
            break;
        }
      }
      
      _concernAnalytics = {
        'totalConcerns': concerns.length,
        'newConcerns': newConcerns,
        'inProgressConcerns': inProgressConcerns,
        'resolvedConcerns': resolvedConcerns,
        'closedConcerns': closedConcerns,
        'resolutionRate': concerns.isNotEmpty ? (resolvedConcerns / concerns.length) * 100 : 0.0,
      };
      
      print('📊 Concern analytics loaded: ${_concernAnalytics['totalConcerns']} total concerns');
    } catch (e) {
      print('❌ Error loading concern analytics: $e');
      _concernAnalytics = {
        'totalConcerns': 0,
        'newConcerns': 0,
        'inProgressConcerns': 0,
        'resolvedConcerns': 0,
        'closedConcerns': 0,
        'resolutionRate': 0.0,
      };
    }
  }

  Future<void> _loadMediaAnalytics() async {
    try {
      final mediaSnapshot = await _firestore.collection('media').get();
      final media = mediaSnapshot.docs;
      
      int totalMedia = media.length;
      double totalViews = 0;
      double totalLikes = 0;
      double totalShares = 0;
      
      for (final item in media) {
        final data = item.data();
        totalViews += (data['views'] ?? 0);
        totalLikes += (data['likes'] ?? 0);
        totalShares += (data['shares'] ?? 0);
      }
      
      _mediaAnalytics = {
        'totalMedia': totalMedia,
        'totalViews': totalViews.toDouble(),
        'totalLikes': totalLikes.toDouble(),
        'totalShares': totalShares.toDouble(),
        'averageViews': totalMedia > 0 ? totalViews / totalMedia : 0.0,
        'engagementRate': totalViews > 0 ? ((totalLikes + totalShares) / totalViews) * 100 : 0.0,
      };
    } catch (e) {
      _mediaAnalytics = {
        'totalMedia': 0,
        'totalViews': 0.0,
        'totalLikes': 0.0,
        'totalShares': 0.0,
        'averageViews': 0.0,
        'engagementRate': 0.0,
      };
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text(
          'Reports & Analytics',
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
            onPressed: _loadAnalyticsData,
            tooltip: 'Refresh Analytics',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : FadeTransition(
              opacity: _fadeAnimation,
              child: SlideTransition(
                position: _slideAnimation,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 48),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildOverviewCards(),
                      const SizedBox(height: 12),
                      _buildBudgetAnalytics(),
                      const SizedBox(height: 12),
                      _buildTenderAnalytics(),
                      const SizedBox(height: 12),
                      _buildProjectAnalytics(),
                      const SizedBox(height: 12),
                      _buildConcernAnalytics(),
                      const SizedBox(height: 12),
                      _buildMediaAnalytics(),
                    ],
                  ),
                ),
              ),
            ),
    );
  }

  Widget _buildOverviewCards() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Quick Overview',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 16),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          childAspectRatio: 1.8,
          crossAxisSpacing: 8,
          mainAxisSpacing: 8,
          children: [
            _buildOverviewCard(
              'Budget',
              '${_budgetAnalytics['totalCategories'] ?? 0}',
              'Categories',
              Icons.account_balance_wallet,
              Colors.blue,
            ),
            _buildOverviewCard(
              'Tenders',
              '${_tenderAnalytics['totalTenders'] ?? 0}',
              'Total',
              Icons.shopping_cart,
              Colors.orange,
            ),
            _buildOverviewCard(
              'Projects',
              '${_projectAnalytics['totalProjects'] ?? 0}',
              'Total',
              Icons.work,
              Colors.green,
            ),
            _buildOverviewCard(
              'Concerns',
              '${_concernAnalytics['totalConcerns'] ?? 0}',
              'Total',
              Icons.report_problem,
              Colors.red,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildOverviewCard(String title, String value, String subtitle, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Icon(icon, color: color, size: 14),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            title,
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
            textAlign: TextAlign.center,
          ),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 8,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildBudgetAnalytics() {
    return _buildAnalyticsSection(
      'Budget Analytics',
      Icons.account_balance_wallet,
      Colors.blue,
      [
        _buildMetricCard('Total Allocated', '\$${_formatNumber(_budgetAnalytics['totalAllocated'] ?? 0)}', Colors.blue),
        _buildMetricCard('Total Spent', '\$${_formatNumber(_budgetAnalytics['totalSpent'] ?? 0)}', Colors.orange),
        _buildMetricCard('Remaining', '\$${_formatNumber(_budgetAnalytics['remaining'] ?? 0)}', Colors.green),
        _buildMetricCard('Spending %', '${(_budgetAnalytics['spendingPercentage'] ?? 0).toStringAsFixed(1)}%', Colors.purple),
      ],
      _buildBudgetChart(),
    );
  }

  Widget _buildTenderAnalytics() {
    return _buildAnalyticsSection(
      'Tender Analytics',
      Icons.shopping_cart,
      Colors.orange,
      [
        _buildMetricCard('Total Tenders', '${_tenderAnalytics['totalTenders'] ?? 0}', Colors.blue),
        _buildMetricCard('Active', '${_tenderAnalytics['activeTenders'] ?? 0}', Colors.orange),
        _buildMetricCard('Completed', '${_tenderAnalytics['completedTenders'] ?? 0}', Colors.green),
        _buildMetricCard('Pending', '${_tenderAnalytics['pendingTenders'] ?? 0}', Colors.red),
      ],
      null, // Remove the chart
    );
  }

  Widget _buildProjectAnalytics() {
    return _buildAnalyticsSection(
      'Project Analytics',
      Icons.work,
      Colors.green,
      [
        _buildMetricCard('Total Projects', '${_projectAnalytics['totalProjects'] ?? 0}', Colors.blue),
        _buildMetricCard('Active', '${_projectAnalytics['activeProjects'] ?? 0}', Colors.green),
        _buildMetricCard('Completed', '${_projectAnalytics['completedProjects'] ?? 0}', Colors.blue),
        _buildMetricCard('Pending', '${_projectAnalytics['pendingProjects'] ?? 0}', Colors.orange),
      ],
      null, // Remove the chart
    );
  }

  Widget _buildConcernAnalytics() {
    return _buildAnalyticsSection(
      'Concern Analytics',
      Icons.report_problem,
      Colors.red,
      [
        _buildMetricCard('Total Concerns', '${_concernAnalytics['totalConcerns'] ?? 0}', Colors.blue),
        _buildMetricCard('New', '${_concernAnalytics['newConcerns'] ?? 0}', Colors.red),
        _buildMetricCard('In Progress', '${_concernAnalytics['inProgressConcerns'] ?? 0}', Colors.orange),
        _buildMetricCard('Resolved', '${_concernAnalytics['resolvedConcerns'] ?? 0}', Colors.green),
      ],
      null, // Remove the chart
    );
  }

  Widget _buildMediaAnalytics() {
    return _buildAnalyticsSection(
      'Media Analytics',
      Icons.media_bluetooth_on,
      Colors.purple,
      [
        _buildMetricCard('Total Media', '${_mediaAnalytics['totalMedia'] ?? 0}', Colors.blue),
        _buildMetricCard('Total Views', _formatNumber(_mediaAnalytics['totalViews'] ?? 0), Colors.purple),
        _buildMetricCard('Total Likes', _formatNumber(_mediaAnalytics['totalLikes'] ?? 0), Colors.red),
        _buildMetricCard('Engagement %', '${(_mediaAnalytics['engagementRate'] ?? 0).toStringAsFixed(1)}%', Colors.green),
      ],
      null, // Remove the chart
    );
  }

  Widget _buildAnalyticsSection(String title, IconData icon, Color color, List<Widget> metrics, Widget? chart) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            childAspectRatio: 3.5,
            crossAxisSpacing: 6,
            mainAxisSpacing: 6,
            children: metrics,
          ),
          if (chart != null) ...[
            const SizedBox(height: 12),
            SizedBox(
              height: 160,
              child: chart,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMetricCard(String title, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: color,
            ),
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
          ),
          const SizedBox(height: 2),
          Text(
            title,
            style: TextStyle(
              fontSize: 9,
              color: Colors.grey[600],
            ),
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
          ),
        ],
      ),
    );
  }

  Widget _buildBudgetChart() {
    final spent = (_budgetAnalytics['totalSpent'] ?? 0).toDouble();
    final remaining = (_budgetAnalytics['remaining'] ?? 0).toDouble();
    final total = spent + remaining;
    
    if (total == 0) {
      return const Center(
        child: Text('No budget data available'),
      );
    }
    
    return PieChart(
      PieChartData(
        sections: [
          PieChartSectionData(
            value: spent,
            title: 'Spent\n${((spent / total) * 100).toStringAsFixed(1)}%',
            color: Colors.orange,
            radius: 60,
            titleStyle: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          PieChartSectionData(
            value: remaining,
            title: 'Remaining\n${((remaining / total) * 100).toStringAsFixed(1)}%',
            color: Colors.green,
            radius: 60,
            titleStyle: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ],
        sectionsSpace: 2,
        centerSpaceRadius: 40,
      ),
    );
  }

  Widget _buildTenderChart() {
    final active = (_tenderAnalytics['activeTenders'] ?? 0).toDouble();
    final completed = (_tenderAnalytics['completedTenders'] ?? 0).toDouble();
    final pending = (_tenderAnalytics['pendingTenders'] ?? 0).toDouble();
    
    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: [active, completed, pending].reduce((a, b) => a > b ? a : b) + 1,
        barGroups: [
          BarChartGroupData(x: 0, barRods: [BarChartRodData(toY: active.toDouble(), color: Colors.orange)]),
          BarChartGroupData(x: 1, barRods: [BarChartRodData(toY: completed.toDouble(), color: Colors.green)]),
          BarChartGroupData(x: 2, barRods: [BarChartRodData(toY: pending.toDouble(), color: Colors.red)]),
        ],
        titlesData: FlTitlesData(
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                switch (value.toInt()) {
                  case 0: return const Text('Active');
                  case 1: return const Text('Completed');
                  case 2: return const Text('Pending');
                  default: return const Text('');
                }
              },
            ),
          ),
          leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
      ),
    );
  }

  Widget _buildProjectChart() {
    final active = (_projectAnalytics['activeProjects'] ?? 0).toDouble();
    final completed = (_projectAnalytics['completedProjects'] ?? 0).toDouble();
    final pending = (_projectAnalytics['pendingProjects'] ?? 0).toDouble();
    
    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: [active, completed, pending].reduce((a, b) => a > b ? a : b) + 1,
        barGroups: [
          BarChartGroupData(x: 0, barRods: [BarChartRodData(toY: active.toDouble(), color: Colors.green)]),
          BarChartGroupData(x: 1, barRods: [BarChartRodData(toY: completed.toDouble(), color: Colors.blue)]),
          BarChartGroupData(x: 2, barRods: [BarChartRodData(toY: pending.toDouble(), color: Colors.orange)]),
        ],
        titlesData: FlTitlesData(
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                switch (value.toInt()) {
                  case 0: return const Text('Active');
                  case 1: return const Text('Completed');
                  case 2: return const Text('Pending');
                  default: return const Text('');
                }
              },
            ),
          ),
          leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
      ),
    );
  }

  Widget _buildConcernChart() {
    final newConcerns = (_concernAnalytics['newConcerns'] ?? 0).toDouble();
    final inProgress = (_concernAnalytics['inProgressConcerns'] ?? 0).toDouble();
    final resolved = (_concernAnalytics['resolvedConcerns'] ?? 0).toDouble();
    final closed = (_concernAnalytics['closedConcerns'] ?? 0).toDouble();
    
    return PieChart(
      PieChartData(
        sections: [
          PieChartSectionData(
            value: newConcerns.toDouble(),
            title: 'New\n$newConcerns',
            color: Colors.red,
            radius: 50,
            titleStyle: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white),
          ),
          PieChartSectionData(
            value: inProgress.toDouble(),
            title: 'Progress\n$inProgress',
            color: Colors.orange,
            radius: 50,
            titleStyle: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white),
          ),
          PieChartSectionData(
            value: resolved.toDouble(),
            title: 'Resolved\n$resolved',
            color: Colors.green,
            radius: 50,
            titleStyle: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white),
          ),
          PieChartSectionData(
            value: closed.toDouble(),
            title: 'Closed\n$closed',
            color: Colors.grey,
            radius: 50,
            titleStyle: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white),
          ),
        ],
        sectionsSpace: 2,
        centerSpaceRadius: 30,
      ),
    );
  }

  Widget _buildMediaChart() {
    final views = (_mediaAnalytics['totalViews'] ?? 0).toDouble();
    final likes = (_mediaAnalytics['totalLikes'] ?? 0).toDouble();
    final shares = (_mediaAnalytics['totalShares'] ?? 0).toDouble();
    
    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: [views, likes, shares].reduce((a, b) => a > b ? a : b) + 1,
        barGroups: [
          BarChartGroupData(x: 0, barRods: [BarChartRodData(toY: views.toDouble(), color: Colors.purple)]),
          BarChartGroupData(x: 1, barRods: [BarChartRodData(toY: likes.toDouble(), color: Colors.red)]),
          BarChartGroupData(x: 2, barRods: [BarChartRodData(toY: shares.toDouble(), color: Colors.blue)]),
        ],
        titlesData: FlTitlesData(
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                switch (value.toInt()) {
                  case 0: return const Text('Views');
                  case 1: return const Text('Likes');
                  case 2: return const Text('Shares');
                  default: return const Text('');
                }
              },
            ),
          ),
          leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
      ),
    );
  }

  String _formatNumber(dynamic value) {
    if (value is double) {
      if (value >= 1000000) {
        return '${(value / 1000000).toStringAsFixed(1)}M';
      } else if (value >= 1000) {
        return '${(value / 1000).toStringAsFixed(1)}K';
      } else {
        return value.toStringAsFixed(0);
      }
    }
    return value.toString();
  }
}
