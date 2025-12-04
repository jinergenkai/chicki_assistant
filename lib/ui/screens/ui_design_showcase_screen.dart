import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

/// UI Design Showcase Screen
///
/// Reference screen cho tất cả các UI components được sử dụng trong app.
/// Bao gồm: AppBars, Buttons, Bottom Navigation, Cards, Progress Bars, etc.
///
/// Design System: Modern, Clean với gradients, shadows, và animations
class UIDesignShowcaseScreen extends StatefulWidget {
  const UIDesignShowcaseScreen({super.key});

  @override
  State<UIDesignShowcaseScreen> createState() => _UIDesignShowcaseScreenState();
}

class _UIDesignShowcaseScreenState extends State<UIDesignShowcaseScreen> {
  int _selectedNavIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: _buildModernAppBar(),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _buildSectionTitle('🎨 Modern AppBar Styles'),
          _buildAppBarExamples(),

          const SizedBox(height: 32),
          _buildSectionTitle('🔘 Button Styles'),
          _buildButtonExamples(),

          const SizedBox(height: 32),
          _buildSectionTitle('📱 Bottom Navigation Bar'),
          _buildBottomNavExamples(),

          const SizedBox(height: 32),
          _buildSectionTitle('🎴 Card Styles'),
          _buildCardExamples(),

          const SizedBox(height: 32),
          _buildSectionTitle('📊 Progress Bars'),
          _buildProgressBarExamples(),

          const SizedBox(height: 32),
          _buildSectionTitle('🎭 Icon Buttons'),
          _buildIconButtonExamples(),

          const SizedBox(height: 80),
        ],
      ),
    );
  }

  // ==================== MODERN APPBAR ====================
  PreferredSizeWidget _buildModernAppBar() {
    return PreferredSize(
      preferredSize: const Size.fromHeight(68),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.white,
              Colors.grey.shade50,
            ],
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: AppBar(
          foregroundColor: Colors.black87,
          title: const Text(
            'UI Design Showcase',
            style: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 18,
              letterSpacing: -0.5,
            ),
          ),
          leading: Container(
            margin: const EdgeInsets.only(left: 8, top: 8, bottom: 8),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(12),
            ),
            child: IconButton(
              icon: Icon(Icons.arrow_back_ios_new_rounded,
                size: 18,
                color: Colors.grey.shade800,
              ),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          actions: [
            Container(
              margin: const EdgeInsets.only(right: 12, top: 8, bottom: 8),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.blue.shade400,
                    Colors.blue.shade600,
                  ],
                ),
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: Colors.blue.withOpacity(0.25),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Action button clicked!')),
                    );
                  },
                  borderRadius: BorderRadius.circular(14),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.add_rounded, color: Colors.white, size: 20),
                        SizedBox(width: 6),
                        Text(
                          'Add',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                            letterSpacing: 0.3,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
          backgroundColor: Colors.transparent,
          elevation: 0,
          centerTitle: true,
          toolbarHeight: 68,
        ),
      ),
    );
  }

  // ==================== SECTION TITLE ====================
  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.3,
        ),
      ),
    );
  }

  // ==================== APPBAR EXAMPLES ====================
  Widget _buildAppBarExamples() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildExampleCard(
          'Flash Card Style AppBar',
          'Gradient background, modern buttons, shadow',
          Container(
            height: 68,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Colors.white, Colors.grey.shade50],
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                const SizedBox(width: 12),
                _buildBackButton(),
                const Expanded(
                  child: Center(
                    child: Text(
                      'Screen Title',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 18,
                        letterSpacing: -0.5,
                      ),
                    ),
                  ),
                ),
                _buildAddButton(),
                const SizedBox(width: 12),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ==================== BUTTON EXAMPLES ====================
  Widget _buildButtonExamples() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Primary Gradient Button
        _buildExampleCard(
          'Primary Button (Gradient)',
          'Blue gradient with shadow, used for main actions',
          Container(
            height: 56,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.blue.shade400,
                  Colors.blue.shade600,
                ],
              ),
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: Colors.blue.withOpacity(0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () {},
                borderRadius: BorderRadius.circular(14),
                child: const Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.play_arrow_rounded, color: Colors.white, size: 24),
                      SizedBox(width: 8),
                      Text(
                        'START LEARNING',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),

        const SizedBox(height: 16),

        // Secondary Outlined Button
        _buildExampleCard(
          'Secondary Button (Outlined)',
          'Outlined style with border, used for secondary actions',
          OutlinedButton.icon(
            onPressed: () {},
            icon: const Icon(Icons.add_rounded, size: 20),
            label: const Text(
              'ADD VOCAB',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 14,
                letterSpacing: 0.3,
              ),
            ),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              side: BorderSide(color: Colors.grey.shade300, width: 1.5),
            ),
          ),
        ),
      ],
    );
  }

  // ==================== BOTTOM NAV EXAMPLES ====================
  Widget _buildBottomNavExamples() {
    return _buildExampleCard(
      'Modern Bottom Navigation',
      'Animated, gradient for selected item, shadows',
      Container(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.12),
              blurRadius: 24,
              offset: const Offset(0, 8),
            ),
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Colors.white, Colors.grey.shade50],
            ),
            borderRadius: BorderRadius.circular(24),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(LucideIcons.home, true),
              _buildNavItem(LucideIcons.search, false),
              _buildNavItem(LucideIcons.shoppingBag, false),
              _buildNavItem(LucideIcons.user, false),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(IconData icon, bool selected) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        gradient: selected
            ? LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Colors.blue.shade400, Colors.blue.shade600],
              )
            : null,
        borderRadius: BorderRadius.circular(14),
        boxShadow: selected
            ? [
                BoxShadow(
                  color: Colors.blue.withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ]
            : null,
      ),
      child: Icon(
        icon,
        size: 22,
        color: selected ? Colors.white : Colors.grey.shade600,
      ),
    );
  }

  // ==================== CARD EXAMPLES ====================
  Widget _buildCardExamples() {
    return Column(
      children: [
        _buildExampleCard(
          'Stats Card with Gradient',
          'Gradient background, colored value, shadow',
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Colors.white, Colors.grey.shade50],
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey.shade100),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.orange.withOpacity(0.15),
                            Colors.orange.withOpacity(0.1),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(LucideIcons.flame, color: Colors.orange, size: 18),
                    ),
                    Text(
                      'Streak',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey.shade600,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                const Text(
                  '15',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: Colors.orange,
                    letterSpacing: -0.5,
                  ),
                ),
                Text(
                  'days in a row',
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.grey.shade500,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 16),

        _buildExampleCard(
          'Content Card',
          'White background with subtle shadow',
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(LucideIcons.bookOpen, color: Colors.blue, size: 20),
                    SizedBox(width: 8),
                    Text(
                      'Card Title',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.3,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 12),
                Text(
                  'Card content goes here. This is a clean card with white background and subtle shadow for depth.',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.black87,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ==================== PROGRESS BAR EXAMPLES ====================
  Widget _buildProgressBarExamples() {
    return _buildExampleCard(
      'Progress Bar with Shadow',
      'Colored bar with matching shadow, rounded corners',
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Mastered',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  letterSpacing: -0.2,
                ),
              ),
              Text(
                '60%',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Colors.green.shade600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              boxShadow: [
                BoxShadow(
                  color: Colors.green.withOpacity(0.2),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: LinearProgressIndicator(
                value: 0.6,
                minHeight: 12,
                backgroundColor: Colors.grey.shade100,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.green.shade600),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ==================== ICON BUTTON EXAMPLES ====================
  Widget _buildIconButtonExamples() {
    return _buildExampleCard(
      'Icon Button Styles',
      'Different styles for different contexts',
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          Column(
            children: [
              _buildBackButton(),
              const SizedBox(height: 8),
              const Text('Back', style: TextStyle(fontSize: 12)),
            ],
          ),
          Column(
            children: [
              Container(
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: IconButton(
                  icon: Icon(LucideIcons.settings, size: 20, color: Colors.grey.shade700),
                  onPressed: () {},
                ),
              ),
              const SizedBox(height: 8),
              const Text('Settings', style: TextStyle(fontSize: 12)),
            ],
          ),
          Column(
            children: [
              _buildAddButton(),
              const SizedBox(height: 8),
              const Text('Add', style: TextStyle(fontSize: 12)),
            ],
          ),
        ],
      ),
    );
  }

  // ==================== HELPER WIDGETS ====================
  Widget _buildExampleCard(String title, String description, Widget example) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            description,
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 16),
          example,
        ],
      ),
    );
  }

  Widget _buildBackButton() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
      ),
      child: IconButton(
        icon: Icon(Icons.arrow_back_ios_new_rounded,
          size: 18,
          color: Colors.grey.shade800,
        ),
        onPressed: () {},
      ),
    );
  }

  Widget _buildAddButton() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.blue.shade400, Colors.blue.shade600],
        ),
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withOpacity(0.25),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {},
          borderRadius: BorderRadius.circular(14),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.add_rounded, color: Colors.white, size: 20),
                SizedBox(width: 6),
                Text(
                  'Add',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    letterSpacing: 0.3,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
