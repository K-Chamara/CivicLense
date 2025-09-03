import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/report.dart';
import '../services/news_service.dart';

class PublishReportScreen extends StatefulWidget {
  const PublishReportScreen({super.key});

  @override
  State<PublishReportScreen> createState() => _PublishReportScreenState();
}

class _PublishReportScreenState extends State<PublishReportScreen> {
  final _formKey = GlobalKey<FormState>();
  final _newsService = NewsService();

  final _titleController = TextEditingController();
  final _authorNameController = TextEditingController();
  final _authorEmailController = TextEditingController();
  final _organizationController = TextEditingController();
  final _abstractController = TextEditingController();
  final _summaryController = TextEditingController();
  final _contentController = TextEditingController();
  final _referencesController = TextEditingController();
  final _hashtagsController = TextEditingController();
  String _category = '';
  bool _isBreaking = false;
  bool _isVerified = false;
  bool _isSubmitting = false;

  final List<String> _categories = <String>[
    'Politics', 'Economy', 'Health', 'Education', 'Infrastructure', 'Environment', 'Justice'
  ];

  @override
  void dispose() {
    _titleController.dispose();
    _authorNameController.dispose();
    _authorEmailController.dispose();
    _organizationController.dispose();
    _abstractController.dispose();
    _summaryController.dispose();
    _contentController.dispose();
    _referencesController.dispose();
    _hashtagsController.dispose();
    super.dispose();
  }

  void _previewArticle() {
    if (!_formKey.currentState!.validate()) return;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (context) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.85,
          maxChildSize: 0.95,
          minChildSize: 0.5,
          builder: (context, controller) {
            return SingleChildScrollView(
              controller: controller,
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          _titleController.text,
                          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                        ),
                      ),
                      if (_isBreaking) _buildChip('Breaking', Colors.red),
                      const SizedBox(width: 8),
                      if (_isVerified) _buildChip('Verified', Colors.green),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text('By ${_authorNameController.text} • ${_organizationController.text}', style: const TextStyle(color: Colors.grey)),
                  const SizedBox(height: 12),
                  if (_category.isNotEmpty) _buildChip(_category, Colors.blue),
                  const SizedBox(height: 12),
                  Text(_abstractController.text, style: const TextStyle(fontStyle: FontStyle.italic)),
                  const Divider(height: 24),
                  Text(_summaryController.text),
                  const SizedBox(height: 12),
                  Text(_contentController.text),
                  const Divider(height: 24),
                  Text('References\n${_referencesController.text}'),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 6,
                    children: _hashtagsController.text
                        .split(',')
                        .map((h) => h.trim())
                        .where((h) => h.isNotEmpty)
                        .map((h) => _buildChip('#$h', Colors.purple))
                        .toList(),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildChip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
      child: Text(label, style: TextStyle(color: color, fontWeight: FontWeight.w600)),
    );
  }

  Future<void> _publish() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSubmitting = true);
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
      final article = ReportArticle(
        id: '',
        title: _titleController.text.trim(),
        authorName: _authorNameController.text.trim(),
        authorEmail: _authorEmailController.text.trim(),
        organization: _organizationController.text.trim(),
        abstractText: _abstractController.text.trim(),
        summary: _summaryController.text.trim(),
        content: _contentController.text.trim(),
        references: _referencesController.text.trim(),
        category: _category,
        hashtags: _hashtagsController.text
            .split(',')
            .map((h) => h.trim())
            .where((h) => h.isNotEmpty)
            .toList(),
        isBreakingNews: _isBreaking,
        isVerified: _isVerified,
        authorUid: uid,
        likeCount: 0,
        commentCount: 0,
        createdAt: Timestamp.now(),
      );

      final id = await _newsService.publishArticle(article);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Article published')),
      );
      Navigator.pop(context);
      Navigator.pushNamed(context, '/article', arguments: id);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to publish: $e')),
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: const BackButton(),
        title: const Text('Publish Report'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Title', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 6),
              _buildTextField(_titleController, 'Enter title', validator: (v) => v!.isEmpty ? 'Required' : null),
              const SizedBox(height: 12),
              const Text('Author Information', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 6),
              _buildTextField(_authorNameController, 'Author name', validator: (v) => v!.isEmpty ? 'Required' : null),
              const SizedBox(height: 12),
              const Text('Contact Email', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 6),
              _buildTextField(_authorEmailController, 'Email address', keyboardType: TextInputType.emailAddress, validator: (v) => v!.contains('@') ? null : 'Invalid email'),
              const SizedBox(height: 12),
              const Text('Organization / Affiliation', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 6),
              _buildTextField(_organizationController, 'Organization or affiliation'),
              const SizedBox(height: 12),
              const Text('Abstract / Introduction', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 6),
              _buildTextField(_abstractController, 'Write the abstract or introduction', maxLines: 4, validator: (v) => v!.isEmpty ? 'Required' : null),
              const SizedBox(height: 12),
              const Text('Summary', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 6),
              _buildTextField(_summaryController, 'Short summary', maxLines: 3, validator: (v) => v!.isEmpty ? 'Required' : null),
              const SizedBox(height: 12),
              const Text('Main Content', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 6),
              _buildTextField(_contentController, 'Body of the article', maxLines: 8, validator: (v) => v!.isEmpty ? 'Required' : null),
              const SizedBox(height: 12),
              const Text('References', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 6),
              _buildTextField(_referencesController, 'Citations and references', maxLines: 3),
              const SizedBox(height: 12),
              const Text('Category', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 6),
              DropdownButtonFormField<String>(
                value: _category.isNotEmpty ? _category : null,
                items: _categories.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                onChanged: (v) => setState(() => _category = v ?? ''),
                decoration: const InputDecoration(hintText: 'Select a category', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 12),
              const Text('Hashtags', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 6),
              _buildTextField(_hashtagsController, 'Comma separated tags (e.g. corruption, budget)'),
              const SizedBox(height: 12),
              SwitchListTile(
                value: _isBreaking,
                onChanged: (v) => setState(() => _isBreaking = v),
                title: const Text('Breaking News'),
              ),
              SwitchListTile(
                value: _isVerified,
                onChanged: (v) => setState(() => _isVerified = v),
                title: const Text('Verified Content'),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _isSubmitting ? null : _previewArticle,
                      icon: const Icon(Icons.visibility),
                      label: const Text('Preview'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _isSubmitting ? null : _publish,
                      icon: const Icon(Icons.publish),
                      label: _isSubmitting ? const Text('Publishing...') : const Text('Publish'),
                    ),
                  ),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label, {int maxLines = 1, TextInputType? keyboardType, String? Function(String?)? validator}) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      validator: validator,
      decoration: const InputDecoration(
        labelText: 'Enter value',
        border: OutlineInputBorder(),
      ).copyWith(labelText: label),
    );
  }
}


