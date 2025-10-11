import 'package:flutter/material.dart';
import '../utils/test_notifications.dart';

/// Widget to test push notifications
/// Add this to any screen during development
class NotificationTestWidget extends StatelessWidget {
  const NotificationTestWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.science, color: Colors.blue),
                const SizedBox(width: 8),
                Text(
                  '🧪 Notification Testing',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Run all tests
            ElevatedButton.icon(
              onPressed: () async {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Running notification tests...')),
                );
                
                final results = await NotificationTester.runAllTests();
                
                final allPassed = results.values.every((passed) => passed);
                
                if (context.mounted) {
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: Row(
                        children: [
                          Icon(
                            allPassed ? Icons.check_circle : Icons.error,
                            color: allPassed ? Colors.green : Colors.red,
                          ),
                          const SizedBox(width: 8),
                          Text(allPassed ? 'All Tests Passed!' : 'Some Tests Failed'),
                        ],
                      ),
                      content: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: results.entries.map((entry) {
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            child: Row(
                              children: [
                                Icon(
                                  entry.value ? Icons.check : Icons.close,
                                  color: entry.value ? Colors.green : Colors.red,
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Expanded(child: Text(entry.key)),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('OK'),
                        ),
                      ],
                    ),
                  );
                }
              },
              icon: const Icon(Icons.play_arrow),
              label: const Text('Run All Tests'),
            ),
            
            const SizedBox(height: 8),
            
            // Individual tests
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                OutlinedButton(
                  onPressed: () async {
                    final result = await NotificationTester.testFCMTokenSaved();
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(result 
                            ? '✅ FCM Token is saved' 
                            : '❌ FCM Token not saved'),
                          backgroundColor: result ? Colors.green : Colors.red,
                        ),
                      );
                    }
                  },
                  child: const Text('Check Token'),
                ),
                OutlinedButton(
                  onPressed: () async {
                    final result = await NotificationTester.testSendNotification();
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(result 
                            ? '✅ Test notification sent' 
                            : '❌ Failed to send'),
                          backgroundColor: result ? Colors.green : Colors.red,
                        ),
                      );
                    }
                  },
                  child: const Text('Send Test'),
                ),
                OutlinedButton(
                  onPressed: () async {
                    final count = await NotificationTester.testUnreadNotificationCount();
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('📬 Unread notifications: $count'),
                          backgroundColor: Colors.blue,
                        ),
                      );
                    }
                  },
                  child: const Text('Check Unread'),
                ),
              ],
            ),
            
            const SizedBox(height: 8),
            
            Text(
              'Note: Check console for detailed logs',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.grey,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

