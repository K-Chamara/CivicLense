import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/media_hub_service.dart';
import '../models/report.dart';
import 'article_detail_screen.dart';

class MediaHubScreen extends StatefulWidget {
  const MediaHubScreen({super.key});

  @override
  State<MediaHubScreen> createState() => _MediaHubScreenState();
}

class _MediaHubScreenState extends State<MediaHubScreen> with TickerProviderStateMixin {
  final _hub = MediaHubService();
  late AnimationController _cardAnimationController;
  late Animation<double> _cardAnimation;
  
  final _searchController = TextEditingController();
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    
    _cardAnimationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    
    _cardAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _cardAnimationController, curve: Curves.easeInOut),
    );
    
    _cardAnimationController.forward();
  }

  @override
  void dispose() {
    _cardAnimationController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surfaceContainerLowest,
      appBar: AppBar(
        title: const Text('Media Hub - Saved Articles'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Theme.of(context).colorScheme.onPrimary,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(_isSearching ? Icons.close : Icons.search),
            onPressed: () {
              setState(() {
                _isSearching = !_isSearching;
                if (!_isSearching) {
                  _searchController.clear();
                }
              });
            },
            tooltip: _isSearching ? 'Close Search' : 'Search Articles',
          ),
        ],
      ),
      body: Column(
        children: [
          if (_isSearching) ...[
            Container(
              padding: const EdgeInsets.all(16),
              color: Colors.white,
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Search saved articles...',
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: Colors.grey[50],
                ),
                onChanged: (value) {
                  setState(() {});
                },
              ),
            ),
          ],
          Expanded(
            child: _buildSavedArticlesList(),
          ),
        ],
      ),
    );
  }

  Widget _buildSavedArticlesList() {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: _hub.streamSavedArticles(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error, size: 64, color: Colors.red),
                const SizedBox(height: 16),
                Text('Error loading saved articles: ${snapshot.error}'),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => setState(() {}),
                  child: const Text('Retry'),
                ),
              ],
            ),
          );
        }

        final articles = snapshot.data ?? [];
        
        // Filter articles based on search query
        final filteredArticles = _isSearching && _searchController.text.isNotEmpty
            ? articles.where((article) {
                final query = _searchController.text.toLowerCase();
                return article['title']?.toString().toLowerCase().contains(query) == true ||
                       article['summary']?.toString().toLowerCase().contains(query) == true ||
                       article['authorName']?.toString().toLowerCase().contains(query) == true;
              }).toList()
            : articles;

        if (filteredArticles.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  _isSearching ? Icons.search_off : Icons.bookmark_border,
                  size: 64,
                  color: Colors.grey[400],
                ),
                const SizedBox(height: 16),
                Text(
                  _isSearching 
                      ? 'No articles found matching your search'
                      : 'No saved articles yet',
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _isSearching
                      ? 'Try a different search term'
                      : 'Save articles from the news feed to view them here',
                  style: TextStyle(
                    color: Colors.grey[500],
                  ),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: filteredArticles.length,
          itemBuilder: (context, index) {
            final article = filteredArticles[index];
            return ScaleTransition(
              scale: _cardAnimation,
              child: _buildSavedArticleCard(article),
            );
          },
        );
      },
    );
  }

  Widget _buildSavedArticleCard(Map<String, dynamic> article) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: InkWell(
        onTap: () => _viewSavedArticle(article),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with title and remove button
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      article['title'] ?? 'Untitled',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.bookmark_remove, color: Colors.red),
                    onPressed: () => _removeSavedArticle(article['id']),
                    tooltip: 'Remove from saved articles',
                  ),
                ],
              ),
              const SizedBox(height: 8),
              
              // Author and organization
              Text(
                'By ${article['authorName'] ?? 'Unknown'} • ${article['organization'] ?? 'Unknown Organization'}',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 8),
              
              // Summary
              Text(
                article['summary'] ?? 'No summary available',
                style: const TextStyle(fontSize: 14),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 12),
              
              // Tags and metadata
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: [
                  if (article['category'] != null && article['category'].isNotEmpty)
                    _buildChip(article['category'], Colors.blue),
                  if (article['isBreakingNews'] == true)
                    _buildChip('Breaking', Colors.red),
                  if (article['isVerified'] == true)
                    _buildChip('Verified', Colors.green),
                  ...(article['hashtags'] as List<dynamic>? ?? [])
                      .take(3)
                      .map((tag) => _buildChip('#$tag', Colors.purple))
                      .toList(),
                ],
              ),
              const SizedBox(height: 8),
              
              // Saved date
              Text(
                'Saved on ${_formatDate(article['savedAt'])}',
                style: TextStyle(
                  color: Colors.grey[500],
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildChip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  String _formatDate(dynamic timestamp) {
    if (timestamp == null) return 'Unknown date';
    
    try {
      final date = timestamp is Timestamp 
          ? timestamp.toDate() 
          : DateTime.parse(timestamp.toString());
      return '${date.day}/${date.month}/${date.year}';
    } catch (e) {
      return 'Unknown date';
    }
  }

  void _viewSavedArticle(Map<String, dynamic> article) {
    // Navigate to a saved article detail screen
    // For now, we'll show a dialog with the article content
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(article['title'] ?? 'Article'),
        content: SizedBox(
          width: double.maxFinite,
          height: 400,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'By ${article['authorName'] ?? 'Unknown'} • ${article['organization'] ?? 'Unknown Organization'}',
                  style: TextStyle(color: Colors.grey[600]),
                ),
                const SizedBox(height: 16),
                if (article['abstractText'] != null && article['abstractText'].isNotEmpty) ...[
                  const Text(
                    'Abstract:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(article['abstractText']),
                  const SizedBox(height: 16),
                ],
                const Text(
                  'Summary:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(article['summary'] ?? 'No summary available'),
                const SizedBox(height: 16),
                const Text(
                  'Content:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(article['content'] ?? 'No content available'),
              ],
            ),
          ),
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

  Future<void> _removeSavedArticle(String savedArticleId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove Article'),
        content: const Text('Are you sure you want to remove this article from your saved articles?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Remove'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _hub.removeSavedArticle(savedArticleId);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Article removed from saved articles'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error removing article: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }
}