import 'package:flutter/material.dart';
import '../services/transparency_service.dart';
import '../services/contract_analysis_service.dart';

/// TransparencyDashboardScreen - Enhanced transparency and accountability dashboard
/// 
/// This screen provides comprehensive transparency features that enhance
/// existing budget and tender data without modifying existing functionality.
class TransparencyDashboardScreen extends StatefulWidget {
  const TransparencyDashboardScreen({super.key});

  @override
  State<TransparencyDashboardScreen> createState() => _TransparencyDashboardScreenState();
}

class _TransparencyDashboardScreenState extends State<TransparencyDashboardScreen>
    with TickerProviderStateMixin {
  
  // Animation controllers
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  
  // Data
  Map<String, dynamic>? _transparencyReport;
  Map<String, dynamic>? _contractAnalysis;
  Map<String, dynamic>? _districtSpending;
  Map<String, dynamic>? _sectorPerformance;
  bool _isLoading = true;
  String? _errorMessage;
  
  // UI state
  int _selectedTab = 0;
  final List<String> _tabs = ['Overview', 'Contracts', 'Districts', 'Sectors'];

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _loadData();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  void _initializeAnimations() {
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 400),
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

  Future<void> _loadData() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      // Load all transparency data
      final results = await Future.wait([
        TransparencyService.getTransparencyReport(),
        ContractAnalysisService.analyzeContractPerformance(),
        TransparencyService.getDistrictSpending(),
        TransparencyService.getSectorPerformance(),
      ]);

      setState(() {
        _transparencyReport = results[0] as Map<String, dynamic>;
        _contractAnalysis = results[1] as Map<String, dynamic>;
        _districtSpending = results[2] as Map<String, dynamic>;
        _sectorPerformance = results[3] as Map<String, dynamic>;
        _isLoading = false;
      });

      // Start animations
      _fadeController.forward();
      _slideController.forward();
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Transparency Dashboard'),
        backgroundColor: const Color(0xFF2E4A62),
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
          : _errorMessage != null
              ? _buildErrorState()
              : _buildMainContent(),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 64, color: Colors.red),
          const SizedBox(height: 16),
          Text(
            'Error loading transparency data',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(
            _errorMessage!,
            style: Theme.of(context).textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _loadData,
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildMainContent() {
    return Column(
      children: [
        _buildTabBar(),
        Expanded(
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: SlideTransition(
              position: _slideAnimation,
              child: _buildTabContent(),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTabBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TabBar(
        controller: TabController(length: _tabs.length, vsync: this, initialIndex: _selectedTab),
        onTap: (index) {
          setState(() {
            _selectedTab = index;
          });
        },
        labelColor: const Color(0xFF2E4A62),
        unselectedLabelColor: Colors.grey,
        indicatorColor: const Color(0xFF2E4A62),
        tabs: _tabs.map((tab) => Tab(text: tab)).toList(),
      ),
    );
  }

  Widget _buildTabContent() {
    switch (_selectedTab) {
      case 0:
        return _buildOverviewTab();
      case 1:
        return _buildContractsTab();
      case 2:
        return _buildDistrictsTab();
      case 3:
        return _buildSectorsTab();
      default:
        return _buildOverviewTab();
    }
  }

  Widget _buildOverviewTab() {
    if (_transparencyReport == null) return const Center(child: CircularProgressIndicator());
    
    final report = _transparencyReport!;
    final transparencyScore = report['transparencyScore'] as double;
    final utilizationRate = report['utilizationRate'] as double;
    final totalAllocated = report['totalAllocated'] as double;
    final totalSpent = report['totalSpent'] as double;
    final remainingBudget = report['remainingBudget'] as double;
    final anomalies = report['anomalies'] as List<dynamic>;
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildTransparencyScoreCard(transparencyScore),
          const SizedBox(height: 16),
          _buildBudgetOverviewCard(totalAllocated, totalSpent, remainingBudget, utilizationRate),
          const SizedBox(height: 16),
          _buildAnomaliesCard(anomalies),
          const SizedBox(height: 16),
          _buildCategoriesCard(report['categories'] as List<dynamic>),
        ],
      ),
    );
  }

  Widget _buildTransparencyScoreCard(double score) {
    Color scoreColor;
    String scoreText;
    
    if (score >= 80) {
      scoreColor = Colors.green;
      scoreText = 'Excellent';
    } else if (score >= 60) {
      scoreColor = Colors.orange;
      scoreText = 'Good';
    } else {
      scoreColor = Colors.red;
      scoreText = 'Needs Improvement';
    }
    
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.visibility, color: scoreColor),
                const SizedBox(width: 8),
                const Text(
                  'Transparency Score',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${score.toStringAsFixed(1)}/100',
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: scoreColor,
                        ),
                      ),
                      Text(
                        scoreText,
                        style: TextStyle(
                          fontSize: 16,
                          color: scoreColor,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                CircularProgressIndicator(
                  value: score / 100,
                  backgroundColor: Colors.grey[300],
                  valueColor: AlwaysStoppedAnimation<Color>(scoreColor),
                  strokeWidth: 8,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBudgetOverviewCard(double allocated, double spent, double remaining, double utilization) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.account_balance, color: Colors.blue),
                SizedBox(width: 8),
                Text(
                  'Budget Overview',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildBudgetMetric(
                    'Total Allocated',
                    _formatCurrency(allocated),
                    Colors.blue,
                  ),
                ),
                Expanded(
                  child: _buildBudgetMetric(
                    'Total Spent',
                    _formatCurrency(spent),
                    Colors.green,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildBudgetMetric(
                    'Remaining',
                    _formatCurrency(remaining),
                    Colors.orange,
                  ),
                ),
                Expanded(
                  child: _buildBudgetMetric(
                    'Utilization',
                    '${utilization.toStringAsFixed(1)}%',
                    Colors.purple,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            LinearProgressIndicator(
              value: utilization / 100,
              backgroundColor: Colors.grey[300],
              valueColor: AlwaysStoppedAnimation<Color>(
                utilization > 100 ? Colors.red : Colors.green,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBudgetMetric(String label, String value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.grey,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildAnomaliesCard(List<dynamic> anomalies) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.warning,
                  color: anomalies.isNotEmpty ? Colors.orange : Colors.green,
                ),
                const SizedBox(width: 8),
                const Text(
                  'Budget Anomalies',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (anomalies.isEmpty)
              const Text(
                'No anomalies detected. Budget data looks healthy!',
                style: TextStyle(color: Colors.green, fontWeight: FontWeight.w500),
              )
            else
              Column(
                children: anomalies.map((anomaly) {
                  final type = anomaly['type'] as String;
                  final severity = anomaly['severity'] as String;
                  final category = anomaly['category'] as String;
                  
                  Color severityColor;
                  switch (severity) {
                    case 'high':
                      severityColor = Colors.red;
                      break;
                    case 'medium':
                      severityColor = Colors.orange;
                      break;
                    default:
                      severityColor = Colors.yellow;
                  }
                  
                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: severityColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: severityColor.withOpacity(0.3)),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.warning, color: severityColor, size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            '$type in $category',
                            style: TextStyle(
                              fontWeight: FontWeight.w500,
                              color: severityColor,
                            ),
                          ),
                        ),
                        Text(
                          severity.toUpperCase(),
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: severityColor,
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoriesCard(List<dynamic> categories) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.category, color: Colors.blue),
                SizedBox(width: 8),
                Text(
                  'Category Performance',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...categories.map((category) {
              final name = category['name'] as String;
              final utilization = category['utilization'] as double;
              final transparency = category['transparency'] as double;
              
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          name,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                          ),
                        ),
                        Text(
                          '${utilization.toStringAsFixed(1)}%',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: utilization > 100 ? Colors.red : Colors.green,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    LinearProgressIndicator(
                      value: utilization / 100,
                      backgroundColor: Colors.grey[300],
                      valueColor: AlwaysStoppedAnimation<Color>(
                        utilization > 100 ? Colors.red : Colors.green,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Transparency: ${transparency.toStringAsFixed(1)}%',
                          style: const TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                        Text(
                          'Allocated: ${_formatCurrency(category['allocated'] as double)}',
                          style: const TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildContractsTab() {
    if (_contractAnalysis == null) return const Center(child: CircularProgressIndicator());
    
    final analysis = _contractAnalysis!;
    final performanceMetrics = analysis['performanceMetrics'] as Map<String, dynamic>;
    final suspiciousPatterns = analysis['suspiciousPatterns'] as List<dynamic>;
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildContractPerformanceCard(performanceMetrics),
          const SizedBox(height: 16),
          _buildSuspiciousPatternsCard(suspiciousPatterns),
        ],
      ),
    );
  }

  Widget _buildContractPerformanceCard(Map<String, dynamic> metrics) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.analytics, color: Colors.blue),
                SizedBox(width: 8),
                Text(
                  'Contract Performance',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildPerformanceMetric(
                    'On-Time Delivery',
                    '${metrics['onTimeDelivery'].toStringAsFixed(1)}%',
                    Colors.green,
                  ),
                ),
                Expanded(
                  child: _buildPerformanceMetric(
                    'Budget Accuracy',
                    '${metrics['budgetAccuracy'].toStringAsFixed(1)}%',
                    Colors.blue,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildPerformanceMetric(
                    'Quality Score',
                    '${metrics['qualityScore'].toStringAsFixed(1)}%',
                    Colors.purple,
                  ),
                ),
                Expanded(
                  child: _buildPerformanceMetric(
                    'Completion Rate',
                    '${metrics['completionRate'].toStringAsFixed(1)}%',
                    Colors.orange,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPerformanceMetric(String label, String value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.grey,
            fontWeight: FontWeight.w500,
          ),
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
      ],
    );
  }

  Widget _buildSuspiciousPatternsCard(List<dynamic> patterns) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.security,
                  color: patterns.isNotEmpty ? Colors.red : Colors.green,
                ),
                const SizedBox(width: 8),
                const Text(
                  'Suspicious Patterns',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (patterns.isEmpty)
              const Text(
                'No suspicious patterns detected. Contract data looks clean!',
                style: TextStyle(color: Colors.green, fontWeight: FontWeight.w500),
              )
            else
              Column(
                children: patterns.map((pattern) {
                  final type = pattern['type'] as String;
                  final severity = pattern['severity'] as String;
                  final description = pattern['description'] as String;
                  
                  Color severityColor;
                  switch (severity) {
                    case 'high':
                      severityColor = Colors.red;
                      break;
                    case 'medium':
                      severityColor = Colors.orange;
                      break;
                    default:
                      severityColor = Colors.yellow;
                  }
                  
                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: severityColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: severityColor.withOpacity(0.3)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.warning, color: severityColor, size: 20),
                            const SizedBox(width: 8),
                            Text(
                              type.replaceAll('_', ' ').toUpperCase(),
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: severityColor,
                              ),
                            ),
                            const Spacer(),
                            Text(
                              severity.toUpperCase(),
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: severityColor,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          description,
                          style: const TextStyle(fontSize: 14),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildDistrictsTab() {
    if (_districtSpending == null) return const Center(child: CircularProgressIndicator());
    
    final districts = _districtSpending!['districts'] as List<dynamic>;
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildDistrictSummaryCard(_districtSpending!),
          const SizedBox(height: 16),
          _buildDistrictsListCard(districts),
        ],
      ),
    );
  }

  Widget _buildDistrictSummaryCard(Map<String, dynamic> summary) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.location_on, color: Colors.blue),
                SizedBox(width: 8),
                Text(
                  'District Summary',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildSummaryMetric(
                    'Total Allocated',
                    _formatCurrency(summary['totalAllocated'] as double),
                    Colors.blue,
                  ),
                ),
                Expanded(
                  child: _buildSummaryMetric(
                    'Total Spent',
                    _formatCurrency(summary['totalSpent'] as double),
                    Colors.green,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildSummaryMetric(
              'Overall Utilization',
              '${summary['overallUtilization'].toStringAsFixed(1)}%',
              Colors.purple,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryMetric(String label, String value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.grey,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildDistrictsListCard(List<dynamic> districts) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.list, color: Colors.blue),
                SizedBox(width: 8),
                Text(
                  'District Breakdown',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...districts.map((district) {
              final name = district['name'] as String;
              final allocated = district['allocated'] as double;
              final spent = district['spent'] as double;
              final utilization = district['utilization'] as double;
              
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          name,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                          ),
                        ),
                        Text(
                          '${utilization.toStringAsFixed(1)}%',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: utilization > 80 ? Colors.green : Colors.orange,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    LinearProgressIndicator(
                      value: utilization / 100,
                      backgroundColor: Colors.grey[300],
                      valueColor: AlwaysStoppedAnimation<Color>(
                        utilization > 80 ? Colors.green : Colors.orange,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Allocated: ${_formatCurrency(allocated)}',
                          style: const TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                        Text(
                          'Spent: ${_formatCurrency(spent)}',
                          style: const TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildSectorsTab() {
    if (_sectorPerformance == null) return const Center(child: CircularProgressIndicator());
    
    final sectors = _sectorPerformance!['sectors'] as List<dynamic>;
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectorSummaryCard(_sectorPerformance!),
          const SizedBox(height: 16),
          _buildSectorsListCard(sectors),
        ],
      ),
    );
  }

  Widget _buildSectorSummaryCard(Map<String, dynamic> summary) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.business, color: Colors.blue),
                SizedBox(width: 8),
                Text(
                  'Sector Summary',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildSummaryMetric(
                    'Total Allocated',
                    _formatCurrency(summary['totalAllocated'] as double),
                    Colors.blue,
                  ),
                ),
                Expanded(
                  child: _buildSummaryMetric(
                    'Total Spent',
                    _formatCurrency(summary['totalSpent'] as double),
                    Colors.green,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildSummaryMetric(
              'Overall Utilization',
              '${summary['overallUtilization'].toStringAsFixed(1)}%',
              Colors.purple,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectorsListCard(List<dynamic> sectors) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.list, color: Colors.blue),
                SizedBox(width: 8),
                Text(
                  'Sector Breakdown',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...sectors.map((sector) {
              final name = sector['name'] as String;
              final allocated = sector['allocated'] as double;
              final spent = sector['spent'] as double;
              final utilization = sector['utilization'] as double;
              final priority = sector['priority'] as String;
              final projects = sector['projects'] as int;
              final completed = sector['completed'] as int;
              
              Color priorityColor;
              switch (priority) {
                case 'high':
                  priorityColor = Colors.red;
                  break;
                case 'medium':
                  priorityColor = Colors.orange;
                  break;
                default:
                  priorityColor = Colors.green;
              }
              
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            name,
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 16,
                            ),
                          ),
                        ),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: priorityColor.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: priorityColor.withOpacity(0.3)),
                              ),
                              child: Text(
                                priority.toUpperCase(),
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: priorityColor,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '${utilization.toStringAsFixed(1)}%',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: utilization > 80 ? Colors.green : Colors.orange,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    LinearProgressIndicator(
                      value: utilization / 100,
                      backgroundColor: Colors.grey[300],
                      valueColor: AlwaysStoppedAnimation<Color>(
                        utilization > 80 ? Colors.green : Colors.orange,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Projects: $completed/$projects',
                          style: const TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                        Text(
                          'Spent: ${_formatCurrency(spent)}',
                          style: const TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }

  String _formatCurrency(double amount) {
    if (amount >= 1000000) {
      return 'LKR ${(amount / 1000000).toStringAsFixed(1)}M';
    } else if (amount >= 1000) {
      return 'LKR ${(amount / 1000).toStringAsFixed(1)}K';
    } else {
      return 'LKR ${amount.toStringAsFixed(0)}';
    }
  }
}
