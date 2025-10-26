import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/user_service.dart';
import '../services/admin_service.dart';
import '../widgets/document_viewer_widget.dart';
import '../widgets/pdf_viewer_widget.dart';
import '../widgets/document_ai_validation_widget.dart';

class UserManagementScreen extends StatefulWidget {
  const UserManagementScreen({super.key});

  @override
  State<UserManagementScreen> createState() => _UserManagementScreenState();
}

class _UserManagementScreenState extends State<UserManagementScreen> {
  final UserService _userService = UserService();
  final AdminService _adminService = AdminService();
  String _selectedFilter = 'all';
  String _selectedUserType = 'all';
  String _selectedRole = 'all';
  bool _isLoading = true;
  String _searchQuery = '';
  
  // Statistics counts
  int _pendingCount = 0;
  int _approvedCount = 0;
  int _rejectedCount = 0;
  int _totalUsers = 0;
  
  // User data
  List<Map<String, dynamic>> _allUsers = [];
  List<Map<String, dynamic>> _filteredUsers = [];

  final List<String> _statusFilters = [
    'all',
    'pending',
    'approved',
    'rejected',
  ];

  final List<String> _userTypeFilters = [
    'all',
    'government',
    'public',
  ];

  final List<String> _roleFilters = [
    'all',
    'citizen',
    'journalist',
    'ngo',
    'contractor',
    'researcher',
    'activist',
    'community_leader',
    'admin',
  ];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    if (!mounted) return;
    
    setState(() {
      _isLoading = true;
    });

    try {
      // Load all users
      final querySnapshot = await FirebaseFirestore.instance.collection('users').get();
      final users = querySnapshot.docs.map((doc) {
        final data = doc.data();
        data['uid'] = doc.id;
        return data;
      }).toList();
      
      // Calculate statistics for all users
      int pendingCount = 0;
      int approvedCount = 0;
      int rejectedCount = 0;
      
      for (final user in users) {
        final status = user['status'] ?? 'pending';
        switch (status) {
          case 'pending':
            pendingCount++;
            break;
          case 'approved':
            approvedCount++;
            break;
          case 'rejected':
            rejectedCount++;
            break;
        }
      }
      
      if (mounted) {
        setState(() {
          _allUsers = users;
          _totalUsers = users.length;
          _pendingCount = pendingCount;
          _approvedCount = approvedCount;
          _rejectedCount = rejectedCount;
          _isLoading = false;
        });
        _applyFilters();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading users: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _applyFilters() {
    List<Map<String, dynamic>> filtered = List.from(_allUsers);

    // Apply status filter
    if (_selectedFilter != 'all') {
      filtered = filtered.where((user) => (user['status'] ?? 'pending') == _selectedFilter).toList();
    }

    // Apply user type filter
    if (_selectedUserType != 'all') {
      filtered = filtered.where((user) {
        final role = user['role'];
        if (role is Map) {
          final userType = role['userType']?.toString().toLowerCase();
          return userType == _selectedUserType;
        }
        return false;
      }).toList();
    }

    // Apply role filter
    if (_selectedRole != 'all') {
      filtered = filtered.where((user) {
        final role = user['role'];
        if (role is Map) {
          final roleId = role['id']?.toString().toLowerCase();
          return roleId == _selectedRole;
        } else if (role is String) {
          return role.toLowerCase() == _selectedRole;
        }
        return false;
      }).toList();
    }

    // Apply search filter
    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((user) {
        final firstName = user['firstName']?.toString().toLowerCase() ?? '';
        final lastName = user['lastName']?.toString().toLowerCase() ?? '';
        final email = user['email']?.toString().toLowerCase() ?? '';
        final role = user['role'];
        String roleName = '';
        if (role is Map) {
          roleName = role['name']?.toString().toLowerCase() ?? '';
        } else if (role is String) {
          roleName = role.toLowerCase();
        }
        
        final query = _searchQuery.toLowerCase();
        return firstName.contains(query) ||
               lastName.contains(query) ||
               email.contains(query) ||
               roleName.contains(query) ||
               '$firstName $lastName'.contains(query);
      }).toList();
    }

    setState(() {
      _filteredUsers = filtered;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text(
          'User Management',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.blue,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          // Filter dropdown
          Container(
            margin: const EdgeInsets.only(right: 16),
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _selectedFilter,
                style: const TextStyle(color: Colors.white),
                dropdownColor: Colors.blue.shade800,
                icon: const Icon(Icons.filter_list, color: Colors.white),
                items: _statusFilters.map((String filter) {
                  return DropdownMenuItem<String>(
                    value: filter,
                    child: Text(
                      filter.toUpperCase(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  setState(() {
                    _selectedFilter = newValue ?? 'all';
                  });
                  _applyFilters();
                },
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Search Bar
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.white,
            child: TextField(
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
                _applyFilters();
              },
              decoration: InputDecoration(
                hintText: 'Search by name, email, or role...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Colors.blue),
                ),
                filled: true,
                fillColor: Colors.grey.shade50,
              ),
            ),
          ),
          
          // Filter Chips
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: Colors.white,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildFilterChip('User Type', _selectedUserType, _userTypeFilters, (value) {
                    setState(() {
                      _selectedUserType = value;
                    });
                    _applyFilters();
                  }),
                  const SizedBox(width: 8),
                  _buildFilterChip('Role', _selectedRole, _roleFilters, (value) {
                    setState(() {
                      _selectedRole = value;
                    });
                    _applyFilters();
                  }),
                ],
              ),
            ),
          ),
          
          // Statistics Cards
          _buildStatisticsCards(),
          
          // Users List
          Expanded(
            child: _isLoading 
                ? const Center(child: CircularProgressIndicator())
                : _buildUsersList(),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, String selectedValue, List<String> options, Function(String) onChanged) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: selectedValue,
          style: const TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.w500,
            fontSize: 12,
          ),
          underline: Container(),
          items: options.map((String option) {
            return DropdownMenuItem<String>(
              value: option,
              child: Text(
                option.toUpperCase(),
                style: const TextStyle(fontSize: 12),
              ),
            );
          }).toList(),
          onChanged: (String? newValue) {
            if (newValue != null) {
              onChanged(newValue);
            }
          },
        ),
      ),
    );
  }

  Widget _buildStatisticsCards() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: _buildStatCard(
              'Total',
              Icons.people,
              Colors.blue,
              _totalUsers,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _buildStatCard(
              'Pending',
              Icons.pending_actions,
              Colors.orange,
              _pendingCount,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _buildStatCard(
              'Approved',
              Icons.check_circle,
              Colors.green,
              _approvedCount,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _buildStatCard(
              'Rejected',
              Icons.cancel,
              Colors.red,
              _rejectedCount,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, IconData icon, Color color, int count) {
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
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            count.toString(),
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: const TextStyle(
              fontSize: 12,
              color: Colors.black87,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUsersList() {
    if (_filteredUsers.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.people_outline,
              size: 64,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              'No users found',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey.shade600,
              ),
            ),
            if (_searchQuery.isNotEmpty || _selectedFilter != 'all' || _selectedUserType != 'all' || _selectedRole != 'all')
              Text(
                'Try adjusting your filters',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade500,
                ),
              ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _filteredUsers.length,
      itemBuilder: (context, index) {
        final userData = _filteredUsers[index];
        final userId = userData['uid'] as String;
        return _buildUserCard(userId, userData);
      },
    );
  }

  Widget _buildDocumentWidget(String documentUrl, String documentName) {
    // Check if it's a PDF file
    final fileExtension = _getFileExtension(documentUrl).toLowerCase();
    
    if (fileExtension == 'pdf') {
      return PDFViewerWidget(
        documentUrl: documentUrl,
        documentName: documentName,
      );
    } else {
      return DocumentViewerWidget(
        documentUrl: documentUrl,
        documentName: documentName,
      );
    }
  }

  String _getFileExtension(String url) {
    try {
      final uri = Uri.parse(url);
      final pathSegments = uri.pathSegments;
      if (pathSegments.isNotEmpty) {
        final fileName = pathSegments.last;
        final dotIndex = fileName.lastIndexOf('.');
        if (dotIndex != -1 && dotIndex < fileName.length - 1) {
          return fileName.substring(dotIndex + 1);
        }
      }
    } catch (e) {
      // If parsing fails, try to extract from URL string
      final dotIndex = url.lastIndexOf('.');
      if (dotIndex != -1 && dotIndex < url.length - 1) {
        return url.substring(dotIndex + 1);
      }
    }
    return '';
  }

  Widget _buildUserCard(String userId, Map<String, dynamic> userData) {
    final firstName = userData['firstName'] ?? '';
    final lastName = userData['lastName'] ?? '';
    final email = userData['email'] ?? '';
    final status = userData['status'] ?? 'pending';
    final role = userData['role'];
    final documents = userData['documents'] as List<dynamic>?;
    final uploadedAt = userData['uploadedAt'] as Timestamp?;
    final createdAt = userData['createdAt'] as Timestamp?;
    final isActive = userData['isActive'] ?? true;

    // Extract role information
    String roleName = 'Unknown';
    String userType = 'public';
    Color roleColor = Colors.grey;
    IconData roleIcon = Icons.person;
    
    if (role is Map) {
      roleName = role['name'] ?? 'Unknown';
      userType = role['userType'] ?? 'public';
      roleColor = _getRoleColor(role['id'] ?? '');
      roleIcon = _getRoleIcon(role['id'] ?? '');
    } else if (role is String) {
      roleName = role;
      roleColor = _getRoleColor(role);
      roleIcon = _getRoleIcon(role);
    }

    Color statusColor;
    IconData statusIcon;
    switch (status) {
      case 'approved':
        statusColor = Colors.green;
        statusIcon = Icons.check_circle;
        break;
      case 'rejected':
        statusColor = Colors.red;
        statusIcon = Icons.cancel;
        break;
      default:
        statusColor = Colors.orange;
        statusIcon = Icons.pending_actions;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
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
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        childrenPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        title: Row(
          children: [
            CircleAvatar(
              backgroundColor: statusColor.withOpacity(0.2),
              child: Icon(
                statusIcon,
                color: statusColor,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$firstName $lastName',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  Text(
                    email,
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 14,
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
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    status.toUpperCase(),
                    style: TextStyle(
                      color: statusColor,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(roleIcon, size: 14, color: roleColor),
                    const SizedBox(width: 4),
                    Text(
                      roleName,
                      style: TextStyle(
                        color: roleColor,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                if (!isActive) ...[
                  const SizedBox(height: 2),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      'INACTIVE',
                      style: TextStyle(
                        color: Colors.red,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
        children: [
          // User Details
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // User Information Grid
                Row(
                  children: [
                    Expanded(
                      child: _buildInfoItem('Role', roleName),
                    ),
                    Expanded(
                      child: _buildInfoItem('User Type', userType.toUpperCase()),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: _buildInfoItem(
                        'Created',
                        createdAt != null 
                            ? _formatDate(createdAt.toDate())
                            : 'Unknown',
                      ),
                    ),
                    Expanded(
                      child: _buildInfoItem(
                        'Status',
                        isActive ? 'Active' : 'Inactive',
                      ),
                    ),
                  ],
                ),
                if (uploadedAt != null) ...[
                  const SizedBox(height: 8),
                  _buildInfoItem(
                    'Documents Uploaded',
                    _formatDate(uploadedAt.toDate()),
                  ),
                ],
                
                // Documents Section with AI Validation
                if (documents != null && documents.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      const Text(
                        'Uploaded Documents:',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      const Spacer(),
                      if (status == 'pending')
                        ElevatedButton.icon(
                          onPressed: () => _validateDocumentsWithAI(userId, documents),
                          icon: const Icon(Icons.psychology, size: 16),
                          label: const Text('AI Validate'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.purple,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ...documents.asMap().entries.map((entry) => 
                    Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: _buildDocumentWidget(entry.value, 'Document ${entry.key + 1}'),
                    ),
                  ),
                ],
                
                // Action Buttons
                const SizedBox(height: 16),
                _buildActionButtons(userId, userData, status, isActive),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(String userId, Map<String, dynamic> userData, String status, bool isActive) {
    return Column(
      children: [
        // Status-based actions
        if (status == 'pending') ...[
          // PENDING: Only Approve/Reject
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _approveUser(userId),
                  icon: const Icon(Icons.check, size: 18),
                  label: const Text('Approve'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _rejectUser(userId),
                  icon: const Icon(Icons.close, size: 18),
                  label: const Text('Reject'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ] else if (status == 'rejected') ...[
          // REJECTED: Only Delete/View Details
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _showDeleteConfirmation(userId, userData),
                  icon: const Icon(Icons.delete, size: 18),
                  label: const Text('Delete'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _showUserDetails(userData),
                  icon: const Icon(Icons.info_outline, size: 18),
                  label: const Text('View Details'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ] else if (status == 'approved') ...[
          // APPROVED: Activate/Deactivate, Delete, View Details
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _toggleUserActiveStatus(userId, !isActive),
                  icon: Icon(isActive ? Icons.pause : Icons.play_arrow, size: 18),
                  label: Text(isActive ? 'Deactivate' : 'Activate'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isActive ? Colors.orange : Colors.green,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _showDeleteConfirmation(userId, userData),
                  icon: const Icon(Icons.delete, size: 18),
                  label: const Text('Delete'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => _showUserDetails(userData),
              icon: const Icon(Icons.info_outline, size: 18),
              label: const Text('View Full Details'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildInfoItem(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.grey.shade600,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Color _getRoleColor(String roleId) {
    switch (roleId.toLowerCase()) {
      case 'admin':
        return Colors.red;
      case 'journalist':
        return Colors.blue;
      case 'ngo':
        return Colors.green;
      case 'contractor':
        return Colors.orange;
      case 'researcher':
        return Colors.purple;
      case 'activist':
      case 'community_leader':
        return Colors.teal;
      case 'citizen':
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }

  IconData _getRoleIcon(String roleId) {
    switch (roleId.toLowerCase()) {
      case 'admin':
        return Icons.admin_panel_settings;
      case 'journalist':
        return Icons.mic;
      case 'ngo':
        return Icons.business;
      case 'contractor':
        return Icons.build;
      case 'researcher':
        return Icons.school;
      case 'activist':
      case 'community_leader':
        return Icons.group;
      case 'citizen':
        return Icons.person;
      default:
        return Icons.person;
    }
  }

  Future<void> _approveUser(String userId) async {
    try {
      setState(() => _isLoading = true);
      
      await _userService.updateUserStatus(userId, 'approved');
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('User approved successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        _loadData(); // Reload data to update UI
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error approving user: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _rejectUser(String userId) async {
    // Show dialog to enter rejection message
    final TextEditingController messageController = TextEditingController();
    
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reject User'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Please provide a reason for rejecting this user:'),
            const SizedBox(height: 16),
            TextField(
              controller: messageController,
              decoration: const InputDecoration(
                labelText: 'Rejection Reason',
                hintText: 'Enter the reason for rejection...',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
              maxLength: 200,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (messageController.text.trim().isNotEmpty) {
                Navigator.of(context).pop(true);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Please enter a rejection reason'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Reject'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        setState(() => _isLoading = true);
        
        // Update user status to rejected with message
        await FirebaseFirestore.instance.collection('users').doc(userId).update({
          'status': 'rejected',
          'rejectionMessage': messageController.text.trim(),
          'rejectedAt': FieldValue.serverTimestamp(),
          'rejectedBy': FirebaseAuth.instance.currentUser?.uid,
        });
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('User rejected successfully!'),
              backgroundColor: Colors.red,
            ),
          );
          _loadData(); // Reload data to update UI
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error rejecting user: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } finally {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _toggleUserActiveStatus(String userId, bool isActive) async {
    try {
      setState(() => _isLoading = true);
      
      await _userService.updateUserActiveStatus(userId, isActive);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('User ${isActive ? 'activated' : 'deactivated'} successfully!'),
            backgroundColor: isActive ? Colors.green : Colors.orange,
          ),
        );
        _loadData(); // Reload data to update UI
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating user status: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _showDeleteConfirmation(String userId, Map<String, dynamic> userData) async {
    final firstName = userData['firstName'] ?? '';
    final lastName = userData['lastName'] ?? '';
    final role = userData['role'];
    String roleName = 'Unknown';
    if (role is Map) {
      roleName = role['name'] ?? 'Unknown';
    } else if (role is String) {
      roleName = role;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete User Account'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Are you sure you want to delete this user account?'),
            const SizedBox(height: 8),
            Text('Name: $firstName $lastName'),
            Text('Role: $roleName'),
            const SizedBox(height: 8),
            const Text(
              'This action cannot be undone. The user will no longer be able to access the system.',
              style: TextStyle(color: Colors.red, fontSize: 12),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _deleteUser(userId);
    }
  }

  Future<void> _deleteUser(String userId) async {
    try {
      setState(() => _isLoading = true);
      
      await _adminService.deleteUser(userId);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('User deleted from database successfully! User can no longer login through the app.'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 4),
          ),
        );
        _loadData(); // Reload data to update UI
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error deleting user: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _showUserDetails(Map<String, dynamic> userData) async {
    await showDialog(
      context: context,
      builder: (context) => UserDetailsDialog(userData: userData),
    );
  }

  Future<void> _validateDocumentsWithAI(String userId, List<dynamic> documents) async {
    try {
      setState(() => _isLoading = true);
      
      // Get user role for AI validation
      final userDoc = await FirebaseFirestore.instance.collection('users').doc(userId).get();
      final userData = userDoc.data() as Map<String, dynamic>;
      final role = userData['role'];
      String userRole = 'citizen';
      
      if (role is Map) {
        userRole = role['id'] ?? 'citizen';
      } else if (role is String) {
        userRole = role;
      }

      // Show AI validation dialog
      if (mounted) {
        await showDialog(
          context: context,
          builder: (context) => DocumentAIValidationWidget(
            userId: userId,
            documents: documents.cast<String>(),
            userRole: userRole,
            onValidationComplete: (result) {
              // Handle validation result
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('AI Validation completed: ${result.overallRecommendation}'),
                  backgroundColor: result.overallRecommendation == 'APPROVE' ? Colors.green : Colors.orange,
                ),
              );
            },
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error validating documents: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}

// User Details Dialog
class UserDetailsDialog extends StatelessWidget {
  final Map<String, dynamic> userData;

  const UserDetailsDialog({super.key, required this.userData});

  @override
  Widget build(BuildContext context) {
    final firstName = userData['firstName'] ?? '';
    final lastName = userData['lastName'] ?? '';
    final email = userData['email'] ?? '';
    final status = userData['status'] ?? 'pending';
    final role = userData['role'];
    final documents = userData['documents'] as List<dynamic>?;
    final uploadedAt = userData['uploadedAt'] as Timestamp?;
    final createdAt = userData['createdAt'] as Timestamp?;
    final isActive = userData['isActive'] ?? true;
    final emailVerified = userData['emailVerified'] ?? false;

    String roleName = 'Unknown';
    String userType = 'public';
    if (role is Map) {
      roleName = role['name'] ?? 'Unknown';
      userType = role['userType'] ?? 'public';
    } else if (role is String) {
      roleName = role;
    }

    return Dialog(
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        height: MediaQuery.of(context).size.height * 0.8,
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text(
                  'User Details',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Basic Information
                    _buildDetailSection('Basic Information', [
                      _buildDetailRow('Name', '$firstName $lastName'),
                      _buildDetailRow('Email', email),
                      _buildDetailRow('Email Verified', emailVerified ? 'Yes' : 'No'),
                      _buildDetailRow('Status', status.toUpperCase()),
                      _buildDetailRow('Account Status', isActive ? 'Active' : 'Inactive'),
                    ]),
                    
                    const SizedBox(height: 20),
                    
                    // Role Information
                    _buildDetailSection('Role Information', [
                      _buildDetailRow('Role', roleName),
                      _buildDetailRow('User Type', userType.toUpperCase()),
                    ]),
                    
                    const SizedBox(height: 20),
                    
                    // Timestamps
                    _buildDetailSection('Timestamps', [
                      _buildDetailRow('Created', createdAt != null ? _formatDate(createdAt.toDate()) : 'Unknown'),
                      if (uploadedAt != null)
                        _buildDetailRow('Documents Uploaded', _formatDate(uploadedAt.toDate())),
                    ]),
                    
                    const SizedBox(height: 20),
                    
                    // Documents
                    if (documents != null && documents.isNotEmpty) ...[
                      _buildDetailSection('Uploaded Documents', [
                        for (int i = 0; i < documents.length; i++)
                          _buildDetailRow('Document ${i + 1}', documents[i]),
                      ]),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.blue,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: Column(
            children: children,
          ),
        ),
      ],
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.grey,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }
}
