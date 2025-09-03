import 'package:flutter/material.dart';
import '../services/news_service.dart';
import '../models/report.dart';

class NewsFeedScreen extends StatefulWidget {
  const NewsFeedScreen({super.key});

  @override
  State<NewsFeedScreen> createState() => _NewsFeedScreenState();
}

class _NewsFeedScreenState extends State<NewsFeedScreen> {
  final _news = NewsService();
  String _query = '';
  String _category = '';
  bool _breakingOnly = false;
  bool _verifiedOnly = false;
  bool _showFilters = false;

  final List<String> _categories = <String>[
    '', 'Politics', 'Economy', 'Health', 'Education', 'Infrastructure', 'Environment', 'Justice'
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: const BackButton(),
        title: const Text('News Feed'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    decoration: const InputDecoration(
                      hintText: 'Search articles...',
                      prefixIcon: Icon(Icons.search),
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (v) => setState(() => _query = v),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: () => setState(() => _showFilters = !_showFilters),
                  icon: const Icon(Icons.filter_list),
                  tooltip: 'Filters',
                )
              ],
            ),
          ),
          if (_showFilters)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Padding(
                      padding: EdgeInsets.only(bottom: 8),
                      child: Text('Filters', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ),
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: _category.isEmpty ? '' : _category,
                          items: _categories
                              .map((c) => DropdownMenuItem(
                                    value: c,
                                    child: Text(c.isEmpty ? 'All Categories' : c),
                                  ))
                              .toList(),
                          onChanged: (v) => setState(() => _category = v ?? ''),
                          decoration: const InputDecoration(
                            labelText: 'Category',
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          children: [
                            CheckboxListTile(
                              value: _breakingOnly,
                              onChanged: (v) => setState(() => _breakingOnly = v ?? false),
                              title: const Text('Breaking News only'),
                              controlAffinity: ListTileControlAffinity.leading,
                              dense: true,
                              contentPadding: EdgeInsets.zero,
                            ),
                            CheckboxListTile(
                              value: _verifiedOnly,
                              onChanged: (v) => setState(() => _verifiedOnly = v ?? false),
                              title: const Text('Verified only'),
                              controlAffinity: ListTileControlAffinity.leading,
                              dense: true,
                              contentPadding: EdgeInsets.zero,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton.icon(
                      onPressed: () => setState(() {
                        _query = '';
                        _category = '';
                        _breakingOnly = false;
                        _verifiedOnly = false;
                      }),
                      icon: const Icon(Icons.restart_alt),
                      label: const Text('Reset'),
                    ),
                  )
                ],
              ),
            ),
          const SizedBox(height: 8),
          Expanded(
            child: StreamBuilder<List<ReportArticle>>(
              stream: _news.streamArticles(
                searchQuery: _query,
                category: _category.isEmpty ? null : _category,
                breakingOnly: _breakingOnly ? true : null,
                verifiedOnly: _verifiedOnly ? true : null,
              ),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final items = snapshot.data!;
                if (items.isEmpty) {
                  return const Center(child: Text('No news found'));
                }
                return ListView.separated(
                  itemCount: items.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final a = items[index];
                    return ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      title: Row(
                        children: [
                          Expanded(child: Text(a.title, style: const TextStyle(fontWeight: FontWeight.bold))),
                          if (a.isBreakingNews) _chip('Breaking', Colors.red),
                          const SizedBox(width: 6),
                          if (a.isVerified) _chip('Verified', Colors.green),
                        ],
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(a.summary, maxLines: 2, overflow: TextOverflow.ellipsis),
                          const SizedBox(height: 4),
                          Wrap(
                            spacing: 6,
                            children: [
                              if (a.category.isNotEmpty) _chip(a.category, Colors.blue),
                              ...a.hashtags.take(3).map((h) => _chip('#$h', Colors.purple)).toList(),
                            ],
                          ),
                        ],
                      ),
                      onTap: () => Navigator.pushNamed(context, '/article', arguments: a.id),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _chip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(16)),
      child: Text(label, style: TextStyle(color: color, fontSize: 12)),
    );
  }
}


