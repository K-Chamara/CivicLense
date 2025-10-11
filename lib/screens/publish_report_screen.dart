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
  bool _isUploadingImage = false;
  bool _canPublish = false;
  bool _isCheckingPermission = true;

  @override
  void initState() {
    super.initState();
    _checkJournalistPermission();
    _setAuthorEmailFromLogin();
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

  void _setAuthorEmailFromLogin() {
    final user = FirebaseAuth.instance.currentUser;
    if (user?.email != null) {
      _authorEmailController.text = user!.email!;
    }
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

  Future<void> _checkJournalistPermission() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        setState(() {
          _canPublish = false;
          _isCheckingPermission = false;
        });
        return;
      }

      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      if (userDoc.exists) {
        final userData = userDoc.data()!;
        final roleId = userData['role'] is Map 
            ? userData['role']['id'] 
            : userData['role'];
        final status = userData['status'] ?? 'pending';

        print('🔍 Checking article publish permission:');
        print('🔍 - roleId: $roleId');
        print('🔍 - status: $status');

        // Only approved journalists can publish articles
        final canPublish = roleId == 'journalist' && status == 'approved';

        print('🔍 - canPublish: $canPublish');

        setState(() {
          _canPublish = canPublish;
          _isCheckingPermission = false;
        });

        // If user doesn't have permission, show a dialog and go back
        if (!canPublish) {
          if (mounted) {
            await showDialog(
              context: context,
              barrierDismissible: false,
              builder: (context) => AlertDialog(
                title: const Row(
                  children: [
                    Icon(Icons.lock, color: Colors.orange),
                    SizedBox(width: 8),
                    Text('Permission Required'),
                  ],
                ),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (roleId != 'journalist')
                      const Text(
                        'Only users with the Journalist role can publish articles.',
                        style: TextStyle(fontSize: 14),
                      )
                    else if (status != 'approved')
                      const Text(
                        'Your journalist account is pending approval by the admin. Once approved, you will be able to publish articles.',
                        style: TextStyle(fontSize: 14),
                      ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.blue.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.blue.withOpacity(0.3)),
                      ),
                      child: const Text(
                        'ℹ️ You can still use all citizen features until your account is approved.',
                        style: TextStyle(
                          color: Colors.blue,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
                actions: [
                  TextButton(
                    onPressed: () {
                      Navigator.pop(context);
                      Navigator.pop(context); // Go back to previous screen
                    },
                    child: const Text('OK'),
                  ),
                ],
              ),
            );
          }
        }
      } else {
        setState(() {
          _canPublish = false;
          _isCheckingPermission = false;
        });
      }
    } catch (e) {
      print('Error checking journalist permission: $e');
      setState(() {
        _canPublish = false;
        _isCheckingPermission = false;
      });
    }
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
          SnackBar(content: Text('Error picking image: $e')),
        );
      }
    }
  }


  void _removeImage() {
    setState(() {
      _selectedImage = null;
      _bannerImageUrl = null;
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
        imageUrl: _bannerImageUrl, // Use the same image for both banner and article image
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
    // Show loading indicator while checking permission
    if (_isCheckingPermission) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    // If no permission, show empty container (user will be redirected by dialog)
    if (!_canPublish) {
      return const Scaffold(
        body: Center(
          child: Text('Checking permissions...'),
        ),
      );
    }

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
                    Expanded(child: _buildReadOnlyTextField(_authorEmailController, 'Email address (from login)')),
                  ],
                )
              else ...[
                _buildTextField(_authorNameController, 'Author name', validator: (v) => v!.isEmpty ? 'Required' : null),
                const SizedBox(height: 12),
                _buildReadOnlyTextField(_authorEmailController, 'Email address (from login)'),
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
          if (_selectedImage != null || _bannerImageUrl != null) ...[
            Container(
              width: double.infinity,
              height: 200,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                image: DecorationImage(
                  image: _bannerImageUrl != null 
                    ? NetworkImage(_bannerImageUrl!) 
                    : FileImage(_selectedImage!) as ImageProvider,
                  fit: BoxFit.cover,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _isUploadingImage ? null : _pickImage,
                    icon: _isUploadingImage 
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.edit),
                    label: Text(_isUploadingImage ? 'Uploading...' : 'Change Image'),
                  ),
                ),
                const SizedBox(width: 12),
                OutlinedButton.icon(
                  onPressed: _removeImage,
                  icon: const Icon(Icons.delete),
                  label: const Text('Remove'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red,
                    side: const BorderSide(color: Colors.red),
                  ),
                ),
              ],
            ),
          ] else ...[
            InkWell(
              onTap: _isUploadingImage ? null : _pickImage,
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
                    _isUploadingImage 
                      ? const CircularProgressIndicator()
                      : Icon(
                          Icons.add_photo_alternate,
                          size: 48,
                          color: Colors.grey[600],
                        ),
                    const SizedBox(height: 8),
                    Text(
                      _isUploadingImage ? 'Uploading...' : 'Tap to add image',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 14,
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

  Widget _buildReadOnlyTextField(TextEditingController controller, String label) {
    return TextFormField(
      controller: controller,
      readOnly: true,
      decoration: InputDecoration(
        hintText: label,
        labelText: label,
        filled: true,
        fillColor: Colors.grey[100],
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
        suffixIcon: const Icon(Icons.lock, color: Colors.grey, size: 16),
      ),
    );
  }

}


