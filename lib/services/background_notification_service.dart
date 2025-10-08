import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'notification_service.dart';

class BackgroundNotificationService {
  final NotificationService _notificationService = NotificationService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Check for projects with approaching due dates and create notifications
  Future<void> checkAndCreateDueDateNotifications() async {
    try {
      print('🔔 Checking for project due dates...');
      
      final now = DateTime.now();
      final threeDaysFromNow = now.add(const Duration(days: 3));
      final oneWeekFromNow = now.add(const Duration(days: 7));

      // Get all projects
      final projectsSnapshot = await _firestore.collection('projects').get();
      int notificationsCreated = 0;
      
      for (final projectDoc in projectsSnapshot.docs) {
        final projectData = projectDoc.data();
        final deadline = projectData['deadline'] as String?;
        final createdBy = projectData['createdBy'] as String?;
        final projectTitle = projectData['tenderTitle'] ?? 'Unknown Project';
        
        if (deadline != null && createdBy != null) {
          try {
            final deadlineDate = DateTime.parse(deadline);
            
            // Check if deadline is within 3 days (urgent)
            if (deadlineDate.isBefore(threeDaysFromNow) && deadlineDate.isAfter(now)) {
              final daysLeft = deadlineDate.difference(now).inDays + 1;
              
              await NotificationService.createNotification(
                userId: createdBy,
                title: '🚨 Project Deadline Approaching',
                body: 'Project "$projectTitle" is due in $daysLeft day${daysLeft == 1 ? '' : 's'}! Please take action.',
                type: 'deadline_alert',
                data: {
                  'projectId': projectDoc.id,
                  'priority': 'high',
                },
              );
              
              notificationsCreated++;
              print('📢 Created urgent deadline notification for project: $projectTitle');
            }
            // Check if deadline is within 1 week (reminder)
            else if (deadlineDate.isBefore(oneWeekFromNow) && deadlineDate.isAfter(threeDaysFromNow)) {
              final daysLeft = deadlineDate.difference(now).inDays + 1;
              
              await NotificationService.createNotification(
                userId: createdBy,
                title: '⏰ Project Deadline Reminder',
                body: 'Project "$projectTitle" is due in $daysLeft day${daysLeft == 1 ? '' : 's'}. Please review progress.',
                type: 'deadline_reminder',
                data: {
                  'projectId': projectDoc.id,
                  'priority': 'normal',
                },
              );
              
              notificationsCreated++;
              print('📢 Created deadline reminder for project: $projectTitle');
            }
          } catch (e) {
            print('❌ Error parsing deadline for project ${projectDoc.id}: $e');
          }
        }
      }
      
      print('✅ Due date check completed. Created $notificationsCreated notifications.');
    } catch (e) {
      print('❌ Error checking project due dates: $e');
    }
  }

  /// Check for overdue projects and create notifications
  Future<void> checkOverdueProjects() async {
    try {
      print('🔔 Checking for overdue projects...');
      
      final now = DateTime.now();
      final projectsSnapshot = await _firestore.collection('projects').get();
      int overdueNotificationsCreated = 0;
      
      for (final projectDoc in projectsSnapshot.docs) {
        final projectData = projectDoc.data();
        final deadline = projectData['deadline'] as String?;
        final createdBy = projectData['createdBy'] as String?;
        final projectTitle = projectData['tenderTitle'] ?? 'Unknown Project';
        
        if (deadline != null && createdBy != null) {
          try {
            final deadlineDate = DateTime.parse(deadline);
            
            // Check if project is overdue
            if (deadlineDate.isBefore(now)) {
              final daysOverdue = now.difference(deadlineDate).inDays;
              
              await NotificationService.createNotification(
                userId: createdBy,
                title: '⚠️ Project Overdue',
                body: 'Project "$projectTitle" is $daysOverdue day${daysOverdue == 1 ? '' : 's'} overdue! Please update status.',
                type: 'overdue_alert',
                data: {
                  'projectId': projectDoc.id,
                  'priority': 'high',
                },
              );
              
              overdueNotificationsCreated++;
              print('📢 Created overdue notification for project: $projectTitle');
            }
          } catch (e) {
            print('❌ Error parsing deadline for overdue project ${projectDoc.id}: $e');
          }
        }
      }
      
      print('✅ Overdue check completed. Created $overdueNotificationsCreated notifications.');
    } catch (e) {
      print('❌ Error checking overdue projects: $e');
    }
  }

  /// Run all notification checks
  Future<void> runAllNotificationChecks() async {
    print('🚀 Running all notification checks...');
    
    await checkAndCreateDueDateNotifications();
    await checkOverdueProjects();
    
    print('✅ All notification checks completed.');
  }
}
