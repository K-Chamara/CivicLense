import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/concern_models.dart';
import '../services/officer_ai_service.dart';
import '../services/enhanced_officer_ai_service.dart';
import '../services/smart_priority_service.dart';
import 'concern_detail_screen.dart';

class EnhancedConcernManagementScreen extends StatefulWidget {
  const EnhancedConcernManagementScreen({super.key});

  @override
  State<EnhancedConcernManagementScreen> createState() => _EnhancedConcernManagementScreenState();
}

class _EnhancedConcernManagementScreenState extends State<EnhancedConcernManagementScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  String _searchQuery = '';
  ConcernPriority? _selectedPriority;
  ConcernStatus? _selectedStatus;
  bool _showAIFeatures = true;
  
  // AI Analysis State
  bool _isAnalyzing = false;
  Map<String, SmartAnalysisResult> _aiAnalysisCache = {};
  List<DuplicateConcern> _duplicates = [];
  List<CorruptionPattern> _patterns = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadAIData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadAIData() async {
    setState(() {
      _isAnalyzing = true;
    });

    try {
      // Load duplicate concerns using enhanced AI service
      _duplicates = await EnhancedOfficerAIService.advancedDuplicateDetection(
        Concern(
          id: 'current',
          title: 'Sample',
          description: 'Sample concern for analysis',
          authorId: 'sample',
          authorName: 'Sample',
          authorEmail: 'sample@example.com',
          category: ConcernCategory.corruption,
          type: ConcernType.complaint,
          status: ConcernStatus.pending,
          createdAt: DateTime.now(),
        ),
      );
      
      // Load pattern detection using enhanced AI service
      _patterns = await EnhancedOfficerAIService.detectAdvancedPatterns();
      
      setState(() {});
    } catch (e) {
      print('Error loading AI data: $e');
    } finally {
      setState(() {
        _isAnalyzing = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: CustomScrollView(
        slivers: [
          // Modern App Bar with AI Features
          SliverAppBar(
            expandedHeight: 160,
            floating: false,
            pinned: true,
            backgroundColor: Colors.transparent,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color(0xFF667EEA),
                      Color(0xFF764BA2),
                      Color(0xFF6B73FF),
                    ],
                  ),
                ),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                        Row(
                          children: [
                            const Icon(
                              Icons.psychology,
                              color: Colors.white,
                              size: 28,
                            ),
                            const SizedBox(width: 12),
                            const Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'AI-Powered Concern Management',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    'Intelligent Analysis & Insights',
                                    style: TextStyle(
                                      color: Colors.white70,
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.auto_awesome,
                                    color: Colors.white,
                                    size: 16,
                                  ),
                                  const SizedBox(width: 4),
                                  const Text(
                                    'AI ACTIVE',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                      ],
                    ),
                    ),
                  ),
                ),
              ),
            ),
            bottom: TabBar(
              controller: _tabController,
              isScrollable: true,
              indicatorColor: Colors.white,
              labelColor: Colors.white,
              unselectedLabelColor: Colors.white70,
              tabs: const [
                Tab(text: 'All Concerns'),
                Tab(text: 'High Priority'),
                Tab(text: 'Duplicates'),
                Tab(text: 'Patterns'),
              ],
            ),
          ),

          // Search and Filter Bar
          SliverToBoxAdapter(
            child: Container(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // Search Bar
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: TextField(
                      onChanged: (value) {
                        setState(() {
                          _searchQuery = value;
                        });
                      },
                      decoration: InputDecoration(
                        hintText: 'Search concerns...',
                        prefixIcon: const Icon(Icons.search),
                        suffixIcon: _searchQuery.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear),
                                onPressed: () {
                                  setState(() {
                                    _searchQuery = '';
                                  });
                                },
                              )
                            : null,
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.all(16),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Filter Chips
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _buildFilterChip(
                          'All Priorities',
                          _selectedPriority == null,
                          () => setState(() => _selectedPriority = null),
                        ),
                        ...ConcernPriority.values.map((priority) => 
                          _buildFilterChip(
                            priority.name.toUpperCase(),
                            _selectedPriority == priority,
                            () => setState(() => _selectedPriority = priority),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Content based on selected tab
          SliverFillRemaining(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildConcernsList(),
                _buildHighPriorityConcerns(),
                _buildDuplicatesView(),
                _buildPatternsView(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAIInsightChip(String text, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 12),
          const SizedBox(width: 3),
          Text(
            text,
            style: TextStyle(
              color: color,
              fontSize: 10,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, bool isSelected, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (_) => onTap(),
        selectedColor: Colors.purple.withOpacity(0.2),
        checkmarkColor: Colors.purple,
        labelStyle: TextStyle(
          color: isSelected ? Colors.purple : Colors.grey[600],
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
        ),
      ),
    );
  }

  Widget _buildConcernsList() {
    return StreamBuilder<QuerySnapshot>(
      stream: _getConcernsStream(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        final concerns = snapshot.data?.docs ?? [];
        if (concerns.isEmpty) {
          return _buildEmptyState();
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: concerns.length,
          itemBuilder: (context, index) {
            final concern = Concern.fromFirestore(concerns[index]);
            return _buildConcernCard(concern);
          },
        );
      },
    );
  }

  Widget _buildHighPriorityConcerns() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('concerns')
          .where('priority', whereIn: ['high', 'critical'])
          .orderBy('priority')
          .orderBy('createdAt', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final concerns = snapshot.data?.docs ?? [];
        if (concerns.isEmpty) {
          return _buildEmptyState(message: 'No high priority concerns found');
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: concerns.length,
          itemBuilder: (context, index) {
            final concern = Concern.fromFirestore(concerns[index]);
            return _buildConcernCard(concern, showAIAnalysis: true);
          },
        );
      },
    );
  }

  Widget _buildDuplicatesView() {
    if (_isAnalyzing) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_duplicates.isEmpty) {
      return _buildEmptyState(message: 'No duplicate concerns detected');
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _duplicates.length,
      itemBuilder: (context, index) {
        final duplicate = _duplicates[index];
        return _buildDuplicateCard(duplicate);
      },
    );
  }

  Widget _buildPatternsView() {
    if (_isAnalyzing) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_patterns.isEmpty) {
      return _buildEmptyState(message: 'No patterns detected');
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _patterns.length,
      itemBuilder: (context, index) {
        final pattern = _patterns[index];
        return _buildPatternCard(pattern);
      },
    );
  }

  Widget _buildConcernCard(Concern concern, {bool showAIAnalysis = false}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => _navigateToConcernDetail(concern),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        concern.title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    _buildStatusChip(concern.status),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  concern.description,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    _buildPriorityChip(concern.priority),
                    const SizedBox(width: 8),
                    if (concern.sentimentScore != null)
                      _buildSentimentChip(concern.sentimentScore!),
                    const Spacer(),
                    if (showAIAnalysis)
                      _buildAIAnalysisIndicator(concern),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.person, size: 16, color: Colors.grey[600]),
                    const SizedBox(width: 4),
                    Text(
                      concern.authorName,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                    const Spacer(),
                    Text(
                      _formatDate(concern.createdAt),
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDuplicateCard(DuplicateConcern duplicate) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.orange.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.orange.withOpacity(0.3)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.content_copy, color: Colors.orange, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Duplicate Concern',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.orange[800],
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.orange,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${(duplicate.similarity * 100).round()}%',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              duplicate.reason,
              style: TextStyle(
                fontSize: 14,
                color: Colors.orange[700],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Recommendation: ${duplicate.recommendation}',
              style: TextStyle(
                fontSize: 12,
                color: Colors.orange[600],
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPatternCard(CorruptionPattern pattern) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.green.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.green.withOpacity(0.3)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.trending_up, color: Colors.green, size: 20),
                const SizedBox(width: 8),
                Text(
                  pattern.type.toUpperCase(),
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.green[800],
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.green,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${pattern.concernIds.length} concerns',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              pattern.description,
              style: TextStyle(
                fontSize: 14,
                color: Colors.green[700],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Confidence: ${(pattern.confidence * 100).round()}%',
              style: TextStyle(
                fontSize: 12,
                color: Colors.green[600],
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusChip(ConcernStatus status) {
    Color color;
    String text;
    
    switch (status) {
      case ConcernStatus.pending:
        color = Colors.orange;
        text = 'Pending';
        break;
      case ConcernStatus.underReview:
        color = Colors.blue;
        text = 'Under Review';
        break;
      case ConcernStatus.inProgress:
        color = Colors.purple;
        text = 'In Progress';
        break;
      case ConcernStatus.resolved:
        color = Colors.green;
        text = 'Resolved';
        break;
      case ConcernStatus.dismissed:
        color = Colors.red;
        text = 'Dismissed';
        break;
      case ConcernStatus.escalated:
        color = Colors.deepOrange;
        text = 'Escalated';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildPriorityChip(ConcernPriority priority) {
    Color color;
    String text;
    
    switch (priority) {
      case ConcernPriority.low:
        color = Colors.green;
        text = 'Low';
        break;
      case ConcernPriority.medium:
        color = Colors.orange;
        text = 'Medium';
        break;
      case ConcernPriority.high:
        color = Colors.red;
        text = 'High';
        break;
      case ConcernPriority.critical:
        color = Colors.purple;
        text = 'Critical';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildSentimentChip(SentimentScore sentiment) {
    Color color;
    String text;
    
    switch (sentiment) {
      case SentimentScore.veryNegative:
        color = Colors.red;
        text = 'Very Negative';
        break;
      case SentimentScore.negative:
        color = Colors.orange;
        text = 'Negative';
        break;
      case SentimentScore.neutral:
        color = Colors.grey;
        text = 'Neutral';
        break;
      case SentimentScore.positive:
        color = Colors.lightGreen;
        text = 'Positive';
        break;
      case SentimentScore.veryPositive:
        color = Colors.green;
        text = 'Very Positive';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildAIAnalysisIndicator(Concern concern) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.blue.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.auto_awesome, color: Colors.blue, size: 12),
          const SizedBox(width: 2),
          Text(
            'AI',
            style: TextStyle(
              color: Colors.blue,
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState({String message = 'No concerns found'}) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.inbox,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            message,
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Stream<QuerySnapshot> _getConcernsStream() {
    Query query = FirebaseFirestore.instance
        .collection('concerns')
        .orderBy('createdAt', descending: true);

    if (_searchQuery.isNotEmpty) {
      // Note: Firestore doesn't support full-text search natively
      // This is a simplified implementation
      query = query.where('title', isGreaterThanOrEqualTo: _searchQuery)
          .where('title', isLessThan: _searchQuery + 'z');
    }

    if (_selectedPriority != null) {
      query = query.where('priority', isEqualTo: _selectedPriority!.name);
    }

    if (_selectedStatus != null) {
      query = query.where('status', isEqualTo: _selectedStatus!.name);
    }

    return query.snapshots();
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }

  void _navigateToConcernDetail(Concern concern) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ConcernDetailScreen(
          concern: concern,
          officerId: 'current_officer_id', // Replace with actual officer ID
          officerName: 'Current Officer', // Replace with actual officer name
        ),
      ),
    );
  }
}
