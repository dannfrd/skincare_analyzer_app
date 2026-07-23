import 'package:flutter/material.dart';
import 'package:skincare_analyzer_app/main.dart';
import 'package:skincare_analyzer_app/services/permission_service.dart';
import 'package:skincare_analyzer_app/services/user_session.dart';

class TutorialScreen extends StatefulWidget {
  const TutorialScreen({super.key});

  @override
  State<TutorialScreen> createState() => _TutorialScreenState();
}

class _TutorialScreenState extends State<TutorialScreen>
    with TickerProviderStateMixin {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  late AnimationController _entryCtrl;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  // ── Slide Data ─────────────────────────────────────────────────────────────
  static const List<_TutorialSlide> _slides = [
    _TutorialSlide(
      icon: Icons.spa_rounded,
      title: 'Welcome to Dermify',
      subtitle:
          'Your AI-powered skincare ingredient analyzer. Make smarter, safer choices for your skin.',
      badgeLabel: 'Smart Skincare',
      stepFeatures: [
        'Analyze any skincare product',
        'Identify harmful ingredients',
        'Personalized skin insights',
      ],
    ),
    _TutorialSlide(
      icon: Icons.camera_alt_rounded,
      title: 'Capture the\nIngredient Label',
      subtitle:
          'Take a photo of the ingredients list on your skincare product using your camera or select from your gallery.',
      badgeLabel: 'Step 1',
      stepFeatures: [
        'Use camera for real-time capture',
        'Upload from your photo gallery',
        'Supports all label formats',
      ],
    ),
    _TutorialSlide(
      icon: Icons.auto_awesome_rounded,
      title: 'AI Scans &\nAnalyzes Instantly',
      subtitle:
          'Our Gemini AI reads every ingredient and flags anything that could be harmful, irritating, or beneficial for your skin.',
      badgeLabel: 'Step 2',
      stepFeatures: [
        'Powered by Gemini AI',
        'Detects harmful chemicals',
        'Rates ingredient safety levels',
      ],
    ),
    _TutorialSlide(
      icon: Icons.insert_chart_rounded,
      title: 'Get Your Full\nReport & History',
      subtitle:
          'Review a detailed analysis report and revisit your scan history anytime for informed skincare decisions.',
      badgeLabel: 'Step 3',
      stepFeatures: [
        'Full ingredient breakdown & warnings',
        'AI-generated summary & analysis',
        'Product recommendations & history',
      ],
    ),

  ];

  @override
  void initState() {
    super.initState();

    _entryCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 550),
    );

    _fadeAnim = CurvedAnimation(parent: _entryCtrl, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.06),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _entryCtrl, curve: Curves.easeOut));

    _entryCtrl.forward();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _entryCtrl.dispose();
    super.dispose();
  }

  void _onPageChanged(int index) {
    _entryCtrl.reset();
    setState(() => _currentPage = index);
    _entryCtrl.forward();
  }

  void _nextPage() {
    if (_currentPage < _slides.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 380),
        curve: Curves.easeInOutCubic,
      );
    } else {
      _finishTutorial();
    }
  }

  void _skipTutorial() => _finishTutorial();

  Future<void> _finishTutorial() async {
    await PermissionService.markTutorialSeen();
    if (!mounted) return;
    final route = UserSession.isLoggedIn ? '/main' : '/login';
    Navigator.pushReplacementNamed(context, route);
  }

  @override
  Widget build(BuildContext context) {
    final isLastPage = _currentPage == _slides.length - 1;

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnim,
          child: SlideTransition(
            position: _slideAnim,
            child: Column(
              children: [
                // ── Top Bar ─────────────────────────────────────────────
                _buildTopBar(isLastPage),

                // ── PageView ─────────────────────────────────────────────
                Expanded(
                  child: PageView.builder(
                    controller: _pageController,
                    onPageChanged: _onPageChanged,
                    itemCount: _slides.length,
                    itemBuilder: (context, index) {
                      return _TutorialPage(
                        slide: _slides[index],
                        isActive: index == _currentPage,
                      );
                    },
                  ),
                ),

                // ── Bottom Section ───────────────────────────────────────
                _buildBottomSection(isLastPage),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTopBar(bool isLastPage) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Step counter pill
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.surfaceGreen,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: AppColors.primaryGreen.withValues(alpha: 0.3),
              ),
            ),
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 250),
              child: Text(
                '${_currentPage + 1} of ${_slides.length}',
                key: ValueKey(_currentPage),
                style: const TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primaryGreenDark,
                ),
              ),
            ),
          ),

          // Skip button (hidden on last page)
          AnimatedOpacity(
            duration: const Duration(milliseconds: 250),
            opacity: isLastPage ? 0.0 : 1.0,
            child: GestureDetector(
              onTap: isLastPage ? null : _skipTutorial,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.grey.shade200),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: const Text(
                  'Skip',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textGray,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomSection(bool isLastPage) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 4, 24, 28),
      child: Column(
        children: [
          // Dot indicators
          _DotIndicator(
            count: _slides.length,
            currentIndex: _currentPage,
          ),

          const SizedBox(height: 24),

          // CTA button
          SizedBox(
            width: double.infinity,
            height: 54,
            child: ElevatedButton(
              onPressed: _nextPage,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryGreenDark,
                foregroundColor: Colors.white,
                disabledBackgroundColor:
                    AppColors.primaryGreenDark.withValues(alpha: 0.5),
                elevation: 0,
                shadowColor: Colors.transparent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 250),
                    child: Text(
                      isLastPage ? 'Get Started' : 'Next',
                      key: ValueKey(isLastPage),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 250),
                    child: Icon(
                      isLastPage
                          ? Icons.check_circle_rounded
                          : Icons.arrow_forward_rounded,
                      key: ValueKey(isLastPage),
                      size: 19,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Tutorial Slide Data Model ─────────────────────────────────────────────────

class _TutorialSlide {
  final IconData icon;
  final String title;
  final String subtitle;
  final String badgeLabel;
  final List<String> stepFeatures;

  const _TutorialSlide({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.badgeLabel,
    required this.stepFeatures,
  });
}

// ─── Tutorial Page Widget ──────────────────────────────────────────────────────

class _TutorialPage extends StatelessWidget {
  final _TutorialSlide slide;
  final bool isActive;

  const _TutorialPage({
    required this.slide,
    required this.isActive,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 20),

            // ── Illustration ─────────────────────────────────────────────
            Center(child: _IllustrationBox(icon: slide.icon)),

            const SizedBox(height: 32),

            // ── Step Badge ───────────────────────────────────────────────
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
              decoration: BoxDecoration(
                color: AppColors.primaryGreen.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                slide.badgeLabel.toUpperCase(),
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: AppColors.primaryGreenDark,
                  letterSpacing: 1.0,
                ),
              ),
            ),

            const SizedBox(height: 14),

            // ── Title ────────────────────────────────────────────────────
            Text(
              slide.title,
              style: const TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w800,
                color: AppColors.textDark,
                height: 1.25,
                letterSpacing: -0.5,
              ),
            ),

            const SizedBox(height: 12),

            // ── Subtitle ─────────────────────────────────────────────────
            Text(
              slide.subtitle,
              style: const TextStyle(
                fontSize: 14.5,
                color: AppColors.textGray,
                height: 1.6,
              ),
            ),

            const SizedBox(height: 24),

            // ── Feature chips ─────────────────────────────────────────────
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade100),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Column(
                children: slide.stepFeatures.map((feature) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Row(
                      children: [
                        Container(
                          width: 26,
                          height: 26,
                          decoration: BoxDecoration(
                            color: AppColors.surfaceGreen,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.check_rounded,
                            color: AppColors.primaryGreenDark,
                            size: 15,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            feature,
                            style: const TextStyle(
                              fontSize: 13.5,
                              color: AppColors.textDark,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Illustration Box ──────────────────────────────────────────────────────────

class _IllustrationBox extends StatefulWidget {
  final IconData icon;

  const _IllustrationBox({required this.icon});

  @override
  State<_IllustrationBox> createState() => _IllustrationBoxState();
}

class _IllustrationBoxState extends State<_IllustrationBox>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseCtrl;
  late Animation<double> _pulseAnim;
  late Animation<double> _iconScaleAnim;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat(reverse: true);

    _pulseAnim = Tween<double>(begin: 0.88, end: 1.0).animate(
      CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut),
    );
    _iconScaleAnim = Tween<double>(begin: 0.96, end: 1.04).animate(
      CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _pulseCtrl,
      builder: (context, child) {
        return SizedBox(
          width: 200,
          height: 200,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Outer soft ring
              Transform.scale(
                scale: _pulseAnim.value,
                child: Container(
                  width: 190,
                  height: 190,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color:
                        AppColors.primaryGreen.withValues(alpha: 0.07),
                  ),
                ),
              ),

              // Mid ring
              Container(
                width: 150,
                height: 150,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.primaryGreen.withValues(alpha: 0.1),
                ),
              ),

              // Inner icon container — matches app gradient style
              Transform.scale(
                scale: _iconScaleAnim.value,
                child: Container(
                  width: 104,
                  height: 104,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [
                        AppColors.primaryGreen,
                        AppColors.primaryGreenDark,
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(30),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primaryGreenDark.withValues(alpha: 0.35),
                        blurRadius: 24,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Icon(
                    widget.icon,
                    color: Colors.white,
                    size: 46,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ─── Dot Indicator ────────────────────────────────────────────────────────────

class _DotIndicator extends StatelessWidget {
  final int count;
  final int currentIndex;

  const _DotIndicator({
    required this.count,
    required this.currentIndex,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(count, (i) {
        final isActive = i == currentIndex;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 280),
          curve: Curves.easeInOut,
          margin: const EdgeInsets.symmetric(horizontal: 3.5),
          width: isActive ? 26 : 8,
          height: 8,
          decoration: BoxDecoration(
            color: isActive
                ? AppColors.primaryGreenDark
                : Colors.grey.shade300,
            borderRadius: BorderRadius.circular(4),
          ),
        );
      }),
    );
  }
}
