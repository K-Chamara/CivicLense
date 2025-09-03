import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ProjectDetailsScreen extends StatefulWidget {
  final Map<String, dynamic> project;

  const ProjectDetailsScreen({super.key, required this.project});

  @override
  State<ProjectDetailsScreen> createState() => _ProjectDetailsScreenState();
}

class _ProjectDetailsScreenState extends State<ProjectDetailsScreen> {
  final TextEditingController _milestoneController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _dueDateController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  
  double? _originalTenderAmount;
  double? _winningBidAmount;
  List<Map<String, dynamic>> _milestones = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProjectData();
  }

  @override
  void dispose() {
    _milestoneController.dispose();
    _descriptionController.dispose();
    _dueDateController.dispose();
    super.dispose();
  }

  Future<void> _loadProjectData() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      // Get original tender amount
      if (widget.project['type'] == 'project') {
        final tenderId = widget.project['tenderId'];
        if (tenderId != null) {
          final tenderDoc = await FirebaseFirestore.instance
              .collection('tenders')
              .doc(tenderId)
              .get();
          
          if (tenderDoc.exists) {
            final tenderData = tenderDoc.data()!;
            _originalTenderAmount = (tenderData['budget'] ?? 0.0).toDouble();
          }
        }
      }

      // Get winning bid amount
      _winningBidAmount = widget.project['budget'] as double?;

      // Load milestones
      await _loadMilestones();

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading project data: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _loadMilestones() async {
    try {
      print('Loading milestones for project ID: ${widget.project['id']}');
      
      final milestonesSnapshot = await FirebaseFirestore.instance
          .collection('milestones')
          .where('projectId', isEqualTo: widget.project['id'])
          .get();

      print('Found ${milestonesSnapshot.docs.length} milestones');
      
      setState(() {
        _milestones = milestonesSnapshot.docs
            .map((doc) => {
                  'id': doc.id,
                  ...doc.data(),
                })
            .toList();
      });
      
      print('Loaded milestones: $_milestones');
    } catch (e) {
      print('Error loading milestones: $e');
    }
  }

  Future<void> _addMilestone() async {
    if (!_formKey.currentState!.validate()) return;

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      print('Adding milestone for project ID: ${widget.project['id']}');
      print('Milestone title: ${_milestoneController.text.trim()}');
      print('Due date: ${_dueDateController.text.trim()}');

      final docRef = await FirebaseFirestore.instance.collection('milestones').add({
        'projectId': widget.project['id'],
        'title': _milestoneController.text.trim(),
        'description': '',
        'dueDate': _dueDateController.text.trim(),
        'status': 'pending',
        'createdBy': user.uid,
        'createdAt': FieldValue.serverTimestamp(),
      });

      print('Milestone added with ID: ${docRef.id}');

      // Clear form
      _milestoneController.clear();
      _dueDateController.clear();

      // Reload milestones
      await _loadMilestones();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Milestone added successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      print('Error adding milestone: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error adding milestone: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _updateMilestoneStatus(String milestoneId, String status, {String? delayedDate}) async {
    try {
      final updateData = {
        'status': status,
        'updatedAt': FieldValue.serverTimestamp(),
      };
      
      if (status == 'delayed' && delayedDate != null) {
        updateData['delayedDate'] = delayedDate;
      }

      await FirebaseFirestore.instance
          .collection('milestones')
          .doc(milestoneId)
          .update(updateData);

      await _loadMilestones();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Milestone marked as $status'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating milestone: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showStatusUpdateDialog(Map<String, dynamic> milestone) {
    String selectedStatus = milestone['status'] ?? 'pending';
    final TextEditingController delayedDateController = TextEditingController();
    bool showDelayedDateField = false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text('Update ${milestone['title']} Status'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                value: selectedStatus,
                decoration: const InputDecoration(
                  labelText: 'Status',
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(value: 'pending', child: Text('Pending')),
                  DropdownMenuItem(value: 'ongoing', child: Text('Ongoing')),
                  DropdownMenuItem(value: 'done', child: Text('Done')),
                  DropdownMenuItem(value: 'delayed', child: Text('Delayed')),
                ],
                onChanged: (value) {
                  setDialogState(() {
                    selectedStatus = value!;
                    showDelayedDateField = value == 'delayed';
                  });
                },
              ),
              if (showDelayedDateField) ...[
                const SizedBox(height: 16),
                TextFormField(
                  controller: delayedDateController,
                  readOnly: true,
                  decoration: const InputDecoration(
                    labelText: 'New Due Date *',
                    border: OutlineInputBorder(),
                    hintText: 'Tap to select date',
                    suffixIcon: Icon(Icons.calendar_today),
                  ),
                  onTap: () async {
                    final DateTime? picked = await showDatePicker(
                      context: context,
                      initialDate: DateTime.now(),
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
                    );
                    if (picked != null) {
                      delayedDateController.text = '${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';
                    }
                  },
                ),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                if (selectedStatus == 'delayed' && delayedDateController.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Please select a new due date for delayed milestone'),
                      backgroundColor: Colors.red,
                    ),
                  );
                  return;
                }
                _updateMilestoneStatus(
                  milestone['id'],
                  selectedStatus,
                  delayedDate: selectedStatus == 'delayed' ? delayedDateController.text : null,
                );
              },
                          style: ElevatedButton.styleFrom(
              backgroundColor: Colors.lightBlue,
              foregroundColor: Colors.white,
            ),
            child: const Text('Update'),
            ),
          ],
        ),
      ),
    );
  }

  String _formatBudget(double budget) {
    if (budget >= 1000000) {
      return '\$${(budget / 1000000).toStringAsFixed(1)}M';
    } else if (budget >= 1000) {
      return '\$${(budget / 1000).toStringAsFixed(1)}K';
    } else {
      return '\$${budget.toStringAsFixed(0)}';
    }
  }

  double? get _savings {
    if (_originalTenderAmount != null && _winningBidAmount != null) {
      return _originalTenderAmount! - _winningBidAmount!;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.project['title'] ?? 'Project Details'),
        backgroundColor: Colors.lightBlue,
        foregroundColor: Colors.white,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddMilestoneDialog(),
        backgroundColor: Colors.lightBlue,
        foregroundColor: Colors.white,
        child: const Icon(Icons.add),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Project Overview Card
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Project Overview',
                            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),
                          _buildInfoRow('Project Title', widget.project['title'] ?? ''),
                          _buildInfoRow('Location', widget.project['projectLocation'] ?? ''),
                          _buildInfoRow('Description', widget.project['description'] ?? ''),
                          if (widget.project['winningBidder'] != null)
                            _buildInfoRow('Winning Bidder', widget.project['winningBidder']),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Financial Summary Card
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Financial Summary',
                            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),
                          if (_originalTenderAmount != null)
                            _buildFinancialRow(
                              'Original Tender Amount',
                              _formatBudget(_originalTenderAmount!),
                              Colors.blue,
                            ),
                          if (_winningBidAmount != null)
                            _buildFinancialRow(
                              'Winning Bid Amount',
                              _formatBudget(_winningBidAmount!),
                              Colors.green,
                            ),
                          if (_savings != null)
                            _buildFinancialRow(
                              'Savings',
                              _formatBudget(_savings!),
                              _savings! >= 0 ? Colors.green : Colors.red,
                            ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Milestones Section
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Project Milestones',
                            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),
                                                     if (_milestones.isEmpty)
                             Center(
                               child: Padding(
                                 padding: const EdgeInsets.all(32),
                                 child: Column(
                                   children: [
                                     const Text(
                                       'No milestones added yet',
                                       style: TextStyle(
                                         fontSize: 16,
                                         color: Colors.grey,
                                       ),
                                     ),
                                     const SizedBox(height: 16),
                                     ElevatedButton(
                                       onPressed: () async {
                                         await _loadMilestones();
                                       },
                                       child: const Text('Refresh'),
                                     ),
                                   ],
                                 ),
                               ),
                             )
                           else
                             ..._milestones.map((milestone) => _buildMilestoneCard(milestone)),
                        ],
                      ),
                    ),
                  ),
                  // Add bottom padding to account for FloatingActionButton
                  const SizedBox(height: 80),
                ],
              ),
            ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 16),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFinancialRow(String label, String value, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMilestoneCard(Map<String, dynamic> milestone) {
    final status = milestone['status'] as String? ?? 'pending';
    final isCompleted = status == 'done';
    
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        title: Text(
          milestone['title'] ?? '',
          style: TextStyle(
            decoration: isCompleted ? TextDecoration.lineThrough : null,
            color: isCompleted ? Colors.grey : null,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (milestone['description']?.isNotEmpty == true)
              Text(milestone['description'] ?? ''),
            Text(
              'Due: ${milestone['dueDate'] ?? ''}',
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.lightBlue,
              ),
            ),
            if (status == 'delayed' && milestone['delayedDate'] != null)
              Text(
                'New Due: ${milestone['delayedDate']}',
                style: const TextStyle(
                  fontWeight: FontWeight.w500,
                  color: Colors.red,
                ),
              ),
          ],
        ),
        trailing: GestureDetector(
          onTap: () => _showStatusUpdateDialog(milestone),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: _getStatusColor(status),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              status.toUpperCase(),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'done':
        return Colors.green;
      case 'ongoing':
        return Colors.lightBlue;
      case 'delayed':
        return Colors.red;
      case 'pending':
      default:
        return Colors.grey;
    }
  }

  void _showAddMilestoneDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Milestone'),
        content: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _milestoneController,
                decoration: const InputDecoration(
                  labelText: 'Milestone Title *',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter a milestone title';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
                             TextFormField(
                 controller: _dueDateController,
                 readOnly: true,
                 decoration: const InputDecoration(
                   labelText: 'Due Date *',
                   border: OutlineInputBorder(),
                   hintText: 'Tap to select date',
                   suffixIcon: Icon(Icons.calendar_today),
                 ),
                 onTap: () async {
                   final DateTime? picked = await showDatePicker(
                     context: context,
                     initialDate: DateTime.now(),
                     firstDate: DateTime.now(),
                     lastDate: DateTime.now().add(const Duration(days: 365 * 2)), // 2 years from now
                   );
                   if (picked != null) {
                     _dueDateController.text = '${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';
                   }
                 },
                 validator: (value) {
                   if (value == null || value.trim().isEmpty) {
                     return 'Please select a due date';
                   }
                   return null;
                 },
               ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _addMilestone();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.lightBlue,
              foregroundColor: Colors.white,
            ),
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }
}
