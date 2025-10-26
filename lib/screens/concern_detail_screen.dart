import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/concern_models.dart';
import '../services/concern_management_service.dart';
import '../services/concern_service.dart';
import '../services/notification_service.dart';
import '../services/officer_ai_service.dart';
import '../services/smart_priority_service.dart';
import '../widgets/concern_evidence_validation_widget.dart';
import '../widgets/evidence_viewer_screen.dart';
import '../l10n/app_localizations.dart';
import 'user_concern_tracking_screen.dart';
import 'public_tender_viewer_screen.dart';
import 'package:flutter/services.dart';

class ConcernDetailScreen extends StatefulWidget {
  final Concern concern;
  final String officerId;
  final String officerName;

  const ConcernDetailScreen({
    super.key,
    required this.concern,
    required this.officerId,
    required this.officerName,
  });

  @override
  State<ConcernDetailScreen> createState() => _ConcernDetailScreenState();
}

class _ConcernDetailScreenState extends State<ConcernDetailScreen> {
  final TextEditingController _commentController = TextEditingController();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final ConcernService _concernService = ConcernService();
  bool _isUpdating = false;
  
  // AI Assistant State
  bool _isLoadingAI = false;
  RiskAssessment? _riskAssessment;
  EvidenceAnalysis? _evidenceAnalysis;
  InvestigationStrategy? _investigationStrategy;
  ResponseSuggestion? _responseSuggestion;
  List<DuplicateConcern>? _duplicates;

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: CustomScrollView(
        slivers: [
          // Modern App Bar with Gradient
          SliverAppBar(
            expandedHeight: 120,
            floating: false,
            pinned: true,
            backgroundColor: Colors.transparent,
            automaticallyImplyLeading: true,
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
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Text(
                                'Concern Investigation',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                widget.concern.title,
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.9),
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        // Enhanced AI Assistant Button
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
                            tooltip: 'AI Investigation Assistant',
                            onPressed: () {
                              print('🧠 AI Assistant button tapped!');
                              _showAIAssistant();
                            },
                          ),
                        ),
                        // Status Menu
                        Container(
                          margin: const EdgeInsets.only(left: 8),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.3),
                              width: 1,
                            ),
                          ),
                          child: PopupMenuButton<String>(
                            icon: const Icon(Icons.more_vert, color: Colors.white),
                            onSelected: (value) => _showStatusUpdateDialog(value),
                            itemBuilder: (context) {
                              final validTransitions = _getValidStatusTransitions(widget.concern.status);
                              final items = <PopupMenuEntry<String>>[];
                              
                              // Add valid status transitions
                              for (final status in validTransitions) {
                                switch (status) {
                                  case 'underReview':
                                    items.add(
                                      const PopupMenuItem(
                                        value: 'underReview',
                                        child: Row(
                                          children: [
                                            Icon(Icons.search, color: Colors.blue),
                                            SizedBox(width: 8),
                                            Text('Mark as Under Review'),
                                          ],
                                        ),
                                      ),
                                    );
                                    break;
                                  case 'inProgress':
                                    items.add(
                                      const PopupMenuItem(
                                        value: 'inProgress',
                                        child: Row(
                                          children: [
                                            Icon(Icons.work, color: Colors.purple),
                                            SizedBox(width: 8),
                                            Text('Mark as In Progress'),
                                          ],
                                        ),
                                      ),
                                    );
                                    break;
                                  case 'resolved':
                                    items.add(
                                      const PopupMenuItem(
                                        value: 'resolved',
                                        child: Row(
                                          children: [
                                            Icon(Icons.check_circle, color: Colors.green),
                                            SizedBox(width: 8),
                                            Text('Mark as Resolved'),
                                          ],
                                        ),
                                      ),
                                    );
                                    break;
                                  case 'dismissed':
                                    items.add(
                                      const PopupMenuItem(
                                        value: 'dismissed',
                                        child: Row(
                                          children: [
                                            Icon(Icons.cancel, color: Colors.grey),
                                            SizedBox(width: 8),
                                            Text('Dismiss'),
                                          ],
                                        ),
                                      ),
                                    );
                                    break;
                                }
                              }
                              
                              // Add divider if there are status options
                              if (items.isNotEmpty) {
                                items.add(const PopupMenuDivider());
                              }
                              
                              // Add delete option for users (only if they can delete)
                              if (_canDeleteConcern()) {
                                items.add(
                                  PopupMenuItem(
                                    value: 'delete',
                                    child: Row(
                                      children: [
                                        const Icon(Icons.delete, color: Colors.red),
                                        const SizedBox(width: 8),
                                        Text(AppLocalizations.of(context)!.deleteConcern),
                                      ],
                                    ),
                                  ),
                                );
                              }
                              
                              return items;
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          // Content
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // Concern Details Card
                  _buildConcernDetailsCard(),
                  const SizedBox(height: 16),
                  
                  // AI Analysis Card (always show with SmartPriorityService)
                  _buildAIAnalysisCard(),
                  const SizedBox(height: 16),
                  
                  // Timeline Section
                  _buildTimelineSection(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConcernDetailsCard() {
    return Container(
      padding: const EdgeInsets.all(20),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.concern.title,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            widget.concern.description,
            style: TextStyle(
              fontSize: 15,
              color: Colors.grey.shade700,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 16),
          // Metadata
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildInfoChip(Icons.person, widget.concern.authorName, Colors.blue),
                const SizedBox(width: 8),
                _buildInfoChip(Icons.category, widget.concern.category.name.toUpperCase(), Colors.green),
                const SizedBox(width: 8),
                _buildInfoChip(Icons.access_time, _formatDate(widget.concern.createdAt), Colors.grey),
              ],
            ),
          ),
          const SizedBox(height: 16),
          
          // Evidence Buttons (if evidence exists)
          if (widget.concern.attachments != null && widget.concern.attachments!.isNotEmpty) ...[
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _viewEvidence(),
                    icon: const Icon(Icons.visibility),
                    label: const Text('View Evidence'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
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
                  child: ElevatedButton.icon(
                    onPressed: () => _validateEvidence(),
                    icon: const Icon(Icons.psychology),
                    label: const Text('AI Validate'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.purple,
                      foregroundColor: Colors.white,
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
        ],
      ),
    );
  }

  Widget _buildAIAnalysisCard() {
    // Use SmartPriorityService for real-time analysis
    final analysis = SmartPriorityService.analyzeConcern(
      widget.concern.title,
      widget.concern.description,
      widget.concern.category,
    );
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.blue.shade50,
            Colors.white,
            Colors.purple.shade50,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.blue.shade200,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withOpacity(0.1),
            blurRadius: 10,
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
                  gradient: const LinearGradient(
                    colors: [Colors.blue, Colors.purple],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.psychology,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '🤖 AI Analysis Results',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    Text(
                      'Powered by ${analysis.aiModel} • ${(analysis.confidence * 100).toStringAsFixed(0)}% Confidence',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              // See Full Detail Button
              ElevatedButton.icon(
                onPressed: () => _showFullAIDetail(),
                icon: const Icon(Icons.visibility, size: 16),
                label: const Text('See Full Detail'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // AI Metrics
          Row(
            children: [
              Expanded(
                child: _buildAIMetric(
                  'Priority', 
                  analysis.priority.priority.name.toUpperCase(), 
                  Icons.priority_high, 
                  Colors.red
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildAIMetric(
                  'Sentiment', 
                  analysis.sentiment.sentimentScore.name.replaceAll(RegExp(r'([A-Z])'), r' $1').trim(), 
                  Icons.sentiment_satisfied, 
                  Colors.green
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAIMetric(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimelineSection() {
    return Container(
      padding: const EdgeInsets.all(20),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.timeline, color: Colors.orange),
              const SizedBox(width: 8),
              const Text(
                'Timeline',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('concern_updates')
                .where('concernId', isEqualTo: widget.concern.id)
                .orderBy('createdAt', descending: true)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              
              if (snapshot.hasError) {
                return Text('Error: ${snapshot.error}');
              }
              
              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey[200]!),
                  ),
                  child: const Center(
                    child: Text(
                      'No timeline updates yet',
                      style: TextStyle(
                        color: Colors.grey,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                );
              }
              
              return ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: snapshot.data!.docs.length,
                itemBuilder: (context, index) {
                  final update = snapshot.data!.docs[index];
                  final data = update.data() as Map<String, dynamic>;
                  
                  return _buildTimelineItem(data, index == snapshot.data!.docs.length - 1);
                },
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildTimelineItem(Map<String, dynamic> data, bool isLast) {
    final action = data['action'] ?? '';
    final description = data['description'] ?? '';
    final createdAt = data['createdAt'] != null 
        ? (data['createdAt'] as Timestamp).toDate()
        : DateTime.now();
    final officerName = data['officerName'] ?? 'Unknown Officer';
    final userRole = data['userRole'] ?? 'Officer';
    
    // Determine icon and color based on action
    IconData icon;
    Color color;
    
    switch (action.toLowerCase()) {
      case 'underreview':
        icon = Icons.search;
        color = Colors.blue;
        break;
      case 'inprogress':
        icon = Icons.work;
        color = Colors.purple;
        break;
      case 'resolved':
        icon = Icons.check_circle;
        color = Colors.green;
        break;
      case 'dismissed':
        icon = Icons.cancel;
        color = Colors.grey;
        break;
      case 'assigned':
        icon = Icons.person_add;
        color = Colors.indigo;
        break;
      default:
        icon = Icons.update;
        color = Colors.orange;
    }
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Timeline indicator
          Column(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: color.withOpacity(0.3)),
                ),
                child: Icon(icon, color: color, size: 16),
              ),
              if (!isLast)
                Container(
                  width: 2,
                  height: 40,
                  color: Colors.grey[300],
                  margin: const EdgeInsets.only(top: 8),
                ),
            ],
          ),
          const SizedBox(width: 16),
          // Timeline content
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: color.withOpacity(0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: color.withOpacity(0.2)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        _formatActionName(action),
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: color,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        _formatDateTime(createdAt),
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'By: $officerName ($userRole)',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                  if (description.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey[50],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey[200]!),
                      ),
                      child: Text(
                        description,
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAddCommentSection() {
    return Container(
      padding: const EdgeInsets.all(20),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Add Comment',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _commentController,
            maxLines: 3,
            decoration: InputDecoration(
              hintText: 'Add your investigation notes...',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Colors.blue, width: 2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _isUpdating ? null : _addComment,
              icon: const Icon(Icons.comment),
              label: Text(_isUpdating ? 'Adding...' : 'Add Comment'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCommentsSection() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.comment, color: Colors.blue),
              const SizedBox(width: 8),
              const Text(
                'Comments',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('concerns')
                .doc(widget.concern.id)
                .collection('comments')
                .orderBy('createdAt', descending: true)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              
              if (snapshot.hasError) {
                return Text('Error: ${snapshot.error}');
              }
              
              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey[200]!),
                  ),
                  child: const Center(
                    child: Text(
                      'No comments yet',
                      style: TextStyle(
                        color: Colors.grey,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                );
              }
              
              return ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: snapshot.data!.docs.length,
                itemBuilder: (context, index) {
                  final comment = snapshot.data!.docs[index];
                  final data = comment.data() as Map<String, dynamic>;
                  
                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: data['isOfficerComment'] == true 
                          ? Colors.blue[50] 
                          : Colors.grey[50],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: data['isOfficerComment'] == true 
                            ? Colors.blue[200]! 
                            : Colors.grey[200]!,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              data['isOfficerComment'] == true 
                                  ? Icons.admin_panel_settings 
                                  : Icons.person,
                              size: 16,
                              color: data['isOfficerComment'] == true 
                                  ? Colors.blue 
                                  : Colors.grey,
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    data['createdByName'] ?? 'Unknown',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: data['isOfficerComment'] == true 
                                          ? Colors.blue[700] 
                                          : Colors.grey[700],
                                      fontSize: 12,
                                    ),
                                  ),
                                  Text(
                                    data['userRole'] ?? (data['isOfficerComment'] == true 
                                        ? 'Anti-Corruption Officer' 
                                        : 'Citizen'),
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: data['isOfficerComment'] == true 
                                          ? Colors.blue[600] 
                                          : Colors.grey[600],
                                      fontStyle: FontStyle.italic,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Text(
                              data['createdAt'] != null 
                                  ? _formatDateTime((data['createdAt'] as Timestamp).toDate())
                                  : 'Unknown date',
                              style: const TextStyle(
                                fontSize: 10,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          data['content'] ?? '',
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.black87,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(width: 6),
          Text(
            text,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
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

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  String _formatDateTime(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);
    
    if (difference.inDays > 0) {
      return '${date.day}/${date.month}/${date.year}';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }

  String _formatActionName(String action) {
    switch (action.toLowerCase()) {
      case 'underreview':
        return 'Under Review';
      case 'inprogress':
        return 'In Progress';
      case 'resolved':
        return 'Resolved';
      case 'dismissed':
        return 'Dismissed';
      case 'assigned':
        return 'Assigned';
      case 'created':
        return 'Created';
      case 'status_update':
        return 'Status Updated';
      default:
        // Fallback: convert camelCase to Title Case
        return action.replaceAllMapped(
          RegExp(r'([A-Z])'), 
          (match) => ' ${match.group(1)}'
        ).trim().split(' ').map((word) => 
          word.isNotEmpty ? word[0].toUpperCase() + word.substring(1).toLowerCase() : ''
        ).join(' ');
    }
  }

  void _addComment() async {
    if (_commentController.text.trim().isEmpty) return;

    setState(() {
      _isUpdating = true;
    });

    try {
      // Add comment to Firestore
      await FirebaseFirestore.instance
          .collection('concerns')
          .doc(widget.concern.id)
          .collection('comments')
          .add({
        'content': _commentController.text.trim(),
        'createdBy': widget.officerId,
        'createdByName': widget.officerName,
        'createdAt': FieldValue.serverTimestamp(),
        'isOfficerComment': true,
        'userRole': 'Anti-Corruption Officer',
      });
      
      _commentController.clear();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Comment added successfully'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Error adding comment: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isUpdating = false;
        });
      }
    }
  }

  // Helper function to get valid status transitions based on current status
  List<String> _getValidStatusTransitions(ConcernStatus currentStatus) {
    switch (currentStatus) {
      case ConcernStatus.pending:
        // From pending: can only go to underReview or dismissed
        return ['underReview', 'dismissed'];
      case ConcernStatus.underReview:
        // From underReview: can go to inProgress or dismissed
        return ['inProgress', 'dismissed'];
      case ConcernStatus.inProgress:
        // From inProgress: can go to resolved or dismissed
        return ['resolved', 'dismissed'];
      case ConcernStatus.resolved:
        // From resolved: no further transitions allowed
        return [];
      case ConcernStatus.dismissed:
        // From dismissed: no further transitions allowed
        return [];
      case ConcernStatus.escalated:
        // From escalated: can go to underReview or dismissed
        return ['underReview', 'dismissed'];
    }
  }

  void _showStatusUpdateDialog(String status) async {
    // Handle delete action
    if (status == 'delete') {
      _showDeleteConfirmation();
      return;
    }

    // Validate status transition
    final validTransitions = _getValidStatusTransitions(widget.concern.status);
    if (!validTransitions.contains(status)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Invalid status transition from ${widget.concern.status.name} to $status'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Show dialog to get reason for status change
    final reason = await _showStatusReasonDialog(status);
    if (reason == null) return; // User cancelled

    try {
      setState(() {
        _isUpdating = true;
      });

      // Convert string status to enum
      ConcernStatus newStatus;
      switch (status) {
        case 'underReview':
          newStatus = ConcernStatus.underReview;
          break;
        case 'inProgress':
          newStatus = ConcernStatus.inProgress;
          break;
        case 'resolved':
          newStatus = ConcernStatus.resolved;
          break;
        case 'dismissed':
          newStatus = ConcernStatus.dismissed;
          break;
        default:
          newStatus = widget.concern.status;
      }

      // Update the concern status using the service
      await _concernService.updateConcernStatus(
        concernId: widget.concern.id,
        status: newStatus,
        officerId: widget.officerId,
        officerName: widget.officerName,
        comment: reason,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ Status updated to: ${status.replaceAll(RegExp(r'([A-Z])'), r' $1').toLowerCase()}'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Error updating status: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isUpdating = false;
        });
      }
    }
  }

  Future<String?> _showStatusReasonDialog(String status) async {
    final reasonController = TextEditingController();
    final statusText = status.replaceAll(RegExp(r'([A-Z])'), r' $1').toLowerCase();
    
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Update Status to ${statusText.toUpperCase()}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Please provide a reason for changing the status:'),
            const SizedBox(height: 16),
            TextField(
              controller: reasonController,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'Enter reason for status change...',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final reason = reasonController.text.trim();
              if (reason.isNotEmpty) {
                Navigator.of(context).pop(reason);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Please enter a reason'),
                    backgroundColor: Colors.orange,
                  ),
                );
              }
            },
            child: Text('Update Status'),
          ),
        ],
      ),
    );
  }

  void _showAIAssistant() {
    // AI Assistant logic here
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('🧠 AI Assistant opened!'),
        backgroundColor: Colors.purple,
      ),
    );
  }

  void _viewEvidence() {
    if (widget.concern.attachments == null || widget.concern.attachments!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No evidence files to view'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Navigate to a full-screen evidence viewer
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EvidenceViewerScreen(
          attachments: widget.concern.attachments!,
          concernTitle: widget.concern.title,
        ),
      ),
    );
  }


  void _validateEvidence() {
    if (widget.concern.attachments == null || widget.concern.attachments!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No evidence images to validate'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) => ConcernEvidenceValidationWidget(
        concernId: widget.concern.id,
        concernTitle: widget.concern.title,
        concernDescription: widget.concern.description,
        evidenceUrls: widget.concern.attachments.map((attachment) => attachment.fileUrl).toList(),
        onValidationComplete: (result) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Evidence validation completed: ${result.overallRecommendation}'),
              backgroundColor: result.recommendationColor,
            ),
          );
        },
      ),
    );
  }

  void _showFullAIDetail() {
    // Generate AI analysis using SmartPriorityService
    final analysis = SmartPriorityService.analyzeConcern(
      widget.concern.title,
      widget.concern.description,
      widget.concern.category,
    );

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.psychology, color: Colors.blue),
            const SizedBox(width: 8),
            const Text('AI Full Analysis'),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Analysis Summary
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Analysis Summary',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.blue.shade800,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(analysis.summary),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              
              // Sentiment Analysis
              _buildAnalysisSection(
                'Sentiment Analysis',
                Icons.sentiment_satisfied,
                Colors.green,
                [
                  'Sentiment: ${analysis.sentiment.sentimentScore.name.replaceAll(RegExp(r'([A-Z])'), r' $1').trim()}',
                  'Score: ${analysis.sentiment.score.toStringAsFixed(2)}',
                  'Magnitude: ${analysis.sentiment.magnitude.toStringAsFixed(2)}',
                ],
              ),
              
              // Priority Analysis
              _buildAnalysisSection(
                'Priority Analysis',
                Icons.priority_high,
                Colors.red,
                [
                  'Priority: ${analysis.priority.priority.name.toUpperCase()}',
                  'Score: ${(analysis.priority.score * 100).toStringAsFixed(0)}%',
                  'Reasoning: ${analysis.priority.reasoning}',
                ],
              ),
              
              // Topics
              if (analysis.topics.isNotEmpty)
                _buildAnalysisSection(
                  'Key Topics',
                  Icons.topic,
                  Colors.purple,
                  analysis.topics.map((topic) => '• $topic').toList(),
                ),
              
              // Confidence
              _buildAnalysisSection(
                'Analysis Confidence',
                Icons.analytics,
                Colors.orange,
                [
                  'Confidence: ${(analysis.confidence * 100).toStringAsFixed(0)}%',
                  'AI Model: ${analysis.aiModel}',
                  'Analyzed: ${analysis.analyzedAt.toString().split('.')[0]}',
                ],
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildAnalysisSection(String title, IconData icon, Color color, List<String> items) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 16),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: color.withOpacity(0.8),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ...items.map((item) => Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Text(
              item,
              style: const TextStyle(fontSize: 14),
            ),
          )),
        ],
      ),
    );
  }

  /// Check if current user can delete this concern
  bool _canDeleteConcern() {
    final currentUser = _auth.currentUser;
    if (currentUser == null) return false;
    if (widget.concern.authorId != currentUser.uid) return false;
    if (widget.concern.status == ConcernStatus.resolved || widget.concern.status == ConcernStatus.dismissed) {
      return false;
    }
    return true;
  }

  /// Show delete confirmation dialog
  void _showDeleteConfirmation() {
    final l10n = AppLocalizations.of(context)!;
    
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(l10n.deleteConcern),
          content: Text(l10n.deleteConcernConfirmation),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(AppLocalizations.of(context)!.cancel),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _deleteConcern();
              },
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: Text(l10n.deleteConcern),
            ),
          ],
        );
      },
    );
  }

  /// Delete the concern and navigate back
  Future<void> _deleteConcern() async {
    final l10n = AppLocalizations.of(context)!;
    
    try {
      // Show loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return const AlertDialog(
            content: Row(
              children: [
                CircularProgressIndicator(),
                SizedBox(width: 16),
                Text('Deleting concern...'),
              ],
            ),
          );
        },
      );

      // Delete the concern
      await _concernService.deleteUserConcern(widget.concern.id);

      // Close loading dialog
      if (mounted) Navigator.of(context).pop();

      // Show success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.deleteConcernSuccess),
            backgroundColor: Colors.green,
          ),
        );
      }

      // Navigate back to previous screen
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      // Close loading dialog
      if (mounted) Navigator.of(context).pop();

      // Show error message
      String errorMessage = l10n.deleteConcernError;
      if (e.toString().contains('You can only delete your own concerns')) {
        errorMessage = l10n.onlyDeleteOwnConcerns;
      } else if (e.toString().contains('Cannot delete resolved or dismissed concerns')) {
        errorMessage = l10n.cannotDeleteResolvedConcern;
      } else if (e.toString().contains('Cannot delete this concern')) {
        errorMessage = l10n.cannotDeleteConcern;
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}