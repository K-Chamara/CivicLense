import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class SampleDataCreator {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Create sample awarded projects for testing
  static Future<void> createSampleAwardedProjects() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        print('❌ No user logged in');
        return;
      }

      final awardedProjects = [
        {
          'title': 'Smart City Infrastructure',
          'projectName': 'Digital City Initiative',
          'projectLocation': 'Tech Hub District, Bangalore',
          'description': 'Implementation of smart city infrastructure including IoT sensors, data analytics, and citizen services platform.',
          'budget': 8000000.0,
          'deadline': '2024-09-30',
          'category': 'Technology',
          'region': 'South',
          'status': 'closed',
          'createdBy': user.uid,
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
          'bids': [],
          'progress': 0.0,
          'totalBids': 0,
          'lowestBid': null,
          'highestBid': null,
          'awardedTo': 'TechCorp Solutions',
          'awardedAmount': 7500000.0,
          'awardedDate': Timestamp.fromDate(DateTime.now().subtract(const Duration(days: 5))),
        },
        {
          'title': 'Water Treatment Plant',
          'projectName': 'Clean Water Initiative',
          'projectLocation': 'Industrial Zone, Mumbai',
          'description': 'Construction of modern water treatment facility with advanced filtration systems for industrial use.',
          'budget': 12000000.0,
          'deadline': '2024-11-15',
          'category': 'Infrastructure',
          'region': 'West',
          'status': 'closed',
          'createdBy': user.uid,
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
          'bids': [],
          'progress': 0.0,
          'totalBids': 0,
          'lowestBid': null,
          'highestBid': null,
          'awardedTo': 'AquaTech Engineering',
          'awardedAmount': 11200000.0,
          'awardedDate': Timestamp.fromDate(DateTime.now().subtract(const Duration(days: 12))),
        },
      ];

      for (final project in awardedProjects) {
        await _firestore.collection('tenders').add(project);
      }

      print('✅ Sample awarded projects created successfully');
    } catch (e) {
      print('❌ Error creating sample awarded projects: $e');
    }
  }

  // Create sample tenders for testing
  static Future<void> createSampleTenders() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        print('❌ No user logged in');
        return;
      }

      final sampleTenders = [
        {
          'title': 'IT Infrastructure Upgrade Project',
          'projectName': 'Government IT Modernization',
          'projectLocation': 'Central Government Complex, New Delhi',
          'description': 'Comprehensive upgrade of government IT infrastructure including servers, networking equipment, and software licenses.',
          'budget': 5000000.0, // 50 Lakhs
          'deadline': '2024-06-15',
          'category': 'IT Services',
          'region': 'Central',
          'status': 'active',
          'createdBy': user.uid,
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
          'bids': [],
          'progress': 0.0,
          'totalBids': 0,
          'lowestBid': null,
          'highestBid': null,
          'awardedTo': null,
          'awardedAmount': null,
          'awardedDate': null,
        },
        {
          'title': 'Office Supplies Procurement',
          'projectName': 'Government Office Supplies',
          'projectLocation': 'Various Government Offices, Mumbai',
          'description': 'Procurement of office supplies including paper, pens, furniture, and electronic equipment for government departments.',
          'budget': 2500000.0, // 25 Lakhs
          'deadline': '2024-05-20',
          'category': 'Office Supplies',
          'region': 'West',
          'status': 'active',
          'createdBy': user.uid,
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
          'bids': [],
          'progress': 0.0,
          'totalBids': 0,
          'lowestBid': null,
          'highestBid': null,
          'awardedTo': null,
          'awardedAmount': null,
          'awardedDate': null,
        },
        {
          'title': 'Security Services Contract',
          'projectName': 'Government Building Security',
          'projectLocation': 'Government Buildings, Bangalore',
          'description': 'Provision of security services including guards, surveillance systems, and access control for government buildings.',
          'budget': 8000000.0, // 80 Lakhs
          'deadline': '2024-07-10',
          'category': 'Security Services',
          'region': 'South',
          'status': 'active',
          'createdBy': user.uid,
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
          'bids': [],
          'progress': 0.0,
          'totalBids': 0,
          'lowestBid': null,
          'highestBid': null,
          'awardedTo': null,
          'awardedAmount': null,
          'awardedDate': null,
        },
        {
          'title': 'Vehicle Maintenance Services',
          'projectName': 'Government Fleet Maintenance',
          'projectLocation': 'Government Transport Department, Chennai',
          'description': 'Comprehensive maintenance services for government vehicle fleet including repairs, servicing, and spare parts.',
          'budget': 3500000.0, // 35 Lakhs
          'deadline': '2024-06-30',
          'category': 'Vehicle Maintenance',
          'region': 'South',
          'status': 'closed',
          'createdBy': user.uid,
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
          'bids': [],
          'progress': 0.0,
          'totalBids': 0,
          'lowestBid': null,
          'highestBid': null,
          'awardedTo': 'AutoCare Solutions Ltd.',
          'awardedAmount': 3200000.0,
          'awardedDate': Timestamp.fromDate(DateTime.now().subtract(const Duration(days: 15))),
        },
        {
          'title': 'Healthcare Equipment Procurement',
          'projectName': 'Government Hospital Equipment',
          'projectLocation': 'Government Hospitals, Kolkata',
          'description': 'Procurement of medical equipment and supplies for government hospitals and healthcare facilities.',
          'budget': 15000000.0, // 1.5 Crores
          'deadline': '2024-08-15',
          'category': 'Healthcare',
          'region': 'East',
          'status': 'closed',
          'createdBy': user.uid,
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
          'bids': [],
          'progress': 0.0,
          'totalBids': 0,
          'lowestBid': null,
          'highestBid': null,
          'awardedTo': 'MedTech Solutions Pvt Ltd',
          'awardedAmount': 14200000.0,
          'awardedDate': Timestamp.fromDate(DateTime.now().subtract(const Duration(days: 8))),
        },
        {
          'title': 'Road Construction Project',
          'projectName': 'Highway Development Phase 2',
          'projectLocation': 'National Highway 44, Karnataka',
          'description': 'Construction and maintenance of 50km stretch of national highway with modern infrastructure.',
          'budget': 25000000.0, // 2.5 Crores
          'deadline': '2024-12-31',
          'category': 'Infrastructure',
          'region': 'South',
          'status': 'closed',
          'createdBy': user.uid,
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
          'bids': [],
          'progress': 0.0,
          'totalBids': 0,
          'lowestBid': null,
          'highestBid': null,
          'awardedTo': 'InfraBuild Construction Ltd',
          'awardedAmount': 23800000.0,
          'awardedDate': Timestamp.fromDate(DateTime.now().subtract(const Duration(days: 3))),
        },
      ];

      for (final tender in sampleTenders) {
        await _firestore.collection('tenders').add(tender);
      }

      print('✅ Sample tenders created successfully');
    } catch (e) {
      print('❌ Error creating sample tenders: $e');
      rethrow;
    }
  }

  // Create sample bids for testing
  static Future<void> createSampleBids() async {
    try {
      // Get the first tender to add bids to
      final tenderQuery = await _firestore.collection('tenders').limit(1).get();
      if (tenderQuery.docs.isEmpty) {
        print('❌ No tenders found to add bids to');
        return;
      }

      final tenderId = tenderQuery.docs.first.id;
      final tenderData = tenderQuery.docs.first.data();
      final budget = tenderData['budget'] as double;

      final sampleBids = [
        {
          'tenderId': tenderId,
          'bidderName': 'Tech Solutions Ltd.',
          'bidderEmail': 'bids@techsolutions.com',
          'bidAmount': budget * 0.85, // 15% below budget
          'proposal': 'Comprehensive IT infrastructure solution with 24/7 support and 3-year warranty.',
          'submittedAt': FieldValue.serverTimestamp(),
          'status': 'pending',
        },
        {
          'tenderId': tenderId,
          'bidderName': 'Digital Systems Corp.',
          'bidderEmail': 'info@digitalsystems.com',
          'bidAmount': budget * 0.90, // 10% below budget
          'proposal': 'Advanced IT infrastructure with cloud integration and cybersecurity features.',
          'submittedAt': FieldValue.serverTimestamp(),
          'status': 'pending',
        },
        {
          'tenderId': tenderId,
          'bidderName': 'Innovation Tech Pvt Ltd.',
          'bidderEmail': 'contact@innovationtech.com',
          'bidAmount': budget * 0.95, // 5% below budget
          'proposal': 'Complete IT modernization with AI-powered monitoring and analytics.',
          'submittedAt': FieldValue.serverTimestamp(),
          'status': 'pending',
        },
      ];

      for (final bid in sampleBids) {
        await _firestore.collection('bids').add(bid);
      }

      // Update tender with bid statistics
      final bids = sampleBids.map((b) => b['bidAmount'] as double).toList();
      final lowestBid = bids.reduce((a, b) => a < b ? a : b);
      final highestBid = bids.reduce((a, b) => a > b ? a : b);

      await _firestore.collection('tenders').doc(tenderId).update({
        'totalBids': sampleBids.length,
        'lowestBid': lowestBid,
        'highestBid': highestBid,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      print('✅ Sample bids created successfully');
    } catch (e) {
      print('❌ Error creating sample bids: $e');
      rethrow;
    }
  }

  // Create sample notifications
  static Future<void> createSampleNotifications() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        print('❌ No user logged in');
        return;
      }

      final sampleNotifications = [
        {
          'userId': user.uid,
          'title': 'New Tender Published',
          'message': 'A new tender for IT Infrastructure Upgrade has been published.',
          'type': 'tender',
          'isRead': false,
          'createdAt': FieldValue.serverTimestamp(),
          'tenderId': null,
        },
        {
          'userId': user.uid,
          'title': 'Bid Received',
          'message': 'Tech Solutions Ltd. has submitted a bid for IT Infrastructure Upgrade.',
          'type': 'bid',
          'isRead': false,
          'createdAt': FieldValue.serverTimestamp(),
          'tenderId': null,
        },
        {
          'userId': user.uid,
          'title': 'Deadline Approaching',
          'message': 'Vehicle Maintenance Services tender closes in 3 days.',
          'type': 'reminder',
          'isRead': true,
          'createdAt': FieldValue.serverTimestamp(),
          'tenderId': null,
        },
        {
          'userId': user.uid,
          'title': 'Tender Awarded',
          'message': 'Healthcare Equipment Procurement has been awarded to Medical Supplies Co.',
          'type': 'award',
          'isRead': false,
          'createdAt': FieldValue.serverTimestamp(),
          'tenderId': null,
        },
      ];

      for (final notification in sampleNotifications) {
        await _firestore.collection('notifications').add(notification);
      }

      print('✅ Sample notifications created successfully');
    } catch (e) {
      print('❌ Error creating sample notifications: $e');
      rethrow;
    }
  }

  // Create sample project timeline
  static Future<void> createSampleTimeline() async {
    try {
      // Get the first tender to add timeline to
      final tenderQuery = await _firestore.collection('tenders').limit(1).get();
      if (tenderQuery.docs.isEmpty) {
        print('❌ No tenders found to add timeline to');
        return;
      }

      final tenderId = tenderQuery.docs.first.id;

      final sampleMilestones = [
        {
          'tenderId': tenderId,
          'milestone': 'Project Planning',
          'completionDate': '2024-04-15',
          'isCompleted': true,
          'actualCompletionDate': '2024-04-12',
          'createdAt': FieldValue.serverTimestamp(),
        },
        {
          'tenderId': tenderId,
          'milestone': 'Infrastructure Assessment',
          'completionDate': '2024-04-30',
          'isCompleted': true,
          'actualCompletionDate': '2024-04-28',
          'createdAt': FieldValue.serverTimestamp(),
        },
        {
          'tenderId': tenderId,
          'milestone': 'Equipment Procurement',
          'completionDate': '2024-05-15',
          'isCompleted': false,
          'actualCompletionDate': null,
          'createdAt': FieldValue.serverTimestamp(),
        },
        {
          'tenderId': tenderId,
          'milestone': 'Installation & Testing',
          'completionDate': '2024-06-01',
          'isCompleted': false,
          'actualCompletionDate': null,
          'createdAt': FieldValue.serverTimestamp(),
        },
        {
          'tenderId': tenderId,
          'milestone': 'Final Handover',
          'completionDate': '2024-06-15',
          'isCompleted': false,
          'actualCompletionDate': null,
          'createdAt': FieldValue.serverTimestamp(),
        },
      ];

      for (final milestone in sampleMilestones) {
        await _firestore.collection('project_timeline').add(milestone);
      }

      print('✅ Sample project timeline created successfully');
    } catch (e) {
      print('❌ Error creating sample timeline: $e');
      rethrow;
    }
  }

  // Create all sample data
  static Future<void> createAllSampleData() async {
    try {
      print('🚀 Creating sample data...');
      
      await createSampleTenders();
      await createSampleBids();
      await createSampleNotifications();
      await createSampleTimeline();
      
      print('✅ All sample data created successfully!');
    } catch (e) {
      print('❌ Error creating sample data: $e');
      rethrow;
    }
  }
}
