import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:share_plus/share_plus.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../services/news_service.dart';
import '../services/media_hub_service.dart';
import '../services/community_service.dart';
import '../models/report.dart';
import '../models/community_models.dart';
import 'edit_article_screen.dart';

class ArticleDetailScreen extends StatefulWidget {
  const ArticleDetailScreen({super.key});

  @override
  State<ArticleDetailScreen> createState() => _ArticleDetailScreenState();
}

class _ArticleDetailScreenState extends State<ArticleDetailScreen> with TickerProviderStateMixin {
  final _news = NewsService();
  final _hub = MediaHubService();
  final _communityService = CommunityService();
  final _commentController = TextEditingController();
  
  late AnimationController _likeAnimationController;
  late AnimationController _shareAnimationController;
  late Animation<double> _likeAnimation;
  late Animation<double> _shareAnimation;

  @override
  void initState() {
    super.initState();
    _likeAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _shareAnimationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    
    _likeAnimation = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(parent: _likeAnimationController, curve: Curves.elasticOut),
    );
    _shareAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _shareAnimationController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _commentController.dispose();
    _likeAnimationController.dispose();
    _shareAnimationController.dispose();
    super.dispose();
  }

  Future<void> _downloadPdf(ReportArticle a) async {
    final doc = pw.Document();
    doc.addPage(
      pw.MultiPage(
        build: (context) => [
          pw.Header(level: 0, child: pw.Text(a.title, style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold))),
          pw.Text('By ${a.authorName} • ${a.organization}'),
          pw.SizedBox(height: 10),
          if (a.category.isNotEmpty) pw.Text('Category: ${a.category}'),
          pw.SizedBox(height: 10),
          pw.Text('Abstract/Introduction', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
          pw.Text(a.abstractText),
          pw.SizedBox(height: 10),
          pw.Text('Summary', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
          pw.Text(a.summary),
          pw.SizedBox(height: 10),
          pw.Text('Content', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
          pw.Text(a.content),
          pw.SizedBox(height: 10),
          if (a.references.isNotEmpty) pw.Text('References', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
          if (a.references.isNotEmpty) pw.Text(a.references),
          pw.SizedBox(height: 10),
          if (a.hashtags.isNotEmpty) pw.Text('Tags: ${a.hashtags.map((e) => '#$e').join(', ')}'),
        ],
      ),
    );
    await Printing.layoutPdf(onLayout: (format) async => doc.save());
  }

  @override
  Widget build(BuildContext context) {
    final String articleId = ModalRoute.of(context)?.settings.arguments as String? ?? '';
    
    // Debug: Print current user info
    final currentUser = FirebaseAuth.instance.currentUser;
    print('=== AUTHENTICATION DEBUG ===');
    print('Current User: ${currentUser?.uid}');
    print('User Email: ${currentUser?.email}');
    print('User Display Name: ${currentUser?.displayName}');
    print('============================');
    
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surfaceContainerLowest,
      appBar: AppBar(
        title: const Text('Article'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Theme.of(context).colorScheme.onPrimary,
        elevation: 0,
        centerTitle: true,
        actions: [
          // Debug button to test authentication
          IconButton(
            icon: const Icon(Icons.info),
            onPressed: () {
              final currentUser = FirebaseAuth.instance.currentUser;
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Authentication Info'),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('User ID: ${currentUser?.uid ?? 'Not logged in'}'),
                      Text('Email: ${currentUser?.email ?? 'No email'}'),
                      Text('Display Name: ${currentUser?.displayName ?? 'No name'}'),
                    ],
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('OK'),
                    ),
                  ],
                ),
              );
            },
            tooltip: 'Auth Info',
          ),
          StreamBuilder<ReportArticle?>(
            stream: _news.streamArticle(articleId),
            builder: (context, snapshot) {
              if (!snapshot.hasData) return const SizedBox.shrink();
              final article = snapshot.data!;
              final currentUserId = FirebaseAuth.instance.currentUser?.uid;
              
              // Debug: Print authentication info
              print('=== EDIT BUTTON DEBUG ===');
              print('Current User ID: $currentUserId');
              print('Article Author UID: ${article.authorUid}');
              print('Article Title: ${article.title}');
              print('User authenticated: ${currentUserId != null && currentUserId.isNotEmpty}');
              print('Is Author: ${currentUserId != null && currentUserId.isNotEmpty && article.authorUid == currentUserId}');
              print('========================');
              
              // Only show edit button if user is authenticated and is the author
              if (currentUserId == null || currentUserId.isEmpty) {
                print('❌ No authenticated user - hiding edit button');
                return const SizedBox.shrink();
              }
              
              if (article.authorUid != currentUserId) {
                print('❌ User is not the author - hiding edit button');
                return const SizedBox.shrink();
              }
              
              print('✅ Showing edit button for author');
              return IconButton(
                icon: const Icon(Icons.edit),
                onPressed: () => _showEditOptions(article),
                tooltip: 'Edit Article',
              );
            },
          ),
          ScaleTransition(
            scale: _shareAnimation,
            child: IconButton(
              icon: const Icon(Icons.share_rounded),
              onPressed: () async {
                _shareAnimationController.forward().then((_) {
                  _shareAnimationController.reverse();
                });
                final a = await _news.getArticle(articleId);
                if (a == null) return;
                Share.share('${a.title}\n\n${a.summary}');
              },
            ),
          ),
        ],
      ),
      body: StreamBuilder<ReportArticle?>(
        stream: _news.streamArticle(articleId),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final a = snapshot.data!;
          return Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Banner image as header
                      if (a.bannerImageUrl != null) ...[
                        Container(
                          width: double.infinity,
                          height: 250,
                          decoration: BoxDecoration(
                            borderRadius: const BorderRadius.only(
                              bottomLeft: Radius.circular(20),
                              bottomRight: Radius.circular(20),
                            ),
                            image: DecorationImage(
                              image: NetworkImage(a.bannerImageUrl!),
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],
                      // Header section container (no shadow; bordered)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.black12),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(a.title, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
                            const SizedBox(height: 8),
                            Text('By ${a.authorName} • ${a.organization} • ${a.authorEmail}', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.black54)),
                            const SizedBox(height: 10),
                            Wrap(spacing: 6, children: [
                              if (a.isBreakingNews) _chip('Breaking', Colors.red),
                              if (a.isVerified) _chip('Verified', Colors.green),
                              if (a.category.isNotEmpty) _chip(a.category, Colors.blue),
                              ...a.hashtags.map((h) => _chip('#$h', Colors.purple)).toList(),
                            ]),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      // Content cards (no shadow; bordered)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.black12),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(a.abstractText, style: const TextStyle(fontStyle: FontStyle.italic)),
                            const SizedBox(height: 12),
                            Text(a.summary, style: Theme.of(context).textTheme.bodyMedium),
                            const SizedBox(height: 12),
                            Text(a.content, style: Theme.of(context).textTheme.bodyLarge),
                            if (a.references.isNotEmpty) ...[
                              const SizedBox(height: 16),
                              Text('References', style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
                              const SizedBox(height: 4),
                              Text(a.references, style: Theme.of(context).textTheme.bodySmall),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      // Actions row using chips for consistency
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          StreamBuilder<bool>(
                            stream: _news.streamUserLiked(a.id),
                            builder: (context, likedSnap) {
                              final liked = likedSnap.data == true;
                              return ScaleTransition(
                                scale: _likeAnimation,
                                child: ActionChip(
                                  avatar: Icon(
                                    liked ? Icons.thumb_up_rounded : Icons.thumb_up_outlined, 
                                    size: 18, 
                                    color: liked ? Theme.of(context).colorScheme.primary : null
                                  ),
                                  label: Text(liked ? 'Liked ${a.likeCount}' : 'Like ${a.likeCount}'),
                                  onPressed: () async {
                                    _likeAnimationController.forward().then((_) {
                                      _likeAnimationController.reverse();
                                    });
                                    try {
                                      await _news.toggleLike(a.id);
                                    } catch (e) {
                                      if (context.mounted) {
                                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
                                      }
                                    }
                                  },
                                  backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(liked ? 0.15 : 0.08),
                                  labelStyle: TextStyle(
                                    color: Theme.of(context).colorScheme.primary,
                                    fontWeight: FontWeight.w600,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                    side: BorderSide(
                                      color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
                                    ),
                                  ),
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                ),
                              );
                            },
                          ),
                          ActionChip(
                            avatar: const Icon(Icons.download, size: 18),
                            label: const Text('PDF'),
                            onPressed: () => _downloadPdf(a),
                            backgroundColor: Colors.grey.withOpacity(0.06),
                            shape: StadiumBorder(side: BorderSide(color: Colors.black12)),
                          ),
                          StreamBuilder<bool>(
                            stream: _hub.streamIsArticleSaved(a.id),
                            builder: (context, savedSnap) {
                              final isSaved = savedSnap.data ?? false;
                              return ActionChip(
                                avatar: Icon(
                                  isSaved ? Icons.bookmark : Icons.bookmark_border,
                                  size: 18,
                                  color: isSaved ? Colors.blue : null,
                                ),
                                label: Text(isSaved ? 'Saved' : 'Save to Media Hub'),
                                onPressed: () async {
                                  if (isSaved) {
                                    // Article is already saved, show message
                                    if (mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(
                                          content: Text('Article is already saved in your Media Hub'),
                                          backgroundColor: Colors.blue,
                                        ),
                                      );
                                    }
                                  } else {
                                    // Save the article
                                    try {
                                      await _hub.saveArticleFromReport(a);
                                      if (mounted) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(
                                            content: Text('Article saved to Media Hub'),
                                            backgroundColor: Colors.green,
                                          ),
                                        );
                                      }
                                    } catch (e) {
                                      if (mounted) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(
                                            content: Text('Error saving article: $e'),
                                            backgroundColor: Colors.red,
                                          ),
                                        );
                                      }
                                    }
                                  }
                                },
                                backgroundColor: isSaved 
                                    ? Colors.blue.withOpacity(0.1)
                                    : Colors.grey.withOpacity(0.06),
                                shape: StadiumBorder(
                                  side: BorderSide(
                                    color: isSaved 
                                        ? Colors.blue.withOpacity(0.3)
                                        : Colors.black12,
                                  ),
                                ),
                              );
                            },
                          ),
                          ActionChip(
                            avatar: const Icon(Icons.people, size: 18),
                            label: const Text('Community'),
                            onPressed: () => _showShareToCommunityDialog(a),
                            backgroundColor: Colors.grey.withOpacity(0.06),
                            shape: StadiumBorder(side: BorderSide(color: Colors.black12)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      // Comments section (styled)
                      Text('Comments', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      StreamBuilder<List<ArticleComment>>(
                        stream: _news.streamComments(a.id),
                        builder: (context, snap) {
                          if (!snap.hasData) return const Center(child: CircularProgressIndicator());
                          final comments = snap.data!;
                          if (comments.isEmpty) return const Text('No comments yet.');
                          return Column(
                            children: comments.map((c) => Container(
                              width: double.infinity,
                              margin: const EdgeInsets.only(bottom: 8),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.black12),
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  CircleAvatar(
                                    radius: 16,
                                    backgroundColor: Colors.blue.withOpacity(0.1),
                                    child: const Icon(Icons.person, color: Colors.blue, size: 18),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(c.userName, style: const TextStyle(fontWeight: FontWeight.bold)),
                                        const SizedBox(height: 4),
                                        Text(c.text),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  PopupMenuButton<String>(
                                    onSelected: (value) async {
                                      if (value == 'edit') {
                                        final controller = TextEditingController(text: c.text);
                                        final newText = await showDialog<String>(
                                          context: context,
                                          builder: (context) => AlertDialog(
                                            title: const Text('Edit Comment'),
                                            content: TextField(
                                              controller: controller,
                                              maxLines: 4,
                                              decoration: const InputDecoration(border: OutlineInputBorder()),
                                            ),
                                            actions: [
                                              TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
                                              ElevatedButton(onPressed: () => Navigator.pop(context, controller.text.trim()), child: const Text('Save')),
                                            ],
                                          ),
                                        );
                                        if (newText != null && newText.isNotEmpty) {
                                          try {
                                            await _news.updateComment(articleId: a.id, commentId: c.id, newText: newText);
                                          } catch (e) {
                                            if (context.mounted) {
                                              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
                                            }
                                          }
                                        }
                                      } else if (value == 'delete') {
                                        try {
                                          await _news.deleteComment(articleId: a.id, commentId: c.id);
                                        } catch (e) {
                                          if (context.mounted) {
                                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
                                          }
                                        }
                                      }
                                    },
                                    itemBuilder: (context) => const [
                                      PopupMenuItem(value: 'edit', child: Text('Edit')),
                                      PopupMenuItem(value: 'delete', child: Text('Delete')),
                                    ],
                                  ),
                                ],
                              ),
                            )).toList(),
                          );
                        },
                      ),
                      const SizedBox(height: 80),
                    ],
                  ),
                ),
              ),
               Container(
                padding: const EdgeInsets.all(12),
                color: Colors.white,
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 16,
                      backgroundColor: Colors.blue.withOpacity(0.1),
                      child: const Icon(Icons.person, color: Colors.blue, size: 18),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextField(
                        controller: _commentController,
                        minLines: 1,
                        maxLines: 4,
                        decoration: InputDecoration(
                          hintText: 'Write a comment...',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      child: FilledButton.icon(
                        onPressed: () async {
                          final text = _commentController.text.trim();
                          if (text.isEmpty) return;
                          await _news.addComment(articleId: a.id, text: text);
                          _commentController.clear();
                        },
                        icon: const Icon(Icons.send_rounded, size: 18),
                        label: const Text('Post'),
                        style: FilledButton.styleFrom(
                          backgroundColor: Theme.of(context).colorScheme.primary,
                          foregroundColor: Theme.of(context).colorScheme.onPrimary,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          elevation: 2,
                        ),
                      ),
                    )
                  ],
                ),
              )
            ],
          );
        },
      ),
    );
  }

  Widget _chip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.4), width: 1.5),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  void _showShareToCommunityDialog(ReportArticle article) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Share to Community'),
        content: SizedBox(
          width: double.maxFinite,
          height: 400,
          child: StreamBuilder(
            stream: _communityService.getUserCommunities(FirebaseAuth.instance.currentUser?.uid ?? ''),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (snapshot.hasError) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error, size: 48, color: Colors.red),
                      const SizedBox(height: 16),
                      Text('Error loading communities: ${snapshot.error}'),
                    ],
                  ),
                );
              }

              if (!snapshot.hasData || (snapshot.data as List<Community>).isEmpty) {
                return const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.people_outline, size: 48, color: Colors.grey),
                      SizedBox(height: 16),
                      Text('You are not a member of any communities yet.'),
                      SizedBox(height: 8),
                      Text('Join some communities to share this article!'),
                    ],
                  ),
                );
              }

              final communities = snapshot.data as List<Community>;
              return ListView.builder(
                itemCount: communities.length,
                itemBuilder: (context, index) {
                  final community = communities[index];
                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Colors.blue.withOpacity(0.1),
                      child: const Icon(Icons.people, color: Colors.blue),
                    ),
                    title: Text(community.name),
                    subtitle: Text('${community.memberCount} members'),
                    onTap: () => _shareToCommunity(article, community),
                  );
                },
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  Future<void> _shareToCommunity(ReportArticle article, dynamic community) async {
    try {
      await _communityService.shareNewsToCommunity(
        communityId: community.id,
        newsTitle: article.title,
        newsContent: '${article.summary}\n\n${article.content}',
        newsImageUrl: article.imageUrl,
        sharedFrom: article.id,
        sharedFromType: 'news',
      );

      if (mounted) {
        Navigator.pop(context); // Close dialog
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Successfully shared to ${community.name}!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // Close dialog
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error sharing to community: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showEditOptions(ReportArticle article) {
    // Double-check authorization before showing options
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;
    
    print('=== EDIT OPTIONS DEBUG ===');
    print('Current User ID: $currentUserId');
    print('Article Author UID: ${article.authorUid}');
    print('Article Title: ${article.title}');
    print('========================');
    
    if (currentUserId == null || currentUserId.isEmpty) {
      print('❌ No authenticated user in edit options');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('You must be signed in to edit articles'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    
    if (article.authorUid != currentUserId) {
      print('❌ User is not the author in edit options');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('You are not authorized to edit this article'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    
    print('✅ Showing edit options for author');
    
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Edit Options',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF1565C0).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.edit, color: Color(0xFF1565C0)),
              ),
              title: const Text('Edit Article'),
              subtitle: const Text('Modify article content and details'),
              onTap: () {
                Navigator.pop(context);
                _navigateToEditArticle(article);
              },
            ),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.flag, color: Colors.orange),
              ),
              title: const Text('Toggle Breaking News'),
              subtitle: Text(article.isBreakingNews ? 'Remove breaking news status' : 'Mark as breaking news'),
              onTap: () {
                Navigator.pop(context);
                _toggleBreakingNews(article);
              },
            ),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.verified, color: Colors.green),
              ),
              title: const Text('Toggle Verified Status'),
              subtitle: Text(article.isVerified ? 'Remove verification' : 'Mark as verified'),
              onTap: () {
                Navigator.pop(context);
                _toggleVerified(article);
              },
            ),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.delete, color: Colors.red),
              ),
              title: const Text('Delete Article'),
              subtitle: const Text('Permanently remove this article'),
              onTap: () {
                Navigator.pop(context);
                _showDeleteConfirmation(article);
              },
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () => Navigator.pop(context),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.grey,
                  side: const BorderSide(color: Colors.grey),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                child: const Text('Cancel'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _navigateToEditArticle(ReportArticle article) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditArticleScreen(articleId: article.id),
      ),
    );
  }

  Future<void> _toggleBreakingNews(ReportArticle article) async {
    try {
      await _news.toggleBreakingNews(article.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(article.isBreakingNews 
              ? 'Removed breaking news status' 
              : 'Marked as breaking news'),
            backgroundColor: Colors.green,
          ),
        );
      }
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

  Future<void> _toggleVerified(ReportArticle article) async {
    try {
      await _news.toggleVerified(article.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(article.isVerified 
              ? 'Removed verification status' 
              : 'Marked as verified'),
            backgroundColor: Colors.green,
          ),
        );
      }
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

  void _showDeleteConfirmation(ReportArticle article) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Article'),
        content: Text('Are you sure you want to delete "${article.title}"? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteArticle(article);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteArticle(ReportArticle article) async {
    try {
      await _news.deleteArticle(article.id);
      if (mounted) {
        Navigator.pop(context); // Go back to news feed
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Article deleted successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
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
}


