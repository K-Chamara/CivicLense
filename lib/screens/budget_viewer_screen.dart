import 'package:flutter/material.dart';
import '../widgets/budget_navigator.dart';
import 'raise_concern_screen.dart';
import 'common_home_screen.dart';
import 'citizen_tender_screen.dart';
import '../services/auth_service.dart';
import '../models/user_role.dart';
import 'enhanced_dashboard_screen.dart';
import 'admin_dashboard_screen.dart';
import 'finance_officer_dashboard_screen.dart';
import 'procurement_officer_dashboard_screen.dart';
import 'anticorruption_officer_dashboard_screen.dart';
import 'public_user_dashboard_screen.dart';

/// Budget Viewer Screen - Main screen for viewing government budget data
/// 
/// This screen provides a comprehensive view of government budget data
/// with hierarchical navigation and detailed breakdowns.
class BudgetViewerScreen extends StatefulWidget {
  const BudgetViewerScreen({super.key});

  @override
  State<BudgetViewerScreen> createState() => _BudgetViewerScreenState();
}

class _BudgetViewerScreenState extends State<BudgetViewerScreen> {
  int _currentIndex = 1; // Budget tab is selected
  final AuthService _authService = AuthService();

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
      bottomNavigationBar: _buildBottomNavigationBar(),
      body: const BudgetNavigator(),
    );
  }

  Widget _buildBottomNavigationBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) {
            setState(() {
              _currentIndex = index;
            });
            
            // Navigate based on selection
            switch (index) {
              case 0:
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => const CommonHomeScreen()),
                );
                break;
              case 1:
                // Already on budget page
                break;
              case 2:
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => const CitizenTenderScreen()),
                );
                break;
              case 3:
                // Navigate to role-specific dashboard
                _navigateToDashboard();
                break;
            }
          },
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.white,
          selectedItemColor: Colors.blue,
          unselectedItemColor: Colors.grey.shade600,
          selectedFontSize: 12,
          unselectedFontSize: 12,
          elevation: 0,
          items: [
            BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined, size: 22),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.account_balance, size: 24),
              label: 'Budget',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.shopping_cart_outlined, size: 22),
              label: 'Tenders',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.dashboard_outlined, size: 22),
              label: 'Dashboard',
            ),
          ],
        ),
      ),
    );
  }

  /// Navigate to role-specific dashboard
  Future<void> _navigateToDashboard() async {
    try {
      final user = _authService.currentUser;
      if (user != null) {
        final userRole = await _authService.getUserRole(user.uid);
        final userData = await _authService.getUserData(user.uid);
        
        // Check if user is pending (not approved yet)
        final isPending = userData?['status'] == 'pending';
        
        Widget dashboard;
        
        if (isPending) {
          // Pending users get limited access with EnhancedDashboardScreen
          dashboard = const EnhancedDashboardScreen();
        } else {
          // Approved users get full access based on their role
          switch (userRole?.id) {
            case 'admin':
              dashboard = const AdminDashboardScreen();
              break;
            case 'finance_officer':
              dashboard = const FinanceOfficerDashboardScreen();
              break;
            case 'procurement_officer':
              dashboard = const ProcurementOfficerDashboardScreen();
              break;
            case 'anticorruption_officer':
              dashboard = const AntiCorruptionOfficerDashboardScreen();
              break;
            default:
              // Public users (citizen, journalist, community_leader, researcher, ngo)
              dashboard = const PublicUserDashboardScreen();
              break;
          }
        }
        
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => dashboard),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error navigating to dashboard: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
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
