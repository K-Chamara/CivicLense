import 'package:flutter/material.dart';
import '../services/media_hub_service.dart';

class MediaHubScreen extends StatelessWidget {
  const MediaHubScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final service = MediaHubService();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Media Hub'),
        backgroundColor: Colors.purple,
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: service.streamHubPosts(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final posts = snapshot.data!;
          if (posts.isEmpty) {
            return const Center(child: Text('No shared posts yet'));
          }
          return ListView.separated(
            itemCount: posts.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, i) {
              final p = posts[i];
              return ListTile(
                title: Text(p['title'] ?? ''),
                subtitle: Text(p['summary'] ?? '', maxLines: 2, overflow: TextOverflow.ellipsis),
                trailing: IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () async {
                    await service.deleteHubPost(p['id']);
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Deleted')));
                  },
                ),
                onTap: () => Navigator.pushNamed(context, '/article', arguments: p['articleId']),
              );
            },
          );
        },
      ),
    );
  }
}


