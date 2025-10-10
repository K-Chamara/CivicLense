import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import '../models/report.dart';
import '../services/news_service.dart';
import '../services/cloudinary_service.dart';

class PublishReportScreen extends StatefulWidget {
  const PublishReportScreen({super.key});

  @override
  State<PublishReportScreen> createState() => _PublishReportScreenState();
}

class _PublishReportScreenState extends State<PublishReportScreen> with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _newsService = NewsService();
  // Using static methods from CloudinaryService
  
  late AnimationController _formAnimationController;
  late AnimationController _buttonAnimationController;
  late Animation<double> _formAnimation;
  late Animation<double> _buttonAnimation;

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
  File? _selectedImage;
  String? _bannerImageUrl;
  String? _imageUrl;
  bool _isUploadingImage = false;

  @override
  void initState() {
    super.initState();
    _formAnimationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _buttonAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    
    _formAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _formAnimationController, curve: Curves.easeOut),
    );
    _buttonAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _buttonAnimationController, curve: Curves.elasticOut),
    );
    
    _formAnimationController.forward();
    _buttonAnimationController.forward();
  }

  @override
  void dispose() {
    _formAnimationController.dispose();
    _buttonAnimationController.dispose();
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

  final List<String> _categories = <String>[
    'Politics', 'Economy', 'Health', 'Education', 'Infrastructure', 'Environment', 'Justice'
  ];

  Future<void> _pickImage() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );
      
      if (image != null) {
        setState(() {
          _selectedImage = File(image.path);
          _isUploadingImage = true;
        });
        
        // Automatically upload the image
        try {
          final imageUrl = await CloudinaryService.uploadFile(_selectedImage!);
          setState(() {
            _bannerImageUrl = imageUrl;
            _isUploadingImage = false;
          });
          
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Image uploaded successfully')),
            );
          }
        } catch (uploadError) {
          setState(() {
            _isUploadingImage = false;
            _selectedImage = null;
          });
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Failed to upload image: $uploadError')),
            );
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to pick image: $e')),
        );
      }
    }
  }

  Future<void> _uploadImage() async {
    if (_selectedImage == null) return;
    
    setState(() {
      _isUploadingImage = true;
    });
    
    try {
      final url = await CloudinaryService.uploadFile(_selectedImage!);
      if (url != null) {
        setState(() {
          _imageUrl = url;
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Image uploaded successfully')),
          );
        }
      } else {
        throw Exception('Failed to upload image');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error uploading image: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isUploadingImage = false;
        });
      }
    }
  }

  void _removeImage() {
    setState(() {
      _selectedImage = null;
      _bannerImageUrl = null;
      _imageUrl = null;
    });
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
        bannerImageUrl: _bannerImageUrl,
        imageUrl: _imageUrl,
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
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        leading: const BackButton(),
        title: const Text('Publish Report'),
        backgroundColor: const Color(0xFF1565C0),
        foregroundColor: Colors.white,
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final bool wide = constraints.maxWidth > 900;
          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 900),
              child: Form(
                key: _formKey,
                child: FadeTransition(
                  opacity: _formAnimation,
                  child: SlideTransition(
                    position: Tween<Offset>(
                      begin: const Offset(0, 0.1),
                      end: Offset.zero,
                    ).animate(CurvedAnimation(
                      parent: _formAnimationController,
                      curve: Curves.easeOut,
                    )),
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
              const SizedBox(height: 16),
              const Text('Banner Image', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 6),
              _buildImageUploadSection(),
              const SizedBox(height: 12),
              const Text('Author Information', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 6),
              if (wide)
                Row(
                  children: [
                    Expanded(child: _buildTextField(_authorNameController, 'Author name', validator: (v) => v!.isEmpty ? 'Required' : null)),
                    const SizedBox(width: 12),
                    Expanded(child: _buildTextField(_authorEmailController, 'Email address', keyboardType: TextInputType.emailAddress, validator: (v) => v!.contains('@') ? null : 'Invalid email')),
                  ],
                )
              else ...[
                _buildTextField(_authorNameController, 'Author name', validator: (v) => v!.isEmpty ? 'Required' : null),
                const SizedBox(height: 12),
                _buildTextField(_authorEmailController, 'Email address', keyboardType: TextInputType.emailAddress, validator: (v) => v!.contains('@') ? null : 'Invalid email'),
              ],
              const SizedBox(height: 12),
              const Text('Organization / Affiliation', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 6),
              _buildTextField(_organizationController, 'Organization or affiliation'),
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
              const Text('Article Image', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 6),
              _buildImageUploadSection(),
              const SizedBox(height: 12),
              const Text('Hashtags', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 6),
              _buildTextField(_hashtagsController, 'Comma separated tags (e.g. corruption, budget)'),
              const SizedBox(height: 12),
              if (wide)
                Row(
                  children: [
                    Expanded(
                      child: SwitchListTile(
                        value: _isBreaking,
                        onChanged: (v) => setState(() => _isBreaking = v),
                        title: const Text('Breaking News'),
                      ),
                    ),
                    Expanded(
                      child: SwitchListTile(
                        value: _isVerified,
                        onChanged: (v) => setState(() => _isVerified = v),
                        title: const Text('Verified Content'),
                      ),
                    ),
                  ],
                )
              else ...[
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
              ],
              const SizedBox(height: 16),
              ScaleTransition(
                scale: _buttonAnimation,
                child: Row(
                  children: [
                    Expanded(
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        child: OutlinedButton.icon(
                          onPressed: _isSubmitting ? null : _previewArticle,
                          icon: const Icon(Icons.visibility_rounded),
                          label: const Text(
                            'Preview',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Theme.of(context).colorScheme.primary,
                            side: BorderSide(color: Theme.of(context).colorScheme.primary),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      flex: 2,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        child: FilledButton.icon(
                          onPressed: _isSubmitting ? null : _publish,
                          icon: _isSubmitting 
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.publish_rounded),
                          label: Text(
                            _isSubmitting ? 'Publishing...' : 'Publish Article',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          style: FilledButton.styleFrom(
                            backgroundColor: const Color(0xFF2ECC71),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            elevation: 4,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
                    ],
                  ),
                ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildImageUploadSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_bannerImageUrl != null) ...[
            // Show uploaded image
            Container(
              width: double.infinity,
              height: 200,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                image: DecorationImage(
                  image: NetworkImage(_bannerImageUrl!),
                  fit: BoxFit.cover,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Image uploaded successfully',
                    style: TextStyle(
                      color: Colors.green[700],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: _removeImage,
                  icon: const Icon(Icons.delete, color: Colors.red),
                  tooltip: 'Remove image',
                ),
              ],
            ),
          ] else if (_isUploadingImage) ...[
            // Show uploading state
            Container(
              width: double.infinity,
              height: 200,
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: 16),
                  Text(
                    'Uploading image...',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ] else ...[
            // Show upload button
            InkWell(
              onTap: _pickImage,
              borderRadius: BorderRadius.circular(8),
              child: Container(
                width: double.infinity,
                height: 120,
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: Colors.grey[300]!,
                    style: BorderStyle.solid,
                    width: 2,
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.add_photo_alternate,
                      size: 48,
                      color: Colors.grey[600],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Tap to add banner image',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Recommended: 800x400px',
                      style: TextStyle(
                        color: Colors.grey[500],
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
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


