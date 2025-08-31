import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class TimelineTrackerScreen extends StatefulWidget {
  const TimelineTrackerScreen({super.key});

  @override
  State<TimelineTrackerScreen> createState() => _TimelineTrackerScreenState();
}

class _TimelineTrackerScreenState extends State<TimelineTrackerScreen> {
  final _formKey = GlobalKey<FormState>();
  final _milestoneController = TextEditingController();
  final _completionDateController = TextEditingController();
  String _selectedTender = '';
  bool _isLoading = false;
  List<Map<String, dynamic>> _tenders = [];
  List<Map<String, dynamic>> _milestones = [];

  @override
  void initState() {
    super.initState();
    _loadTenders();
  }

  @override
  void dispose() {
    _milestoneController.dispose();
    _completionDateController.dispose();
    super.dispose();
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
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading milestones: $e')),
        );
      }
    }
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 30)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() {
        _completionDateController.text = "${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}";
      });
    }
  }

  Future<void> _addMilestone() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      await FirebaseFirestore.instance.collection('project_timeline').add({
        'tenderId': _selectedTender,
        'milestone': _milestoneController.text.trim(),
        'completionDate': _completionDateController.text,
        'isCompleted': false,
        'createdAt': FieldValue.serverTimestamp(),
      });

      _milestoneController.clear();
      _completionDateController.clear();
      _loadMilestones();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Milestone added successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
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

  Future<void> _toggleMilestoneCompletion(String milestoneId, bool isCompleted) async {
    try {
      await FirebaseFirestore.instance
          .collection('project_timeline')
          .doc(milestoneId)
          .update({
        'isCompleted': !isCompleted,
        'actualCompletionDate': !isCompleted ? DateTime.now().toIso8601String() : null,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      _loadMilestones();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating milestone: $e')),
        );
      }
    }
  }

  double _calculateProgress() {
    if (_milestones.isEmpty) return 0.0;
    final completedCount = _milestones.where((m) => m['isCompleted'] == true).length;
    return completedCount / _milestones.length;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Timeline Tracker'),
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // Tender Selection
          Container(
            padding: const EdgeInsets.all(16),
                          child: DropdownButtonFormField<String>(
                value: _selectedTender.isEmpty ? null : _selectedTender,
              decoration: const InputDecoration(
                labelText: 'Select Tender',
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
          ),

          // Progress Bar
          if (_milestones.isNotEmpty) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Project Progress',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '${(_calculateProgress() * 100).toStringAsFixed(1)}%',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.orange,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  LinearProgressIndicator(
                    value: _calculateProgress(),
                    backgroundColor: Colors.grey[300],
                    valueColor: const AlwaysStoppedAnimation<Color>(Colors.orange),
                    minHeight: 8,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],

          // Add Milestone Form
          if (_selectedTender.isNotEmpty) ...[
            Container(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      'Add New Milestone',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _milestoneController,
                      decoration: const InputDecoration(
                        labelText: 'Milestone Description',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.flag),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter a milestone description';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _completionDateController,
                      decoration: InputDecoration(
                        labelText: 'Planned Completion Date',
                        border: const OutlineInputBorder(),
                        prefixIcon: const Icon(Icons.calendar_today),
                        suffixIcon: IconButton(
                          icon: const Icon(Icons.date_range),
                          onPressed: _selectDate,
                        ),
                      ),
                      readOnly: true,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please select a completion date';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _isLoading ? null : _addMilestone,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : const Text('Add Milestone'),
                    ),
                  ],
                ),
              ),
            ),
          ],

          // Milestones List
          Expanded(
            child: _milestones.isEmpty
                ? const Center(
                    child: Text(
                      'No milestones found. Add milestones to track project progress.',
                      style: TextStyle(color: Colors.grey),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _milestones.length,
                    itemBuilder: (context, index) {
                      final milestone = _milestones[index];
                      final isCompleted = milestone['isCompleted'] ?? false;
                      final plannedDate = DateTime.tryParse(milestone['completionDate'] ?? '');
                      final isOverdue = plannedDate != null && 
                          plannedDate.isBefore(DateTime.now()) && 
                          !isCompleted;

                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: ListTile(
                          leading: Icon(
                            isCompleted ? Icons.check_circle : Icons.radio_button_unchecked,
                            color: isCompleted ? Colors.green : Colors.grey,
                          ),
                          title: Text(
                            milestone['milestone'],
                            style: TextStyle(
                              decoration: isCompleted ? TextDecoration.lineThrough : null,
                              color: isCompleted ? Colors.grey : null,
                            ),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Planned: ${milestone['completionDate']}'),
                              if (isOverdue)
                                const Text(
                                  'OVERDUE',
                                  style: TextStyle(
                                    color: Colors.red,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                            ],
                          ),
                          trailing: IconButton(
                            icon: Icon(
                              isCompleted ? Icons.undo : Icons.check,
                              color: isCompleted ? Colors.orange : Colors.green,
                            ),
                            onPressed: () => _toggleMilestoneCompletion(
                              milestone['id'],
                              isCompleted,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
