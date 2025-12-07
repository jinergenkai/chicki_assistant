import 'package:chicki_buddy/controllers/app_config.controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';
import 'package:moon_design/moon_design.dart'; // Ensure Moon Design is used for buttons if preferred, or stick to Material

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  late final PageController _buddyPageController;
  final TextEditingController _nameController = TextEditingController();
  int _currentStep = 0;
  String? _selectedAvatar;

  // Avatar files available in assets/avatar/
  final List<Map<String, String>> _avatarOptions = [
    {'id': '4', 'path': 'assets/avatar/4.png', 'label': 'Buddy'},
    {'id': '6', 'path': 'assets/avatar/6.png', 'label': 'Smarty'},
    {'id': 'a', 'path': 'assets/avatar/a.png', 'label': 'Friendly'},
    {'id': 'c', 'path': 'assets/avatar/c.png', 'label': 'Cool'},
    {'id': 'cat', 'path': 'assets/avatar/cat.png', 'label': 'Kitty'},
    {'id': 'chuoi', 'path': 'assets/avatar/chuoi.png', 'label': 'Banana'},
    {'id': 'dog', 'path': 'assets/avatar/dog.png', 'label': 'Doggy'},
    {'id': 'luoi', 'path': 'assets/avatar/luoi.png', 'label': 'Lazy'}
  ];
  @override
  void initState() {
    super.initState();
    _buddyPageController = PageController(viewportFraction: 0.55);
    // Select first avatar by default
    _selectedAvatar = _avatarOptions[0]['id'];
  }

  @override
  void dispose() {
    _pageController.dispose();
    _buddyPageController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  void _nextStep() {
    // Always dismiss keyboard when moving steps
    FocusScope.of(context).unfocus();

    // Validate name step (step 4 is name input, index 4)
    if (_currentStep == 4) {
      if (_nameController.text.trim().isEmpty) {
        MoonToast.show(context, label: const Text('Please enter your name'));
        return;
      }
    }

    // Steps: 0=Welcome, 1=Feature1, 2=Feature2, 3=Feature3, 4=Name, 5=Avatar
    if (_currentStep < 5) {
      setState(() => _currentStep++);
      _pageController.animateToPage(
        _currentStep,
        duration: const Duration(milliseconds: 400),
        curve: Curves.fastEaseInToSlowEaseOut,
      );
    } else {
      // Last step (avatar), complete onboarding
      _completeOnboarding();
    }
  }

  void _previousStep() {
    if (_currentStep > 0) {
      setState(() => _currentStep--);
      _pageController.animateToPage(
        _currentStep,
        duration: const Duration(milliseconds: 400),
        curve: Curves.fastEaseInToSlowEaseOut,
      );
    }
  }

  Future<void> _completeOnboarding() async {
    final appConfig = Get.find<AppConfigController>();

    appConfig.isFirstTimeUser.value = false;
    appConfig.userName.value = _nameController.text.trim();
    appConfig.userAvatar.value = _selectedAvatar ?? 'dog';

    await appConfig.saveConfig();

    if (mounted) {
      context.go('/');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // Header with Progress
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Row(
                children: [
                  // Back button or Spacer
                  if (_currentStep > 0)
                    MoonButton.icon(
                      icon: const Icon(Icons.arrow_back_rounded),
                      onTap: _previousStep,
                      buttonSize: MoonButtonSize.sm,
                      //  variant: MoonButtonVariant.ghost,
                    )
                  else
                    const SizedBox(width: 40),

                  const Spacer(),

                  // Step Indicator
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: List.generate(6, (index) {
                      final isActive = index == _currentStep;
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        margin: const EdgeInsets.symmetric(horizontal: 2),
                        height: 6,
                        width: isActive ? 16 : 6,
                        decoration: BoxDecoration(
                          color: isActive ? Colors.blue : Colors.grey.shade200,
                          borderRadius: BorderRadius.circular(3),
                        ),
                      );
                    }),
                  ),

                  const Spacer(),
                  const SizedBox(width: 40), // Balance left side
                ],
              ),
            ),

            // Content Area - Flexible
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(), // Disable swipe
                children: [
                  _buildWelcomeStep(),
                  _buildFeatureStep(
                    imageUrl: 'assets/avatar/dog.png', // Placeholder or use relevant assets
                    icon: Icons.school_rounded,
                    color: Colors.blue,
                    title: 'Learn Smarter',
                    subtitle: 'Master new vocabulary with AI-powered stories and flashcards.',
                  ),
                  _buildFeatureStep(
                    imageUrl: 'assets/avatar/cat.png',
                    icon: Icons.book_rounded,
                    color: Colors.purple,
                    title: 'Your Personal Journal',
                    subtitle: 'Capture your thoughts and memories in a beautiful private space.',
                  ),
                  _buildFeatureStep(
                    imageUrl: 'assets/avatar/6.png',
                    icon: Icons.chat_bubble_rounded,
                    color: Colors.orange,
                    title: 'Chat with Chicky',
                    subtitle: 'Practice conversation and get instant help from your AI buddy.',
                  ),
                  _buildNameStep(),
                  _buildAvatarStep(),
                ],
              ),
            ),

            // Bottom Action Area
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
              child: SizedBox(
                width: double.infinity,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Colors.blue.shade400,
                        Colors.blue.shade600,
                      ],
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.blue.withOpacity(0.4),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ElevatedButton(
                    onPressed: _nextStep,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: Text(
                      _currentStep == 5 ? 'Get Started' : 'Continue',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // STEP 0: WELCOME
  Widget _buildWelcomeStep() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Spacer(flex: 2),
          // Hero Image/Icon
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.waving_hand_rounded, size: 64, color: Colors.blue),
          ),
          const SizedBox(height: 32),

          Text(
            "Hi there!",
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade900,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            "Welcome to Chicky Buddy,\nyour new AI companion.",
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 18,
              height: 1.5,
              color: Colors.grey.shade600,
            ),
          ),
          const Spacer(flex: 3),
        ],
      ),
    );
  }

  // GENERIC FEATURE STEP
  Widget _buildFeatureStep({
    required String? imageUrl,
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Spacer(flex: 2),
          // Illustration Area
          Container(
            height: 200,
            width: 200,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Icon(icon, size: 80, color: color),
            ),
          ),
          const SizedBox(height: 48),

          // Text Content
          Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade900,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 17,
              height: 1.4,
              color: Colors.grey.shade600,
            ),
          ),
          const Spacer(flex: 3),
        ],
      ),
    );
  }

  // STEP 4: NAME INPUT
  Widget _buildNameStep() {
    // Keep SingleChildScrollView here for keyboard support
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.amber.shade50,
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.person_outline_rounded, size: 48, color: Colors.amber.shade700),
            ),
            const SizedBox(height: 32),
            Text(
              "What should we call you?",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade900,
              ),
            ),
            const SizedBox(height: 32),
            Container(
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(16),
              ),
              child: TextField(
                controller: _nameController,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
                decoration: InputDecoration(
                  border: InputBorder.none,
                  hintText: "Your Name",
                  hintStyle: TextStyle(color: Colors.grey.shade400),
                  contentPadding: const EdgeInsets.all(20),
                ),
                textCapitalization: TextCapitalization.words,
                autofocus: true,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              "This is how Chicky will address you.",
              style: TextStyle(color: Colors.grey.shade500, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }

  // STEP 5: AVATAR SELECTION
  Widget _buildAvatarStep() {
    return Column(
      children: [
        const SizedBox(height: 20),
        Text(
          "Choose your Buddy",
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.grey.shade900,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          "Swipe to find your perfect match",
          style: TextStyle(color: Colors.grey.shade600),
        ),
        const SizedBox(height: 48), // Space for top of bigger card

        SizedBox(
          height: 420, // Increased height to prevent shadow cutoff
          child: PageView.builder(
            controller: _buddyPageController,
            physics: const BouncingScrollPhysics(),
            clipBehavior: Clip.none,
            onPageChanged: (index) {
              setState(() => _selectedAvatar = _avatarOptions[index]['id']);
            },
            itemCount: _avatarOptions.length,
            itemBuilder: (context, index) {
              final avatar = _avatarOptions[index];

              return AnimatedBuilder(
                animation: _buddyPageController,
                builder: (context, child) {
                  double value = 1.0;
                  if (_buddyPageController.position.haveDimensions) {
                    value = _buddyPageController.page! - index;
                    value = (1 - (value.abs() * 0.3)).clamp(0.0, 1.0);
                  }

                  return Center(
                    child: Transform.scale(
                      scale: Curves.easeOut.transform(value),
                      child: child,
                    ),
                  );
                },
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(32),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.blue.withOpacity(0.15),
                        blurRadius: 24,
                        offset: const Offset(0, 12),
                        spreadRadius: 4,
                      )
                    ],
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(24),
                            child: Image.asset(
                              avatar['path']!,
                              fit: BoxFit.contain,
                            ),
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(bottom: 24),
                        child: Text(
                          avatar['label']!,
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey.shade800,
                            letterSpacing: -0.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
