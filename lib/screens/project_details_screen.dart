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
  bool _isTracked = false; // Track if this project is being tracked by the user
  String _selectedColor = '#FF5722'; // Default color (red)

  // Available colors for milestones
  final List<String> _availableColors = [
    '#FF5722', // Red
    '#2196F3', // Blue
    '#4CAF50', // Green
    '#FF9800', // Orange
    '#9C27B0', // Purple
    '#00BCD4', // Cyan
    '#8BC34A', // Light Green
    '#FFC107', // Amber
    '#E91E63', // Pink
    '#607D8B', // Blue Grey
  ];

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

  bool _shouldShowAddButton() {
    // Only procurement officers can add milestones
    // Citizens can only view and track projects
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return false;
    
    // TODO: Implement proper role checking
    // For now, hide the add button for all users to prevent editing
    // Only procurement officers should be able to add/edit milestones
    return false; // Citizens can only view and track, not edit
  }

  Widget _buildStatusRow() {
    final status = widget.project['status'] as String? ?? 'ongoing';
    final statusColor = _getStatusColor(status);
    final statusText = status.toUpperCase();
    
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          const Text(
            'Status: ',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 16,
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: statusColor),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  _getStatusIcon(status),
                  size: 16,
                  color: statusColor,
                ),
                const SizedBox(width: 6),
                Text(
                  statusText,
                  style: TextStyle(
                    color: statusColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'ongoing':
        return Colors.blue;
      case 'done':
        return Colors.green;
      case 'delayed':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'ongoing':
        return Icons.play_circle;
      case 'done':
        return Icons.check_circle;
      case 'delayed':
        return Icons.schedule;
      default:
        return Icons.help;
    }
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

      // Check if this project is already being tracked
      await _checkTrackingStatus();

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
        'description': _descriptionController.text.trim(),
        'dueDate': _dueDateController.text.trim(),
        'color': _selectedColor,
        'status': 'pending',
        'createdBy': user.uid,
        'createdAt': FieldValue.serverTimestamp(),
      });

      print('Milestone added with ID: ${docRef.id}');

      // Clear form
      _milestoneController.clear();
      _descriptionController.clear();
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
      floatingActionButton: _shouldShowAddButton() ? FloatingActionButton(
        onPressed: () => _showAddMilestoneDialog(),
        backgroundColor: Colors.lightBlue,
        foregroundColor: Colors.white,
        child: const Icon(Icons.add),
      ) : null,
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
                          _buildStatusRow(),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Track Project Button (for citizens)
                  if (_isCitizenUser())
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Project Tracking',
                              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Get notified when milestones are updated for this project.',
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: Colors.grey[600],
                              ),
                            ),
                            const SizedBox(height: 16),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                onPressed: _toggleProjectTracking,
                                icon: Icon(_isProjectTracked() ? Icons.notifications_active : Icons.notifications_off),
                                label: Text(_isProjectTracked() ? 'Stop Tracking' : 'Track This Project'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: _isProjectTracked() ? Colors.red : Colors.blue,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                ),
                              ),
                            ),
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
                          Row(
                            children: [
                              Text(
                                'Project Milestones',
                                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const Spacer(),
                              if (_isCitizenUser())
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.blue.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    'View Only',
                                    style: TextStyle(
                                      color: Colors.blue[700],
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                            ],
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
    final color = milestone['color'] as String? ?? '#FF5722';
    
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: Color(int.parse(color.replaceAll('#', '0xFF'))),
            shape: BoxShape.circle,
          ),
        ),
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


  void _showAddMilestoneDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(
          'Add Milestone',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _milestoneController,
                decoration: const InputDecoration(
                  labelText: 'Milestone Title *',
                  hintText: 'Milestone Title *',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.flag),
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
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  hintText: 'Description',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.description),
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _dueDateController,
                readOnly: true,
                decoration: const InputDecoration(
                  labelText: 'Due Date *',
                  hintText: 'Due Date *',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.calendar_today),
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
              const SizedBox(height: 16),
              // Color Selection Section
              const Text(
                'Milestone Color',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _availableColors.map((color) {
                  final isSelected = color == _selectedColor;
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedColor = color;
                      });
                    },
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Color(int.parse(color.replaceAll('#', '0xFF'))),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isSelected ? Colors.black : Colors.grey,
                          width: isSelected ? 3 : 1,
                        ),
                      ),
                    ),
                  );
                }).toList(),
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

  bool _isCitizenUser() {
    // Check if current user is a citizen (not a government officer)
    // This is a simplified check - in a real app, you'd check the user's role
    // For now, show tracking button to all users (citizens and officers)
    return true; // Allow all users to track projects for notifications
  }

  bool _isProjectTracked() {
    // Return the current tracking state
    return _isTracked;
  }

  Future<void> _checkTrackingStatus() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final projectId = widget.project['id'];
      final trackedProjectsRef = FirebaseFirestore.instance
          .collection('tracked_projects')
          .doc('${user.uid}_$projectId');

      final doc = await trackedProjectsRef.get();
      setState(() {
        _isTracked = doc.exists;
      });
    } catch (e) {
      print('Error checking tracking status: $e');
      setState(() {
        _isTracked = false;
      });
    }
  }

  Future<void> _toggleProjectTracking() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final projectId = widget.project['id'];
      final trackedProjectsRef = FirebaseFirestore.instance
          .collection('tracked_projects')
          .doc('${user.uid}_$projectId');

      if (_isProjectTracked()) {
        // Stop tracking
        await trackedProjectsRef.delete();
        setState(() {
          _isTracked = false;
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Stopped tracking this project'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      } else {
        // Start tracking
        await trackedProjectsRef.set({
          'userId': user.uid,
          'projectId': projectId,
          'projectTitle': widget.project['title'],
          'trackedAt': FieldValue.serverTimestamp(),
        });
        setState(() {
          _isTracked = true;
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Now tracking this project! You\'ll get notifications for updates.'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating tracking: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
