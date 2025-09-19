import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../services/news_service.dart';
import '../services/media_hub_service.dart';
import '../services/community_service.dart';
import '../models/report.dart';

class ArticleDetailScreen extends StatefulWidget {
  const ArticleDetailScreen({super.key});

  @override
  State<ArticleDetailScreen> createState() => _ArticleDetailScreenState();
}

class _ArticleDetailScreenState extends State<ArticleDetailScreen> {
  final _news = NewsService();
  final _hub = MediaHubService();
  final _communityService = CommunityService();
  final _commentController = TextEditingController();

  @override
  void dispose() {
    _commentController.dispose();
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Article'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () async {
              final a = await _news.getArticle(articleId);
              if (a == null) return;
              Share.share('${a.title}\n\n${a.summary}');
            },
          ),
        ],
      ),
      body: FutureBuilder<ReportArticle?>(
        future: _news.getArticle(articleId),
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
                      Row(
                        children: [
                          Expanded(child: Text(a.title, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold))),
                          if (a.isBreakingNews) _chip('Breaking', Colors.red),
                          const SizedBox(width: 6),
                          if (a.isVerified) _chip('Verified', Colors.green),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text('By ${a.authorName} • ${a.organization} • ${a.authorEmail}', style: const TextStyle(color: Colors.grey)),
                      const SizedBox(height: 10),
                      Wrap(spacing: 6, children: [
                        if (a.category.isNotEmpty) _chip(a.category, Colors.blue),
                        ...a.hashtags.map((h) => _chip('#$h', Colors.purple)).toList(),
                      ]),
                      const Divider(height: 24),
                      Text(a.abstractText, style: const TextStyle(fontStyle: FontStyle.italic)),
                      const SizedBox(height: 12),
                      Text(a.summary),
                      const SizedBox(height: 12),
                      Text(a.content),
                      const Divider(height: 24),
                      if (a.references.isNotEmpty) Text('References\n${a.references}'),
                      const SizedBox(height: 20),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            ElevatedButton.icon(
                              onPressed: () => _news.likeArticle(a.id),
                              icon: const Icon(Icons.thumb_up_alt_outlined),
                              label: Text('Like (${a.likeCount})'),
                            ),
                            const SizedBox(width: 8),
                            OutlinedButton.icon(
                              onPressed: () => _downloadPdf(a),
                              icon: const Icon(Icons.download),
                              label: const Text('Download PDF'),
                            ),
                            const SizedBox(width: 8),
                            OutlinedButton.icon(
                              onPressed: () async {
                                await _hub.shareArticleToHub(
                                  articleId: a.id,
                                  title: a.title,
                                  summary: a.summary,
                                  authorName: a.authorName,
                                );
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Shared to Media Hub')));
                                }
                              },
                              icon: const Icon(Icons.send),
                              label: const Text('Share to Media Hub'),
                            ),
                            const SizedBox(width: 8),
                            OutlinedButton.icon(
                              onPressed: () => _showShareToCommunityDialog(a),
                              icon: const Icon(Icons.people),
                              label: const Text('Share to Community'),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      const Text('Comments', style: TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      StreamBuilder<List<ArticleComment>>(
                        stream: _news.streamComments(a.id),
                        builder: (context, snap) {
                          if (!snap.hasData) return const Center(child: CircularProgressIndicator());
                          final comments = snap.data!;
                          if (comments.isEmpty) return const Text('No comments yet.');
                          return Column(
                            children: comments.map((c) => ListTile(
                              contentPadding: EdgeInsets.zero,
                              title: Text(c.userName, style: const TextStyle(fontWeight: FontWeight.bold)),
                              subtitle: Text(c.text),
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
                padding: const EdgeInsets.all(8),
                color: Colors.white,
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _commentController,
                        decoration: const InputDecoration(hintText: 'Add a comment...', border: OutlineInputBorder()),
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: () async {
                        final text = _commentController.text.trim();
                        if (text.isEmpty) return;
                        await _news.addComment(articleId: a.id, text: text, userName: 'User');
                        _commentController.clear();
                      },
                      child: const Text('Post'),
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
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(16)),
      child: Text(label, style: TextStyle(color: color)),
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
            stream: _communityService.getUserCommunities(),
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

              if (!snapshot.hasData || snapshot.data!.isEmpty) {
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

              final communities = snapshot.data!;
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
        newsId: article.id,
        authorName: article.authorName,
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
}


