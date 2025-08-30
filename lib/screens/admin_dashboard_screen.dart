import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/admin_service.dart';
import '../services/auth_service.dart';
import '../models/user_role.dart';
import '../widgets/custom_button.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen>
    with TickerProviderStateMixin {
  final AdminService _adminService = AdminService();
  final AuthService _authService = AuthService();
  
  List<Map<String, dynamic>> _users = [];
  Map<String, int> _userStats = {};
  bool _isLoading = true;
  String _selectedFilter = 'all';
  
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
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
    
    _loadData();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    if (!mounted) return;
    
    setState(() {
      _isLoading = true;
    });

    try {
      final users = await _adminService.getAllUsers();
      final stats = await _adminService.getUserStatistics();
      
      if (mounted) {
        setState(() {
          _users = users;
          _userStats = stats;
          _isLoading = false;
        });
        
        // Start animations after data loads
        _fadeController.forward();
        _slideController.forward();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading data: $e'),
            backgroundColor: const Color(0xFFD32F2F),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
        );
      }
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
            backgroundColor: const Color(0xFFD32F2F),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: SafeArea(
        child: Column(
          children: [
            // Professional Header
            _buildProfessionalHeader(),
            
            // Main Content
            Expanded(
              child: _isLoading
                  ? _buildLoadingState()
                  : FadeTransition(
                      opacity: _fadeAnimation,
                      child: SlideTransition(
                        position: _slideAnimation,
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Welcome Section
                              _buildWelcomeSection(),
                              const SizedBox(height: 24),
                              
                              // Statistics Cards
                              _buildStatisticsCards(),
                              const SizedBox(height: 24),
                              
                              // Quick Actions
                              _buildQuickActions(),
                              const SizedBox(height: 24),
                              
                              // User Management
                              _buildUserManagement(),
                            ],
                          ),
                        ),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfessionalHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Color(0x1A000000),
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF1976D2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.admin_panel_settings,
              color: Colors.white,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'CivicLense Admin Dashboard',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1A1A1A),
                    fontFamily: 'Roboto',
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Government Platform Management',
                  style: TextStyle(
                    fontSize: 14,
                    color: const Color(0xFF1A1A1A).withOpacity(0.7),
                    fontFamily: 'Roboto',
                  ),
                ),
              ],
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFFD32F2F),
              borderRadius: BorderRadius.circular(8),
            ),
            child: IconButton(
              icon: const Icon(Icons.logout, color: Colors.white, size: 20),
              onPressed: _signOut,
              tooltip: 'Sign Out',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x1A000000),
                  blurRadius: 8,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: const Column(
              children: [
                CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF1976D2)),
                  strokeWidth: 3,
                ),
                SizedBox(height: 16),
                Text(
                  'Loading Dashboard...',
                  style: TextStyle(
                    fontSize: 16,
                    color: Color(0xFF1A1A1A),
                    fontWeight: FontWeight.w500,
                    fontFamily: 'Roboto',
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWelcomeSection() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(
            color: Color(0x1A000000),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF1976D2).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.waving_hand,
              color: Color(0xFF1976D2),
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Welcome, Administrator',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1A1A1A),
                    fontFamily: 'Roboto',
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'You have ${_users.length} users to manage today',
                  style: TextStyle(
                    fontSize: 14,
                    color: const Color(0xFF1A1A1A).withOpacity(0.7),
                    fontFamily: 'Roboto',
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatisticsCards() {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 12,
      mainAxisSpacing: 16,
      childAspectRatio: 1.3,
      children: [
        _buildStatCard(
          'Total Users',
          _users.length.toString(),
          Icons.people,
          const Color(0xFF1976D2),
        ),
        _buildStatCard(
          'Government Users',
          _userStats.values.fold(0, (sum, count) => sum + count).toString(),
          Icons.account_balance,
          const Color(0xFF388E3C),
        ),
        _buildStatCard(
          'Public Users',
          _users.where((user) => user['role']?['userType'] == 'public').length.toString(),
          Icons.person,
          const Color(0xFFF57C00),
        ),
        _buildStatCard(
          'Active Users',
          _users.where((user) => user['isActive'] == true).length.toString(),
          Icons.check_circle,
          const Color(0xFF388E3C),
        ),
      ],
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(
            color: Color(0x1A000000),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () {
            HapticFeedback.lightImpact();
          },
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(5),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(5),
                  ),
                  child: Icon(
                    icon,
                    size: 18,
                    color: color,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: color,
                    fontFamily: 'Roboto',
                  ),
                ),
                const SizedBox(height: 2),
                Flexible(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 10,
                      color: Color(0xFF1A1A1A),
                      fontWeight: FontWeight.w500,
                      fontFamily: 'Roboto',
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildQuickActions() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(
            color: Color(0x1A000000),
            blurRadius: 8,
            offset: Offset(0, 2),
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
                  color: const Color(0xFF1976D2).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Icon(
                  Icons.flash_on,
                  color: Color(0xFF1976D2),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Quick Actions',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1A1A1A),
                  fontFamily: 'Roboto',
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _buildActionButton(
                  'Create User',
                  Icons.add_business,
                  const Color(0xFF388E3C),
                  () => _showCreateUserDialog(),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildActionButton(
                  'Refresh Data',
                  Icons.refresh,
                  const Color(0xFF1976D2),
                  () => _refreshData(),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(String text, IconData icon, Color color, VoidCallback onPressed) {
    return Container(
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.3),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: () {
            HapticFeedback.lightImpact();
            onPressed();
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  icon,
                  color: Colors.white,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    text,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      fontFamily: 'Roboto',
                    ),
                    textAlign: TextAlign.center,
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildUserManagement() {
    final filteredUsers = _getFilteredUsers();

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(
            color: Color(0x1A000000),
            blurRadius: 8,
            offset: Offset(0, 2),
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
                  color: const Color(0xFF1976D2).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Icon(
                  Icons.people_alt,
                  color: Color(0xFF1976D2),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'User Management',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1A1A1A),
                  fontFamily: 'Roboto',
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFFF5F5F5),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: const Color(0xFFE0E0E0)),
                ),
                child: DropdownButton<String>(
                  value: _selectedFilter,
                  style: const TextStyle(
                    color: Color(0xFF1A1A1A),
                    fontWeight: FontWeight.w500,
                    fontFamily: 'Roboto',
                  ),
                  underline: Container(),
                  items: const [
                    DropdownMenuItem(value: 'all', child: Text('All Users')),
                    DropdownMenuItem(value: 'government', child: Text('Government')),
                    DropdownMenuItem(value: 'public', child: Text('Public')),
                    DropdownMenuItem(value: 'admin', child: Text('Admin')),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _selectedFilter = value!;
                    });
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 400,
            child: ListView.builder(
              itemCount: filteredUsers.length,
              itemBuilder: (context, index) {
                final user = filteredUsers[index];
                
                final firstName = user['firstName']?.toString() ?? 'Unknown';
                final lastName = user['lastName']?.toString() ?? 'User';
                final email = user['email']?.toString() ?? 'No email';
                final roleData = user['role'];
                
                if (roleData == null) {
                  return _buildUserCard(
                    firstName: firstName,
                    lastName: lastName,
                    email: email,
                    role: 'Role data missing',
                    color: const Color(0xFF757575),
                    icon: Icons.person,
                    isActive: false,
                    onAction: (action) => _handleUserAction(action, user),
                  );
                }
                
                final role = UserRole.fromMap(roleData);
                
                return _buildUserCard(
                  firstName: firstName,
                  lastName: lastName,
                  email: email,
                  role: role.name,
                  color: role.color,
                  icon: role.icon,
                  isActive: user['isActive'] == true,
                  onAction: (action) => _handleUserAction(action, user),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserCard({
    required String firstName,
    required String lastName,
    required String email,
    required String role,
    required Color color,
    required IconData icon,
    required bool isActive,
    required Function(String) onAction,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE0E0E0)),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: () {
            HapticFeedback.lightImpact();
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Icon(
                    icon,
                    color: color,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '$firstName $lastName',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1A1A1A),
                          fontFamily: 'Roboto',
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        email,
                        style: TextStyle(
                          fontSize: 14,
                          color: const Color(0xFF1A1A1A).withOpacity(0.7),
                          fontFamily: 'Roboto',
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        role,
                        style: TextStyle(
                          fontSize: 12,
                          color: color,
                          fontWeight: FontWeight.w600,
                          fontFamily: 'Roboto',
                        ),
                      ),
                    ],
                  ),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: isActive ? const Color(0xFF388E3C).withOpacity(0.1) : const Color(0xFFD32F2F).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Icon(
                        isActive ? Icons.check_circle : Icons.cancel,
                        color: isActive ? const Color(0xFF388E3C) : const Color(0xFFD32F2F),
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 8),
                    PopupMenuButton<String>(
                      icon: Icon(
                        Icons.more_vert,
                        color: const Color(0xFF1A1A1A).withOpacity(0.7),
                      ),
                      color: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      onSelected: onAction,
                      itemBuilder: (context) => [
                        PopupMenuItem(
                          value: 'toggle_status',
                          child: Row(
                            children: [
                              Icon(
                                isActive ? Icons.block : Icons.check_circle,
                                color: const Color(0xFF1A1A1A),
                                size: 18,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                isActive ? 'Deactivate' : 'Activate',
                                style: const TextStyle(
                                  color: Color(0xFF1A1A1A),
                                  fontFamily: 'Roboto',
                                ),
                              ),
                            ],
                          ),
                        ),
                        const PopupMenuItem(
                          value: 'delete',
                          child: Row(
                            children: [
                              Icon(
                                Icons.delete,
                                color: Color(0xFFD32F2F),
                                size: 18,
                              ),
                              SizedBox(width: 8),
                              Text(
                                'Delete',
                                style: TextStyle(
                                  color: Color(0xFFD32F2F),
                                  fontFamily: 'Roboto',
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  List<Map<String, dynamic>> _getFilteredUsers() {
    switch (_selectedFilter) {
      case 'government':
        return _users.where((user) => user['role']?['userType'] == 'government').toList();
      case 'public':
        return _users.where((user) => user['role']?['userType'] == 'public').toList();
      case 'admin':
        return _users.where((user) => user['role']?['userType'] == 'admin').toList();
      default:
        return _users;
    }
  }

  void _showCreateUserDialog() {
    showDialog(
      context: context,
      builder: (context) => const CreateGovernmentUserDialog(),
    ).then((_) {
      // Reload data after user creation
      _loadData();
    });
  }

  





  Future<void> _handleUserAction(String action, Map<String, dynamic> user) async {
    try {
      switch (action) {
        case 'toggle_status':
          await _adminService.updateUserStatus(
            user['uid'],
            !(user['isActive'] ?? true),
          );
          break;
        case 'delete':
          final confirmed = await _showDeleteConfirmation(user);
          if (confirmed) {
            await _adminService.deleteUser(user['uid']);
            
            // Show success message with additional information
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Text('User deleted from database successfully'),
                  backgroundColor: Colors.green,
                  duration: const Duration(seconds: 3),
                  action: SnackBarAction(
                    label: 'Info',
                    textColor: Colors.white,
                    onPressed: () => _showDeleteInfoDialog(),
                  ),
                ),
              );
            }
          }
          break;
      }
      _loadData();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showDeleteInfoDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.info, color: Colors.blue),
            SizedBox(width: 8),
            Text('User Deletion Info'),
          ],
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'The user has been deleted from the database and can no longer log in through the app.',
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(height: 16),
            Text(
              'Important Notes:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text('• The user still exists in Firebase Authentication'),
            Text('• For complete cleanup, manually delete from Firebase Console'),
            Text('• Or deploy Firebase Functions for automatic deletion'),
            SizedBox(height: 8),
            Text(
              'This is a limitation of client-side Firebase SDK.',
              style: TextStyle(fontStyle: FontStyle.italic, color: Colors.grey),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }





  Future<bool> _showDeleteConfirmation(Map<String, dynamic> user) async {
    return await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Delete'),
        content: Text('Are you sure you want to delete ${user['firstName']} ${user['lastName']}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete'),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
          ),
        ],
      ),
    ) ?? false;
  }

  void _refreshData() {
    _loadData();
  }


}

class CreateGovernmentUserDialog extends StatefulWidget {
  const CreateGovernmentUserDialog({super.key});

  @override
  State<CreateGovernmentUserDialog> createState() => _CreateGovernmentUserDialogState();
}

class _CreateGovernmentUserDialogState extends State<CreateGovernmentUserDialog> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final AdminService _adminService = AdminService();
  
  UserRole? _selectedRole;
  bool _isLoading = false;

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  void _showCredentialsDialogInParent(Map<String, dynamic> result) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        child: Container(
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF11998e),
                Color(0xFF38ef7d),
              ],
            ),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Success Icon
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Icon(
                    Icons.check_circle,
                    color: Colors.white,
                    size: 48,
                  ),
                ),
                const SizedBox(height: 16),
                
                // Title
                const Text(
                  'User Created Successfully!',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                
                Text(
                  'Please share these credentials with the user:',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.white.withOpacity(0.9),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                
                // Credentials Card
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(15),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildCredentialRow('Email', result['email']),
                      const SizedBox(height: 12),
                      _buildCredentialRow('Username', result['username']),
                      const SizedBox(height: 12),
                      _buildCredentialRow('Password', result['password']),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                
                // Important Notes
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.orange.withOpacity(0.4),
                      width: 1,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.info,
                            color: Colors.orange.shade300,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Important Notes:',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.orange.shade300,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      _buildNoteItem('Email functionality is not implemented yet. Please manually share these credentials.'),
                      _buildNoteItem('The new user can now log in with these credentials.'),
                      _buildNoteItem('Government users will receive an OTP when they log in.', isHighlighted: true),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                
                                 // OK Button
                 SizedBox(
                   width: double.infinity,
                   child: _buildActionButton(
                     'Got it!',
                     Icons.check,
                     const Color(0xFF388E3C),
                     () => Navigator.of(context).pop(),
                   ),
                 ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCredentialRow(String label, String value) {
    return Row(
      children: [
        Text(
          '$label: ',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildNoteItem(String text, {bool isHighlighted = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '• ',
            style: TextStyle(
              color: Colors.orange.shade300,
              fontWeight: FontWeight.bold,
            ),
          ),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 13,
                color: isHighlighted ? Colors.white : Colors.orange.shade200,
                fontWeight: isHighlighted ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
        ],
      ),
    );
  }



  Future<void> _createUser() async {
    if (!_formKey.currentState!.validate() || _selectedRole == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill all fields and select a role'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final result = await _adminService.createGovernmentUser(
        email: _emailController.text.trim(),
        firstName: _firstNameController.text.trim(),
        lastName: _lastNameController.text.trim(),
        role: _selectedRole!,
      );

             if (mounted) {
         Navigator.of(context).pop();
         
         // Show success message and credentials dialog
         WidgetsBinding.instance.addPostFrameCallback((_) {
           if (context.mounted) {
             // Show success snackbar
             ScaffoldMessenger.of(context).showSnackBar(
               SnackBar(
                 content: Text('${_selectedRole!.name} created successfully!'),
                 backgroundColor: Colors.green,
                 duration: const Duration(seconds: 3),
               ),
             );
             
             // Show credentials dialog
             _showCredentialsDialogInParent(result);
           }
         });
       }
         } catch (e) {
       if (mounted) {
         ScaffoldMessenger.of(context).showSnackBar(
           SnackBar(
             content: Text('Error creating user: $e'),
             backgroundColor: Colors.red,
           ),
         );
       }
     } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1976D2).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Icon(
                      Icons.add_business,
                      color: Color(0xFF1976D2),
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Create Government User',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1A1A1A),
                        fontFamily: 'Roboto',
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              
              // Form
              Form(
                key: _formKey,
                child: Column(
                  children: [
                    _buildFormField(
                      controller: _firstNameController,
                      label: 'First Name',
                      icon: Icons.person,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter first name';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    _buildFormField(
                      controller: _lastNameController,
                      label: 'Last Name',
                      icon: Icons.person,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter last name';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    _buildFormField(
                      controller: _emailController,
                      label: 'Email',
                      icon: Icons.email,
                      keyboardType: TextInputType.emailAddress,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter email';
                        }
                        if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                          return 'Please enter a valid email';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    _buildRoleDropdown(),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              
              // Actions
              Row(
                children: [
                  Expanded(
                    child: _buildActionButton(
                      'Cancel',
                      Icons.close,
                      const Color(0xFF757575),
                      () => Navigator.of(context).pop(),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildActionButton(
                      _isLoading ? 'Creating...' : 'Create User',
                      Icons.check,
                      const Color(0xFF388E3C),
                      _isLoading ? null : _createUser,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFormField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF5F5F5),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE0E0E0)),
      ),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        validator: validator,
        style: const TextStyle(
          color: Color(0xFF1A1A1A),
          fontFamily: 'Roboto',
        ),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(
            color: Color(0xFF1A1A1A),
            fontWeight: FontWeight.w500,
            fontFamily: 'Roboto',
          ),
          prefixIcon: Icon(
            icon,
            color: const Color(0xFF1A1A1A).withOpacity(0.7),
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 16,
          ),
        ),
      ),
    );
  }

  Widget _buildRoleDropdown() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF5F5F5),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE0E0E0)),
      ),
      child: DropdownButtonFormField<UserRole>(
        value: _selectedRole,
        style: const TextStyle(
          color: Color(0xFF1A1A1A),
          fontFamily: 'Roboto',
        ),
        dropdownColor: Colors.white,
        decoration: const InputDecoration(
          labelText: 'Role',
          labelStyle: TextStyle(
            color: Color(0xFF1A1A1A),
            fontWeight: FontWeight.w500,
            fontFamily: 'Roboto',
          ),
          prefixIcon: Icon(
            Icons.work,
            color: Color(0xFF1A1A1A),
          ),
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 16,
          ),
        ),
        items: UserRole.governmentRoles.map((role) {
          return DropdownMenuItem(
            value: role,
            child: Text(
              role.name,
              style: const TextStyle(
                color: Color(0xFF1A1A1A),
                fontFamily: 'Roboto',
              ),
            ),
          );
        }).toList(),
        onChanged: (value) {
          setState(() {
            _selectedRole = value;
          });
        },
        validator: (value) {
          if (value == null) {
            return 'Please select a role';
          }
          return null;
        },
      ),
    );
  }

  Widget _buildActionButton(String text, IconData icon, Color color, VoidCallback? onPressed) {
    return Container(
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.3),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: onPressed,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  icon,
                  color: Colors.white,
                  size: 18,
                ),
                const SizedBox(width: 8),
                Text(
                  text,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    fontFamily: 'Roboto',
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
