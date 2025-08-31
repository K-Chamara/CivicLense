import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ProgressTrackingScreen extends StatefulWidget {
  const ProgressTrackingScreen({super.key});

  @override
  State<ProgressTrackingScreen> createState() => _ProgressTrackingScreenState();
}

class _ProgressTrackingScreenState extends State<ProgressTrackingScreen> {
  List<Map<String, dynamic>> _tenders = [];
  List<Map<String, dynamic>> _milestones = [];
  String _selectedTender = '';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadTenders();
  }

  Future<void> _loadTenders() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final querySnapshot = await FirebaseFirestore.instance
          .collection('tenders')
          .where('createdBy', isEqualTo: user.uid)
          .where('status', isEqualTo: 'active')
          .get();

      setState(() {
        _tenders = querySnapshot.docs.map((doc) {
          final data = doc.data();
          return {
            'id': doc.id,
            'title': data['title'] ?? '',
            'budget': data['budget'] ?? 0.0,
            'deadline': data['deadline'] ?? '',
            'progress': data['progress'] ?? 0.0,
          };
        }).toList();
      });

      if (_tenders.isNotEmpty) {
        _selectedTender = _tenders.first['id'];
        _loadMilestones();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading tenders: $e')),
        );
      }
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _loadMilestones() async {
    if (_selectedTender.isEmpty) return;

    try {
      final querySnapshot = await FirebaseFirestore.instance
          .collection('project_timeline')
          .where('tenderId', isEqualTo: _selectedTender)
          .get();

      setState(() {
        _milestones = querySnapshot.docs.map((doc) {
          final data = doc.data();
          return {
            'id': doc.id,
            'milestone': data['milestone'] ?? '',
            'completionDate': data['completionDate'] ?? '',
            'isCompleted': data['isCompleted'] ?? false,
            'actualCompletionDate': data['actualCompletionDate'],
          };
        }).toList();
        
        // Sort by completionDate in ascending order
        _milestones.sort((a, b) {
          final aDate = DateTime.tryParse(a['completionDate'] ?? '');
          final bDate = DateTime.tryParse(b['completionDate'] ?? '');
          if (aDate == null && bDate == null) return 0;
          if (aDate == null) return 1;
          if (bDate == null) return -1;
          return aDate.compareTo(bDate);
        });
        
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading milestones: $e')),
        );
      }
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _updateProgress(double newProgress) async {
    try {
      await FirebaseFirestore.instance
          .collection('tenders')
          .doc(_selectedTender)
          .update({
        'progress': newProgress,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Update local state
      setState(() {
        final index = _tenders.indexWhere((t) => t['id'] == _selectedTender);
        if (index != -1) {
          _tenders[index]['progress'] = newProgress;
        }
      });

      // Create notification for progress update
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await FirebaseFirestore.instance.collection('notifications').add({
          'userId': user.uid,
          'title': 'Progress Updated',
          'message': 'Project progress updated to ${newProgress.toStringAsFixed(1)}%',
          'type': 'progress_update',
          'tenderId': _selectedTender,
          'isRead': false,
          'createdAt': FieldValue.serverTimestamp(),
          'priority': 'normal',
        });
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Progress updated to ${newProgress.toStringAsFixed(1)}%'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating progress: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  String _getDelayPrediction() {
    if (_milestones.isEmpty) return 'No milestones to analyze';

    final overdueMilestones = _milestones.where((m) {
      final plannedDate = DateTime.tryParse(m['completionDate'] ?? '');
      return plannedDate != null && 
          plannedDate.isBefore(DateTime.now()) && 
          !(m['isCompleted'] ?? false);
    }).length;

    final totalMilestones = _milestones.length;
    final completedMilestones = _milestones.where((m) => m['isCompleted'] ?? false).length;
    final completionRate = totalMilestones > 0 ? completedMilestones / totalMilestones : 0.0;

    if (overdueMilestones > 0) {
      return '⚠️ High risk of delay: $overdueMilestones milestone(s) overdue';
    } else if (completionRate < 0.3) {
      return '⚠️ Moderate risk: Low completion rate (${(completionRate * 100).toStringAsFixed(1)}%)';
    } else {
      return '✅ On track: Good progress maintained';
    }
  }

  String _getRecommendations() {
    final currentProgress = _tenders.firstWhere(
      (t) => t['id'] == _selectedTender,
      orElse: () => {'progress': 0.0},
    )['progress'] as double;

    if (currentProgress < 25) {
      return '• Focus on initial planning and resource allocation\n• Set up project milestones\n• Establish communication channels';
    } else if (currentProgress < 50) {
      return '• Monitor milestone completion closely\n• Address any bottlenecks early\n• Update stakeholders regularly';
    } else if (currentProgress < 75) {
      return '• Accelerate remaining tasks\n• Review quality standards\n• Prepare for final delivery';
    } else {
      return '• Finalize remaining deliverables\n• Conduct quality assurance\n• Prepare project closure documentation';
    }
  }

  @override
  Widget build(BuildContext context) {
    final selectedTenderData = _tenders.firstWhere(
      (t) => t['id'] == _selectedTender,
      orElse: () => {'title': 'No tender selected', 'progress': 0.0},
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Progress Tracking'),
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Tender Selection
                  DropdownButtonFormField<String>(
                    value: _selectedTender.isEmpty ? null : _selectedTender,
                    decoration: const InputDecoration(
                      labelText: 'Select Project',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.assignment),
                    ),
                    items: _tenders.map((tender) {
                      return DropdownMenuItem<String>(
                        value: tender['id'],
                        child: Text(tender['title']),
                      );
                    }).toList(),
                    onChanged: (String? newValue) {
                      setState(() {
                        _selectedTender = newValue ?? '';
                      });
                      _loadMilestones();
                    },
                  ),
                  const SizedBox(height: 24),

                  if (_selectedTender.isNotEmpty) ...[
                    // Current Progress
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'Current Progress',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  '${selectedTenderData['progress'].toStringAsFixed(1)}%',
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.orange,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            LinearProgressIndicator(
                              value: selectedTenderData['progress'] / 100,
                              backgroundColor: Colors.grey[300],
                              valueColor: const AlwaysStoppedAnimation<Color>(Colors.orange),
                              minHeight: 10,
                            ),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                Expanded(
                                  child: ElevatedButton(
                                    onPressed: () => _updateProgress(
                                      (selectedTenderData['progress'] as double) + 10,
                                    ),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.green,
                                      foregroundColor: Colors.white,
                                    ),
                                    child: const Text('+10%'),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: ElevatedButton(
                                    onPressed: () => _updateProgress(
                                      (selectedTenderData['progress'] as double) + 25,
                                    ),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.blue,
                                      foregroundColor: Colors.white,
                                    ),
                                    child: const Text('+25%'),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: ElevatedButton(
                                    onPressed: () => _updateProgress(100.0),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.orange,
                                      foregroundColor: Colors.white,
                                    ),
                                    child: const Text('Complete'),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // AI Predictions
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.psychology, color: Colors.orange),
                                const SizedBox(width: 8),
                                const Text(
                                  'AI Analysis',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.orange.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.orange.withOpacity(0.3)),
                              ),
                              child: Text(
                                _getDelayPrediction(),
                                style: const TextStyle(fontSize: 14),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Recommendations
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.lightbulb, color: Colors.yellow.shade700),
                                const SizedBox(width: 8),
                                const Text(
                                  'Recommendations',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              _getRecommendations(),
                              style: const TextStyle(fontSize: 14),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Milestones Overview
                    if (_milestones.isNotEmpty) ...[
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Milestones Overview',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 16),
                              ..._milestones.map((milestone) {
                                final isCompleted = milestone['isCompleted'] ?? false;
                                final plannedDate = DateTime.tryParse(milestone['completionDate'] ?? '');
                                final isOverdue = plannedDate != null && 
                                    plannedDate.isBefore(DateTime.now()) && 
                                    !isCompleted;

                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 8),
                                  child: Row(
                                    children: [
                                      Icon(
                                        isCompleted ? Icons.check_circle : Icons.radio_button_unchecked,
                                        color: isCompleted ? Colors.green : 
                                               isOverdue ? Colors.red : Colors.grey,
                                        size: 20,
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          milestone['milestone'],
                                          style: TextStyle(
                                            decoration: isCompleted ? TextDecoration.lineThrough : null,
                                            color: isCompleted ? Colors.grey : null,
                                          ),
                                        ),
                                      ),
                                      if (isOverdue)
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 6,
                                            vertical: 2,
                                          ),
                                          decoration: BoxDecoration(
                                            color: Colors.red,
                                            borderRadius: BorderRadius.circular(4),
                                          ),
                                          child: const Text(
                                            'OVERDUE',
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 10,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                );
                              }).toList(),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ] else ...[
                    const Center(
                      child: Column(
                        children: [
                          Icon(
                            Icons.assignment_outlined,
                            size: 64,
                            color: Colors.grey,
                          ),
                          SizedBox(height: 16),
                          Text(
                            'No active projects found',
                            style: TextStyle(
                              fontSize: 18,
                              color: Colors.grey,
                            ),
                          ),
                          Text(
                            'Create a new tender to start tracking progress',
                            style: TextStyle(
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
    );
  }
}
