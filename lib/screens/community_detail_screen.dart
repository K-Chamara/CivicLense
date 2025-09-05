import 'package:flutter/material.dart';
import '../models/community_models.dart';
import '../services/community_service.dart';
import 'community_posts_screen.dart';

class CommunityDetailScreen extends StatefulWidget {
  final Community community;

  const CommunityDetailScreen({super.key, required this.community});

  @override
  State<CommunityDetailScreen> createState() => _CommunityDetailScreenState();
}

class _CommunityDetailScreenState extends State<CommunityDetailScreen> {
  final CommunityService _communityService = CommunityService();
  bool _isMember = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _checkMembership();
  }

  Future<void> _checkMembership() async {
    try {
      final isMember = await _communityService.isUserMember(widget.community.id);
      setState(() {
        _isMember = isMember;
      });
    } catch (e) {
      print('Error checking membership: $e');
    }
  }

  Future<void> _joinCommunity() async {
    setState(() {
      _isLoading = true;
    });

    try {
      await _communityService.joinCommunity(widget.community.id);
      setState(() {
        _isMember = true;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Successfully joined the community!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error joining community: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _leaveCommunity() async {
    setState(() {
      _isLoading = true;
    });

    try {
      await _communityService.leaveCommunity(widget.community.id);
      setState(() {
        _isMember = false;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Successfully left the community'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error leaving community: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(
          widget.community.name,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: Colors.blue,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: _showCommunityInfo,
            tooltip: 'Community Info',
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Community Header
            Container(
              width: double.infinity,
              decoration: const BoxDecoration(
                color: Colors.blue,
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(24),
                  bottomRight: Radius.circular(24),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    // Community Icon
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(40),
                      ),
                      child: Center(
                        child: Text(
                          CommunityCategory.categoryIcons[widget.community.category] ?? '📋',
                          style: const TextStyle(fontSize: 36),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    // Community Name
                    Text(
                      widget.community.name,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    
                    // Category
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(
                        widget.community.category,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    // Member Count
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.people, color: Colors.white, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          '${widget.community.memberCount} members',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            
            // Community Content
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Description
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'About',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            widget.community.description,
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[700],
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Tags
                  if (widget.community.tags.isNotEmpty) ...[
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Tags',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: widget.community.tags.map((tag) {
                                return Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: Colors.blue.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(color: Colors.blue.withOpacity(0.3)),
                                  ),
                                  child: Text(
                                    '#$tag',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.blue[700],
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                  
                  // Rules
                  if (widget.community.rules.isNotEmpty) ...[
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Community Rules',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                            const SizedBox(height: 8),
                            ...widget.community.rules.map((rule) {
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 4),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text('• ', style: TextStyle(color: Colors.blue)),
                                    Expanded(
                                      child: Text(
                                        rule,
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: Colors.grey[700],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }).toList(),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                  
                  // Creator Info
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          CircleAvatar(
                            backgroundColor: Colors.blue.withOpacity(0.1),
                            child: const Icon(Icons.person, color: Colors.blue),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Created by',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey,
                                  ),
                                ),
                                Text(
                                  widget.community.createdByName,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.black87,
                                  ),
                                ),
                                Text(
                                  _formatDate(widget.community.createdAt),
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  // Action Buttons
                  if (_isMember) ...[
                    // View Posts Button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => CommunityPostsScreen(community: widget.community),
                            ),
                          );
                        },
                        icon: const Icon(Icons.forum),
                        label: const Text('View Posts & Discussions'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    
                    // Leave Community Button
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: _isLoading ? null : _leaveCommunity,
                        icon: _isLoading 
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(Icons.exit_to_app),
                        label: Text(_isLoading ? 'Leaving...' : 'Leave Community'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.red,
                          side: const BorderSide(color: Colors.red),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                  ] else ...[
                    // Join Community Button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _isLoading ? null : _joinCommunity,
                        icon: _isLoading 
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(Icons.person_add),
                        label: Text(_isLoading ? 'Joining...' : 'Join Community'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
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

  void _showCommunityInfo() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(widget.community.name),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Category: ${widget.community.category}'),
            const SizedBox(height: 8),
            Text('Members: ${widget.community.memberCount}'),
            const SizedBox(height: 8),
            Text('Privacy: ${widget.community.privacy}'),
            const SizedBox(height: 8),
            Text('Created: ${_formatDate(widget.community.createdAt)}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}
