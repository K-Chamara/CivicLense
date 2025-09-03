import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';
import '../models/user_role.dart';
import 'add_tender_screen.dart';
import 'ongoing_tenders_screen.dart';
import 'notifications_screen.dart';
import 'tender_management_screen.dart';

class ProcurementOfficerDashboardScreen extends StatefulWidget {
  const ProcurementOfficerDashboardScreen({super.key});

  @override
  State<ProcurementOfficerDashboardScreen> createState() => _ProcurementOfficerDashboardScreenState();
}

class _ProcurementOfficerDashboardScreenState extends State<ProcurementOfficerDashboardScreen> {
  final AuthService _authService = AuthService();
  UserRole? userRole;
  Map<String, dynamic>? userData;
  bool isLoading = true;
  int _currentIndex = 0;
  
  // Dashboard statistics
  int tenderCount = 0;
  int activeProjects = 0;
  int notificationCount = 0;
  int pendingMilestones = 0;
  List<Map<String, dynamic>> recentProjects = [];

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _loadDashboardData();
  }

  Future<void> _loadUserData() async {
    final user = _authService.currentUser;
    if (user != null) {
      final role = await _authService.getUserRole(user.uid);
      final data = await _authService.getUserData(user.uid);
      
      setState(() {
        userRole = role;
        userData = data;
      });
    }
  }

  Future<void> _loadDashboardData() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      // Load tenders created by the current user
      final tendersQuery = await FirebaseFirestore.instance
          .collection('tenders')
          .where('createdBy', isEqualTo: user.uid)
          .get();

      final tenders = tendersQuery.docs.map((doc) => doc.data()).toList();

      // Load projects created by the current user
      final projectsQuery = await FirebaseFirestore.instance
          .collection('projects')
          .where('createdBy', isEqualTo: user.uid)
          .get();

      final projects = projectsQuery.docs.map((doc) => doc.data()).toList();

      // Calculate statistics
      tenderCount = tenders.length;
      activeProjects = tenders.where((tender) => tender['status'] == 'active').length + projects.length;
      
      // Load notifications count
      try {
        final notificationsSnapshot = await FirebaseFirestore.instance
            .collection('notifications')
            .where('userId', isEqualTo: user.uid)
            .where('isRead', isEqualTo: false)
            .get();
        notificationCount = notificationsSnapshot.docs.length;
      } catch (e) {
        print('Error loading notifications count: $e');
        notificationCount = 0;
      }
      
      // Load pending milestones count
      try {
        final milestonesSnapshot = await FirebaseFirestore.instance
            .collection('milestones')
            .where('status', isEqualTo: 'pending')
            .get();
        pendingMilestones = milestonesSnapshot.docs.length;
      } catch (e) {
        print('Error loading pending milestones count: $e');
        pendingMilestones = 0;
      }

      // Get recent projects (combine active tenders and projects)
      final List<Map<String, dynamic>> allRecentItems = [];

      // Add active tenders
      final activeTenders = tenders
          .where((tender) => tender['status'] == 'active')
          .map((tender) => {
                'id': tender['id'],
                'title': tender['title'] ?? '',
                'budget': tender['budget'] ?? 0.0,
                'deadline': tender['deadline'] ?? '',
                'category': tender['category'] ?? '',
                'totalBids': tender['totalBids'] ?? 0,
                'type': 'tender',
                'createdAt': tender['createdAt'],
              })
          .toList();

             // Add projects with winning bid amounts
       final List<Map<String, dynamic>> projectItems = [];
       for (final project in projects) {
         // Get winning bid amount for this project
         double winningBidAmount = project['budget'] ?? 0.0; // fallback to original budget
         
         if (project['tenderId'] != null) {
           try {
             final bidsSnapshot = await FirebaseFirestore.instance
                 .collection('bids')
                 .where('tenderId', isEqualTo: project['tenderId'])
                 .where('status', isEqualTo: 'awarded')
                 .get();
             
             if (bidsSnapshot.docs.isNotEmpty) {
               final winningBid = bidsSnapshot.docs.first.data();
               winningBidAmount = winningBid['bidAmount'] ?? project['budget'] ?? 0.0;
             }
           } catch (e) {
             print('Error fetching winning bid for project ${project['id']}: $e');
           }
         }
         
         projectItems.add({
           'id': project['id'],
           'title': project['tenderTitle'] ?? '',
           'budget': winningBidAmount,
           'deadline': '',
           'category': project['category'] ?? '',
           'totalBids': 0,
           'type': 'project',
           'createdAt': project['createdAt'],
         });
       }

             allRecentItems.addAll(activeTenders);
       allRecentItems.addAll(projectItems);

      // Sort by creation date (newest first) and take the most recent 4
      allRecentItems.sort((a, b) {
        final aDate = a['createdAt'] as Timestamp?;
        final bDate = b['createdAt'] as Timestamp?;
        if (aDate == null && bDate == null) return 0;
        if (aDate == null) return 1;
        if (bDate == null) return -1;
        return bDate.compareTo(aDate);
      });

      recentProjects = allRecentItems.take(4).toList();

      setState(() {
        isLoading = false;
      });
    } catch (e) {
      print('Error loading dashboard data: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _signOut() async {
    try {
      await _authService.signOut();
      if (mounted) {
        Navigator.of(context).pushReplacementNamed('/login');
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

  String _formatBudget(double budget) {
    if (budget >= 1000000) {
      return '\$${(budget / 1000000).toStringAsFixed(1)}M';
    } else if (budget >= 1000) {
      return '\$${(budget / 1000).toStringAsFixed(1)}K';
    } else {
      return '\$${budget.toStringAsFixed(0)}';
    }
  }

  String _getDaysRemaining(String deadline) {
    try {
      final deadlineDate = DateTime.parse(deadline);
      final now = DateTime.now();
      final difference = deadlineDate.difference(now).inDays;
      
      if (difference < 0) {
        return 'Expired';
      } else if (difference == 0) {
        return 'Today';
      } else if (difference == 1) {
        return 'Tomorrow';
      } else {
        return '$difference days left';
      }
    } catch (e) {
      return 'Invalid date';
    }
  }

  Color _getCategoryColor(String category) {
    switch (category) {
      case 'IT Services':
        return Colors.blue;
      case 'Office Supplies':
        return Colors.green;
      case 'Security Services':
        return Colors.orange;
      case 'Vehicle Maintenance':
        return Colors.purple;
      case 'Healthcare':
        return Colors.red;
      case 'Infrastructure':
        return Colors.indigo;
      default:
        return Colors.grey;
    }
  }

  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'IT Services':
        return Icons.computer;
      case 'Office Supplies':
        return Icons.inventory;
      case 'Security Services':
        return Icons.security;
      case 'Vehicle Maintenance':
        return Icons.directions_car;
      case 'Healthcare':
        return Icons.medical_services;
      case 'Infrastructure':
        return Icons.construction;
      default:
        return Icons.work;
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

    final List<Widget> screens = [
      _buildHomeScreen(),
      const TenderManagementScreen(),
      const OngoingTendersScreen(),
      const NotificationsScreen(),
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: Text(_getAppBarTitle()),
        backgroundColor: Colors.lightBlue,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadDashboardData,
            tooltip: 'Refresh Data',
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _signOut,
          ),
        ],
      ),
      body: screens[_currentIndex],
             bottomNavigationBar: BottomNavigationBar(
         type: BottomNavigationBarType.fixed,
         currentIndex: _currentIndex,
         selectedItemColor: Colors.lightBlue,
         unselectedItemColor: Colors.grey,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.manage_accounts),
            label: 'Tenders',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.assignment),
            label: 'Projects',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.notifications),
            label: 'Notifications',
          ),
        ],
      ),
             floatingActionButton: _currentIndex == 0 ? FloatingActionButton(
         onPressed: () {
           Navigator.push(
             context,
             MaterialPageRoute(builder: (context) => const AddTenderScreen()),
           ).then((_) {
             // Refresh data when returning from add tender screen
             _loadDashboardData();
           });
         },
         backgroundColor: Colors.lightBlue,
         foregroundColor: Colors.white,
        child: const Icon(Icons.add),
      ) : null,
    );
  }

  String _getAppBarTitle() {
    switch (_currentIndex) {
      case 0:
        return 'PO Dashboard';
      case 1:
        return 'Tender Management';
      case 2:
        return 'Active Projects';
      case 3:
        return 'Notifications';
      default:
        return 'PO Dashboard';
    }
  }

  Widget _buildHomeScreen() {
    return SingleChildScrollView(
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

          // Active Projects
          _buildActiveProjects(),
          
          // Bottom padding to prevent FAB overlap
          const SizedBox(height: 80),
        ],
      ),
    );
  }

  Widget _buildWelcomeCard() {
    return Container(
      padding: const EdgeInsets.all(20),
             decoration: BoxDecoration(
         gradient: const LinearGradient(
           colors: [Colors.lightBlue, Colors.blue],
           begin: Alignment.topLeft,
           end: Alignment.bottomRight,
         ),
         borderRadius: BorderRadius.circular(16),
         boxShadow: [
           BoxShadow(
             color: Colors.lightBlue.withOpacity(0.3),
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
              Icons.manage_accounts,
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
                  'Welcome, ${userData?['firstName'] ?? 'Procurement Officer'}!',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Manage projects, tenders, and procurement processes efficiently',
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
    return Container(
      height: 240,
      child: GridView.count(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 1.8,
        children: [
          _buildStatCard(
            'Tender\nCount',
            tenderCount.toString(),
            Icons.description,
            Colors.blue,
          ),
          _buildStatCard(
            'Active\nProjects',
            activeProjects.toString(),
            Icons.assignment,
            Colors.green,
          ),
          _buildStatCard(
            'Notifications',
            notificationCount.toString(),
            Icons.notifications,
            Colors.orange,
          ),
          _buildStatCard(
            'Pending\nMilestones',
            pendingMilestones.toString(),
            Icons.schedule,
            Colors.purple,
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
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
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                color: color,
                size: 24,
              ),
              const SizedBox(width: 8),
              Text(
                value,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            title,
            style: const TextStyle(
              fontSize: 11,
              color: Colors.grey,
              height: 1.2,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
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
          'Procurement Management Tools',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 16),
        _buildFeatureCard(
          'Tender Management',
          'Manage your tenders and bidders',
          Icons.manage_accounts,
          Colors.green,
          () {
            setState(() {
              _currentIndex = 1;
            });
          },
        ),
        _buildFeatureCard(
          'Active Projects',
          'View and browse all active projects',
          Icons.assignment,
          Colors.blue,
          () {
            setState(() {
              _currentIndex = 2;
            });
          },
        ),

        _buildFeatureCard(
          'Notifications',
          'Manage alerts and notifications',
          Icons.notifications,
          Colors.teal,
          () {
            setState(() {
              _currentIndex = 3;
            });
          },
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

  Widget _buildActiveProjects() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Recent Projects',
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
          child: recentProjects.isEmpty
              ? const Center(
                  child: Padding(
                    padding: EdgeInsets.all(20),
                    child: Text(
                      'No active projects found',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey,
                      ),
                    ),
                  ),
                )
              : Column(
                  children: recentProjects.map((project) => _buildProjectItem(
                    project['title'],
                    project['type'] == 'project' ? 'Project' : _getDaysRemaining(project['deadline']),
                    _formatBudget(project['budget']),
                    project['type'] == 'project' ? Icons.assignment : _getCategoryIcon(project['category']),
                    project['type'] == 'project' ? Colors.purple : _getCategoryColor(project['category']),
                  )).toList(),
                ),
        ),
      ],
    );
  }

  Widget _buildProjectItem(String title, String deadline, String value, IconData icon, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
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
                  deadline,
                  style: const TextStyle(
                    color: Colors.grey,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
