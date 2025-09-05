import 'package:flutter/material.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import '../utils/onboarding_utils.dart';
import 'login_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final controller = PageController();
  bool isLastPage = false;

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        padding: const EdgeInsets.only(bottom: 80),
        child: PageView(
          controller: controller,
          onPageChanged: (index) {
            setState(() {
              isLastPage = index == 2;
            });
          },
          children: [
            _buildOnboardingPage(
              title: 'Transparency in Public Spending',
              description: 'Track government budgets, tenders, and projects with complete transparency. Know where your tax money goes.',
              image: Icons.account_balance,
              color: Colors.blue,
            ),
            _buildOnboardingPage(
              title: 'Community Engagement',
              description: 'Join communities, raise concerns, and collaborate with other citizens, journalists, and researchers.',
              image: Icons.people,
              color: Colors.green,
            ),
            _buildOnboardingPage(
              title: 'Data-Driven Insights',
              description: 'Access comprehensive reports, analytics, and research data to make informed decisions.',
              image: Icons.analytics,
              color: Colors.orange,
            ),
          ],
        ),
      ),
      bottomSheet: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        height: 80,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            TextButton(
              onPressed: () async {
                // Mark onboarding as completed when skipping
                await OnboardingUtils.markOnboardingCompleted();
                
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(
                    builder: (context) => const LoginScreen(),
                  ),
                );
              },
              child: const Text('Skip'),
            ),
            Center(
              child: SmoothPageIndicator(
                controller: controller,
                count: 3,
                effect: const WormEffect(
                  spacing: 16,
                  dotColor: Colors.black26,
                  activeDotColor: Colors.blue,
                ),
                onDotClicked: (index) => controller.animateToPage(
                  index,
                  duration: const Duration(milliseconds: 500),
                  curve: Curves.easeInOut,
                ),
              ),
            ),
            TextButton(
              onPressed: () async {
                if (isLastPage) {
                  // Mark onboarding as completed
                  await OnboardingUtils.markOnboardingCompleted();
                  
                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute(
                      builder: (context) => const LoginScreen(),
                    ),
                  );
                } else {
                  controller.nextPage(
                    duration: const Duration(milliseconds: 500),
                    curve: Curves.easeInOut,
                  );
                }
              },
              child: Text(
                isLastPage ? 'Done' : 'Next',
                style: const TextStyle(fontSize: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOnboardingPage({
    required String title,
    required String description,
    required IconData image,
    required Color color,
  }) {
    return Padding(
      padding: const EdgeInsets.all(40),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            image,
            size: 100,
            color: color,
          ),
          const SizedBox(height: 40),
          Text(
            title,
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          Text(
            description,
            style: const TextStyle(
              fontSize: 16,
              color: Colors.grey,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}



