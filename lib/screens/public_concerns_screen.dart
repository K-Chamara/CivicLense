import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/concern_models.dart';
import '../services/concern_service.dart';
import 'concern_detail_screen.dart';

class PublicConcernsScreen extends StatefulWidget {
  const PublicConcernsScreen({super.key});

  @override
  State<PublicConcernsScreen> createState() => _PublicConcernsScreenState();
}

class _PublicConcernsScreenState extends State<PublicConcernsScreen>
    with SingleTickerProviderStateMixin {
  final ConcernService _concernService = ConcernService();
  final TextEditingController _searchController = TextEditingController();
  late TabController _tabController;
  
  String _searchQuery = '';
  Map<String, bool> _userSupportStatus = {};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _checkUserSupportStatus(String concernId) async {
    try {
      final isSupporting = await _concernService.isUserSupporting(concernId);
      if (mounted) {
        setState(() {
          _userSupportStatus[concernId] = isSupporting;
        });
      }
    } catch (e) {
      print('Error checking support status: $e');
    }
  }

  Future<void> _toggleSupport(String concernId) async {
    try {
      await _concernService.toggleSupport(concernId);
      await _checkUserSupportStatus(concernId);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _userSupportStatus[concernId] == true 
                ? 'Support added! 🎉' 
                : 'Support removed'
            ),
            backgroundColor: _userSupportStatus[concernId] == true 
              ? Colors.green 
              : Colors.orange,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Widget _buildConcernCard(Concern concern) {
    final isSupporting = _userSupportStatus[concern.id] ?? false;
    
    // Check support status when building the card (only if not already checked)
    if (!_userSupportStatus.containsKey(concern.id)) {
      _checkUserSupportStatus(concern.id);
    }
    
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 2,
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ConcernDetailScreen(
                concern: concern,
                officerId: 'public_user',
                officerName: 'Public User',
              ),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with category and priority
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _getCategoryColor(concern.category),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      concern.category.name.toUpperCase(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _getPriorityColor(concern.priority),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      concern.priority.name.toUpperCase(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const Spacer(),
                  Text(
                    _formatDate(concern.createdAt),
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              
              // Title
              Text(
                concern.title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),
              
              // Description
              Text(
                concern.description,
                style: TextStyle(
                  color: Colors.grey[700],
                  fontSize: 14,
                ),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 12),
              
              // Author and status
              Row(
                children: [
                  Icon(
                    Icons.person,
                    size: 16,
                    color: Colors.grey[600],
                  ),
                  const SizedBox(width: 4),
                  Text(
                    concern.isAnonymous ? 'Anonymous' : concern.authorName,
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 12,
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _getStatusColor(concern.status),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      concern.status.name.toUpperCase(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              
              // Support button and stats
              Row(
                children: [
                  ElevatedButton.icon(
                    onPressed: () => _toggleSupport(concern.id),
                    icon: Icon(
                      isSupporting ? Icons.thumb_up : Icons.thumb_up_outlined,
                      color: isSupporting ? Colors.white : Colors.blue,
                    ),
                    label: Text(
                      'Support (${concern.supportCount})',
                      style: TextStyle(
                        color: isSupporting ? Colors.white : Colors.blue,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isSupporting ? Colors.blue : Colors.blue.shade50,
                      elevation: isSupporting ? 2 : 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Icon(
                    Icons.comment,
                    size: 16,
                    color: Colors.grey[600],
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${concern.commentCount}',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 12,
                    ),
                  ),
                  const Spacer(),
                  if (concern.tags.isNotEmpty)
                    Wrap(
                      spacing: 4,
                      children: concern.tags.take(2).map((tag) => Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '#$tag',
                          style: TextStyle(
                            color: Colors.grey[700],
                            fontSize: 10,
                          ),
                        ),
                      )).toList(),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getCategoryColor(ConcernCategory category) {
    switch (category) {
      case ConcernCategory.budget:
        return Colors.blue;
      case ConcernCategory.tender:
        return Colors.green;
      case ConcernCategory.community:
        return Colors.purple;
      case ConcernCategory.system:
        return Colors.orange;
      case ConcernCategory.corruption:
        return Colors.red;
      case ConcernCategory.transparency:
        return Colors.teal;
      case ConcernCategory.other:
        return Colors.grey;
    }
  }

  Color _getPriorityColor(ConcernPriority priority) {
    switch (priority) {
      case ConcernPriority.low:
        return Colors.green;
      case ConcernPriority.medium:
        return Colors.orange;
      case ConcernPriority.high:
        return Colors.red;
      case ConcernPriority.critical:
        return Colors.purple;
    }
  }

  Color _getStatusColor(ConcernStatus status) {
    switch (status) {
      case ConcernStatus.pending:
        return Colors.orange;
      case ConcernStatus.underReview:
        return Colors.blue;
      case ConcernStatus.inProgress:
        return Colors.purple;
      case ConcernStatus.resolved:
        return Colors.green;
      case ConcernStatus.dismissed:
        return Colors.grey;
      case ConcernStatus.escalated:
        return Colors.red;
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);
    
    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Public Concerns'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(text: 'Most Supported', icon: Icon(Icons.trending_up)),
            Tab(text: 'Recent', icon: Icon(Icons.access_time)),
            Tab(text: 'Trending', icon: Icon(Icons.whatshot)),
          ],
        ),
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search concerns...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
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
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
            ),
          ),
          
          // Tab content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                // Most Supported
                _searchQuery.isEmpty
                    ? StreamBuilder<List<Concern>>(
                        stream: _concernService.getPublicConcernsBySupport(),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState == ConnectionState.waiting) {
                            return const Center(child: CircularProgressIndicator());
                          }
                          
                          if (snapshot.hasError) {
                            // Fallback to simpler query if there's an error
                            return StreamBuilder<List<Concern>>(
                              stream: _concernService.getAllPublicConcerns(),
                              builder: (context, fallbackSnapshot) {
                                if (fallbackSnapshot.connectionState == ConnectionState.waiting) {
                                  return const Center(child: CircularProgressIndicator());
                                }
                                
                                if (fallbackSnapshot.hasError) {
                                  return Center(
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        const Icon(Icons.error, size: 64, color: Colors.red),
                                        const SizedBox(height: 16),
                                        Text('Error loading concerns: ${fallbackSnapshot.error}'),
                                        const SizedBox(height: 16),
                                        ElevatedButton(
                                          onPressed: () => setState(() {}),
                                          child: const Text('Retry'),
                                        ),
                                      ],
                                    ),
                                  );
                                }
                                
                                final concerns = fallbackSnapshot.data ?? [];
                                if (concerns.isEmpty) {
                                  return const Center(
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(Icons.inbox, size: 64, color: Colors.grey),
                                        SizedBox(height: 16),
                                        Text('No concerns yet', style: TextStyle(fontSize: 18, color: Colors.grey)),
                                        Text('Be the first to raise a concern!', style: TextStyle(color: Colors.grey)),
                                      ],
                                    ),
                                  );
                                }
                                
                                // Sort by support count in memory
                                concerns.sort((a, b) => b.supportCount.compareTo(a.supportCount));
                                
                                return RefreshIndicator(
                                  onRefresh: () async => setState(() {}),
                                  child: ListView.builder(
                                    itemCount: concerns.length,
                                    itemBuilder: (context, index) => _buildConcernCard(concerns[index]),
                                  ),
                                );
                              },
                            );
                          }
                          
                          final concerns = snapshot.data ?? [];
                          
                          if (concerns.isEmpty) {
                            return const Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.inbox,
                                    size: 64,
                                    color: Colors.grey,
                                  ),
                                  SizedBox(height: 16),
                                  Text(
                                    'No concerns yet',
                                    style: TextStyle(
                                      fontSize: 18,
                                      color: Colors.grey,
                                    ),
                                  ),
                                  Text(
                                    'Be the first to raise a concern!',
                                    style: TextStyle(
                                      color: Colors.grey,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }
                          
                          return RefreshIndicator(
                            onRefresh: () async {
                              setState(() {});
                            },
                            child: ListView.builder(
                              itemCount: concerns.length,
                              itemBuilder: (context, index) {
                                return _buildConcernCard(concerns[index]);
                              },
                            ),
                          );
                        },
                      )
                    : StreamBuilder<List<Concern>>(
                        stream: _concernService.searchConcerns(_searchQuery),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState == ConnectionState.waiting) {
                            return const Center(child: CircularProgressIndicator());
                          }
                          
                          if (snapshot.hasError) {
                            return Center(
                              child: Text('Error: ${snapshot.error}'),
                            );
                          }
                          
                          final concerns = snapshot.data ?? [];
                          
                          if (concerns.isEmpty) {
                            return const Center(
                              child: Text('No concerns found matching your search.'),
                            );
                          }
                          
                          return ListView.builder(
                            itemCount: concerns.length,
                            itemBuilder: (context, index) {
                              return _buildConcernCard(concerns[index]);
                            },
                          );
                        },
                      ),
                
                // Recent
                StreamBuilder<List<Concern>>(
                  stream: _concernService.getAllPublicConcerns(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    
                    if (snapshot.hasError) {
                      // Fallback to simpler query if there's an error
                      return StreamBuilder<List<Concern>>(
                        stream: _concernService.getAllPublicConcerns(),
                        builder: (context, fallbackSnapshot) {
                          if (fallbackSnapshot.connectionState == ConnectionState.waiting) {
                            return const Center(child: CircularProgressIndicator());
                          }
                          
                          if (fallbackSnapshot.hasError) {
                            return Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(Icons.error, size: 64, color: Colors.red),
                                  const SizedBox(height: 16),
                                  Text('Error loading concerns: ${fallbackSnapshot.error}'),
                                  const SizedBox(height: 16),
                                  ElevatedButton(
                                    onPressed: () => setState(() {}),
                                    child: const Text('Retry'),
                                  ),
                                ],
                              ),
                            );
                          }
                          
                          final concerns = fallbackSnapshot.data ?? [];
                          // Sort by creation date (most recent first)
                          concerns.sort((a, b) => b.createdAt.compareTo(a.createdAt));
                          
                          if (concerns.isEmpty) {
                            return const Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.inbox, size: 64, color: Colors.grey),
                                  SizedBox(height: 16),
                                  Text('No concerns yet', style: TextStyle(fontSize: 18, color: Colors.grey)),
                                ],
                              ),
                            );
                          }
                          
                          return RefreshIndicator(
                            onRefresh: () async => setState(() {}),
                            child: ListView.builder(
                              itemCount: concerns.length,
                              itemBuilder: (context, index) => _buildConcernCard(concerns[index]),
                            ),
                          );
                        },
                      );
                    }
                    
                    final concerns = snapshot.data ?? [];
                    // Sort by creation date (most recent first)
                    concerns.sort((a, b) => b.createdAt.compareTo(a.createdAt));
                    
                    if (concerns.isEmpty) {
                      return const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.inbox,
                              size: 64,
                              color: Colors.grey,
                            ),
                            SizedBox(height: 16),
                            Text(
                              'No concerns yet',
                              style: TextStyle(
                                fontSize: 18,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      );
                    }
                    
                    return RefreshIndicator(
                      onRefresh: () async {
                        setState(() {});
                      },
                      child: ListView.builder(
                        itemCount: concerns.length,
                        itemBuilder: (context, index) {
                          return _buildConcernCard(concerns[index]);
                        },
                      ),
                    );
                  },
                ),
                
                // Trending
                StreamBuilder<List<Concern>>(
                  stream: _concernService.getTrendingConcerns(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    
                    if (snapshot.hasError) {
                      // Fallback to simpler query if there's an error
                      return StreamBuilder<List<Concern>>(
                        stream: _concernService.getAllPublicConcerns(),
                        builder: (context, fallbackSnapshot) {
                          if (fallbackSnapshot.connectionState == ConnectionState.waiting) {
                            return const Center(child: CircularProgressIndicator());
                          }
                          
                          if (fallbackSnapshot.hasError) {
                            return Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(Icons.error, size: 64, color: Colors.red),
                                  const SizedBox(height: 16),
                                  Text('Error loading concerns: ${fallbackSnapshot.error}'),
                                  const SizedBox(height: 16),
                                  ElevatedButton(
                                    onPressed: () => setState(() {}),
                                    child: const Text('Retry'),
                                  ),
                                ],
                              ),
                            );
                          }
                          
                          final concerns = fallbackSnapshot.data ?? [];
                          if (concerns.isEmpty) {
                            return const Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.trending_up, size: 64, color: Colors.grey),
                                  SizedBox(height: 16),
                                  Text('No trending concerns', style: TextStyle(fontSize: 18, color: Colors.grey)),
                                  Text('Check back later for trending topics!', style: TextStyle(color: Colors.grey)),
                                ],
                              ),
                            );
                          }
                          
                          // Sort by support count for trending
                          concerns.sort((a, b) => b.supportCount.compareTo(a.supportCount));
                          
                          return RefreshIndicator(
                            onRefresh: () async => setState(() {}),
                            child: ListView.builder(
                              itemCount: concerns.length,
                              itemBuilder: (context, index) => _buildConcernCard(concerns[index]),
                            ),
                          );
                        },
                      );
                    }
                    
                    final concerns = snapshot.data ?? [];
                    
                    if (concerns.isEmpty) {
                      return const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.trending_up,
                              size: 64,
                              color: Colors.grey,
                            ),
                            SizedBox(height: 16),
                            Text(
                              'No trending concerns',
                              style: TextStyle(
                                fontSize: 18,
                                color: Colors.grey,
                              ),
                            ),
                            Text(
                              'Check back later for trending topics!',
                              style: TextStyle(
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      );
                    }
                    
                    return RefreshIndicator(
                      onRefresh: () async {
                        setState(() {});
                      },
                      child: ListView.builder(
                        itemCount: concerns.length,
                        itemBuilder: (context, index) {
                          return _buildConcernCard(concerns[index]);
                        },
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.pushNamed(context, '/raise-concern');
        },
        icon: const Icon(Icons.add),
        label: const Text('Raise Concern'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
    );
  }
}
