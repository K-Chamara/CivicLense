import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import '../models/concern_models.dart';
import '../services/concern_service.dart';
import '../services/auth_service.dart';
import '../services/sentiment_service.dart';

class RaiseConcernScreen extends StatefulWidget {
  final String? relatedBudgetId;
  final String? relatedTenderId;
  final String? relatedCommunityId;
  final String? preSelectedCategory;

  const RaiseConcernScreen({
    super.key,
    this.relatedBudgetId,
    this.relatedTenderId,
    this.relatedCommunityId,
    this.preSelectedCategory,
  });

  @override
  State<RaiseConcernScreen> createState() => _RaiseConcernScreenState();
}

class _RaiseConcernScreenState extends State<RaiseConcernScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _locationController = TextEditingController();
  final _concernService = ConcernService();
  final _authService = AuthService();

  // Form state
  ConcernCategory _selectedCategory = ConcernCategory.other;
  ConcernType _selectedType = ConcernType.complaint;
  bool _isAnonymous = false;
  bool _isPublic = true;
  bool _isLoading = false;
  
  // File upload
  List<File> _attachedFiles = [];
  List<String> _fileNames = [];
  
  // Sentiment analysis
  SentimentAnalysisResult? _sentimentResult;
  bool _isAnalyzingSentiment = false;
  
  // Engagement meter
  double _engagementScore = 0.0;
  
  // Districts for location selector
  final List<String> _districts = [
    'Colombo', 'Gampaha', 'Kalutara', 'Kandy', 'Matale', 'Nuwara Eliya',
    'Galle', 'Matara', 'Hambantota', 'Jaffna', 'Vanni', 'Batticaloa',
    'Trincomalee', 'Kurunegala', 'Puttalam', 'Anuradhapura', 'Polonnaruwa',
    'Badulla', 'Monaragala', 'Ratnapura', 'Kegalle'
  ];

  @override
  void initState() {
    super.initState();
    _initializeForm();
  }

  void _initializeForm() {
    if (widget.preSelectedCategory != null) {
      _selectedCategory = ConcernCategory.values.firstWhere(
        (e) => e.name == widget.preSelectedCategory,
        orElse: () => ConcernCategory.other,
      );
    } else if (widget.relatedBudgetId != null) {
      _selectedCategory = ConcernCategory.budget;
    } else if (widget.relatedTenderId != null) {
      _selectedCategory = ConcernCategory.tender;
    } else if (widget.relatedCommunityId != null) {
      _selectedCategory = ConcernCategory.community;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  // File upload methods
  Future<void> _pickFiles() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        allowMultiple: true,
        type: FileType.custom,
        allowedExtensions: ['jpg', 'jpeg', 'png', 'pdf', 'doc', 'docx', 'txt'],
      );

      if (result != null) {
        setState(() {
          for (var file in result.files) {
            if (file.path != null) {
              _attachedFiles.add(File(file.path!));
              _fileNames.add(file.name);
            }
          }
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error picking files: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _removeFile(int index) {
    setState(() {
      _attachedFiles.removeAt(index);
      _fileNames.removeAt(index);
    });
  }

  // Sentiment analysis
  Future<void> _analyzeSentiment() async {
    if (_descriptionController.text.trim().isEmpty) return;

    setState(() {
      _isAnalyzingSentiment = true;
    });

    try {
      // Simulate sentiment analysis (replace with actual API call)
      await Future.delayed(const Duration(seconds: 1));
      
      // Mock sentiment analysis result
      setState(() {
        _sentimentResult = SentimentAnalysisResult(
          score: -0.3, // Slightly negative
          magnitude: 0.7,
          sentimentScore: SentimentScore.negative,
        );
      });
    } catch (e) {
      // Handle error silently
    } finally {
      setState(() {
        _isAnalyzingSentiment = false;
      });
    }
  }

  // Engagement score calculation
  void _calculateEngagementScore() {
    // Mock engagement calculation based on similar concerns
    setState(() {
      _engagementScore = 0.65; // 65% support from community
    });
  }

  Future<void> _submitConcern() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final user = _authService.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      final userData = await _authService.getUserData(user.uid);
      final userName = userData?['firstName'] != null && userData?['lastName'] != null
          ? '${userData!['firstName']} ${userData['lastName']}'
          : user.email?.split('@').first ?? 'Anonymous User';

      final concern = Concern(
        id: '',
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        authorId: user.uid,
        authorName: _isAnonymous ? 'Anonymous User' : userName,
        authorEmail: _isAnonymous ? 'anonymous@example.com' : user.email ?? '',
        category: _selectedCategory,
        type: _selectedType,
        // Priority will be auto-determined by system
        status: ConcernStatus.pending,
        createdAt: DateTime.now(),
        relatedBudgetId: widget.relatedBudgetId,
        relatedTenderId: widget.relatedTenderId,
        relatedCommunityId: widget.relatedCommunityId,
        tags: [],
        isAnonymous: _isAnonymous,
        isPublic: _isPublic,
        metadata: {
          'location': _locationController.text.trim(),
          'sentimentScore': _sentimentResult?.sentimentScore.name,
          'sentimentMagnitude': _sentimentResult?.magnitude,
          'engagementScore': _engagementScore,
          'attachmentCount': _attachedFiles.length,
        },
      );

      await _concernService.createConcern(concern);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Concern submitted successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error submitting concern: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Raise a Concern',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            Text(
              'Empower transparency by reporting issues you notice',
              style: TextStyle(
                fontSize: 12,
                color: Colors.white70,
                fontWeight: FontWeight.normal,
              ),
            ),
          ],
        ),
        backgroundColor: const Color(0xFF1A3C73),
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        toolbarHeight: 80,
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Center(
            child: Container(
              constraints: const BoxConstraints(maxWidth: 800),
              child: Card(
                elevation: 8,
                shadowColor: Colors.black26,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
                            // Concern Title
                            _buildModernTextField(
                controller: _titleController,
                              label: 'Concern Title',
                              hint: 'Brief, clear description of your concern',
                              prefixIcon: Icons.title,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter a title';
                  }
                  if (value.trim().length < 10) {
                    return 'Title must be at least 10 characters';
                  }
                  return null;
                },
                maxLength: 100,
              ),
                            const SizedBox(height: 16),

                            // Category/Type Dropdown
                            _buildDropdownSection(),
                            const SizedBox(height: 16),

                            // Description Box
                            _buildDescriptionSection(),
                            const SizedBox(height: 16),

                            // Sentiment Preview
                            if (_sentimentResult != null) _buildSentimentPreview(),
                            if (_sentimentResult != null) const SizedBox(height: 24),

                            // Citizen Engagement Meter
                            if (_engagementScore > 0) _buildEngagementMeter(),
                            if (_engagementScore > 0) const SizedBox(height: 24),

                            // File Upload
                            _buildFileUploadSection(),
                            const SizedBox(height: 16),

                            // Location Selector
                            _buildLocationSelector(),
                            const SizedBox(height: 16),

                            // Anonymity Toggle
                            _buildAnonymityToggle(),
                            const SizedBox(height: 24),

                            // Action Buttons
                            _buildActionButtons(),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // Modern UI Components
  Widget _buildModernTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData prefixIcon,
    String? Function(String?)? validator,
    int? maxLines,
    int? maxLength,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
                children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Color(0xFF1A3C73),
          ),
        ),
                const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          validator: validator,
          maxLines: maxLines ?? 1,
          maxLength: maxLength,
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: Icon(prefixIcon, color: const Color(0xFF1A3C73)),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFF1A3C73), width: 2),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
            ),
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          ),
        ),
      ],
    );
  }

  Widget _buildDropdownSection() {
    return LayoutBuilder(
      builder: (context, constraints) {
        // If screen is too narrow, stack dropdowns vertically
        if (constraints.maxWidth < 400) {
          return Column(
            children: [
              _buildDropdown(
                label: 'Category',
                value: _getCategoryDisplayName(_selectedCategory),
                items: ConcernCategory.values.map((category) =>
                  DropdownMenuItem(
                    value: _getCategoryDisplayName(category),
                child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Text(
                        _getCategoryDisplayName(category),
                        style: const TextStyle(
                          fontWeight: FontWeight.w500,
                          fontSize: 14,
                        ),
                        overflow: TextOverflow.ellipsis,
                        softWrap: false,
                      ),
                    ),
                  ),
                ).toList(),
                        onChanged: (value) {
                          setState(() {
                    _selectedCategory = ConcernCategory.values.firstWhere(
                      (c) => _getCategoryDisplayName(c) == value,
                    );
                          });
                        },
                      ),
              const SizedBox(height: 16),
              _buildDropdown(
                label: 'Type',
                value: _getTypeDisplayName(_selectedType),
                items: ConcernType.values.map((type) =>
                  DropdownMenuItem(
                    value: _getTypeDisplayName(type),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Text(
                        _getTypeDisplayName(type),
                        style: const TextStyle(
                          fontWeight: FontWeight.w500,
                          fontSize: 14,
                        ),
                        overflow: TextOverflow.ellipsis,
                        softWrap: false,
                      ),
                    ),
                  ),
                ).toList(),
                        onChanged: (value) {
                          setState(() {
                    _selectedType = ConcernType.values.firstWhere(
                      (t) => _getTypeDisplayName(t) == value,
                    );
                          });
                        },
                      ),
                    ],
          );
        }
        
        // For wider screens, use horizontal layout
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: _buildDropdown(
                label: 'Category',
                value: _getCategoryDisplayName(_selectedCategory),
              items: ConcernCategory.values.map((category) =>
                DropdownMenuItem(
                  value: _getCategoryDisplayName(category),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Text(
                      _getCategoryDisplayName(category),
                      style: const TextStyle(
                        fontWeight: FontWeight.w500,
                        fontSize: 14,
                      ),
                      overflow: TextOverflow.ellipsis,
                      softWrap: false,
                    ),
                  ),
                ),
              ).toList(),
                        onChanged: (value) {
                          setState(() {
                _selectedCategory = ConcernCategory.values.firstWhere(
                  (c) => _getCategoryDisplayName(c) == value,
                );
                          });
                        },
                      ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildDropdown(
            label: 'Type',
            value: _getTypeDisplayName(_selectedType),
              items: ConcernType.values.map((type) =>
                DropdownMenuItem(
                  value: _getTypeDisplayName(type),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Text(
                      _getTypeDisplayName(type),
                      style: const TextStyle(
                        fontWeight: FontWeight.w500,
                        fontSize: 14,
                      ),
                      overflow: TextOverflow.ellipsis,
                      softWrap: false,
                    ),
                  ),
                ),
              ).toList(),
                        onChanged: (value) {
                          setState(() {
                _selectedType = ConcernType.values.firstWhere(
                  (t) => _getTypeDisplayName(t) == value,
                );
                          });
                        },
          ),
        ),
      ],
    );
      },
    );
  }

  Widget _buildDropdown({
    required String label,
    required String? value,
    required List<DropdownMenuItem<String>> items,
    required Function(String?) onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Color(0xFF1A3C73),
          ),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: value,
          items: items,
          onChanged: onChanged,
          hint: Text('Select $label'),
          decoration: InputDecoration(
            border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFF1A3C73), width: 1),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
            ),
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
          ),
          dropdownColor: Colors.white,
          style: const TextStyle(
            color: Colors.black87,
            fontSize: 14,
          ),
        ),
      ],
    );
  }


  Widget _buildDescriptionSection() {
    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
              'Description',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1A3C73),
              ),
            ),
            TextButton.icon(
              onPressed: _analyzeSentiment,
              icon: _isAnalyzingSentiment 
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.psychology, size: 16),
              label: const Text('Analyze Tone'),
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xFF1A3C73),
              ),
            ),
          ],
                        ),
                        const SizedBox(height: 8),
              TextFormField(
                controller: _descriptionController,
          maxLines: 6,
          maxLength: 1000,
          onChanged: (value) {
            if (value.length > 50) {
              _calculateEngagementScore();
            }
          },
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter a description';
                  }
                  if (value.trim().length < 20) {
                    return 'Description must be at least 20 characters';
                  }
                  return null;
                },
          decoration: InputDecoration(
            hintText: 'Provide detailed information about your concern. Include specific details, dates, locations, and any relevant context.',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFF1A3C73), width: 2),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
            ),
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.all(16),
            alignLabelWithHint: true,
          ),
        ),
      ],
    );
  }

  Widget _buildSentimentPreview() {
    if (_sentimentResult == null) return const SizedBox.shrink();
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _getSentimentColor(_sentimentResult!.sentimentScore).withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _getSentimentColor(_sentimentResult!.sentimentScore),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(
            _getSentimentIcon(_sentimentResult!.sentimentScore),
            color: _getSentimentColor(_sentimentResult!.sentimentScore),
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Tone Analysis: ${_getSentimentDisplayName(_sentimentResult!.sentimentScore)}',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: _getSentimentColor(_sentimentResult!.sentimentScore),
                  ),
                ),
                Text(
                  'Magnitude: ${(_sentimentResult!.magnitude * 100).toStringAsFixed(0)}%',
        style: const TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
        ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEngagementMeter() {
    return Container(
        padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue.shade200),
      ),
        child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.people, color: Colors.blue.shade700),
              const SizedBox(width: 8),
              Text(
                'Citizen Engagement',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: Colors.blue.shade700,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Community Support for Similar Issues',
            style: const TextStyle(
              fontSize: 14,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                child: LinearProgressIndicator(
                  value: _engagementScore,
                  backgroundColor: Colors.grey.shade300,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    _engagementScore > 0.7 
                        ? Colors.green 
                        : _engagementScore > 0.4 
                            ? Colors.orange 
                            : Colors.red,
                  ),
                  minHeight: 8,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                '${(_engagementScore * 100).toStringAsFixed(0)}%',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: _engagementScore > 0.7 
                      ? Colors.green 
                      : _engagementScore > 0.4 
                          ? Colors.orange 
                          : Colors.red,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            '${(_engagementScore * 1000).toInt()} citizens have supported similar concerns',
            style: const TextStyle(
              fontSize: 12,
              color: Colors.grey,
            ),
                  ),
                ],
              ),
    );
  }

  Widget _buildFileUploadSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Attach Evidence',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Color(0xFF1A3C73),
          ),
        ),
                const SizedBox(height: 8),
        GestureDetector(
          onTap: _pickFiles,
          child: Container(
            width: double.infinity,
            height: 120,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: const Color(0xFFE0E0E0),
                style: BorderStyle.solid,
                width: 2,
              ),
            ),
            child: const Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.cloud_upload_outlined,
                  size: 48,
                  color: Color(0xFF1A3C73),
                ),
                SizedBox(height: 8),
                Text(
                  'Drag & drop files here or click to browse',
                  style: TextStyle(
                    color: Color(0xFF1A3C73),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  'Supports: JPG, PNG, PDF, DOC, TXT (Max 10MB)',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          ),
        ),
        if (_attachedFiles.isNotEmpty) ...[
          const SizedBox(height: 12),
          ...List.generate(_attachedFiles.length, (index) {
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Row(
                children: [
                  Icon(
                    _getFileIcon(_fileNames[index]),
                    color: const Color(0xFF1A3C73),
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
      child: Text(
                      _fileNames[index],
        style: const TextStyle(
                        fontWeight: FontWeight.w500,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => _removeFile(index),
                    icon: const Icon(Icons.close, size: 20, color: Colors.red),
                  ),
                ],
              ),
            );
          }),
        ],
      ],
    );
  }

  Widget _buildLocationSelector() {
    return _buildDropdown(
      label: 'Location',
      value: _locationController.text.isEmpty ? null : _locationController.text,
      items: _districts.map((district) => 
        DropdownMenuItem(
          value: district,
          child: Row(
            children: [
              const Icon(Icons.location_on, size: 16, color: Color(0xFF1A3C73)),
              const SizedBox(width: 8),
              Text(district),
            ],
          ),
        ),
      ).toList(),
              onChanged: (value) {
                setState(() {
          _locationController.text = value ?? '';
                });
              },
    );
  }

  Widget _buildAnonymityToggle() {
    return Container(
        padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE0E0E0)),
      ),
      child: Row(
        children: [
          const Icon(Icons.visibility_off, color: Color(0xFF1A3C73)),
          const SizedBox(width: 12),
          Expanded(
        child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                const Text(
                  'Submit Anonymously',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
                const Text(
                  'Your name will not be visible to others',
                  style: TextStyle(
                    color: Colors.grey,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          Switch(
                        value: _isAnonymous,
              onChanged: (value) {
                setState(() {
                            _isAnonymous = value;
                });
              },
            activeColor: const Color(0xFF1A3C73),
                      ),
                    ],
                  ),
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: () => Navigator.pop(context),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              side: const BorderSide(color: Colors.grey),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              'Cancel',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.grey,
              ),
                    ),
                  ),
                ),
        const SizedBox(width: 16),
        Expanded(
          flex: 2,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submitConcern,
                  style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2ECC71),
                    foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                    ),
              elevation: 4,
                  ),
                  child: _isLoading
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                      : const Text(
                    'Publish Concern',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                        ),
                ),
              ),
      ],
    );
  }

  Widget _buildTipsSidebar() {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Tips for Writing Effective Concerns',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1A3C73),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            '• Be specific and factual - include dates, locations, and people involved',
            style: TextStyle(
              fontSize: 14,
              color: Colors.black87,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            '• Provide evidence when possible - attach documents, photos, or screenshots',
            style: TextStyle(
              fontSize: 14,
              color: Colors.black87,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            '• Stay objective and professional - focus on facts rather than emotions',
            style: TextStyle(
              fontSize: 14,
              color: Colors.black87,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            '• Priority is automatically determined by our AI system based on content analysis',
            style: TextStyle(
              fontSize: 14,
              color: Colors.black87,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 32),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF1A3C73).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFF1A3C73)),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.shield, color: Color(0xFF1A3C73)),
                    SizedBox(width: 8),
                    Text(
                      'Trust & Transparency',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1A3C73),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 8),
                Text(
                  'Your concern will be reviewed transparently by the Anti-Corruption Officer. You can track status in real-time.',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.black87,
                    height: 1.4,
                  ),
                ),
            ],
          ),
        ),
        ],
      ),
    );
  }

  // Helper methods for styling
  Color _getSentimentColor(SentimentScore sentiment) {
    switch (sentiment) {
      case SentimentScore.veryPositive:
        return Colors.green;
      case SentimentScore.positive:
        return Colors.lightGreen;
      case SentimentScore.neutral:
        return Colors.grey;
      case SentimentScore.negative:
        return Colors.orange;
      case SentimentScore.veryNegative:
        return Colors.red;
    }
  }

  IconData _getSentimentIcon(SentimentScore sentiment) {
    switch (sentiment) {
      case SentimentScore.veryPositive:
        return Icons.sentiment_very_satisfied;
      case SentimentScore.positive:
        return Icons.sentiment_satisfied;
      case SentimentScore.neutral:
        return Icons.sentiment_neutral;
      case SentimentScore.negative:
        return Icons.sentiment_dissatisfied;
      case SentimentScore.veryNegative:
        return Icons.sentiment_very_dissatisfied;
    }
  }

  String _getSentimentDisplayName(SentimentScore sentiment) {
    switch (sentiment) {
      case SentimentScore.veryPositive:
        return 'Very Positive';
      case SentimentScore.positive:
        return 'Positive';
      case SentimentScore.neutral:
        return 'Neutral';
      case SentimentScore.negative:
        return 'Negative';
      case SentimentScore.veryNegative:
        return 'Very Negative';
    }
  }

  IconData _getFileIcon(String fileName) {
    final extension = fileName.split('.').last.toLowerCase();
    switch (extension) {
      case 'pdf':
        return Icons.picture_as_pdf;
      case 'doc':
      case 'docx':
        return Icons.description;
      case 'jpg':
      case 'jpeg':
      case 'png':
        return Icons.image;
      case 'txt':
        return Icons.text_snippet;
      default:
        return Icons.attach_file;
    }
  }


  String _getCategoryDisplayName(ConcernCategory category) {
    switch (category) {
      case ConcernCategory.budget:
        return 'Budget & Finance';
      case ConcernCategory.tender:
        return 'Tenders & Procurement';
      case ConcernCategory.community:
        return 'Community Issues';
      case ConcernCategory.system:
        return 'System & Technical';
      case ConcernCategory.corruption:
        return 'Corruption & Fraud';
      case ConcernCategory.transparency:
        return 'Transparency & Accountability';
      case ConcernCategory.other:
        return 'Other';
    }
  }

  String _getCategoryDescription(ConcernCategory category) {
    switch (category) {
      case ConcernCategory.budget:
        return 'Issues related to budget allocation, spending, and financial management';
      case ConcernCategory.tender:
        return 'Concerns about tender processes, procurement, and contractor selection';
      case ConcernCategory.community:
        return 'Community-related issues, local problems, and public services';
      case ConcernCategory.system:
        return 'Technical issues with the platform, bugs, and system improvements';
      case ConcernCategory.corruption:
        return 'Reports of corruption, fraud, or unethical behavior';
      case ConcernCategory.transparency:
        return 'Requests for transparency, information disclosure, and accountability';
      case ConcernCategory.other:
        return 'Any other concerns not covered by the above categories';
    }
  }

  String _getTypeDisplayName(ConcernType type) {
    switch (type) {
      case ConcernType.complaint:
        return 'Complaint';
      case ConcernType.suggestion:
        return 'Suggestion';
      case ConcernType.report:
        return 'Report';
      case ConcernType.question:
        return 'Question';
      case ConcernType.feedback:
        return 'Feedback';
    }
  }

  String _getTypeDescription(ConcernType type) {
    switch (type) {
      case ConcernType.complaint:
        return 'Formal complaint about an issue or problem';
      case ConcernType.suggestion:
        return 'Suggestion for improvement or change';
      case ConcernType.report:
        return 'Report of misconduct or violation';
      case ConcernType.question:
        return 'Question or request for information';
      case ConcernType.feedback:
        return 'General feedback or opinion';
    }
  }

}
