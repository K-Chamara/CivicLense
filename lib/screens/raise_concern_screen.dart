import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/concern_models.dart';
import '../services/concern_service.dart';
import '../services/auth_service.dart';

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
  final _concernService = ConcernService();
  final _authService = AuthService();

  ConcernCategory _selectedCategory = ConcernCategory.other;
  ConcernType _selectedType = ConcernType.complaint;
  bool _isAnonymous = false;
  bool _isPublic = true;
  bool _isLoading = false;
  List<String> _tags = [];
  final _tagController = TextEditingController();

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
    _tagController.dispose();
    super.dispose();
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
        priority: ConcernPriority.medium, // Default priority - will be determined by community support
        status: ConcernStatus.pending,
        createdAt: DateTime.now(),
        relatedBudgetId: widget.relatedBudgetId,
        relatedTenderId: widget.relatedTenderId,
        relatedCommunityId: widget.relatedCommunityId,
        tags: _tags,
        isAnonymous: _isAnonymous,
        isPublic: _isPublic,
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

  void _addTag() {
    final tag = _tagController.text.trim();
    if (tag.isNotEmpty && !_tags.contains(tag)) {
      setState(() {
        _tags.add(tag);
        _tagController.clear();
      });
    }
  }

  void _removeTag(String tag) {
    setState(() {
      _tags.remove(tag);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Raise a Concern'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Category Selection
              _buildSectionTitle('Category'),
              _buildCategorySelector(),
              const SizedBox(height: 20),

              // Type Selection
              _buildSectionTitle('Type'),
              _buildTypeSelector(),
              const SizedBox(height: 20),

              // Title
              _buildSectionTitle('Title'),
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  hintText: 'Brief description of your concern',
                  border: OutlineInputBorder(),
                ),
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
              const SizedBox(height: 20),

              // Description
              _buildSectionTitle('Description'),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  hintText: 'Provide detailed information about your concern',
                  border: OutlineInputBorder(),
                  alignLabelWithHint: true,
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter a description';
                  }
                  if (value.trim().length < 20) {
                    return 'Description must be at least 20 characters';
                  }
                  return null;
                },
                maxLines: 5,
                maxLength: 1000,
              ),
              const SizedBox(height: 20),

              // Tags
              _buildSectionTitle('Tags (Optional)'),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _tagController,
                      decoration: const InputDecoration(
                        hintText: 'Add a tag',
                        border: OutlineInputBorder(),
                      ),
                      onFieldSubmitted: (_) => _addTag(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: _addTag,
                    child: const Text('Add'),
                  ),
                ],
              ),
              if (_tags.isNotEmpty) ...[
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: _tags.map((tag) => Chip(
                    label: Text(tag),
                    deleteIcon: const Icon(Icons.close, size: 18),
                    onDeleted: () => _removeTag(tag),
                  )).toList(),
                ),
              ],
              const SizedBox(height: 20),

              // Privacy Options
              _buildSectionTitle('Privacy Options'),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      SwitchListTile(
                        title: const Text('Submit anonymously'),
                        subtitle: const Text('Your name will not be visible to others'),
                        value: _isAnonymous,
                        onChanged: (value) {
                          setState(() {
                            _isAnonymous = value;
                          });
                        },
                      ),
                      SwitchListTile(
                        title: const Text('Make public'),
                        subtitle: const Text('Other users can view and vote on this concern'),
                        value: _isPublic,
                        onChanged: (value) {
                          setState(() {
                            _isPublic = value;
                          });
                        },
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Related Information
              if (widget.relatedBudgetId != null || 
                  widget.relatedTenderId != null || 
                  widget.relatedCommunityId != null) ...[
                _buildSectionTitle('Related Information'),
                Card(
                  color: Colors.blue.shade50,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'This concern is related to:',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        if (widget.relatedBudgetId != null)
                          const Text('• Budget Item'),
                        if (widget.relatedTenderId != null)
                          const Text('• Tender/Procurement'),
                        if (widget.relatedCommunityId != null)
                          const Text('• Community'),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
              ],

              // Submit Button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submitConcern,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                          'Submit Concern',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: Colors.black87,
        ),
      ),
    );
  }

  Widget _buildCategorySelector() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: ConcernCategory.values.map((category) {
            return RadioListTile<ConcernCategory>(
              title: Text(_getCategoryDisplayName(category)),
              subtitle: Text(_getCategoryDescription(category)),
              value: category,
              groupValue: _selectedCategory,
              onChanged: (value) {
                setState(() {
                  _selectedCategory = value!;
                });
              },
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildTypeSelector() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: ConcernType.values.map((type) {
            return RadioListTile<ConcernType>(
              title: Text(_getTypeDisplayName(type)),
              subtitle: Text(_getTypeDescription(type)),
              value: type,
              groupValue: _selectedType,
              onChanged: (value) {
                setState(() {
                  _selectedType = value!;
                });
              },
            );
          }).toList(),
        ),
      ),
    );
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
