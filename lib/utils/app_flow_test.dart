import 'package:flutter/material.dart';
import 'onboarding_utils.dart';

class AppFlowTest {
  /// Show a dialog to test different app flow scenarios
  static void showTestDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('App Flow Test'),
        content: const Text('Choose a test scenario:'),
        actions: [
          TextButton(
            onPressed: () async {
              Navigator.of(context).pop();
              await OnboardingUtils.resetOnboardingStatus();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Onboarding status reset! Restart app to see onboarding.'),
                  backgroundColor: Colors.orange,
                ),
              );
            },
            child: const Text('Reset Onboarding\n(First Time User)'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Current flow: Returning user (no onboarding)'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            child: const Text('Current Flow\n(Returning User)'),
          ),
        ],
      ),
    );
  }
  
  /// Get current onboarding status for debugging
  static Future<String> getOnboardingStatus() async {
    final hasSeen = await OnboardingUtils.hasSeenOnboarding();
    return hasSeen ? 'Onboarding completed' : 'First time user';
  }
}
