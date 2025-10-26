import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import '../services/notification_service.dart';
import '../services/document_validation_ai_service.dart';
import '../widgets/document_ai_validation_widget.dart';
import 'document_viewer_screen.dart';

class AdminApprovalScreen extends StatefulWidget {
  const AdminApprovalScreen({super.key});

  @override
  State<AdminApprovalScreen> createState() => _AdminApprovalScreenState();
}

class _AdminApprovalScreenState extends State<AdminApprovalScreen>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  String _selectedFilter = 'all';
  bool _isLoading = false;
  final NotificationService _notificationService = NotificationService();
  
  // AI Validation state
  final Map<String, BatchValidationResult> _aiValidationResults = {};
  final Map<String, bool> _isAnalyzing = {};

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _approveUser(String userId, String userEmail, String userRole) async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Update user status to approved
      await FirebaseFirestore.instance.collection('users').doc(userId).update({
        'status': 'approved',
        'approvedAt': FieldValue.serverTimestamp(),
        'approvedBy': 'admin', // You can get this from current user
      });

      // Send push notification
      await NotificationService.sendApprovalNotification(userEmail, userRole);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('User approved successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error approving user: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _rejectUser(String userId, String userEmail) async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Update user status to rejected
      await FirebaseFirestore.instance.collection('users').doc(userId).update({
        'status': 'rejected',
        'rejectedAt': FieldValue.serverTimestamp(),
        'rejectedBy': 'admin',
      });

      // Send rejection notification
      await NotificationService.sendRejectionNotification(userEmail);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('User rejected successfully!'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error rejecting user: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }


  Future<void> _viewDocument(String documentUrl) async {
    try {
      print('🔗 Opening document in web view: $documentUrl');
      
      // Extract filename from URL for display
      final uri = Uri.parse(documentUrl);
      final pathSegments = uri.pathSegments;
      final filename = pathSegments.isNotEmpty ? pathSegments.last : 'Document';
      
      // Navigate to document viewer screen
      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => DocumentViewerScreen(
              documentUrl: documentUrl,
              documentName: filename,
            ),
          ),
        );
      }
    } catch (e) {
      print('❌ Error opening document: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error opening document: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }
  }

  /// AI Validate Documents
  Future<void> _aiValidateDocuments(String userId, List<String> documentUrls, String userRole) async {
    setState(() {
      _isAnalyzing[userId] = true;
    });

    try {
      print('🤖 Starting AI validation for user: $userId');
      
      final result = await DocumentValidationAIService.analyzeBatchDocuments(
        documentUrls: documentUrls,
        userRole: userRole,
      );
      
      setState(() {
        _aiValidationResults[userId] = result;
        _isAnalyzing[userId] = false;
      });
      
      // Show summary notification
      if (mounted) {
        final icon = result.overallRecommendation == 'APPROVE' 
            ? Icons.check_circle
            : result.overallRecommendation == 'REJECT'
                ? Icons.cancel
                : Icons.warning;
        
        final color = result.overallRecommendation == 'APPROVE'
            ? Colors.green
            : result.overallRecommendation == 'REJECT'
                ? Colors.red
                : Colors.orange;
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(icon, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'AI Recommendation: ${result.overallRecommendation}\n'
                    'Confidence: ${(result.overallConfidence * 100).toStringAsFixed(0)}%',
                  ),
                ),
              ],
            ),
            backgroundColor: color,
            duration: const Duration(seconds: 5),
          ),
        );
      }
      
    } catch (e) {
      print('❌ AI validation error: $e');
      setState(() {
        _isAnalyzing[userId] = false;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('AI validation failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Widget _buildBatchValidationResults(BatchValidationResult result) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: result.overallRecommendation == 'APPROVE'
              ? [Colors.green.shade700, Colors.green.shade900]
              : result.overallRecommendation == 'REJECT'
                  ? [Colors.red.shade700, Colors.red.shade900]
                  : [Colors.orange.shade700, Colors.orange.shade900],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.psychology, color: Colors.white, size: 24),
              SizedBox(width: 8),
              Text(
                '🤖 AI Validation Summary',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Recommendation: ${result.overallRecommendation}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '${(result.overallConfidence * 100).toStringAsFixed(0)}%',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                LinearProgressIndicator(
                  value: result.overallConfidence,
                  backgroundColor: Colors.white24,
                  valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildStatChip('Total', result.totalDocuments.toString()),
                    _buildStatChip('Analyzed', result.analyzedDocuments.toString()),
                    if (result.failedDocuments > 0)
                      _buildStatChip('Failed', result.failedDocuments.toString(), isError: true),
                    if (result.hasHighRiskDocuments)
                      _buildStatChip('⚠️', 'High Risk', isError: true),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          // Individual document results
          ...result.individualResults.asMap().entries.map((entry) {
            final index = entry.key;
            final docResult = entry.value;
            return ExpansionTile(
              title: Text(
                'Document ${index + 1}: ${docResult.verdict}',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              subtitle: Text(
                'Risk: ${docResult.riskLevel.toUpperCase()} | Confidence: ${(docResult.confidenceScore * 100).toStringAsFixed(0)}%',
                style: const TextStyle(color: Colors.white70, fontSize: 12),
              ),
              iconColor: Colors.white,
              collapsedIconColor: Colors.white,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Document Type: ${docResult.documentType}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Confidence: ${(docResult.confidenceScore * 100).toStringAsFixed(1)}%',
                        style: const TextStyle(color: Colors.white70),
                      ),
                      Text(
                        'Risk Level: ${docResult.riskLevel}',
                        style: const TextStyle(color: Colors.white70),
                      ),
                      Text(
                        'Verdict: ${docResult.verdict}',
                        style: const TextStyle(color: Colors.white70),
                      ),
                      if (docResult.adminNotes.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Text(
                          'Admin Notes: ${docResult.adminNotes}',
                          style: const TextStyle(color: Colors.white70),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            );
          }),
        ],
      ),
    );
  }

  Widget _buildStatChip(String label, String value, {bool isError = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: isError ? Colors.red.withOpacity(0.3) : Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  String _getRoleDisplayName(String roleId) {
    switch (roleId) {
      case 'admin':
        return 'System Administrator';
      case 'finance_officer':
        return 'Finance Officer';
      case 'procurement_officer':
        return 'Procurement Officer';
      case 'anticorruption_officer':
        return 'Anti-corruption Officer';
      case 'citizen':
        return 'Citizen/Taxpayer';
      case 'journalist':
        return 'Journalist/Media User';
      case 'community_leader':
        return 'Community Leader/Activist';
      case 'researcher':
        return 'Researcher/Academic User';
      case 'ngo':
        return 'NGO/Private Contractor';
      default:
        return roleId;
    }
  }

  Widget _buildUserCard(DocumentSnapshot userDoc) {
    final data = userDoc.data() as Map<String, dynamic>;
    final userId = userDoc.id;
    final userEmail = data['email'] ?? 'No email';
    
    // Extract role ID from role object or string
    String userRole = 'Unknown';
    String roleDisplayName = 'Unknown';
    final roleData = data['role'];
    if (roleData is String) {
      userRole = roleData;
      roleDisplayName = _getRoleDisplayName(roleData);
    } else if (roleData is Map && roleData['id'] != null) {
      userRole = roleData['id'];
      roleDisplayName = roleData['name'] ?? _getRoleDisplayName(roleData['id']);
    }
    
    final status = data['status'] ?? 'pending';
    final documents = List<String>.from(data['documents'] ?? []);
    final uploadedAt = data['uploadedAt'] as Timestamp?;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with status
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        userEmail,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Role: $roleDisplayName',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: status == 'approved'
                        ? Colors.green.withOpacity(0.1)
                        : status == 'rejected'
                            ? Colors.red.withOpacity(0.1)
                            : Colors.orange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    status.toUpperCase(),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: status == 'approved'
                          ? Colors.green
                          : status == 'rejected'
                              ? Colors.red
                              : Colors.orange,
                    ),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Upload date
            if (uploadedAt != null) ...[
              Row(
                children: [
                  Icon(Icons.schedule, size: 16, color: Colors.grey.shade600),
                  const SizedBox(width: 8),
                  Text(
                    'Uploaded: ${_formatDate(uploadedAt.toDate())}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
            ],
            
            // Documents section
            if (documents.isNotEmpty) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Uploaded Documents:',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: (_isAnalyzing[userId] ?? false)
                        ? null
                        : () => _aiValidateDocuments(userId, documents, userRole),
                    icon: (_isAnalyzing[userId] ?? false)
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.psychology, size: 18),
                    label: Text(
                      (_isAnalyzing[userId] ?? false) ? 'Analyzing...' : '🤖 AI Validate',
                      style: const TextStyle(fontSize: 12),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.purple,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ...documents.asMap().entries.map((entry) => 
                Container(
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
                        Icons.description,
                        color: Colors.blue,
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Document ${entry.key + 1}',
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.black87,
                          ),
                        ),
                      ),
                      TextButton(
                        onPressed: () => _viewDocument(entry.value),
                        child: const Text(
                          'View',
                          style: TextStyle(color: Colors.blue),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              // AI Validation Results
              if (_isAnalyzing[userId] ?? false)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.purple.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.purple.withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      const CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.purple),
                      ),
                      const SizedBox(width: 12),
                      const Text(
                        'AI is analyzing documents...',
                        style: TextStyle(
                          color: Colors.purple,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              if (_aiValidationResults.containsKey(userId) && !(_isAnalyzing[userId] ?? false)) ...[
                const SizedBox(height: 12),
                _buildBatchValidationResults(_aiValidationResults[userId]!),
              ],
            ],
            
            const SizedBox(height: 16),
            
            // Action buttons
            if (status == 'pending') ...[
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : () => _approveUser(userId, userEmail, userRole),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : const Text('Approve'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : () => _rejectUser(userId, userEmail),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text('Reject'),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} at ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text('User Approvals'),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black87),
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: Column(
          children: [
            // Filter section
            Container(
              color: Colors.white,
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  const Text(
                    'Filter:',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          _buildFilterChip('all', 'All'),
                          const SizedBox(width: 8),
                          _buildFilterChip('pending', 'Pending'),
                          const SizedBox(width: 8),
                          _buildFilterChip('approved', 'Approved'),
                          const SizedBox(width: 8),
                          _buildFilterChip('rejected', 'Rejected'),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            // Users list
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: _selectedFilter == 'all'
                    ? FirebaseFirestore.instance
                        .collection('users')
                        .where('status', isNotEqualTo: null)
                        .orderBy('status')
                        .orderBy('uploadedAt', descending: true)
                        .snapshots()
                    : FirebaseFirestore.instance
                        .collection('users')
                        .where('status', isEqualTo: _selectedFilter)
                        .orderBy('uploadedAt', descending: true)
                        .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: CircularProgressIndicator(),
                    );
                  }

                  if (snapshot.hasError) {
                    return Center(
                      child: Text('Error: ${snapshot.error}'),
                    );
                  }

                  final users = snapshot.data?.docs ?? [];

                  if (users.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.people_outline,
                            size: 64,
                            color: Colors.grey.shade400,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No users found',
                            style: TextStyle(
                              fontSize: 18,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.all(20),
                    itemCount: users.length,
                    itemBuilder: (context, index) {
                      return _buildUserCard(users[index]);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(String value, String label) {
    final isSelected = _selectedFilter == value;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedFilter = value;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? Colors.blue : Colors.grey.shade200,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.black87,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
