import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';
import '../models/concern_models.dart';

class ConcernReportsScreen extends StatefulWidget {
  const ConcernReportsScreen({super.key});

  @override
  State<ConcernReportsScreen> createState() => _ConcernReportsScreenState();
}

class _ConcernReportsScreenState extends State<ConcernReportsScreen> {
  String _selectedPeriod = 'monthly'; // daily, monthly, yearly
  DateTime _selectedDate = DateTime.now();
  bool _isLoading = false;
  
  // Statistics
  int _totalConcerns = 0;
  int _resolvedConcerns = 0;
  int _pendingConcerns = 0;
  int _inProgressConcerns = 0;
  int _dismissedConcerns = 0;
  
  Map<String, int> _concernsByCategory = {};
  Map<String, int> _concernsByType = {};
  Map<String, int> _concernsByPriority = {};
  List<Map<String, dynamic>> _recentConcerns = [];

  @override
  void initState() {
    super.initState();
    _loadStatistics();
  }

  Future<void> _loadStatistics() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Calculate date range based on selected period
      DateTime startDate;
      DateTime endDate = DateTime.now();

      switch (_selectedPeriod) {
        case 'daily':
          startDate = DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day);
          endDate = startDate.add(const Duration(days: 1));
          break;
        case 'monthly':
          startDate = DateTime(_selectedDate.year, _selectedDate.month, 1);
          endDate = DateTime(_selectedDate.year, _selectedDate.month + 1, 1);
          break;
        case 'yearly':
          startDate = DateTime(_selectedDate.year, 1, 1);
          endDate = DateTime(_selectedDate.year + 1, 1, 1);
          break;
        default:
          startDate = DateTime(_selectedDate.year, _selectedDate.month, 1);
          endDate = DateTime(_selectedDate.year, _selectedDate.month + 1, 1);
      }

      // Query concerns within the date range
      final querySnapshot = await FirebaseFirestore.instance
          .collection('concerns')
          .where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
          .where('createdAt', isLessThan: Timestamp.fromDate(endDate))
          .get();

      // Reset statistics
      _totalConcerns = querySnapshot.docs.length;
      _resolvedConcerns = 0;
      _pendingConcerns = 0;
      _inProgressConcerns = 0;
      _dismissedConcerns = 0;
      _concernsByCategory = {};
      _concernsByType = {};
      _concernsByPriority = {};
      _recentConcerns = [];

      // Process each concern
      for (var doc in querySnapshot.docs) {
        final data = doc.data();
        
        // Count by status
        final status = data['status'] as String?;
        switch (status) {
          case 'resolved':
            _resolvedConcerns++;
            break;
          case 'pending':
            _pendingConcerns++;
            break;
          case 'underReview':
          case 'inProgress':
            _inProgressConcerns++;
            break;
          case 'dismissed':
            _dismissedConcerns++;
            break;
        }

        // Count by category
        final category = data['category'] as String? ?? 'other';
        _concernsByCategory[category] = (_concernsByCategory[category] ?? 0) + 1;

        // Count by type
        final type = data['type'] as String? ?? 'general';
        _concernsByType[type] = (_concernsByType[type] ?? 0) + 1;

        // Count by priority
        final priority = data['priority'] as String? ?? 'medium';
        _concernsByPriority[priority] = (_concernsByPriority[priority] ?? 0) + 1;

        // Store for recent concerns list
        _recentConcerns.add({
          'id': doc.id,
          'title': data['title'] ?? 'Untitled',
          'category': category,
          'status': status ?? 'pending',
          'priority': priority,
          'createdAt': (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
        });
      }

      // Sort recent concerns by date
      _recentConcerns.sort((a, b) => (b['createdAt'] as DateTime).compareTo(a['createdAt'] as DateTime));
      
      // Keep only top 10
      if (_recentConcerns.length > 10) {
        _recentConcerns = _recentConcerns.sublist(0, 10);
      }

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading statistics: $e');
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading statistics: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _generatePDFReport() async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return [
            // Header
            pw.Header(
              level: 0,
              child: pw.Text(
                'Concern Analytics Report',
                style: pw.TextStyle(
                  fontSize: 24,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
            ),
            pw.SizedBox(height: 20),
            
            // Period Information
            pw.Text(
              'Period: ${_getPeriodText()}',
              style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
            ),
            pw.Text(
              'Generated: ${DateFormat('MMM dd, yyyy HH:mm').format(DateTime.now())}',
              style: const pw.TextStyle(fontSize: 12, color: PdfColors.grey700),
            ),
            pw.SizedBox(height: 20),
            
            // Summary Statistics
            pw.Container(
              padding: const pw.EdgeInsets.all(10),
              decoration: pw.BoxDecoration(
                border: pw.Border.all(color: PdfColors.blue),
                borderRadius: const pw.BorderRadius.all(pw.Radius.circular(5)),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    'Summary Statistics',
                    style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
                  ),
                  pw.SizedBox(height: 10),
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text('Total Concerns:', style: const pw.TextStyle(fontSize: 12)),
                      pw.Text('$_totalConcerns', style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
                    ],
                  ),
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text('Resolved:', style: const pw.TextStyle(fontSize: 12)),
                      pw.Text('$_resolvedConcerns', style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, color: PdfColors.green)),
                    ],
                  ),
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text('In Progress:', style: const pw.TextStyle(fontSize: 12)),
                      pw.Text('$_inProgressConcerns', style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, color: PdfColors.orange)),
                    ],
                  ),
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text('Pending:', style: const pw.TextStyle(fontSize: 12)),
                      pw.Text('$_pendingConcerns', style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, color: PdfColors.blue)),
                    ],
                  ),
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text('Dismissed:', style: const pw.TextStyle(fontSize: 12)),
                      pw.Text('$_dismissedConcerns', style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, color: PdfColors.grey)),
                    ],
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 20),
            
            // Concerns by Category
            pw.Text(
              'Concerns by Category',
              style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 10),
            pw.Table(
              border: pw.TableBorder.all(color: PdfColors.grey300),
              children: [
                pw.TableRow(
                  decoration: const pw.BoxDecoration(color: PdfColors.blue50),
                  children: [
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(5),
                      child: pw.Text('Category', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(5),
                      child: pw.Text('Count', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                    ),
                  ],
                ),
                ..._concernsByCategory.entries.map(
                  (entry) => pw.TableRow(
                    children: [
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(5),
                        child: pw.Text(_formatCategoryName(entry.key)),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(5),
                        child: pw.Text('${entry.value}'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            pw.SizedBox(height: 20),
            
            // Concerns by Type
            pw.Text(
              'Concerns by Type',
              style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 10),
            pw.Table(
              border: pw.TableBorder.all(color: PdfColors.grey300),
              children: [
                pw.TableRow(
                  decoration: const pw.BoxDecoration(color: PdfColors.blue50),
                  children: [
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(5),
                      child: pw.Text('Type', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(5),
                      child: pw.Text('Count', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                    ),
                  ],
                ),
                ..._concernsByType.entries.map(
                  (entry) => pw.TableRow(
                    children: [
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(5),
                        child: pw.Text(_formatTypeName(entry.key)),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(5),
                        child: pw.Text('${entry.value}'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ];
        },
      ),
    );

    // Show PDF preview and print dialog
    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
    );
  }

  String _getPeriodText() {
    switch (_selectedPeriod) {
      case 'daily':
        return DateFormat('MMMM dd, yyyy').format(_selectedDate);
      case 'monthly':
        return DateFormat('MMMM yyyy').format(_selectedDate);
      case 'yearly':
        return DateFormat('yyyy').format(_selectedDate);
      default:
        return DateFormat('MMMM yyyy').format(_selectedDate);
    }
  }

  String _formatCategoryName(String category) {
    switch (category) {
      case 'budget':
        return 'Budget Misuse';
      case 'tender':
        return 'Tender Fraud';
      case 'community':
        return 'Community Issue';
      case 'corruption':
        return 'Corruption';
      case 'transparency':
        return 'Transparency';
      default:
        return category[0].toUpperCase() + category.substring(1);
    }
  }

  String _formatTypeName(String type) {
    switch (type) {
      case 'complaint':
        return 'Complaint';
      case 'suggestion':
        return 'Suggestion';
      case 'inquiry':
        return 'Inquiry';
      case 'report':
        return 'Report';
      default:
        return type[0].toUpperCase() + type.substring(1);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Reports & Analytics'),
        backgroundColor: Colors.purple,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.picture_as_pdf),
            onPressed: _generatePDFReport,
            tooltip: 'Export to PDF',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadStatistics,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(12), // Reduced from 16
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Period Selector
                  _buildPeriodSelector(),
                  const SizedBox(height: 12),
                  
                  // Summary Cards
                  _buildSummaryCards(),
                  const SizedBox(height: 12),
                  
                  // Status Distribution Chart
                  _buildStatusChart(),
                  const SizedBox(height: 12), // Reduced from 20
                  
                  // Category Distribution Chart
                  _buildCategoryChart(),
                  const SizedBox(height: 12), // Reduced from 20
                  
                  // Type Distribution Chart
                  _buildTypeChart(),
                  const SizedBox(height: 12), // Reduced from 20
                  
                  // Priority Distribution Chart
                  _buildPriorityChart(),
                  const SizedBox(height: 12), // Reduced from 20
                  
                  // Recent Concerns Table
                  _buildRecentConcernsTable(),
                ],
              ),
            ),
    );
  }

  Widget _buildPeriodSelector() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(12), // Reduced from 16
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Select Period',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: SegmentedButton<String>(
                    segments: const [
                      ButtonSegment(
                        value: 'daily',
                        label: Text('Daily'),
                        icon: Icon(Icons.today),
                      ),
                      ButtonSegment(
                        value: 'monthly',
                        label: Text('Monthly'),
                        icon: Icon(Icons.calendar_month),
                      ),
                      ButtonSegment(
                        value: 'yearly',
                        label: Text('Yearly'),
                        icon: Icon(Icons.calendar_today),
                      ),
                    ],
                    selected: {_selectedPeriod},
                    onSelectionChanged: (Set<String> newSelection) {
                      setState(() {
                        _selectedPeriod = newSelection.first;
                        _loadStatistics();
                      });
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: const Icon(Icons.chevron_left),
                  onPressed: () {
                    setState(() {
                      switch (_selectedPeriod) {
                        case 'daily':
                          _selectedDate = _selectedDate.subtract(const Duration(days: 1));
                          break;
                        case 'monthly':
                          _selectedDate = DateTime(_selectedDate.year, _selectedDate.month - 1, 1);
                          break;
                        case 'yearly':
                          _selectedDate = DateTime(_selectedDate.year - 1, 1, 1);
                          break;
                      }
                      _loadStatistics();
                    });
                  },
                ),
                Text(
                  _getPeriodText(),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.chevron_right),
                  onPressed: () {
                    setState(() {
                      switch (_selectedPeriod) {
                        case 'daily':
                          _selectedDate = _selectedDate.add(const Duration(days: 1));
                          break;
                        case 'monthly':
                          _selectedDate = DateTime(_selectedDate.year, _selectedDate.month + 1, 1);
                          break;
                        case 'yearly':
                          _selectedDate = DateTime(_selectedDate.year + 1, 1, 1);
                          break;
                      }
                      _loadStatistics();
                    });
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCards() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                'Total Concerns',
                _totalConcerns.toString(),
                Icons.report_problem,
                Colors.blue,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                'Resolved',
                _resolvedConcerns.toString(),
                Icons.check_circle,
                Colors.green,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                'In Progress',
                _inProgressConcerns.toString(),
                Icons.work,
                Colors.orange,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                'Pending',
                _pendingConcerns.toString(),
                Icons.pending,
                Colors.amber,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(12), // Reduced from 16
        child: Column(
          children: [
            Icon(icon, size: 40, color: color),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: const TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusChart() {
    if (_totalConcerns == 0) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Center(
            child: Text('No data available'),
          ),
        ),
      );
    }

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(12), // Reduced from 16
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Status Distribution',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 150, // Reduced from 200
              child: PieChart(
                PieChartData(
                  sections: [
                    if (_resolvedConcerns > 0)
                      PieChartSectionData(
                        value: _resolvedConcerns.toDouble(),
                        title: '$_resolvedConcerns',
                        color: Colors.green,
                        radius: 60, // Reduced from 100
                        titleStyle: const TextStyle(
                          fontSize: 14, // Reduced from 16
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    if (_inProgressConcerns > 0)
                      PieChartSectionData(
                        value: _inProgressConcerns.toDouble(),
                        title: '$_inProgressConcerns',
                        color: Colors.orange,
                        radius: 60, // Reduced from 100
                        titleStyle: const TextStyle(
                          fontSize: 14, // Reduced from 16
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    if (_pendingConcerns > 0)
                      PieChartSectionData(
                        value: _pendingConcerns.toDouble(),
                        title: '$_pendingConcerns',
                        color: Colors.amber,
                        radius: 60, // Reduced from 100
                        titleStyle: const TextStyle(
                          fontSize: 14, // Reduced from 16
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    if (_dismissedConcerns > 0)
                      PieChartSectionData(
                        value: _dismissedConcerns.toDouble(),
                        title: '$_dismissedConcerns',
                        color: Colors.grey,
                        radius: 60, // Reduced from 100
                        titleStyle: const TextStyle(
                          fontSize: 14, // Reduced from 16
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                  ],
                  sectionsSpace: 2,
                  centerSpaceRadius: 30, // Reduced from 40
                ),
              ),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 16,
              runSpacing: 8,
              children: [
                _buildLegendItem('Resolved', Colors.green),
                _buildLegendItem('In Progress', Colors.orange),
                _buildLegendItem('Pending', Colors.amber),
                _buildLegendItem('Dismissed', Colors.grey),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryChart() {
    if (_concernsByCategory.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Center(
            child: Text('No data available'),
          ),
        ),
      );
    }

    final categories = _concernsByCategory.entries.toList();
    categories.sort((a, b) => b.value.compareTo(a.value));

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(12), // Reduced from 16
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Concerns by Category',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 200, // Reduced from 300
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  maxY: (categories.first.value * 1.2).toDouble(),
                  barGroups: categories.asMap().entries.map((entry) {
                    return BarChartGroupData(
                      x: entry.key,
                      barRods: [
                        BarChartRodData(
                          toY: entry.value.value.toDouble(),
                          color: _getCategoryColor(entry.value.key),
                          width: 20, // Reduced from 30
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                        ),
                      ],
                    );
                  }).toList(),
                  titlesData: FlTitlesData(
                    show: true,
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          if (value.toInt() >= categories.length) return const Text('');
                          return Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(
                              _formatCategoryName(categories[value.toInt()].key),
                              style: const TextStyle(fontSize: 9), // Reduced from 10
                              textAlign: TextAlign.center,
                            ),
                          );
                        },
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 30, // Reduced from 40
                        getTitlesWidget: (value, meta) {
                          return Text(
                            value.toInt().toString(),
                            style: const TextStyle(fontSize: 9), // Reduced from 10
                          );
                        },
                      ),
                    ),
                    topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                  ),
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                  ),
                  borderData: FlBorderData(show: false),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTypeChart() {
    if (_concernsByType.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Center(
            child: Text('No data available'),
          ),
        ),
      );
    }

    final types = _concernsByType.entries.toList();
    types.sort((a, b) => b.value.compareTo(a.value));

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(12), // Reduced from 16
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Concerns by Type',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            ...types.map((entry) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _formatTypeName(entry.key),
                        style: const TextStyle(fontWeight: FontWeight.w500),
                      ),
                      Text(
                        '${entry.value} (${(_totalConcerns > 0 ? (entry.value / _totalConcerns * 100) : 0).toStringAsFixed(1)}%)',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  LinearProgressIndicator(
                    value: _totalConcerns > 0 ? entry.value / _totalConcerns : 0,
                    backgroundColor: Colors.grey[200],
                    color: _getTypeColor(entry.key),
                    minHeight: 8,
                  ),
                ],
              ),
            )),
          ],
        ),
      ),
    );
  }

  Widget _buildPriorityChart() {
    if (_concernsByPriority.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Center(
            child: Text('No data available'),
          ),
        ),
      );
    }

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(12), // Reduced from 16
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Concerns by Priority',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 150, // Reduced from 200
              child: PieChart(
                PieChartData(
                  sections: _concernsByPriority.entries.map((entry) {
                    return PieChartSectionData(
                      value: entry.value.toDouble(),
                      title: '${entry.value}',
                      color: _getPriorityColor(entry.key),
                      radius: 60, // Reduced from 100
                      titleStyle: const TextStyle(
                        fontSize: 14, // Reduced from 16
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    );
                  }).toList(),
                  sectionsSpace: 2,
                  centerSpaceRadius: 30, // Reduced from 40
                ),
              ),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 16,
              runSpacing: 8,
              children: _concernsByPriority.entries.map((entry) {
                return _buildLegendItem(
                  _formatPriorityName(entry.key),
                  _getPriorityColor(entry.key),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentConcernsTable() {
    if (_recentConcerns.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Center(
            child: Text('No concerns in this period'),
          ),
        ),
      );
    }

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(12), // Reduced from 16
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Recent Concerns',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                columns: const [
                  DataColumn(label: Text('Title')),
                  DataColumn(label: Text('Category')),
                  DataColumn(label: Text('Status')),
                  DataColumn(label: Text('Priority')),
                  DataColumn(label: Text('Date')),
                ],
                rows: _recentConcerns.map((concern) {
                  return DataRow(cells: [
                    DataCell(
                      SizedBox(
                        width: 200,
                        child: Text(
                          concern['title'],
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                    DataCell(Text(_formatCategoryName(concern['category']))),
                    DataCell(
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: _getStatusColor(concern['status']).withOpacity(0.2),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          _formatStatusName(concern['status']),
                          style: TextStyle(
                            color: _getStatusColor(concern['status']),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    DataCell(
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: _getPriorityColor(concern['priority']).withOpacity(0.2),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          _formatPriorityName(concern['priority']),
                          style: TextStyle(
                            color: _getPriorityColor(concern['priority']),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    DataCell(Text(DateFormat('MMM dd').format(concern['createdAt']))),
                  ]);
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 4),
        Text(label),
      ],
    );
  }

  Color _getCategoryColor(String category) {
    switch (category) {
      case 'budget':
        return Colors.blue;
      case 'tender':
        return Colors.purple;
      case 'community':
        return Colors.green;
      case 'corruption':
        return Colors.red;
      case 'transparency':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  Color _getTypeColor(String type) {
    switch (type) {
      case 'complaint':
        return Colors.red;
      case 'suggestion':
        return Colors.blue;
      case 'inquiry':
        return Colors.orange;
      case 'report':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  Color _getPriorityColor(String priority) {
    switch (priority.toLowerCase()) {
      case 'critical':
        return Colors.red;
      case 'high':
        return Colors.orange;
      case 'medium':
        return Colors.amber;
      case 'low':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'resolved':
        return Colors.green;
      case 'inProgress':
      case 'underReview':
        return Colors.orange;
      case 'pending':
        return Colors.blue;
      case 'dismissed':
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }

  String _formatPriorityName(String priority) {
    return priority[0].toUpperCase() + priority.substring(1);
  }

  String _formatStatusName(String status) {
    switch (status) {
      case 'inProgress':
        return 'In Progress';
      case 'underReview':
        return 'Under Review';
      default:
        return status[0].toUpperCase() + status.substring(1);
    }
  }
}

