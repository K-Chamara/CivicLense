import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:math' as math;
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import '../utils/onboarding_utils.dart';
import 'welcome_screen.dart';

class EnhancedOnboardingScreen extends StatefulWidget {
  const EnhancedOnboardingScreen({super.key});

  @override
  State<EnhancedOnboardingScreen> createState() => _EnhancedOnboardingScreenState();
}

class _EnhancedOnboardingScreenState extends State<EnhancedOnboardingScreen>
    with TickerProviderStateMixin {
  final PageController _pageController = PageController();
  final List<OnboardingData> _onboardingData = [
    OnboardingData(
      title: 'Transparency in Action',
      subtitle: 'Government Spending Made Visible',
      description: 'Track every dollar, every tender, every project. Your tax money deserves complete transparency.',
      icon: Icons.visibility_rounded,
      gradient: const LinearGradient(
        colors: [Color(0xFF1E40AF), Color(0xFF3B82F6)], // Blue gradient
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      primaryColor: const Color(0xFF1E40AF), // Blue-800
      animationType: AnimationType.floating,
    ),
    OnboardingData(
      title: 'Community Power',
      subtitle: 'Citizens United for Change',
      description: 'Join forces with journalists, researchers, and fellow citizens to hold government accountable.',
      icon: Icons.groups_rounded,
      gradient: const LinearGradient(
        colors: [Color(0xFF059669), Color(0xFF10B981)], // Emerald green gradient (complements blue)
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      primaryColor: const Color(0xFF1E40AF), // Blue-800 for text
      animationType: AnimationType.pulse,
    ),
    OnboardingData(
      title: 'Data-Driven Democracy',
      subtitle: 'Insights That Matter',
      description: 'Access comprehensive analytics, reports, and research to make informed decisions about your community.',
      icon: Icons.analytics_rounded,
      gradient: const LinearGradient(
        colors: [Color(0xFF7C3AED), Color(0xFF8B5CF6)], // Purple gradient (complements blue)
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      primaryColor: const Color(0xFF1E40AF), // Blue-800 for text
      animationType: AnimationType.rotation,
    ),
  ];

  int _currentPage = 0;
  bool _isLastPage = false;

  // Animation controllers
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late AnimationController _scaleController;
  late AnimationController _rotationController;
  late AnimationController _particleController;
  late AnimationController _gradientController;

  // Animations
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _rotationAnimation;
  late Animation<double> _particleAnimation;
  late Animation<double> _gradientAnimation;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _startAnimations();
  }

  void _initializeAnimations() {
    // Fade animation
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    ));

    // Slide animation
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutBack,
    ));

    // Scale animation
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 0.5,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _scaleController,
      curve: Curves.elasticOut,
    ));

    // Rotation animation
    _rotationController = AnimationController(
      duration: const Duration(seconds: 8),
      vsync: this,
    );
    _rotationAnimation = Tween<double>(
      begin: 0.0,
      end: 2 * math.pi,
    ).animate(CurvedAnimation(
      parent: _rotationController,
      curve: Curves.linear,
    ));

    // Particle animation
    _particleController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    );
    _particleAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _particleController,
      curve: Curves.easeInOut,
    ));

    // Gradient animation
    _gradientController = AnimationController(
      duration: const Duration(seconds: 4),
      vsync: this,
    );
    _gradientAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _gradientController,
      curve: Curves.easeInOut,
    ));
  }

  void _startAnimations() {
    _fadeController.forward();
    _slideController.forward();
    _scaleController.forward();
    _rotationController.repeat();
    _particleController.repeat(reverse: true);
    _gradientController.repeat(reverse: true);
  }

  @override
  void dispose() {
    _pageController.dispose();
    _fadeController.dispose();
    _slideController.dispose();
    _scaleController.dispose();
    _rotationController.dispose();
    _particleController.dispose();
    _gradientController.dispose();
    super.dispose();
  }

  void _onPageChanged(int index) {
    setState(() {
      _currentPage = index;
      _isLastPage = index == _onboardingData.length - 1;
    });
    
    // Reset and restart animations for new page
    _fadeController.reset();
    _slideController.reset();
    _scaleController.reset();
    _startAnimations();
  }

  void _nextPage() {
    if (_isLastPage) {
      _completeOnboarding();
    } else {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 600),
        curve: Curves.easeInOutCubic,
      );
    }
  }

  void _previousPage() {
    if (_currentPage > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 600),
        curve: Curves.easeInOutCubic,
      );
    }
  }

  Future<void> _completeOnboarding() async {
    await OnboardingUtils.markOnboardingCompleted();
    if (mounted) {
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) => const WelcomeScreen(),
          transitionDuration: const Duration(milliseconds: 800),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(
              opacity: animation,
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0, 0.1),
                  end: Offset.zero,
                ).animate(CurvedAnimation(
                  parent: animation,
                  curve: Curves.easeOutCubic,
                )),
                child: child,
              ),
            );
          },
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Skip button
              Padding(
                padding: const EdgeInsets.all(20),
                child: Align(
                  alignment: Alignment.topRight,
                  child: FadeTransition(
                    opacity: _fadeAnimation,
                    child: TextButton(
                      onPressed: _completeOnboarding,
                      style: TextButton.styleFrom(
                        foregroundColor: _onboardingData[_currentPage].primaryColor,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      ),
                      child: Text(
                        'Skip',
                        style: TextStyle(
                          color: _onboardingData[_currentPage].primaryColor,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              
              // Main content
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  onPageChanged: _onPageChanged,
                  itemCount: _onboardingData.length,
                  itemBuilder: (context, index) {
                    return _buildOnboardingPage(_onboardingData[index], index);
                  },
                ),
              ),
              
              // Bottom section
              _buildBottomSection(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOnboardingPage(OnboardingData data, int index) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 30),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Animated background particles
          _buildParticleBackground(),
          
          // Main icon with animation
          _buildAnimatedIcon(data, index),
          
          const SizedBox(height: 60),
          
          // Title with slide animation
          SlideTransition(
            position: _slideAnimation,
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: Column(
                children: [
                  ShaderMask(
                    shaderCallback: (bounds) => data.gradient.createShader(bounds),
                    child: Text(
                      data.title,
                      style: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    data.subtitle,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                      color: data.primaryColor,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 30),
          
          // Description with fade animation
          FadeTransition(
            opacity: _fadeAnimation,
            child: Text(
              data.description,
              style: const TextStyle(
                fontSize: 16,
                color: Color(0xFF64748B), // Slate-500 for better contrast
                height: 1.6,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          
          const SizedBox(height: 40),
          
          // Feature highlights
          _buildFeatureHighlights(data),
        ],
      ),
    );
  }

  Widget _buildAnimatedIcon(OnboardingData data, int index) {
    switch (data.animationType) {
      case AnimationType.floating:
        return _buildFloatingIcon(data);
      case AnimationType.pulse:
        return _buildPulseIcon(data);
      case AnimationType.rotation:
        return _buildRotationIcon(data);
    }
  }

  Widget _buildFloatingIcon(OnboardingData data) {
    return AnimatedBuilder(
      animation: _particleAnimation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(
            0,
            math.sin(_particleAnimation.value * 2 * math.pi) * 10,
          ),
          child: ScaleTransition(
            scale: _scaleAnimation,
            child: Container(
              width: 160,
              height: 160,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: data.gradient,
                boxShadow: [
                  BoxShadow(
                    color: data.primaryColor.withOpacity(0.2),
                    blurRadius: 30,
                    spreadRadius: 5,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Icon(
                data.icon,
                size: 80,
                color: Colors.white,
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildPulseIcon(OnboardingData data) {
    return AnimatedBuilder(
      animation: _particleAnimation,
      builder: (context, child) {
        return ScaleTransition(
          scale: Tween<double>(
            begin: 1.0,
            end: 1.1,
          ).animate(CurvedAnimation(
            parent: _particleController,
            curve: Curves.easeInOut,
          )),
          child: Container(
            width: 160,
            height: 160,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: data.gradient,
              boxShadow: [
                BoxShadow(
                  color: data.primaryColor.withOpacity(0.25),
                  blurRadius: 40,
                  spreadRadius: _particleAnimation.value * 8,
                ),
              ],
            ),
            child: Icon(
              data.icon,
              size: 80,
              color: Colors.white,
            ),
          ),
        );
      },
    );
  }

  Widget _buildRotationIcon(OnboardingData data) {
    return AnimatedBuilder(
      animation: _rotationAnimation,
      builder: (context, child) {
        return Transform.rotate(
          angle: _rotationAnimation.value,
          child: Container(
            width: 160,
            height: 160,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: data.gradient,
              boxShadow: [
                BoxShadow(
                  color: data.primaryColor.withOpacity(0.2),
                  blurRadius: 30,
                  spreadRadius: 5,
                ),
              ],
            ),
            child: Icon(
              data.icon,
              size: 80,
              color: Colors.white,
            ),
          ),
        );
      },
    );
  }

  Widget _buildParticleBackground() {
    return AnimatedBuilder(
      animation: _particleAnimation,
      builder: (context, child) {
        return CustomPaint(
          painter: ParticlePainter(
            animation: _particleAnimation,
            color: _onboardingData[_currentPage].primaryColor,
          ),
        );
      },
    );
  }

  Widget _buildFeatureHighlights(OnboardingData data) {
    List<String> features = [];
    
    switch (data.animationType) {
      case AnimationType.floating:
        features = ['Real-time Tracking', 'Budget Transparency', 'Spending Analysis'];
        break;
      case AnimationType.pulse:
        features = ['Community Forums', 'Collaborative Research', 'Public Discussions'];
        break;
      case AnimationType.rotation:
        features = ['Advanced Analytics', 'Data Visualization', 'Research Reports'];
        break;
    }

    return FadeTransition(
      opacity: _fadeAnimation,
      child: Column(
        children: features.map((feature) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  color: data.primaryColor,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                feature,
                style: TextStyle(
                  fontSize: 14,
                  color: data.primaryColor,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        )).toList(),
      ),
    );
  }

  Widget _buildBottomSection() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 20),
      child: Column(
        children: [
          // Page indicator
          SmoothPageIndicator(
            controller: _pageController,
            count: _onboardingData.length,
            effect: ExpandingDotsEffect(
              activeDotColor: _onboardingData[_currentPage].primaryColor,
              dotColor: const Color(0xFFE2E8F0), // Slate-200 for inactive dots
              dotHeight: 8,
              dotWidth: 8,
              expansionFactor: 4,
              spacing: 8,
            ),
          ),
          
          const SizedBox(height: 30),
          
          // Navigation buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Previous button
              if (_currentPage > 0)
                FadeTransition(
                  opacity: _fadeAnimation,
                  child: TextButton.icon(
                    onPressed: _previousPage,
                    icon: const Icon(Icons.arrow_back_ios),
                    label: const Text('Previous'),
                    style: TextButton.styleFrom(
                      foregroundColor: const Color(0xFF64748B), // Slate-500
                    ),
                  ),
                )
              else
                const SizedBox(width: 100),
              
              // Next/Get Started button
              FadeTransition(
                opacity: _fadeAnimation,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: _onboardingData[_currentPage].gradient,
                    borderRadius: BorderRadius.circular(25),
                    boxShadow: [
                      BoxShadow(
                        color: _onboardingData[_currentPage].primaryColor.withOpacity(0.3),
                        blurRadius: 15,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: ElevatedButton(
                    onPressed: _nextPage,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(25),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _isLastPage ? 'Get Started' : 'Next',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Icon(
                          _isLastPage ? Icons.rocket_launch : Icons.arrow_forward_ios,
                          color: Colors.white,
                          size: 16,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}

// Data classes
class OnboardingData {
  final String title;
  final String subtitle;
  final String description;
  final IconData icon;
  final LinearGradient gradient;
  final Color primaryColor;
  final AnimationType animationType;

  OnboardingData({
    required this.title,
    required this.subtitle,
    required this.description,
    required this.icon,
    required this.gradient,
    required this.primaryColor,
    required this.animationType,
  });
}

enum AnimationType {
  floating,
  pulse,
  rotation,
}

// Custom painter for particle effects
class ParticlePainter extends CustomPainter {
  final Animation<double> animation;
  final Color color;

  ParticlePainter({
    required this.animation,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withOpacity(0.03) // Very subtle particles
      ..style = PaintingStyle.fill;

    final random = math.Random(42); // Fixed seed for consistent particles
    
    for (int i = 0; i < 20; i++) {
      final x = (random.nextDouble() * size.width);
      final y = (random.nextDouble() * size.height);
      final radius = (random.nextDouble() * 3) + 1;
      
      final offset = math.sin(animation.value * 2 * math.pi + i) * 5;
      
      canvas.drawCircle(
        Offset(x, y + offset),
        radius,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
