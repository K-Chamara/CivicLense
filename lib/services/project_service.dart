import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ProjectService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Create a new project from a closed tender
  static Future<String> createProjectFromTender({
    required String tenderId,
    required Map<String, dynamic> tenderData,
    required String winningBidder,
    required double winningBidAmount,
  }) async {
    try {
      print('🏗️ Creating new project from tender: ${tenderData['title']}');
      
      // Generate unique project ID
      final projectId = 'PROJ_${DateTime.now().millisecondsSinceEpoch}';
      
      // Create comprehensive project data
      final projectData = {
        // Project identification
        'projectId': projectId,
        'projectName': tenderData['title'] ?? 'Untitled Project',
        'projectDescription': tenderData['description'] ?? 'Project converted from tender',
        'projectLocation': tenderData['location'] ?? 'To be specified',
        'projectCategory': tenderData['category'] ?? 'General',
        
        // Financial information
        'projectBudget': winningBidAmount, // Use winning bid amount
        'originalTenderBudget': tenderData['budget'] ?? 0.0, // Keep original tender budget
        'budgetVariance': (tenderData['budget'] ?? 0.0) - winningBidAmount, // Calculate variance
        'currency': 'USD',
        
        // Winning bidder information
        'winningBidder': {
          'name': winningBidder,
          'bidAmount': winningBidAmount,
          'awardedDate': FieldValue.serverTimestamp(),
          'contactInfo': '', // Will be populated later
        },
        'hasWinningBidder': true,
        
        // Project status and timeline
        'projectStatus': null, // Project starts with null status (shows NEW indicator)
        'projectPhase': 'initiation', // Project lifecycle phase
        'startDate': FieldValue.serverTimestamp(),
        'expectedCompletionDate': tenderData['deadline'] ?? '',
        'handoverDate': '', // Will be set later by project manager
        'actualCompletionDate': null,
        
        // Source tender information
        'sourceTender': {
          'tenderId': tenderId,
          'tenderTitle': tenderData['title'] ?? '',
          'tenderDescription': tenderData['description'] ?? '',
          'tenderLocation': tenderData['location'] ?? '',
          'tenderCategory': tenderData['category'] ?? '',
          'tenderBudget': tenderData['budget'] ?? 0.0,
          'tenderDeadline': tenderData['deadline'] ?? '',
          'tenderStatus': 'closed',
          'awardedTo': winningBidder,
          'awardedAmount': winningBidAmount,
          'awardedDate': FieldValue.serverTimestamp(),
        },
        
        // Project management information
        'projectManager': tenderData['createdBy'], // Assign to tender creator initially
        'assignedTeam': [], // Will be populated later
        'projectMilestones': [], // Will be populated as project progresses
        'projectDocuments': [], // Will be populated with project documents
        'projectTasks': [], // Will be populated with project tasks
        
        // Progress tracking
        'completionPercentage': 0, // Start at 0%
        'milestonesCompleted': 0,
        'totalMilestones': 0,
        'lastProgressUpdate': FieldValue.serverTimestamp(),
        
        // Audit and tracking
        'createdBy': tenderData['createdBy'],
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'lastActivity': FieldValue.serverTimestamp(),
        'version': 1, // Project version for tracking changes
        
        // Project metadata
        'projectType': 'tender_conversion', // Indicates this was created from a tender
        'priority': 'medium', // Default priority
        'riskLevel': 'low', // Default risk level
        'isActive': true,
        'isPublic': true, // Projects are visible to public
        'isArchived': false,
        
        // Quality and compliance
        'qualityStandards': [], // Will be populated with required standards
        'complianceRequirements': [], // Will be populated with compliance needs
        'inspectionSchedule': [], // Will be populated with inspection dates
        
        // Communication and reporting
        'stakeholders': [], // Will be populated with project stakeholders
        'reportingSchedule': 'monthly', // Default reporting frequency
        'lastReportDate': null,
        'nextReportDate': null,
      };

      // Create the project in the projects collection
      final projectRef = await _firestore
          .collection('projects')
          .add(projectData);

      print('✅ Project created successfully with ID: ${projectRef.id}');
      print('📊 Project Name: ${projectData['projectName']}');
      print('💰 Project Budget: \$${projectData['projectBudget']}');
      print('👤 Winning Bidder: ${projectData['winningBidder']['name']}');
      
      return projectRef.id;
    } catch (e) {
      print('❌ Error creating project from tender: $e');
      throw Exception('Failed to create project: $e');
    }
  }

  /// Get all projects
  static Future<List<Map<String, dynamic>>> getAllProjects() async {
    try {
      print('🔍 ProjectService: Fetching projects from Firestore...');
      
      final snapshot = await _firestore
          .collection('projects')
          .orderBy('createdAt', descending: true)
          .get();

      print('📊 ProjectService: Found ${snapshot.docs.length} projects in Firestore');
      
      final projects = snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        print('📋 Project: ${data['projectName']} (ID: ${doc.id})');
        return data;
      }).toList();
      
      print('✅ ProjectService: Successfully loaded ${projects.length} projects');
      return projects;
    } catch (e) {
      print('❌ Error getting projects: $e');
      throw Exception('Failed to get projects: $e');
    }
  }

  /// Get projects by status
  static Future<List<Map<String, dynamic>>> getProjectsByStatus(String status) async {
    try {
      final snapshot = await _firestore
          .collection('projects')
          .where('projectStatus', isEqualTo: status)
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();
    } catch (e) {
      print('❌ Error getting projects by status: $e');
      throw Exception('Failed to get projects by status: $e');
    }
  }

  /// Update project status
  static Future<void> updateProjectStatus(String projectId, String status) async {
    try {
      await _firestore.collection('projects').doc(projectId).update({
        'projectStatus': status,
        'updatedAt': FieldValue.serverTimestamp(),
        'lastActivity': FieldValue.serverTimestamp(),
      });
      print('✅ Project status updated to: $status');
    } catch (e) {
      print('❌ Error updating project status: $e');
      throw Exception('Failed to update project status: $e');
    }
  }

  /// Delete a project
  static Future<void> deleteProject(String projectId) async {
    try {
      await _firestore.collection('projects').doc(projectId).delete();
      print('✅ Project deleted: $projectId');
    } catch (e) {
      print('❌ Error deleting project: $e');
      throw Exception('Failed to delete project: $e');
    }
  }

  /// Get project count by status
  static Future<Map<String, int>> getProjectCounts() async {
    try {
      final snapshot = await _firestore.collection('projects').get();
      
      Map<String, int> counts = {
        'total': 0,
        'ongoing': 0,
        'completed': 0,
        'delayed': 0,
        'cancelled': 0,
      };

      for (final doc in snapshot.docs) {
        final data = doc.data();
        final status = data['projectStatus'] ?? 'ongoing';
        
        counts['total'] = (counts['total'] ?? 0) + 1;
        counts[status] = (counts[status] ?? 0) + 1;
      }

      return counts;
    } catch (e) {
      print('❌ Error getting project counts: $e');
      return {
        'total': 0,
        'ongoing': 0,
        'completed': 0,
        'delayed': 0,
        'cancelled': 0,
      };
    }
  }

  /// Create a test project for debugging
  static Future<String> createTestProject() async {
    try {
      print('🧪 Creating test project...');
      
      final projectData = {
        'projectId': 'TEST_PROJ_${DateTime.now().millisecondsSinceEpoch}',
        'projectName': 'Test Infrastructure Project',
        'projectDescription': 'This is a test project to verify the projects table connection',
        'projectLocation': 'Test City',
        'projectCategory': 'Infrastructure Development',
        'projectBudget': 50000.0,
        'originalTenderBudget': 60000.0,
        'budgetVariance': 10000.0,
        'winningBidder': {
          'name': 'Test Construction Co.',
          'bidAmount': 50000.0,
          'awardedDate': FieldValue.serverTimestamp(),
        },
        'hasWinningBidder': true,
        'projectStatus': 'ongoing',
        'projectPhase': 'initiation',
        'startDate': FieldValue.serverTimestamp(),
        'expectedCompletionDate': '2024-12-31',
        'handoverDate': '',
        'sourceTender': {
          'tenderId': 'TEST_TENDER_123',
          'tenderTitle': 'Test Infrastructure Project',
          'tenderDescription': 'Test tender description',
          'tenderLocation': 'Test City',
          'tenderCategory': 'Infrastructure Development',
          'tenderBudget': 60000.0,
          'tenderDeadline': '2024-12-31',
          'tenderStatus': 'closed',
          'awardedTo': 'Test Construction Co.',
          'awardedAmount': 50000.0,
          'awardedDate': FieldValue.serverTimestamp(),
        },
        'projectManager': 'test_user_id',
        'assignedTeam': [],
        'projectMilestones': [],
        'projectDocuments': [],
        'projectTasks': [],
        'completionPercentage': 0,
        'milestonesCompleted': 0,
        'totalMilestones': 0,
        'lastProgressUpdate': FieldValue.serverTimestamp(),
        'createdBy': 'test_user_id',
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'lastActivity': FieldValue.serverTimestamp(),
        'version': 1,
        'projectType': 'test_project',
        'priority': 'medium',
        'riskLevel': 'low',
        'isActive': true,
        'isPublic': true,
        'isArchived': false,
        'qualityStandards': [],
        'complianceRequirements': [],
        'inspectionSchedule': [],
        'stakeholders': [],
        'reportingSchedule': 'monthly',
        'lastReportDate': null,
        'nextReportDate': null,
      };

      final projectRef = await _firestore
          .collection('projects')
          .add(projectData);

      print('✅ Test project created successfully with ID: ${projectRef.id}');
      return projectRef.id;
    } catch (e) {
      print('❌ Error creating test project: $e');
      throw Exception('Failed to create test project: $e');
    }
  }
}
