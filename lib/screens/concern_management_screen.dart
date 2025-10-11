import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/concern_models.dart';
import '../services/concern_management_service.dart';
import '../services/notification_service.dart';
import 'concern_detail_screen.dart';
import 'public_tender_viewer_screen.dart';
import '../l10n/app_localizations.dart';
import '../utils/add_ai_to_concerns.dart';

class ConcernManagementScreen extends StatefulWidget {
  const ConcernManagementScreen({super.key});

  @override
  State<ConcernManagementScreen> createState() => _ConcernManagementScreenState();
}

class _ConcernManagementScreenState extends State<ConcernManagementScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  String? _currentUserId;
  String? _currentUserName;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _getCurrentUser();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _getCurrentUser() async {
    final user = _auth.currentUser;
    if (user != null) {
      setState(() {
        _currentUserId = user.uid;
        _currentUserName = user.displayName ?? 'Officer';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: CustomScrollView(
        slivers: [
          // Modern App Bar with Gradient
          SliverAppBar(
            expandedHeight: 140,
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
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: Colors.white.withOpacity(0.3),
                                  width: 1,
                                ),
                              ),
                              child: const Icon(
                                Icons.analytics_outlined,
                                color: Colors.white,
                                size: 24,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'AI-Powered Concern Management',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      shadows: [
                                        Shadow(
                                          color: Colors.black.withOpacity(0.1),
                                          offset: const Offset(0, 1),
                                          blurRadius: 2,
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Smart analysis & investigation tools',
                                    style: TextStyle(
                                      color: Colors.white.withOpacity(0.9),
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            // AI Assistant Button
                            Container(
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: Colors.white.withOpacity(0.3),
                                  width: 1,
                                ),
                              ),
                              child: IconButton(
                                icon: const Icon(Icons.psychology, color: Colors.white),
                                tooltip: 'AI Assistant',
                                onPressed: _addAIToAllConcerns,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          // Modern Tab Bar
          SliverToBoxAdapter(
            child: Container(
              margin: const EdgeInsets.all(16),
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
              child: TabBar(
                controller: _tabController,
                indicator: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                indicatorSize: TabBarIndicatorSize.tab,
                indicatorPadding: const EdgeInsets.all(6),
                labelColor: Colors.white,
                unselectedLabelColor: Colors.grey.shade600,
                labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500, fontSize: 12),
                tabs: [
                  Tab(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.list_alt, size: 16),
                        const SizedBox(width: 6),
                        Text(AppLocalizations.of(context)!.all),
                      ],
                    ),
                  ),
                  Tab(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.pending_actions, size: 16),
                        const SizedBox(width: 6),
                        Text(AppLocalizations.of(context)!.pending),
                      ],
                    ),
                  ),
                  Tab(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.search, size: 16),
                        const SizedBox(width: 4),
                        Text(
                          AppLocalizations.of(context)!.underReview,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  Tab(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.priority_high, size: 16),
                        const SizedBox(width: 6),
                        Text(AppLocalizations.of(context)!.priority),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Tab Content
          SliverFillRemaining(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildConcernsList(ConcernManagementService.getConcernsForOfficer()),
                _buildConcernsList(ConcernManagementService.getConcernsByStatus(ConcernStatus.pending)),
                _buildConcernsList(ConcernManagementService.getConcernsByStatus(ConcernStatus.underReview)),
                _buildConcernsList(ConcernManagementService.getPriorityConcerns()),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConcernsList(Stream<List<Concern>> concernsStream) {
    return StreamBuilder<List<Concern>>(
      stream: concernsStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error, size: 64, color: Colors.red),
                const SizedBox(height: 16),
                Text('Error: ${snapshot.error}'),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => setState(() {}),
                  child: const Text('Retry'),
                ),
              ],
            ),
          );
        }

        final concerns = snapshot.data ?? [];

        if (concerns.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.inbox, size: 64, color: Colors.grey),
                SizedBox(height: 16),
                Text(
                  'No concerns found',
                  style: TextStyle(fontSize: 18, color: Colors.grey),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          itemCount: concerns.length,
          itemBuilder: (context, index) {
            final concern = concerns[index];
            return Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: _buildModernConcernCard(concern),
            );
          },
        );
      },
    );
  }

  Widget _buildModernConcernCard(Concern concern) {
    final aiAnalysis = concern.metadata['aiAnalysis'] as Map<String, dynamic>?;
    final hasAI = aiAnalysis != null;
    final priority = hasAI ? aiAnalysis['priority'] as String? : null;
    final sentiment = hasAI ? aiAnalysis['sentiment'] as String? : null;
    final confidence = hasAI ? (aiAnalysis['confidence'] as num?)?.toDouble() ?? 0.0 : 0.0;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: hasAI 
            ? [_getPriorityGradientColor(priority).withOpacity(0.1), Colors.white]
            : [Colors.grey.shade50, Colors.white],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: hasAI 
              ? _getPriorityGradientColor(priority).withOpacity(0.2)
              : Colors.grey.withOpacity(0.1),
            blurRadius: hasAI ? 12 : 8,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(
          color: hasAI 
            ? _getPriorityGradientColor(priority).withOpacity(0.3)
            : Colors.grey.withOpacity(0.2),
          width: hasAI ? 2 : 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _navigateToConcernDetail(concern),
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header with AI indicator
                Row(
                  children: [
                    // AI Status Indicator
                    if (hasAI) ...[
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              _getPriorityGradientColor(priority),
                              _getPriorityGradientColor(priority).withOpacity(0.7),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: _getPriorityGradientColor(priority).withOpacity(0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.psychology,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                    ],
                    
                    // Title
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            concern.title,
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: hasAI ? Colors.grey.shade800 : Colors.grey.shade700,
                            ),
                          ),
                          if (hasAI) ...[
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Icon(
                                  Icons.auto_awesome,
                                  size: 14,
                                  color: _getPriorityGradientColor(priority),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  'AI Analyzed • ${(confidence * 100).toStringAsFixed(0)}% Confidence',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: _getPriorityGradientColor(priority),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                    
                    // Status Chip
                    _buildModernStatusChip(concern.status),
                  ],
                ),
                
                const SizedBox(height: 16),
                
                // Description
                Text(
                  concern.description,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 14,
                    height: 1.4,
                  ),
                ),
                
                const SizedBox(height: 16),
                
                // AI Analysis Section
                if (hasAI) ...[
                  _buildEnhancedAIAnalysisCard(concern),
                  const SizedBox(height: 16),
                ],
                
                // Metadata Row
                Row(
                  children: [
                    // Author
                    _buildModernInfoChip(
                      Icons.person_outline,
                      concern.authorName,
                      Colors.blue.shade600,
                    ),
                    const SizedBox(width: 8),
                    
                    // Category
                    _buildModernInfoChip(
                      _getCategoryIcon(concern.category),
                      concern.category.name.toUpperCase(),
                      _getCategoryColor(concern.category),
                    ),
                    
                    const Spacer(),
                    
                    // Support Count
                    if (concern.supportCount > 0)
                      _buildModernInfoChip(
                        Icons.thumb_up_outlined,
                        '${concern.supportCount}',
                        Colors.orange.shade600,
                      ),
                  ],
                ),
                
                const SizedBox(height: 12),
                
                // Footer
                Row(
                  children: [
                    Icon(
                      Icons.access_time_rounded,
                      size: 16,
                      color: Colors.grey.shade500,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      _formatDate(concern.createdAt),
                      style: TextStyle(
                        color: Colors.grey.shade500,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    
                    const Spacer(),
                    
                    // Priority Badge
                    if (hasAI && priority != null) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              _getPriorityGradientColor(priority),
                              _getPriorityGradientColor(priority).withOpacity(0.8),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: _getPriorityGradientColor(priority).withOpacity(0.3),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              _getPriorityIcon(priority),
                              color: Colors.white,
                              size: 14,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              priority.toUpperCase(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    
                    // View Button
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.purple.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.arrow_forward_ios_rounded,
                        color: Colors.purple.shade600,
                        size: 16,
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

  Widget _buildStatusChip(ConcernStatus status) {
    Color color;
    String text;
    IconData icon;

    switch (status) {
      case ConcernStatus.pending:
        color = Colors.orange;
        text = AppLocalizations.of(context)!.pending;
        icon = Icons.pending;
        break;
      case ConcernStatus.underReview:
        color = Colors.blue;
        text = AppLocalizations.of(context)!.underReview;
        icon = Icons.search;
        break;
      case ConcernStatus.inProgress:
        color = Colors.purple;
        text = AppLocalizations.of(context)!.inProgress;
        icon = Icons.work;
        break;
      case ConcernStatus.resolved:
        color = Colors.green;
        text = AppLocalizations.of(context)!.resolved;
        icon = Icons.check_circle;
        break;
      case ConcernStatus.dismissed:
        color = Colors.grey;
        text = AppLocalizations.of(context)!.dismissed;
        icon = Icons.cancel;
        break;
      case ConcernStatus.escalated:
        color = Colors.red;
        text = AppLocalizations.of(context)!.escalated;
        icon = Icons.priority_high;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAIAnalysisCard(Concern concern) {
    final aiAnalysis = concern.metadata['aiAnalysis'] as Map<String, dynamic>?;
    if (aiAnalysis == null) return const SizedBox.shrink();
    
    final confidence = (aiAnalysis['confidence'] as num?)?.toDouble() ?? 0.0;
    final topics = List<String>.from(aiAnalysis['topics'] ?? []);
    final priorityScore = (aiAnalysis['priorityScore'] as num?)?.toDouble() ?? 0.0;
    
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.purple.shade50, Colors.blue.shade50],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.purple.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.psychology, color: Colors.purple.shade600, size: 16),
              const SizedBox(width: 6),
              Text(
                '🤖 AI Analysis',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.purple.shade700,
                  fontSize: 12,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.green.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${(confidence * 100).round()}% confidence',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: Colors.green.shade700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _buildAIMetric(
                'Priority',
                concern.priority.name.toUpperCase(),
                _getPriorityColor(concern.priority),
                Icons.priority_high,
              ),
              const SizedBox(width: 12),
              if (concern.sentimentScore != null)
                _buildAIMetric(
                  'Sentiment',
                  concern.sentimentScore!.name.replaceAll(RegExp(r'([A-Z])'), ' \$1').trim(),
                  _getSentimentColor(concern.sentimentScore!),
                  _getSentimentIcon(concern.sentimentScore!),
                ),
            ],
          ),
          if (topics.isNotEmpty) ...[
            const SizedBox(height: 8),
            Wrap(
              spacing: 4,
              runSpacing: 4,
              children: topics.map((topic) => Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.blue.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  topic,
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.blue.shade700,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              )).toList(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildAIMetric(String label, String value, Color color, IconData icon) {
    return Expanded(
      child: Row(
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                value,
                style: TextStyle(
                  fontSize: 11,
                  color: color,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Color _getPriorityColor(ConcernPriority priority) {
    switch (priority) {
      case ConcernPriority.critical:
        return Colors.red;
      case ConcernPriority.high:
        return Colors.orange;
      case ConcernPriority.medium:
        return Colors.blue;
      case ConcernPriority.low:
        return Colors.green;
    }
  }

  Color _getSentimentColor(SentimentScore sentiment) {
    switch (sentiment) {
      case SentimentScore.veryNegative:
        return Colors.red.shade700;
      case SentimentScore.negative:
        return Colors.red.shade400;
      case SentimentScore.neutral:
        return Colors.grey;
      case SentimentScore.positive:
        return Colors.green.shade400;
      case SentimentScore.veryPositive:
        return Colors.green.shade700;
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

  Widget _buildInfoChip(IconData icon, String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              color: color,
              fontSize: 10,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
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
          officerId: _currentUserId!,
          officerName: _currentUserName!,
        ),
      ),
    );
  }

  Future<void> _addAIToAllConcerns() async {
    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.psychology, color: Colors.purple),
            SizedBox(width: 8),
            Text('Add AI Analysis'),
          ],
        ),
        content: const Text(
          'This will analyze all existing concerns with AI and add:\n\n'
          '• Sentiment analysis\n'
          '• Priority detection\n'
          '• Topic extraction\n'
          '• Confidence scores\n\n'
          'This may take a few moments. Continue?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.purple,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Analyze All'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Analyzing concerns with AI...'),
          ],
        ),
      ),
    );

    try {
      await AddAIToConcernsUtility.addAIAnalysisToExistingConcerns();
      
      // Close loading dialog
      if (mounted) Navigator.pop(context);
      
      // Show success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 8),
                Text('AI analysis added to all concerns!'),
              ],
            ),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 3),
          ),
        );
      }
      
      // Refresh the list
      setState(() {});
      
    } catch (e) {
      // Close loading dialog
      if (mounted) Navigator.pop(context);
      
      // Show error message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error, color: Colors.white),
                const SizedBox(width: 8),
                Expanded(child: Text('Error: $e')),
              ],
            ),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }

  Widget _buildBottomNavigationBar() {
    return BottomNavigationBar(
      type: BottomNavigationBarType.fixed,
      backgroundColor: Colors.white,
      selectedItemColor: Colors.purple,
      unselectedItemColor: Colors.grey,
      currentIndex: 3, // Dashboard is selected (index 3)
      onTap: (index) {
        switch (index) {
          case 0:
            Navigator.pushNamed(context, '/common-home');
            break;
          case 1:
            Navigator.pushNamed(context, '/budget-viewer');
            break;
          case 2:
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const PublicTenderViewerScreen()),
            );
            break;
          case 3:
            Navigator.pushNamed(context, '/dashboard');
            break;
        }
      },
      items: [
        BottomNavigationBarItem(
          icon: const Icon(Icons.home),
          label: AppLocalizations.of(context)!.home,
        ),
        BottomNavigationBarItem(
          icon: const Icon(Icons.account_balance),
          label: AppLocalizations.of(context)!.budget,
        ),
        BottomNavigationBarItem(
          icon: const Icon(Icons.shopping_cart),
          label: AppLocalizations.of(context)!.tenders,
        ),
        BottomNavigationBarItem(
          icon: const Icon(Icons.dashboard),
          label: AppLocalizations.of(context)!.dashboard,
        ),
      ],
    );
  }

  // Modern UI Helper Methods
  Widget _buildModernStatusChip(ConcernStatus status) {
    Color color;
    String text;
    IconData icon;

    switch (status) {
      case ConcernStatus.pending:
        color = Colors.orange.shade600;
        text = AppLocalizations.of(context)!.pending;
        icon = Icons.schedule_rounded;
        break;
      case ConcernStatus.underReview:
        color = Colors.blue.shade600;
        text = AppLocalizations.of(context)!.underReview;
        icon = Icons.visibility_rounded;
        break;
      case ConcernStatus.inProgress:
        color = Colors.purple.shade600;
        text = AppLocalizations.of(context)!.inProgress;
        icon = Icons.build_rounded;
        break;
      case ConcernStatus.resolved:
        color = Colors.green.shade600;
        text = AppLocalizations.of(context)!.resolved;
        icon = Icons.check_circle_rounded;
        break;
      case ConcernStatus.dismissed:
        color = Colors.grey.shade600;
        text = AppLocalizations.of(context)!.dismissed;
        icon = Icons.cancel_rounded;
        break;
      case ConcernStatus.escalated:
        color = Colors.red.shade600;
        text = AppLocalizations.of(context)!.escalated;
        icon = Icons.priority_high_rounded;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color, color.withOpacity(0.8)],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: Colors.white),
          const SizedBox(width: 6),
          Text(
            text,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModernInfoChip(IconData icon, String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEnhancedAIAnalysisCard(Concern concern) {
    final aiAnalysis = concern.metadata['aiAnalysis'] as Map<String, dynamic>?;
    if (aiAnalysis == null) return const SizedBox.shrink();
    
    final confidence = (aiAnalysis['confidence'] as num?)?.toDouble() ?? 0.0;
    final topics = List<String>.from(aiAnalysis['topics'] ?? []);
    final priorityScore = (aiAnalysis['priorityScore'] as num?)?.toDouble() ?? 0.0;
    final priorityStr = aiAnalysis['priority'] as String? ?? 'medium';
    final sentiment = aiAnalysis['sentiment'] as String? ?? 'neutral';
    final urgencyLevel = aiAnalysis['urgencyLevel'] as int? ?? 5;
    final estimatedDays = aiAnalysis['estimatedResolutionDays'] as int? ?? 30;
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            _getPriorityGradientColor(priorityStr).withOpacity(0.1),
            Colors.white,
            _getPriorityGradientColor(priorityStr).withOpacity(0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _getPriorityGradientColor(priorityStr).withOpacity(0.2),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: _getPriorityGradientColor(priorityStr).withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      _getPriorityGradientColor(priorityStr),
                      _getPriorityGradientColor(priorityStr).withOpacity(0.8),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.auto_awesome,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '🤖 AI Analysis Results',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: _getPriorityGradientColor(priorityStr),
                      ),
                    ),
                    Text(
                      'Powered by Google Gemini • ${(confidence * 100).toStringAsFixed(0)}% Confidence',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // AI Metrics Grid
          Row(
            children: [
              // Priority Score
              Expanded(
                child: _buildAIMetricCard(
                  'Priority',
                  priorityStr.toUpperCase(),
                  _getPriorityIcon(priorityStr),
                  _getPriorityGradientColor(priorityStr),
                  '${(priorityScore * 100).toStringAsFixed(0)}%',
                ),
              ),
              const SizedBox(width: 12),
              
              // Sentiment
              Expanded(
                child: _buildAIMetricCard(
                  'Sentiment',
                  _getSentimentDisplay(sentiment),
                  _getSentimentIconString(sentiment),
                  _getSentimentColorString(sentiment),
                  _getSentimentScoreString(sentiment),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 12),
          
          Row(
            children: [
              // Urgency
              Expanded(
                child: _buildAIMetricCard(
                  'Urgency',
                  'Level $urgencyLevel',
                  Icons.timeline,
                  Colors.red.shade600,
                  '${estimatedDays}d est.',
                ),
              ),
              const SizedBox(width: 12),
              
              // Topics
              Expanded(
                child: _buildAIMetricCard(
                  'Topics',
                  topics.isNotEmpty ? topics.first : 'General',
                  Icons.label,
                  Colors.purple.shade600,
                  '${topics.length} topics',
                ),
              ),
            ],
          ),
          
          if (topics.isNotEmpty) ...[
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: topics.take(4).map((topic) => Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: _getPriorityGradientColor(priorityStr).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: _getPriorityGradientColor(priorityStr).withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: Text(
                  topic,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: _getPriorityGradientColor(priorityStr),
                  ),
                ),
              )).toList(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildAIMetricCard(String label, String value, IconData icon, Color color, String subtitle) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 16),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 10,
              color: Colors.grey.shade500,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModernAIAnalysisCard(Concern concern) {
    final aiAnalysis = concern.metadata['aiAnalysis'] as Map<String, dynamic>?;
    if (aiAnalysis == null) return const SizedBox.shrink();
    
    final confidence = (aiAnalysis['confidence'] as num?)?.toDouble() ?? 0.0;
    final topics = List<String>.from(aiAnalysis['topics'] ?? []);
    final priorityScore = (aiAnalysis['priorityScore'] as num?)?.toDouble() ?? 0.0;
    final priorityStr = aiAnalysis['priority'] as String? ?? 'medium';
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.purple.shade50,
            Colors.blue.shade50,
            Colors.indigo.shade50,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.purple.shade200, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.purple.withOpacity(0.1),
            blurRadius: 12,
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
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.purple.shade600, Colors.blue.shade600],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.psychology,
                  color: Colors.white,
                  size: 18,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '🤖 AI Analysis',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.purple.shade700,
                        fontSize: 14,
                      ),
                    ),
                    Text(
                      '${(confidence * 100).toStringAsFixed(0)}% Confidence',
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 12),
          
          // Topics
          if (topics.isNotEmpty)
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: topics.take(3).map((topic) => Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.blue.shade100,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.blue.shade300),
                ),
                child: Text(
                  topic.toUpperCase(),
                  style: TextStyle(
                    color: Colors.blue.shade700,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              )).toList(),
            ),
        ],
      ),
    );
  }

  Color _getPriorityGradientColor(String? priority) {
    switch (priority?.toLowerCase()) {
      case 'critical':
        return Colors.red.shade600;
      case 'high':
        return Colors.orange.shade600;
      case 'medium':
        return Colors.blue.shade600;
      case 'low':
        return Colors.green.shade600;
      default:
        return Colors.grey.shade600;
    }
  }

  IconData _getPriorityIcon(String? priority) {
    switch (priority?.toLowerCase()) {
      case 'critical':
        return Icons.priority_high_rounded;
      case 'high':
        return Icons.keyboard_arrow_up_rounded;
      case 'medium':
        return Icons.remove_rounded;
      case 'low':
        return Icons.keyboard_arrow_down_rounded;
      default:
        return Icons.help_outline_rounded;
    }
  }

  String _getSentimentDisplay(String sentiment) {
    switch (sentiment.toLowerCase()) {
      case 'verynegative':
        return 'Very Negative';
      case 'negative':
        return 'Negative';
      case 'neutral':
        return 'Neutral';
      case 'positive':
        return 'Positive';
      case 'verypositive':
        return 'Very Positive';
      default:
        return 'Unknown';
    }
  }

  String _getSentimentScoreString(String sentiment) {
    switch (sentiment.toLowerCase()) {
      case 'verynegative':
        return '-90%';
      case 'negative':
        return '-60%';
      case 'neutral':
        return '0%';
      case 'positive':
        return '+60%';
      case 'verypositive':
        return '+90%';
      default:
        return '0%';
    }
  }

  IconData _getSentimentIconString(String sentiment) {
    switch (sentiment.toLowerCase()) {
      case 'verynegative':
        return Icons.sentiment_very_dissatisfied;
      case 'negative':
        return Icons.sentiment_dissatisfied;
      case 'neutral':
        return Icons.sentiment_neutral;
      case 'positive':
        return Icons.sentiment_satisfied;
      case 'verypositive':
        return Icons.sentiment_very_satisfied;
      default:
        return Icons.help_outline;
    }
  }

  Color _getSentimentColorString(String sentiment) {
    switch (sentiment.toLowerCase()) {
      case 'verynegative':
        return Colors.red.shade700;
      case 'negative':
        return Colors.red.shade500;
      case 'neutral':
        return Colors.grey.shade500;
      case 'positive':
        return Colors.green.shade500;
      case 'verypositive':
        return Colors.green.shade700;
      default:
        return Colors.grey.shade400;
    }
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