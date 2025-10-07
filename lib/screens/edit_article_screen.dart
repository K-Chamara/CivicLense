import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/report.dart';
import '../services/news_service.dart';

class EditArticleScreen extends StatefulWidget {
  final String articleId;
  
  const EditArticleScreen({super.key, required this.articleId});

  @override
  State<EditArticleScreen> createState() => _EditArticleScreenState();
}

class _EditArticleScreenState extends State<EditArticleScreen> {
  final _formKey = GlobalKey<FormState>();
  final _newsService = NewsService();

  final _titleController = TextEditingController();
  final _abstractController = TextEditingController();
  final _summaryController = TextEditingController();
  final _contentController = TextEditingController();
  final _referencesController = TextEditingController();
  final _hashtagsController = TextEditingController();
  
  String _category = '';
  bool _isSubmitting = false;
  bool _isLoading = true;

  final List<String> _categories = <String>[
    'Politics', 'Economy', 'Health', 'Education', 'Infrastructure', 'Environment', 'Justice'
  ];

  @override
  void initState() {
    super.initState();
    _loadArticle();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _abstractController.dispose();
    _summaryController.dispose();
    _contentController.dispose();
    _referencesController.dispose();
    _hashtagsController.dispose();
    super.dispose();
  }

  Future<void> _loadArticle() async {
    try {
      final article = await _newsService.getArticle(widget.articleId);
      if (article != null) {
        _titleController.text = article.title;
        _abstractController.text = article.abstractText;
        _summaryController.text = article.summary;
        _contentController.text = article.content;
        _referencesController.text = article.references;
        _hashtagsController.text = article.hashtags.join(', ');
        setState(() {
          _category = article.category;
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Article not found'),
              backgroundColor: Colors.red,
            ),
          );
          Navigator.pop(context);
        }
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading article: $e'),
            backgroundColor: Colors.red,
          ),
        );
        Navigator.pop(context);
      }
    }
  }

  Future<void> _saveChanges() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() => _isSubmitting = true);
    try {
      await _newsService.updateArticle(
        articleId: widget.articleId,
        title: _titleController.text.trim(),
        summary: _summaryController.text.trim(),
        content: _contentController.text.trim(),
        abstractText: _abstractController.text.trim(),
        references: _referencesController.text.trim(),
        category: _category,
        hashtags: _hashtagsController.text
            .split(',')
            .map((h) => h.trim())
            .where((h) => h.isNotEmpty)
            .toList(),
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Article updated successfully'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to update article: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: const Color(0xFFF5F7FA),
        appBar: AppBar(
          leading: const BackButton(),
          title: const Text('Edit Article'),
          backgroundColor: const Color(0xFF1565C0),
          foregroundColor: Colors.white,
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        leading: const BackButton(),
        title: const Text('Edit Article'),
        backgroundColor: const Color(0xFF1565C0),
        foregroundColor: Colors.white,
        actions: [
          TextButton(
            onPressed: _isSubmitting ? null : _saveChanges,
            child: Text(
              _isSubmitting ? 'Saving...' : 'Save',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final bool wide = constraints.maxWidth > 900;
          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 900),
              child: Form(
                key: _formKey,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4)),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Title', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                            const SizedBox(height: 6),
                            _buildTextField(_titleController, 'Enter title', validator: (v) => v!.isEmpty ? 'Required' : null),
                            const SizedBox(height: 12),
                            const Text('Abstract / Introduction', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                            const SizedBox(height: 6),
                            _buildTextField(_abstractController, 'Write the abstract or introduction', maxLines: 4, validator: (v) => v!.isEmpty ? 'Required' : null),
                            const SizedBox(height: 12),
                            const Text('Summary', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                            const SizedBox(height: 6),
                            _buildTextField(_summaryController, 'Short summary', maxLines: 3, validator: (v) => v!.isEmpty ? 'Required' : null),
                            const SizedBox(height: 12),
                            const Text('Main Content', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                            const SizedBox(height: 6),
                            _buildTextField(_contentController, 'Body of the article', maxLines: 8, validator: (v) => v!.isEmpty ? 'Required' : null),
                            const SizedBox(height: 12),
                            const Text('References', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                            const SizedBox(height: 6),
                            _buildTextField(_referencesController, 'Citations and references', maxLines: 3),
                            const SizedBox(height: 12),
                            const Text('Category', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                            const SizedBox(height: 6),
                            DropdownButtonFormField<String>(
                              value: _category.isNotEmpty ? _category : null,
                              items: _categories.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                              onChanged: (v) => setState(() => _category = v ?? ''),
                              decoration: InputDecoration(
                                hintText: 'Select a category',
                                filled: true,
                                fillColor: Colors.grey[50],
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(color: Color(0xFF1565C0)),
                                ),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                              ),
                            ),
                            const SizedBox(height: 12),
                            const Text('Hashtags', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                            const SizedBox(height: 6),
                            _buildTextField(_hashtagsController, 'Comma separated tags (e.g. corruption, budget)'),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                Expanded(
                                  child: OutlinedButton(
                                    onPressed: _isSubmitting ? null : () => Navigator.pop(context),
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: const Color(0xFF1565C0),
                                      side: const BorderSide(color: Color(0xFF1565C0)),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                      padding: const EdgeInsets.symmetric(vertical: 16),
                                    ),
                                    child: const Text(
                                      'Cancel',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  flex: 2,
                                  child: ElevatedButton(
                                    onPressed: _isSubmitting ? null : _saveChanges,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF2ECC71),
                                      foregroundColor: Colors.white,
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                      padding: const EdgeInsets.symmetric(vertical: 16),
                                      elevation: 4,
                                    ),
                                    child: _isSubmitting
                                      ? const SizedBox(
                                          height: 20,
                                          width: 20,
                                          child: CircularProgressIndicator(
                                            color: Colors.white,
                                            strokeWidth: 2,
                                          ),
                                        )
                                      : const Text(
                                          'Save Changes',
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                  ),
                                ),
                              ],
                            )
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label, {int maxLines = 1, TextInputType? keyboardType, String? Function(String?)? validator}) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      validator: validator,
      decoration: InputDecoration(
        hintText: label,
        labelText: label,
        filled: true,
        fillColor: Colors.grey[50],
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF1565C0)),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      ),
    );
  }
}
