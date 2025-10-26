import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/concern_models.dart';
import '../services/concern_service.dart';
import '../services/auth_service.dart';
import '../services/smart_priority_service.dart';
import '../services/gemini_ai_service.dart';
import '../services/cloudinary_service.dart';
import '../l10n/app_localizations.dart';
import 'dart:async';

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
  bool _isUploadingFiles = false;
  
  // File upload
  List<File> _attachedFiles = [];
  List<String> _fileNames = [];
  
  // Sentiment analysis
  SentimentAnalysisResult? _sentimentResult;
  bool _isAnalyzingSentiment = false;
  
  // AI Analysis
  SmartAnalysisResult? _aiAnalysisResult;
  bool _isAnalyzingWithAI = false;
  
  // Gemini AI Features
  CategorySuggestion? _categorySuggestion;
  bool _isSuggestingCategory = false;
  QualityCheck? _qualityCheck;
  bool _isCheckingQuality = false;
  GeminiAnalysisResult? _geminiAnalysis;
  Timer? _descriptionDebounce;
  List<String> _suggestedTopics = [];
  
  // New AI Suggestions System
  bool _isGeneratingSuggestions = false;
  AISuggestions? _aiSuggestions;
  
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
    _setupGeminiListeners();
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

  void _setupGeminiListeners() {
    // Listen to description changes for real-time AI analysis
    _descriptionController.addListener(() {
      print('📝 Description changed: ${_descriptionController.text.length} characters');
      // Debounce to avoid too many API calls
      _descriptionDebounce?.cancel();
      _descriptionDebounce = Timer(const Duration(milliseconds: 2000), () {
        if (_descriptionController.text.length >= 50) {
          print('🚀 Triggering AI suggestions for ${_descriptionController.text.length} characters');
          _generateAISuggestions();
        } else {
          print('⏳ Not enough characters yet: ${_descriptionController.text.length}/50');
        }
      });
    });
  }

  @override
  void dispose() {
    _descriptionDebounce?.cancel();
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
  Future<void> _calculateEngagementScore() async {
    // Calculate real engagement based on similar concerns in database
    try {
      final description = _descriptionController.text.trim().toLowerCase();
      if (description.length < 20) return;
      
      // Extract keywords from description
      final keywords = description.split(' ')
          .where((word) => word.length > 4)
          .take(5)
          .toList();
      
      if (keywords.isEmpty) return;
      
      // Query Firestore for similar concerns
      final querySnapshot = await FirebaseFirestore.instance
          .collection('concerns')
          .orderBy('createdAt', descending: true)
          .limit(100)
          .get();
      final concernsSnapshot = querySnapshot.docs
          .map((doc) => Concern.fromFirestore(doc))
          .toList();
      
      if (concernsSnapshot.isEmpty) return;
      
      // Find similar concerns based on keywords
      int matchCount = 0;
      double totalSupport = 0;
      
      for (var concern in concernsSnapshot) {
        final concernText = '${concern.title} ${concern.description}'.toLowerCase();
        int matches = keywords.where((keyword) => concernText.contains(keyword)).length;
        
        if (matches >= 2) {
          matchCount++;
          totalSupport += (concern.supportCount ?? 0).toDouble();
        }
      }
      
      if (matchCount > 0) {
        // Calculate engagement score (0.0 to 1.0)
        final avgSupport = totalSupport / matchCount;
        final score = (avgSupport / 100).clamp(0.0, 1.0);
        
        setState(() {
          _engagementScore = score;
        });
        
        print('📊 Engagement calculated: ${(score * 100).toStringAsFixed(0)}% based on $matchCount similar concerns with $totalSupport total support');
      }
    } catch (e) {
      print('⚠️ Engagement calculation failed: $e');
      // Keep at 0 if calculation fails
    }
  }

  // AI Analysis using Smart Priority Service
  Future<void> _analyzeWithAI() async {
    if (_titleController.text.trim().isEmpty || _descriptionController.text.trim().isEmpty) {
      return;
    }

    setState(() {
      _isAnalyzingWithAI = true;
    });

    try {
      // Try Gemini AI first for better analysis
      print('🧠 Using Gemini AI for analysis...');
      final geminiResult = await GeminiAIService.analyzeConcern(
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        category: _selectedCategory,
      );

      setState(() {
        _geminiAnalysis = geminiResult;
        // Convert Gemini result to SmartAnalysisResult for compatibility
        _aiAnalysisResult = SmartAnalysisResult(
          sentiment: SentimentAnalysisResult(
            score: geminiResult.sentimentScore,
            magnitude: geminiResult.sentimentScore.abs(),
            sentimentScore: geminiResult.sentiment,
          ),
          priority: PriorityAnalysisResult(
            priority: geminiResult.priority,
            score: geminiResult.priorityScore,
            reasoning: geminiResult.reasoning,
          ),
          topics: geminiResult.topics,
          summary: geminiResult.reasoning,
          confidence: geminiResult.confidence,
          analyzedAt: DateTime.now(),
          aiModel: 'Gemini 2.0 Flash',
        );
      });

      // Show Gemini analysis results with enhanced features
      if (mounted) {
        _showGeminiAnalysisResults(geminiResult);
      }
    } catch (e) {
      print('⚠️ Gemini AI failed, falling back to keyword analysis: $e');
      // Fallback to keyword-based analysis
      try {
        final aiResult = SmartPriorityService.analyzeConcern(
          _titleController.text.trim(),
          _descriptionController.text.trim(),
          _selectedCategory,
        );

        setState(() {
          _aiAnalysisResult = aiResult;
        });

        if (mounted) {
          _showAIAnalysisResults(aiResult);
        }
      } catch (fallbackError) {
        print('AI Analysis Error: $fallbackError');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('AI Analysis failed: $fallbackError'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      }
    } finally {
      setState(() {
        _isAnalyzingWithAI = false;
      });
    }
  }

  // AI Suggestions System
  Future<void> _generateAISuggestions() async {
    if (_isGeneratingSuggestions) return;
    
    setState(() => _isGeneratingSuggestions = true);
    
    try {
      print('🤖 Generating AI suggestions (OPTIMIZED - 1 API call)...');
      
      // OPTIMIZED: Get all suggestions in ONE API call
      final suggestions = await GeminiAIService.generateAllSuggestions(
        description: _descriptionController.text.trim(),
      );
      
      setState(() {
        _aiSuggestions = AISuggestions(
          suggestedTitle: suggestions.suggestedTitle,
          suggestedCategory: suggestions.suggestedCategory,
          suggestedType: suggestions.suggestedType,
          descriptionFeedback: suggestions.descriptionFeedback.formattedFeedback,
          confidence: suggestions.confidence,
        );
        _isGeneratingSuggestions = false;
      });
      
      print('✅ AI suggestions generated successfully (Used 1 API request)');
      
    } catch (e) {
      print('❌ AI suggestions failed: $e');
      setState(() => _isGeneratingSuggestions = false);
      
      // Show error message to user
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('AI suggestions failed: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }

  void _useAISuggestions() {
    if (_aiSuggestions != null) {
      setState(() {
        _titleController.text = _aiSuggestions!.suggestedTitle;
        _selectedCategory = _aiSuggestions!.suggestedCategory;
        _selectedType = _aiSuggestions!.suggestedType;
        _aiSuggestions = null; // Clear suggestions after using
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ AI suggestions applied successfully!'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  void _suggestCategoryFallback() {
    final text = _descriptionController.text.toLowerCase();
    ConcernCategory suggestedCategory = ConcernCategory.other;
    
    print('🔍 Analyzing text for category: "$text"');
    
    if (text.contains('budget') || text.contains('money') || text.contains('financial')) {
      suggestedCategory = ConcernCategory.budget;
      print('  ✓ Found Budget keyword');
    } else if (text.contains('tender') || text.contains('contract') || text.contains('procurement')) {
      suggestedCategory = ConcernCategory.tender;
      print('  ✓ Found Tender keyword');
    } else if (text.contains('community') || text.contains('neighborhood') || text.contains('local')) {
      suggestedCategory = ConcernCategory.community;
      print('  ✓ Found Community keyword');
    } else if (text.contains('corruption') || text.contains('bribe') || text.contains('fraud')) {
      suggestedCategory = ConcernCategory.corruption;
      print('  ✓ Found Corruption keyword');
    } else if (text.contains('transparency') || text.contains('open') || text.contains('public')) {
      suggestedCategory = ConcernCategory.transparency;
      print('  ✓ Found Transparency keyword');
    } else if (text.contains('system') || text.contains('process') || text.contains('procedure')) {
      suggestedCategory = ConcernCategory.system;
      print('  ✓ Found System keyword');
    } else {
      print('  ⚠ No specific category found, using Other');
    }
    
    setState(() {
      _categorySuggestion = CategorySuggestion(
        category: suggestedCategory,
        confidence: 0.7, // Medium confidence for fallback
        reasoning: 'Basic keyword analysis',
      );
    });
    
    print('✅ Fallback category suggested: ${suggestedCategory.name}');
  }

  Future<void> _suggestTypeWithGemini() async {
    if (_descriptionController.text.isEmpty) return;
    
    try {
      print('🎯 Gemini suggesting type...');
      // Use the existing analyzeConcern method to get comprehensive analysis
      final analysis = await GeminiAIService.analyzeConcern(
        title: _titleController.text.trim().isEmpty ? 'Untitled Concern' : _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        category: _selectedCategory,
      );
      
      // Determine type based on sentiment and priority
      ConcernType suggestedType = ConcernType.complaint; // Default
      
      if (analysis.sentiment == SentimentScore.veryNegative || analysis.sentiment == SentimentScore.negative) {
        suggestedType = ConcernType.complaint;
      } else if (analysis.sentiment == SentimentScore.positive || analysis.sentiment == SentimentScore.veryPositive) {
        suggestedType = ConcernType.suggestion;
      } else if (analysis.priority == ConcernPriority.critical || analysis.priority == ConcernPriority.high) {
        suggestedType = ConcernType.report;
      } else {
        suggestedType = ConcernType.question;
      }
      
      setState(() {
        _selectedType = suggestedType;
      });
      
      print('✅ Type suggested: ${suggestedType.name}');
    } catch (e) {
      print('⚠️ Type suggestion failed: $e');
      // Fallback to basic keyword-based type suggestion
      _suggestTypeFallback();
    }
  }

  void _suggestTypeFallback() {
    final text = _descriptionController.text.toLowerCase();
    ConcernType suggestedType = ConcernType.complaint; // Default
    
    if (text.contains('suggest') || text.contains('improve') || text.contains('better')) {
      suggestedType = ConcernType.suggestion;
    } else if (text.contains('question') || text.contains('ask') || text.contains('how') || text.contains('what')) {
      suggestedType = ConcernType.question;
    } else if (text.contains('report') || text.contains('urgent') || text.contains('critical') || text.contains('emergency')) {
      suggestedType = ConcernType.report;
    } else {
      suggestedType = ConcernType.complaint;
    }
    
    print('🔄 Setting type from ${_selectedType.name} to ${suggestedType.name}');
    setState(() {
      _selectedType = suggestedType;
    });
    
    print('✅ Fallback type suggested: ${suggestedType.name} (Display: ${_getTypeDisplayName(suggestedType)})');
  }

  Future<void> _suggestTopicsWithGemini() async {
    if (_descriptionController.text.isEmpty) return;
    
    try {
      print('🎯 Gemini suggesting topics...');
      // Use the existing analyzeConcern method to get topics
      final analysis = await GeminiAIService.analyzeConcern(
        title: _titleController.text.trim().isEmpty ? 'Untitled Concern' : _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        category: _selectedCategory,
      );
      
      setState(() {
        _suggestedTopics = analysis.topics;
      });
      
      print('✅ Topics suggested: ${analysis.topics.join(', ')}');
    } catch (e) {
      print('⚠️ Topics suggestion failed: $e');
      // Fallback to basic keyword-based topic extraction
      _suggestTopicsFallback();
    }
  }

  void _suggestTopicsFallback() {
    final text = _descriptionController.text.toLowerCase();
    List<String> topics = [];
    
    print('🔍 Analyzing text for topics: "$text"');
    
    // Extract topics based on keywords
    if (text.contains('budget') || text.contains('money') || text.contains('financial')) {
      topics.add('Budget');
      print('  ✓ Found Budget keyword');
    }
    if (text.contains('corruption') || text.contains('bribe') || text.contains('fraud')) {
      topics.add('Corruption');
      print('  ✓ Found Corruption keyword');
    }
    if (text.contains('tender') || text.contains('contract') || text.contains('procurement')) {
      topics.add('Procurement');
      print('  ✓ Found Procurement keyword');
    }
    if (text.contains('community') || text.contains('neighborhood') || text.contains('local')) {
      topics.add('Community');
      print('  ✓ Found Community keyword');
    }
    if (text.contains('transparency') || text.contains('open') || text.contains('public')) {
      topics.add('Transparency');
      print('  ✓ Found Transparency keyword');
    }
    if (text.contains('system') || text.contains('process') || text.contains('procedure')) {
      topics.add('System');
      print('  ✓ Found System keyword');
    }
    if (text.contains('government') || text.contains('official') || text.contains('authority')) {
      topics.add('Government');
      print('  ✓ Found Government keyword');
    }
    
    // If no specific topics found, add generic ones
    if (topics.isEmpty) {
      topics.add('General');
      print('  ⚠ No specific topics found, adding General');
    }
    
    print('🔄 Setting topics from ${_suggestedTopics.length} to ${topics.length} topics');
    setState(() {
      _suggestedTopics = topics;
    });
    
    print('✅ Fallback topics suggested: ${topics.join(', ')}');
  }

  Future<void> _checkQualityWithGemini() async {
    if (_isCheckingQuality) return;
    
    setState(() => _isCheckingQuality = true);
    
    try {
      print('📊 Gemini checking quality...');
      final quality = await GeminiAIService.checkQuality(
        title: _titleController.text.trim().isEmpty ? 'Untitled Concern' : _titleController.text.trim(),
        description: _descriptionController.text.trim(),
      );
      
      setState(() {
        _qualityCheck = quality;
        _isCheckingQuality = false;
      });
      
      print('✅ Quality score: ${(quality.qualityScore * 100).toStringAsFixed(0)}%');
    } catch (e) {
      print('⚠️ Quality check failed: $e');
      // Fallback to basic quality assessment
      _checkQualityFallback();
      setState(() => _isCheckingQuality = false);
    }
  }

  void _checkQualityFallback() {
    final text = _descriptionController.text.trim();
    final title = _titleController.text.trim();
    
    double qualityScore = 0.0;
    List<String> suggestions = [];
    List<String> strengths = [];
    
    // Basic quality assessment
    if (title.isNotEmpty) {
      qualityScore += 0.2;
      strengths.add('Has a clear title');
    }
    
    if (text.length >= 50) {
      qualityScore += 0.3;
      strengths.add('Description is detailed enough');
    } else {
      suggestions.add('Provide more details in your description (at least 50 characters)');
    }
    
    if (text.contains('budget') || text.contains('money') || text.contains('financial') ||
        text.contains('corruption') || text.contains('tender') || text.contains('community')) {
      qualityScore += 0.2;
      strengths.add('Identifies a specific issue');
    }
    
    if (text.contains('wallawatta') || text.contains('location') || text.contains('place')) {
      qualityScore += 0.2;
      strengths.add('Mentions a specific location');
    }
    
    if (text.length >= 100) {
      qualityScore += 0.1;
      strengths.add('Comprehensive description');
    }
    
    // Ensure quality score is between 0 and 1
    qualityScore = qualityScore.clamp(0.0, 1.0);
    
    setState(() {
      _qualityCheck = QualityCheck(
        qualityScore: qualityScore,
        missingElements: suggestions,
        suggestions: suggestions,
        strengths: strengths,
        isSubmittable: qualityScore >= 0.4,
      );
    });
    
    print('✅ Fallback quality score: ${(qualityScore * 100).toStringAsFixed(0)}%');
  }

  void _acceptCategorySuggestion() {
    if (_categorySuggestion != null) {
      setState(() {
        _selectedCategory = _categorySuggestion!.category;
        _categorySuggestion = null; // Dismiss suggestion after accepting
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('✅ Category set to ${_selectedCategory.name.toUpperCase()}'),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  void _showGeminiAnalysisResults(GeminiAnalysisResult result) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.purple.shade600, Colors.blue.shade600],
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.auto_awesome, color: Colors.white, size: 24),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('🤖 Gemini AI Analysis', style: TextStyle(fontSize: 20)),
                  Text('Powered by Google', style: TextStyle(fontSize: 12, color: Colors.grey)),
                ],
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Confidence Badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.green.shade400, Colors.green.shade600],
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.verified, color: Colors.white, size: 18),
                    const SizedBox(width: 6),
                    Text(
                      '${(result.confidence * 100).toStringAsFixed(0)}% Confidence',
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 20),
              
              // Priority
              _buildGeminiMetricCard(
                'Priority Level',
                result.priority.name.toUpperCase(),
                _getPriorityIcon(result.priority),
                _getPriorityColor(result.priority),
                subtitle: 'Score: ${(result.priorityScore * 100).toStringAsFixed(0)}%',
              ),
              
              const SizedBox(height: 12),
              
              // Sentiment
              _buildGeminiMetricCard(
                'Sentiment Analysis',
                result.sentiment.name.toUpperCase(),
                _getSentimentIcon(result.sentiment),
                _getSentimentColor(result.sentiment),
              ),
              
              const SizedBox(height: 12),
              
              // Urgency
              _buildGeminiMetricCard(
                'Urgency Level',
                '${result.urgencyLevel}/10',
                Icons.speed_rounded,
                result.urgencyLevel >= 8 ? Colors.red : result.urgencyLevel >= 6 ? Colors.orange : Colors.blue,
              ),
              
              if (result.estimatedResolutionDays > 0) ...[
                const SizedBox(height: 12),
                _buildGeminiMetricCard(
                  'Est. Resolution Time',
                  '${result.estimatedResolutionDays} days',
                  Icons.calendar_today_rounded,
                  Colors.purple,
                ),
              ],
              
              // Topics
              if (result.topics.isNotEmpty) ...[
                const SizedBox(height: 16),
                const Text('Detected Topics:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: result.topics.map((topic) => Chip(
                    label: Text(topic.toUpperCase()),
                    backgroundColor: Colors.blue.shade100,
                    labelStyle: TextStyle(color: Colors.blue.shade700, fontSize: 11, fontWeight: FontWeight.w600),
                  )).toList(),
                ),
              ],
              
              // User-friendly message instead of detailed actions
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.blue.shade600, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Your concern will be reviewed by anti-corruption officers who will take appropriate action.',
                        style: TextStyle(color: Colors.blue.shade700, fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),
              
              // AI Reasoning
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.purple.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.purple.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.info_outline, color: Colors.purple.shade600, size: 18),
                        const SizedBox(width: 6),
                        Text('AI Reasoning:', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.purple.shade700)),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(result.reasoning, style: const TextStyle(fontSize: 13)),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Got it!'),
          ),
        ],
      ),
    );
  }

  Widget _buildGeminiMetricCard(String label, String value, IconData icon, Color color, {String? subtitle}) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
                Text(value, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color)),
                if (subtitle != null)
                  Text(subtitle, style: TextStyle(fontSize: 10, color: Colors.grey.shade500)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showAIAnalysisResults(SmartAnalysisResult result) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.psychology, color: Colors.purple),
            SizedBox(width: 8),
            Text('🤖 AI Analysis Results'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('✅ AI has analyzed your concern and suggests:', 
                style: TextStyle(fontWeight: FontWeight.bold)),
            SizedBox(height: 12),
            _buildAIAnalysisCard('Priority', _getPriorityIcon(result.priority.priority), 
                '${result.priority.priority.name.toUpperCase()}', 'Based on your description'),
            SizedBox(height: 12),
            _buildAIAnalysisCard('Sentiment', _getSentimentIcon(result.sentiment.sentimentScore), 
                '${result.sentiment.sentimentScore.name.replaceAll(RegExp(r'([A-Z])'), ' \$1').trim()}', 
                'Detected from your text'),
            SizedBox(height: 12),
            if (result.topics.isNotEmpty) ...[
              Text('🎯 Suggested Topics:', style: TextStyle(fontWeight: FontWeight.bold)),
              SizedBox(height: 4),
              Wrap(
                children: result.topics.map((topic) => Chip(
                  label: Text(topic),
                  backgroundColor: Colors.blue.shade100,
                )).toList(),
              ),
            ],
            SizedBox(height: 12),
            Text('📊 Confidence: ${(result.confidence * 100).round()}%', 
                style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green)),
            SizedBox(height: 8),
            Text('💡 You can adjust the category and type if needed before submitting.',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Close'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _applyAIRecommendations(result);
            },
            child: Text('Apply Suggestions'),
          ),
        ],
      ),
    );
  }

  Widget _buildAIAnalysisCard(String title, IconData icon, String value, String subtitle) {
    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.purple, size: 20),
          SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                Text(value, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                Text(subtitle, style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  IconData _getPriorityIcon(ConcernPriority priority) {
    switch (priority) {
      case ConcernPriority.critical:
        return Icons.warning;
      case ConcernPriority.high:
        return Icons.priority_high;
      case ConcernPriority.medium:
        return Icons.remove;
      case ConcernPriority.low:
        return Icons.keyboard_arrow_down;
    }
  }

  IconData _getSentimentIcon(SentimentScore sentiment) {
    switch (sentiment) {
      case SentimentScore.veryNegative:
        return Icons.sentiment_very_dissatisfied;
      case SentimentScore.negative:
        return Icons.sentiment_dissatisfied;
      case SentimentScore.neutral:
        return Icons.sentiment_neutral;
      case SentimentScore.positive:
        return Icons.sentiment_satisfied;
      case SentimentScore.veryPositive:
        return Icons.sentiment_very_satisfied;
    }
  }

  void _applyAIRecommendations(SmartAnalysisResult result) {
    // The AI recommendations are already applied when creating the concern
    // This method can be used for additional actions if needed
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('✅ AI Priority: ${result.priority.priority.name.toUpperCase()} applied'),
        backgroundColor: Colors.green,
      ),
    );
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
      final firstName = userData?['firstName']?.toString();
      final lastName = userData?['lastName']?.toString();
      final userName = (firstName != null && lastName != null)
          ? '$firstName $lastName'
          : user.email?.split('@').first ?? 'Anonymous User';
      
      // Get additional user information for better tracking
      final userRole = userData?['role']?.toString() ?? 'citizen';
      final userPhone = userData?['phone']?.toString() ?? '';
      final userLocation = userData?['location']?.toString() ?? '';
      
      // Handle userRegistrationDate properly - it might be a Firestore Timestamp
      DateTime? userRegistrationDate;
      final createdAtData = userData?['createdAt'];
      if (createdAtData != null) {
        if (createdAtData is DateTime) {
          userRegistrationDate = createdAtData;
        } else if (createdAtData is String) {
          userRegistrationDate = DateTime.tryParse(createdAtData);
        } else if (createdAtData is Map<String, dynamic>) {
          // Handle Firestore Timestamp
          try {
            userRegistrationDate = DateTime.fromMillisecondsSinceEpoch(
              createdAtData['_seconds'] * 1000 + (createdAtData['_nanoseconds'] ?? 0) ~/ 1000000
            );
          } catch (e) {
            print('Error parsing timestamp: $e');
            userRegistrationDate = null;
          }
        }
      }

      // Upload files to Cloudinary if any are attached
      List<ConcernAttachment> uploadedAttachments = [];
      if (_attachedFiles.isNotEmpty) {
        setState(() {
          _isUploadingFiles = true;
        });
        
        try {
          print('📤 Uploading ${_attachedFiles.length} files to Cloudinary...');
          final uploadedUrls = await CloudinaryService.uploadFiles(_attachedFiles);
          
          if (uploadedUrls.isNotEmpty) {
            // Create ConcernAttachment objects from uploaded URLs
            uploadedAttachments = [];
            for (int i = 0; i < uploadedUrls.length; i++) {
              final url = uploadedUrls[i];
              final fileName = i < _fileNames.length ? _fileNames[i] : 'file_${i + 1}';
              final file = _attachedFiles[i];
              
              // Determine file type from extension
              String fileType = 'image';
              if (fileName.toLowerCase().endsWith('.pdf')) {
                fileType = 'pdf';
              } else if (fileName.toLowerCase().endsWith('.doc') || fileName.toLowerCase().endsWith('.docx')) {
                fileType = 'document';
              } else if (fileName.toLowerCase().endsWith('.txt')) {
                fileType = 'text';
              }
              
              // Get file size
              final fileSize = await file.length();
              
              uploadedAttachments.add(ConcernAttachment(
                id: '',
                concernId: '', // Will be set after concern is created
                fileName: fileName,
                fileUrl: url,
                fileType: fileType,
                fileSize: fileSize,
                uploadedAt: DateTime.now(),
                uploadedBy: user.uid,
              ));
            }
            
            print('✅ Successfully uploaded ${uploadedAttachments.length} files');
            
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('✅ ${uploadedAttachments.length} evidence file(s) uploaded successfully!'),
                  backgroundColor: Colors.green,
                ),
              );
            }
          } else {
            print('❌ No files were uploaded successfully');
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('❌ Failed to upload evidence files. Please try again.'),
                  backgroundColor: Colors.red,
                ),
              );
            }
          }
        } catch (e) {
          print('❌ Error uploading files: $e');
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('❌ Error uploading evidence files: $e'),
                backgroundColor: Colors.red,
              ),
            );
          }
        } finally {
          setState(() {
            _isUploadingFiles = false;
          });
        }
      }

      // Always use Smart Priority Service to determine final priority
      final smartAnalysis = SmartPriorityService.analyzeConcern(
        _titleController.text.trim(),
        _descriptionController.text.trim(),
        _selectedCategory,
      );
      
      final ConcernPriority finalPriority = smartAnalysis.priority.priority;
      final SentimentScore? finalSentiment = smartAnalysis.sentiment.sentimentScore;
      final double? finalSentimentMagnitude = smartAnalysis.sentiment.magnitude;
      final List<String> aiTopics = smartAnalysis.topics;
      final double aiConfidence = smartAnalysis.confidence;

      final concern = Concern(
        id: '',
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        authorId: user.uid,
        authorName: _isAnonymous ? 'Anonymous User' : userName,
        authorEmail: _isAnonymous ? 'anonymous@example.com' : user.email ?? '',
        authorRole: _isAnonymous ? null : userRole,
        authorPhone: _isAnonymous ? null : userPhone,
        authorLocation: _isAnonymous ? null : userLocation,
        category: _selectedCategory,
        type: _selectedType,
        priority: finalPriority, // AI-determined priority
        status: ConcernStatus.pending,
        createdAt: DateTime.now(),
        relatedBudgetId: widget.relatedBudgetId,
        relatedTenderId: widget.relatedTenderId,
        relatedCommunityId: widget.relatedCommunityId,
        tags: aiTopics, // AI-detected topics as tags
        isAnonymous: _isAnonymous,
        isPublic: _isPublic,
        sentimentScore: finalSentiment,
        sentimentMagnitude: finalSentimentMagnitude,
        location: _locationController.text.trim().isEmpty ? null : _locationController.text.trim(),
        attachments: uploadedAttachments, // ✅ Include uploaded evidence files
        metadata: {
          'location': _locationController.text.trim(),
          'sentimentScore': finalSentiment?.name,
          'sentimentMagnitude': finalSentimentMagnitude,
          'engagementScore': _engagementScore,
          'attachmentCount': uploadedAttachments.length,
          // AI Analysis Results
          'aiAnalysis': {
            'model': 'SmartKeyword v1.0',
            'confidence': aiConfidence,
            'analyzedAt': DateTime.now().toIso8601String(),
            'topics': aiTopics,
            'priorityScore': smartAnalysis.priority.score,
            'sentimentScore': smartAnalysis.sentiment.score,
            'reasoning': smartAnalysis.priority.reasoning,
            'smartPriority': finalPriority.name,
            'smartSentiment': finalSentiment?.name,
          },
          // Enhanced user tracking information
          'userRole': userRole,
          'userPhone': _isAnonymous ? 'hidden' : userPhone,
          'userLocation': _isAnonymous ? 'hidden' : userLocation,
          'userRegistrationDate': userRegistrationDate?.toIso8601String(),
          'userAccountAge': userRegistrationDate != null 
              ? DateTime.now().difference(userRegistrationDate).inDays
              : null,
          'submissionTimestamp': DateTime.now().toIso8601String(),
          'submissionSource': 'mobile_app',
          'userAgent': 'CivicLense_Mobile_App',
        },
      );

      final concernId = await _concernService.createConcern(concern);
      
      // Update attachments with the concernId
      if (uploadedAttachments.isNotEmpty) {
        // Create new ConcernAttachment objects with the correct concernId
        final updatedAttachments = uploadedAttachments.map((attachment) => ConcernAttachment(
          id: attachment.id,
          concernId: concernId,
          fileName: attachment.fileName,
          fileUrl: attachment.fileUrl,
          fileType: attachment.fileType,
          fileSize: attachment.fileSize,
          uploadedAt: attachment.uploadedAt,
          uploadedBy: attachment.uploadedBy,
        )).toList();
        
        // Update the concern with the correct attachment concernIds
        await _concernService.updateConcernAttachments(concernId, updatedAttachments);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.concernSubmittedSuccessfully),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.concernSubmissionFailed),
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
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              AppLocalizations.of(context)!.raiseConcern,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            Text(
              AppLocalizations.of(context)!.raiseConcernSubtitle,
              style: const TextStyle(
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
                    label: AppLocalizations.of(context)!.concernTitleLabel,
                    hint: AppLocalizations.of(context)!.concernTitleHint,
                    prefixIcon: Icons.title,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return AppLocalizations.of(context)!.concernTitleRequired;
                      }
                      if (value.trim().length < 10) {
                        return AppLocalizations.of(context)!.concernTitleMinLength;
                      }
                      return null;
                    },
                    maxLength: 100,
                  ),
                            const SizedBox(height: 16),

                            // Category/Type Dropdown
                            _buildDropdownSection(),
                            const SizedBox(height: 8),
                            
                            // Gemini Category Suggestion Chip
                            if (_categorySuggestion != null && _categorySuggestion!.confidence > 0.7)
                              _buildCategorySuggestionChip(),
                            if (_categorySuggestion != null && _categorySuggestion!.confidence > 0.7)
                              const SizedBox(height: 8),

                            const SizedBox(height: 8),

                            // Description Box
                            _buildDescriptionSection(),
                            const SizedBox(height: 8),
                            
                            // Gemini Quality Indicator
                            if (_qualityCheck != null)
                              _buildQualityIndicator(),
                            if (_qualityCheck != null)
                              const SizedBox(height: 8),
                            
                            // Suggested Topics
                            if (_suggestedTopics.isNotEmpty)
                              _buildTopicsSuggestion(),
                            if (_suggestedTopics.isNotEmpty)
                              const SizedBox(height: 8),
                            
                            const SizedBox(height: 8),

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
                label: AppLocalizations.of(context)!.category,
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
                label: AppLocalizations.of(context)!.type,
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
                label: AppLocalizations.of(context)!.category,
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


  Widget _buildAISuggestionsCard() {
    if (_aiSuggestions == null) return const SizedBox.shrink();
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.purple.shade50, Colors.blue.shade50],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.purple.shade300, width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.purple.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Icon(Icons.auto_awesome, color: Colors.purple.shade700, size: 28),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '🤖 AI Suggestions',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        color: Color(0xFF1A3C73),
                      ),
                    ),
                    Text(
                      'Based on your description analysis',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.purple.shade600,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${(_aiSuggestions!.confidence * 100).round()}% confidence',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 20),
          
          // Suggestions
          _buildSuggestionItem(
            '📝 Suggested Title',
            _aiSuggestions!.suggestedTitle,
            Icons.title,
            Colors.blue,
          ),
          
          const SizedBox(height: 12),
          
          _buildSuggestionItem(
            '📂 Suggested Category',
            _getCategoryDisplayName(_aiSuggestions!.suggestedCategory),
            Icons.category,
            Colors.green,
          ),
          
          const SizedBox(height: 12),
          
          _buildSuggestionItem(
            '🏷️ Suggested Type',
            _getTypeDisplayName(_aiSuggestions!.suggestedType),
            Icons.label,
            Colors.orange,
          ),
          
          const SizedBox(height: 20),
          
          // Description Feedback
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.7),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.blue.shade200),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.feedback, color: Colors.blue.shade700, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'Description Feedback',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.blue.shade700,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  _aiSuggestions!.descriptionFeedback,
                  style: const TextStyle(
                    fontSize: 13,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 20),
          
          // Action Buttons
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _useAISuggestions,
                  icon: const Icon(Icons.check_circle, size: 18),
                  label: const Text('Use Suggestions'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green.shade600,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    setState(() {
                      _aiSuggestions = null;
                    });
                  },
                  icon: const Icon(Icons.close, size: 18),
                  label: const Text('Dismiss'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.grey.shade600,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSuggestionItem(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.7),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color.fromRGBO(
                      color.red,
                      color.green,
                      color.blue,
                      0.8,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDescriptionSection() {
    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
              AppLocalizations.of(context)!.description,
              style: const TextStyle(
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
              label: Text(AppLocalizations.of(context)!.analyzeTone),
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
                    return AppLocalizations.of(context)!.fieldRequired;
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
        const SizedBox(height: 16),
        
        // AI Suggestions Section
        if (_aiSuggestions != null) _buildAISuggestionsCard(),
        if (_aiSuggestions != null) const SizedBox(height: 16),
        
        // Sentiment Analysis Results Preview
        if (_aiAnalysisResult != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.green.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.check_circle, color: Colors.green.shade600, size: 20),
                      SizedBox(width: 8),
                      Text(
                        'AI Analysis Complete',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.green.shade700,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Priority: ${_aiAnalysisResult!.priority.priority.name.toUpperCase()}',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  Text(
                    'Sentiment: ${_aiAnalysisResult!.sentiment.sentimentScore.name.replaceAll(RegExp(r'([A-Z])'), ' \$1').trim()}',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  if (_aiAnalysisResult!.topics.isNotEmpty) ...[
                    SizedBox(height: 4),
                    Text(
                      'Topics: ${_aiAnalysisResult!.topics.join(', ')}',
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                    ),
                  ],
                  Text(
                    'Confidence: ${(_aiAnalysisResult!.confidence * 100).round()}%',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),
                ],
              ),
            ),
          ],
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
                  onPressed: (_isLoading || _isUploadingFiles) ? null : _submitConcern,
                  style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2ECC71),
                    foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                    ),
              elevation: 4,
                  ),
                  child: (_isLoading || _isUploadingFiles)
                ? Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _isUploadingFiles ? 'Uploading Evidence...' : 'Creating Concern...',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
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

  Color _getPriorityColor(ConcernPriority priority) {
    switch (priority) {
      case ConcernPriority.critical:
        return Colors.red.shade700;
      case ConcernPriority.high:
        return Colors.orange.shade700;
      case ConcernPriority.medium:
        return Colors.blue.shade700;
      case ConcernPriority.low:
        return Colors.green.shade700;
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
        return AppLocalizations.of(context)!.budgetCategory;
      case ConcernCategory.tender:
        return AppLocalizations.of(context)!.tenderCategory;
      case ConcernCategory.community:
        return AppLocalizations.of(context)!.communityCategory;
      case ConcernCategory.system:
        return AppLocalizations.of(context)!.systemCategory;
      case ConcernCategory.corruption:
        return AppLocalizations.of(context)!.corruptionCategory;
      case ConcernCategory.transparency:
        return AppLocalizations.of(context)!.transparencyCategory;
      case ConcernCategory.other:
        return AppLocalizations.of(context)!.otherCategory;
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
        return AppLocalizations.of(context)!.complaintType;
      case ConcernType.suggestion:
        return AppLocalizations.of(context)!.suggestionType;
      case ConcernType.report:
        return AppLocalizations.of(context)!.reportType;
      case ConcernType.question:
        return AppLocalizations.of(context)!.questionType;
      case ConcernType.feedback:
        return AppLocalizations.of(context)!.feedbackType;
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

  // Gemini UI Components
  Widget _buildCategorySuggestionChip() {
    if (_categorySuggestion == null) return const SizedBox.shrink();
    
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.purple.shade50, Colors.blue.shade50],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.purple.shade300, width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.purple.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.purple.shade600, Colors.blue.shade600],
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.auto_awesome, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '🎯 AI Suggests Category',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF1A3C73)),
                    ),
                    Text(
                      '${((_categorySuggestion!.confidence) * 100).toStringAsFixed(0)}% Confidence',
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                    ),
                  ],
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 12),
          
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(
                  _getCategoryIcon(_categorySuggestion!.category),
                  color: _getCategoryColor(_categorySuggestion!.category),
                  size: 24,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _categorySuggestion!.category.name.toUpperCase(),
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                          color: _getCategoryColor(_categorySuggestion!.category),
                        ),
                      ),
                      if (_categorySuggestion!.reasoning.isNotEmpty)
                        Text(
                          _categorySuggestion!.reasoning,
                          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 12),
          
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: () {
                  setState(() => _categorySuggestion = null);
                },
                child: const Text('Dismiss'),
              ),
              const SizedBox(width: 8),
              ElevatedButton.icon(
                onPressed: _acceptCategorySuggestion,
                icon: const Icon(Icons.check, size: 18),
                label: const Text('Use This'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.purple.shade600,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQualityIndicator() {
    if (_qualityCheck == null) return const SizedBox.shrink();
    
    final quality = _qualityCheck!;
    final percentage = (quality.qualityScore * 100).toInt();
    
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.green.shade50, Colors.teal.shade50],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.green.shade300, width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.assessment, color: Colors.green.shade700, size: 24),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Concern Quality',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    Text(
                      '$percentage% Complete',
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: quality.isSubmittable ? Colors.green : Colors.orange,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  quality.isSubmittable ? '✓ Good' : '⚠ Needs Work',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 12),
          
          // Progress Bar
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: quality.qualityScore,
              minHeight: 8,
              backgroundColor: Colors.grey.shade200,
              valueColor: AlwaysStoppedAnimation(
                percentage >= 80 ? Colors.green : percentage >= 60 ? Colors.orange : Colors.red,
              ),
            ),
          ),
          
          // Strengths
          if (quality.strengths.isNotEmpty) ...[
            const SizedBox(height: 12),
            ...quality.strengths.map((strength) => Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.green.shade600, size: 16),
                  const SizedBox(width: 8),
                  Expanded(child: Text(strength, style: const TextStyle(fontSize: 13))),
                ],
              ),
            )),
          ],
          
          // Suggestions for improvement
          if (quality.suggestions.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.orange.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.lightbulb_outline, color: Colors.orange.shade700, size: 18),
                      const SizedBox(width: 6),
                      Text('Suggestions:', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.orange.shade700)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ...quality.suggestions.map((suggestion) => Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('•', style: TextStyle(color: Colors.orange.shade700, fontSize: 16)),
                        const SizedBox(width: 8),
                        Expanded(child: Text(suggestion, style: const TextStyle(fontSize: 12))),
                      ],
                    ),
                  )),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTopicsSuggestion() {
    if (_suggestedTopics.isEmpty) return const SizedBox.shrink();
    
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blue.shade50, Colors.indigo.shade50],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.blue.shade300, width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.tag, color: Colors.blue.shade700, size: 24),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Suggested Topics',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    Text(
                      'AI detected these topics from your description',
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.blue.shade600,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${_suggestedTopics.length} topics',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 12),
          
          // Topics chips
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _suggestedTopics.map((topic) => Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.blue.shade100,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.blue.shade300),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.label, color: Colors.blue.shade700, size: 14),
                  const SizedBox(width: 4),
                  Text(
                    topic,
                    style: TextStyle(
                      color: Colors.blue.shade700,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            )).toList(),
          ),
          
          const SizedBox(height: 8),
          
          Text(
            '💡 These topics will help officers categorize and prioritize your concern.',
            style: TextStyle(fontSize: 11, color: Colors.blue.shade600, fontStyle: FontStyle.italic),
          ),
        ],
      ),
    );
  }

  IconData _getCategoryIcon(ConcernCategory category) {
    switch (category) {
      case ConcernCategory.corruption:
        return Icons.gavel_rounded;
      case ConcernCategory.budget:
        return Icons.account_balance_wallet_rounded;
      case ConcernCategory.tender:
        return Icons.assignment_rounded;
      case ConcernCategory.community:
        return Icons.people_rounded;
      case ConcernCategory.system:
        return Icons.settings_rounded;
      case ConcernCategory.transparency:
        return Icons.visibility_rounded;
      case ConcernCategory.other:
        return Icons.category_rounded;
    }
  }

  Color _getCategoryColor(ConcernCategory category) {
    switch (category) {
      case ConcernCategory.corruption:
        return Colors.red.shade600;
      case ConcernCategory.budget:
        return Colors.green.shade600;
      case ConcernCategory.tender:
        return Colors.blue.shade600;
      case ConcernCategory.community:
        return Colors.purple.shade600;
      case ConcernCategory.system:
        return Colors.deepOrange.shade600;
      case ConcernCategory.transparency:
        return Colors.cyan.shade600;
      case ConcernCategory.other:
        return Colors.grey.shade600;
    }
  }

}

// AI Suggestions Model
class AISuggestions {
  final String suggestedTitle;
  final ConcernCategory suggestedCategory;
  final ConcernType suggestedType;
  final String descriptionFeedback;
  final double confidence;

  AISuggestions({
    required this.suggestedTitle,
    required this.suggestedCategory,
    required this.suggestedType,
    required this.descriptionFeedback,
    required this.confidence,
  });
}
