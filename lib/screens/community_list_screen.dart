import 'package:flutter/material.dart';
import '../models/community_models.dart';
import '../models/user_role.dart';
import '../services/community_service.dart';
import '../services/auth_service.dart';
import 'create_community_screen.dart';
import 'community_detail_screen.dart';
import 'raise_concern_screen.dart';

class CommunityListScreen extends StatefulWidget {
  const CommunityListScreen({super.key});

  @override
  State<CommunityListScreen> createState() => _CommunityListScreenState();
}

class _CommunityListScreenState extends State<CommunityListScreen> {
  final CommunityService _communityService = CommunityService();
  final AuthService _authService = AuthService();
  String _selectedCategory = 'All';
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();
  UserRole? userRole;

  @override
  void initState() {
    super.initState();
    _loadUserRole();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadUserRole() async {
    final user = _authService.currentUser;
    if (user != null) {
      final role = await _authService.getUserRole(user.uid);
      setState(() {
        userRole = role;
      });
    }
  }

  bool _canCreateCommunities() {
    // Only System Admins and Community Leaders/Activists can create communities
    // Citizens can only join and participate
    if (userRole == null) return false;
    
    return userRole!.id == 'admin' || 
           userRole!.id == 'community_leader' || 
           userRole!.id == 'activist';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          'Communities',
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
            icon: const Icon(Icons.report_problem),
            onPressed: _raiseCommunityConcern,
            tooltip: 'Raise Community Concern',
          ),
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: _showInfoDialog,
            tooltip: 'About Communities',
          ),
        ],
      ),
      body: Column(
        children: [
          // Search and Filter Section
          Container(
            color: Colors.white,
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Search Bar
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search communities...',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _searchController.clear();
                              setState(() {
                                _searchQuery = '';
                              });
                            },
                          )
                        : null,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: Colors.grey[100],
                  ),
                  onChanged: (value) {
                    setState(() {
                      _searchQuery = value.toLowerCase();
                    });
                  },
                ),
                const SizedBox(height: 16),
                
                // Category Filter
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildCategoryChip('All', _selectedCategory == 'All'),
                      const SizedBox(width: 8),
                      ...CommunityCategory.categories.map((category) {
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: _buildCategoryChip(category, _selectedCategory == category),
                        );
                      }),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          // Communities List
          Expanded(
            child: StreamBuilder<List<Community>>(
              stream: _communityService.getCommunities(
                category: _selectedCategory == 'All' ? null : _selectedCategory,
                searchQuery: _searchQuery.isEmpty ? null : _searchQuery,
              ),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.error_outline,
                          size: 64,
                          color: Colors.red[300],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Error loading communities',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.red[700],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Exception: ${snapshot.error}',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.red[600],
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () {
                            setState(() {});
                          },
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  );
                }

                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.people_outline,
                          size: 64,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No communities found',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _canCreateCommunities() 
                              ? 'Try adjusting your filters or create a new community'
                              : 'Try adjusting your filters. Only Community Leaders can create new communities.',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[500],
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  );
                }

                final communities = snapshot.data!;

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: communities.length,
                  itemBuilder: (context, index) {
                    final community = communities[index];
                    return _buildCommunityCard(community);
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: _canCreateCommunities() 
          ? FloatingActionButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const CreateCommunityScreen()),
                );
              },
              backgroundColor: Colors.blue,
              child: const Icon(Icons.add, color: Colors.white),
              tooltip: 'Create Community',
            )
          : null,
    );
  }

  Widget _buildCategoryChip(String category, bool isSelected) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedCategory = category;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? Colors.blue : Colors.grey[200],
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? Colors.blue : Colors.grey[300]!,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (category != 'All') ...[
              Text(
                CommunityCategory.categoryIcons[category] ?? '📋',
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(width: 4),
            ],
            Text(
              category,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.grey[700],
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCommunityCard(Community community) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => CommunityDetailScreen(community: community),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Row
              Row(
                children: [
                  // Community Icon
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(25),
                    ),
                    child: Center(
                      child: Text(
                        CommunityCategory.categoryIcons[community.category] ?? '📋',
                        style: const TextStyle(fontSize: 24),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  
                  // Community Info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          community.name,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          community.category,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.blue[600],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  // Member Count
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.people, size: 16, color: Colors.grey[600]),
                        const SizedBox(width: 4),
                        Text(
                          '${community.memberCount}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              
              // Description
              Text(
                community.description,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[700],
                  height: 1.4,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 12),
              
              // Tags
              if (community.tags.isNotEmpty) ...[
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: community.tags.take(3).map((tag) {
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.blue.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '#$tag',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.blue[700],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 8),
              ],
              
              // Footer
              Row(
                children: [
                  Icon(Icons.person, size: 16, color: Colors.grey[500]),
                  const SizedBox(width: 4),
                  Text(
                    'Created by ${community.createdByName}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[500],
                    ),
                  ),
                  const Spacer(),
                  Text(
                    _formatDate(community.createdAt),
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[500],
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

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date).inDays;
    
    if (difference == 0) {
      return 'Today';
    } else if (difference == 1) {
      return 'Yesterday';
    } else if (difference < 7) {
      return '$difference days ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }

  void _raiseCommunityConcern() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const RaiseConcernScreen(
          preSelectedCategory: 'community',
        ),
      ),
    );
  }

  void _showInfoDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('About Communities'),
        content: Text(
          'Communities are groups where citizens can discuss topics, share news, and engage with each other. You can join communities that interest you and participate in discussions.\n\n'
          '${_canCreateCommunities() ? "As a " + (userRole?.name ?? "user") + ", you can create and manage communities." : "Only Community Leaders and System Admins can create new communities. Citizens can join, post, and comment."}\n\n'
          'System Admins and Anti-Corruption Officers can view and moderate all communities.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Got it'),
          ),
        ],
      ),
    );
  }
}
