import 'package:flutter/material.dart';
import '../widgets/budget_navigator.dart';
import 'raise_concern_screen.dart';

/// Budget Viewer Screen - Main screen for viewing government budget data
/// 
/// This screen provides a comprehensive view of government budget data
/// with hierarchical navigation and detailed breakdowns.
class BudgetViewerScreen extends StatelessWidget {
  const BudgetViewerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Government Budget'),
        backgroundColor: const Color(0xFF2E4A62),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.report_problem),
            onPressed: () => _raiseBudgetConcern(context),
            tooltip: 'Raise Budget Concern',
          ),
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: () => _showBudgetInfo(context),
            tooltip: 'Budget Information',
          ),
        ],
      ),
      body: const BudgetNavigator(),
    );
  }

  /// Raise concern about budget
  void _raiseBudgetConcern(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const RaiseConcernScreen(
          preSelectedCategory: 'budget',
        ),
      ),
    );
  }

  /// Show budget information dialog
  void _showBudgetInfo(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.info, color: Color(0xFF2E4A62)),
            SizedBox(width: 8),
            Text('About Government Budget'),
          ],
        ),
        content: const SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'This budget viewer shows how your tax money is allocated and spent by the government.',
                style: TextStyle(fontSize: 16),
              ),
              SizedBox(height: 16),
              Text(
                'Key Features:',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              SizedBox(height: 8),
              Text('• Navigate through budget categories and subcategories'),
              Text('• View detailed spending breakdowns'),
              Text('• Track spending progress with visual indicators'),
              Text('• Real-time data from government sources'),
              SizedBox(height: 16),
              Text(
                'How to Use:',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              SizedBox(height: 8),
              Text('• Tap on any category to see its subcategories'),
              Text('• Tap on subcategories to see individual budget items'),
              Text('• Use the back button to navigate up the hierarchy'),
              Text('• Tap refresh to get the latest data'),
              SizedBox(height: 16),
              Text(
                'Data Source:',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              SizedBox(height: 8),
              Text('All data is sourced from official government budget documents and is updated regularly to ensure accuracy and transparency.'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Got it!'),
          ),
        ],
      ),
    );
  }
}
