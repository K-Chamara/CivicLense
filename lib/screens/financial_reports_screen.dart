import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'dart:typed_data';
import '../models/budget_models.dart';
import '../services/budget_service.dart';

class FinancialReportsScreen extends StatefulWidget {
  const FinancialReportsScreen({super.key});

  @override
  State<FinancialReportsScreen> createState() => _FinancialReportsScreenState();
}

class _FinancialReportsScreenState extends State<FinancialReportsScreen> {
  final BudgetService _budgetService = BudgetService();
  
  BudgetAnalytics? _analytics;
  bool _isLoading = true;
  String _selectedReportType = 'Budget Summary';
  String _selectedPeriod = 'Current Month';

  final List<String> _reportTypes = [
    'Budget Summary',
    'Category Analysis',
    'Spending Trends',
    'Over-budget Alert',
    'Year-over-Year Comparison',
    'AI Suggestions Report',
  ];

  final List<String> _periods = [
    'Current Month',
    'Last 3 Months',
    'Last 6 Months',
    'Current Year',
    'Last Year',
  ];

  @override
  void initState() {
    super.initState();
    _loadAnalytics();
  }

  Future<void> _loadAnalytics() async {
    try {
      setState(() => _isLoading = true);
      final analytics = await _budgetService.getBudgetAnalytics();
      setState(() {
        _analytics = analytics;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading analytics: $e')),
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
          'Financial Reports',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _analytics == null
              ? const Center(child: Text('No analytics data available'))
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildReportSelector(),
                      const SizedBox(height: 24),
                      _buildReportPreview(),
                      const SizedBox(height: 24),
                      _buildActionButtons(),
                    ],
                  ),
                ),
    );
  }

  Widget _buildReportSelector() {
    return Container(
      padding: const EdgeInsets.all(20),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Report Configuration',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          _buildDropdown(
            'Report Type',
            _selectedReportType,
            _reportTypes,
            (value) => setState(() => _selectedReportType = value!),
          ),
          const SizedBox(height: 16),
          _buildDropdown(
            'Time Period',
            _selectedPeriod,
            _periods,
            (value) => setState(() => _selectedPeriod = value!),
          ),
        ],
      ),
    );
  }

  Widget _buildDropdown(String label, String value, List<String> items, Function(String?) onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: value,
          decoration: InputDecoration(
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          ),
          items: items.map((item) => DropdownMenuItem(
            value: item,
            child: Text(item),
          )).toList(),
          onChanged: onChanged,
        ),
      ],
    );
  }

  Widget _buildReportPreview() {
    return Container(
      padding: const EdgeInsets.all(20),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.picture_as_pdf, color: Colors.red, size: 24),
              const SizedBox(width: 8),
              Text(
                '$_selectedReportType Report',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Period: $_selectedPeriod',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 16),
          _buildPreviewContent(),
        ],
      ),
    );
  }

  Widget _buildPreviewContent() {
    switch (_selectedReportType) {
      case 'Budget Summary':
        return _buildBudgetSummaryPreview();
      case 'Category Analysis':
        return _buildCategoryAnalysisPreview();
      case 'Spending Trends':
        return _buildSpendingTrendsPreview();
      case 'Over-budget Alert':
        return _buildOverBudgetPreview();
      case 'Year-over-Year Comparison':
        return _buildYoYPreview();
      case 'AI Suggestions Report':
        return _buildAISuggestionsPreview();
      default:
        return const Text('Select a report type to preview');
    }
  }

  Widget _buildBudgetSummaryPreview() {
    final remainingBudget = _analytics!.totalBudget - _analytics!.totalSpent;
    final utilizationPercentage = (_analytics!.totalSpent / _analytics!.totalBudget) * 100;
    
    return Column(
      children: [
        _buildPreviewItem('Total Budget', '\$${NumberFormat('#,##,##,##0').format(_analytics!.totalBudget)}'),
        _buildPreviewItem('Total Spent', '\$${NumberFormat('#,##,##,##0').format(_analytics!.totalSpent)}'),
        _buildPreviewItem('Remaining Budget', '\$${NumberFormat('#,##,##,##0').format(remainingBudget)}'),
        _buildPreviewItem('Utilization', '${utilizationPercentage.toStringAsFixed(1)}%'),
      ],
    );
  }

  Widget _buildCategoryAnalysisPreview() {
    final topCategories = _analytics!.categoryAnalytics.take(3).toList();
    return Column(
      children: [
        const Text('Top Categories:', style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        ...topCategories.map((category) => _buildPreviewItem(
          category.categoryName,
          '\$${NumberFormat('#,##,##,##0').format(category.allocatedAmount)} (${category.spendingPercentage.toStringAsFixed(1)}%)',
        )),
      ],
    );
  }

  Widget _buildSpendingTrendsPreview() {
    return Column(
      children: [
        _buildPreviewItem('Monthly Trends', '${_analytics!.monthlyTrends.length} months of data'),
        _buildPreviewItem('Average Monthly Spending', '\$${NumberFormat('#,##,##,##0').format(_analytics!.totalSpent / 12)}'),
      ],
    );
  }

  Widget _buildOverBudgetPreview() {
    final overBudgetCategories = _analytics!.categoryAnalytics.where((cat) => cat.spendingPercentage > 100).length;
    return Column(
      children: [
        _buildPreviewItem('Over-budget Categories', '$overBudgetCategories categories'),
        _buildPreviewItem('Alert Level', overBudgetCategories > 0 ? 'High' : 'Low'),
      ],
    );
  }

  Widget _buildYoYPreview() {
    return Column(
      children: [
        _buildPreviewItem('Year-over-Year Data', '${_analytics!.yearlyComparisons.length} years'),
        _buildPreviewItem('Growth Analysis', 'Available'),
      ],
    );
  }

  Widget _buildAISuggestionsPreview() {
    return Column(
      children: [
        _buildPreviewItem('AI Analysis', 'Based on current budget data'),
        _buildPreviewItem('Suggestions', 'Optimization recommendations'),
      ],
    );
  }

  Widget _buildPreviewItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 14)),
          Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed: _generateAndDownloadPDF,
            icon: const Icon(Icons.download),
            label: const Text('Download PDF'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: ElevatedButton.icon(
            onPressed: _sharePDF,
            icon: const Icon(Icons.share),
            label: const Text('Share PDF'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _generateAndDownloadPDF() async {
    try {
      final pdf = await _generatePDF();
      final pdfBytes = await pdf.save();
      
      // Get downloads directory
      final directory = await getDownloadsDirectory();
      if (directory == null) {
        throw Exception('Downloads directory not found');
      }
      
      // Create filename with timestamp
      final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
      final filename = '${_selectedReportType.replaceAll(' ', '_')}_Report_$timestamp.pdf';
      final file = File('${directory.path}/$filename');
      
      // Write PDF to file
      await file.writeAsBytes(pdfBytes);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('PDF saved to Downloads: $filename'),
            backgroundColor: Colors.green,
            action: SnackBarAction(
              label: 'View',
              onPressed: () => _viewPDF(pdfBytes, filename),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error generating PDF: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _sharePDF() async {
    try {
      final pdf = await _generatePDF();
      final pdfBytes = await pdf.save();
      
      // Create filename with timestamp
      final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
      final filename = '${_selectedReportType.replaceAll(' ', '_')}_Report_$timestamp.pdf';
      
      // Get temporary directory for sharing
      final directory = await getTemporaryDirectory();
      final file = File('${directory.path}/$filename');
      await file.writeAsBytes(pdfBytes);
      
      // Share the PDF
      await Share.shareXFiles(
        [XFile(file.path)],
        text: '$_selectedReportType Report - ${DateFormat('MMMM dd, yyyy').format(DateTime.now())}',
        subject: 'Financial Report',
      );
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('PDF shared successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error sharing PDF: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<pw.Document> _generatePDF() async {
    final pdf = pw.Document();
    
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Header(
                level: 0,
                child: pw.Text(
                  '$_selectedReportType Report',
                  style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold),
                ),
              ),
              pw.SizedBox(height: 20),
              pw.Text(
                'Generated on: ${DateFormat('MMMM dd, yyyy').format(DateTime.now())}',
                style: pw.TextStyle(fontSize: 12, color: PdfColors.grey600),
              ),
              pw.Text(
                'Period: $_selectedPeriod',
                style: pw.TextStyle(fontSize: 12, color: PdfColors.grey600),
              ),
              pw.SizedBox(height: 20),
              _buildPDFContent(),
            ],
          );
        },
      ),
    );
    
    return pdf;
  }

  pw.Widget _buildPDFContent() {
    switch (_selectedReportType) {
      case 'Budget Summary':
        return _buildBudgetSummaryPDF();
      case 'Category Analysis':
        return _buildCategoryAnalysisPDF();
      case 'Spending Trends':
        return _buildSpendingTrendsPDF();
      case 'Over-budget Alert':
        return _buildOverBudgetPDF();
      case 'Year-over-Year Comparison':
        return _buildYoYPDF();
      case 'AI Suggestions Report':
        return _buildAISuggestionsPDF();
      default:
        return pw.Text('No content available');
    }
  }

  pw.Widget _buildBudgetSummaryPDF() {
    final remainingBudget = _analytics!.totalBudget - _analytics!.totalSpent;
    final utilizationPercentage = (_analytics!.totalSpent / _analytics!.totalBudget) * 100;
    
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text('Budget Summary', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
        pw.SizedBox(height: 10),
        pw.Text('Total Budget: \$${NumberFormat('#,##,##,##0').format(_analytics!.totalBudget)}'),
        pw.Text('Total Spent: \$${NumberFormat('#,##,##,##0').format(_analytics!.totalSpent)}'),
        pw.Text('Remaining Budget: \$${NumberFormat('#,##,##,##0').format(remainingBudget)}'),
        pw.Text('Utilization: ${utilizationPercentage.toStringAsFixed(1)}%'),
      ],
    );
  }

  pw.Widget _buildCategoryAnalysisPDF() {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text('Category Analysis', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
        pw.SizedBox(height: 10),
        ..._analytics!.categoryAnalytics.map((category) => pw.Text(
          '${category.categoryName}: \$${NumberFormat('#,##,##,##0').format(category.allocatedAmount)} (${category.spendingPercentage.toStringAsFixed(1)}%)',
        )),
      ],
    );
  }

  pw.Widget _buildSpendingTrendsPDF() {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text('Spending Trends', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
        pw.SizedBox(height: 10),
        pw.Text('Monthly Trends: ${_analytics!.monthlyTrends.length} months of data'),
        pw.Text('Average Monthly Spending: \$${NumberFormat('#,##,##,##0').format(_analytics!.totalSpent / 12)}'),
      ],
    );
  }

  pw.Widget _buildOverBudgetPDF() {
    final overBudgetCategories = _analytics!.categoryAnalytics.where((cat) => cat.spendingPercentage > 100).toList();
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text('Over-budget Alert Report', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
        pw.SizedBox(height: 10),
        pw.Text('Over-budget Categories: ${overBudgetCategories.length}'),
        pw.SizedBox(height: 10),
        ...overBudgetCategories.map((category) => pw.Text(
          '${category.categoryName}: ${category.spendingPercentage.toStringAsFixed(1)}% over budget',
        )),
      ],
    );
  }

  pw.Widget _buildYoYPDF() {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text('Year-over-Year Comparison', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
        pw.SizedBox(height: 10),
        pw.Text('Year-over-Year Data: ${_analytics!.yearlyComparisons.length} years'),
        pw.Text('Growth Analysis: Available'),
      ],
    );
  }

  pw.Widget _buildAISuggestionsPDF() {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text('AI Suggestions Report', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
        pw.SizedBox(height: 10),
        pw.Text('AI Analysis: Based on current budget data'),
        pw.Text('Suggestions: Optimization recommendations'),
      ],
    );
  }

  Future<void> _viewPDF(Uint8List pdfBytes, String filename) async {
    try {
      // Use the printing package to view the PDF
      await Printing.layoutPdf(
        onLayout: (PdfPageFormat format) async => pdfBytes,
        name: filename,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error viewing PDF: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
