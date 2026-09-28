import 'package:flutter/material.dart';
import 'features_page.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  static const Color darkGreen = Color(0xFF064E46);
  static const Color green = Color(0xFF0D9488);
  static const Color lightBg = Color(0xFFF8F9FC);

  void _goToFeatures(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const FeaturesPage(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: lightBg,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              _buildHeroSection(context),
              _buildCapabilities(),
              _buildCTA(context),
            ],
          ),
        ),
      ),
    );
  }



  Widget _buildHeroSection(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(20, 35, 20, 40),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth >= 800;
          final content = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
          // Next action in the top corner
          Align(
            alignment: Alignment.topRight,
            child: OutlinedButton.icon(
              onPressed: () => _goToFeatures(context),
              icon: const Icon(Icons.arrow_forward, size: 16),
              label: const Text('Next'),
              style: OutlinedButton.styleFrom(
                foregroundColor: green,
                side: const BorderSide(color: green),
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 7,
                ),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
            ),
          ),

          const SizedBox(height: 12),

          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 7,
            ),
            decoration: BoxDecoration(
              color: green.withOpacity(.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Text(
              'SMART RETAIL MANAGEMENT',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: green,
              ),
            ),
          ),

          const SizedBox(height: 20),

          // Main heading
          const Text.rich(
            TextSpan(
              style: TextStyle(
                fontSize: 34,
                height: 1.05,
                fontWeight: FontWeight.w700,
                color: Color(0xFF17202A),
              ),
              children: [
                TextSpan(text: 'Orchestrate Your\n'),
                TextSpan(
                  text: 'Business with the\nUltimate POS System',
                  style: TextStyle(color: green),
                ),
              ],
            ),
          ),

          const SizedBox(height: 18),

          Text(
            'Powerful retail management software designed '
            'to simplify your operations, improve efficiency, '
            'and help your business grow.',
            style: TextStyle(
              fontSize: 15,
              height: 1.6,
              color: Colors.grey.shade600,
            ),
          ),

          const SizedBox(height: 25),

          // Buttons
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ElevatedButton(
                onPressed: () {
                  _goToFeatures(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: green,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 48),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 10,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(7),
                  ),
                ),
                child: const Text(
                  'Get Started',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),

              const SizedBox(height: 12),

              OutlinedButton(
                onPressed: () {
                  _goToFeatures(context);
                },
                style: OutlinedButton.styleFrom(
                  foregroundColor: green,
                  side: const BorderSide(color: green),
                  minimumSize: const Size(double.infinity, 48),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 10,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(7),
                  ),
                ),
                child: const Text('View Demo'),
              ),
            ],
          ),

          const SizedBox(height: 35),

              if (!isWide) ...[
                const SizedBox(height: 35),
                _buildPosImage(),
              ],
            ],
          );

          if (!isWide) return content;

          return Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(child: content),
              const SizedBox(width: 28),
              Expanded(child: _buildPosImage()),
            ],
          );
        },
      ),
    );
  }
Widget _buildPosImage() {
  return Container(
    height: 300,
    width: double.infinity,
    color: Colors.white, 
    child: ClipRRect(
      child: Image.asset(
        'assets/images/pos.png',
        fit: BoxFit.contain,
      ),
    ),
  );
}

  
  Widget _buildCapabilities() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(18, 20, 18, 45),
      child: Column(
        children: [
          const Text(
            'Core Capabilities',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: darkGreen,
            ),
          ),

          const SizedBox(height: 8),

          Text(
            'Everything you need to manage and grow your retail business.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 13,
            ),
          ),

          const SizedBox(height: 22),

          LayoutBuilder(
            builder: (context, constraints) {
              final cardWidth = constraints.maxWidth >= 800
                  ? (constraints.maxWidth - 36) / 4
                  : constraints.maxWidth;
              return Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  SizedBox(width: cardWidth, child: _capabilityCard(Icons.store, 'Core Retail', 'Manage your entire retail operation from one powerful platform.')),
                  SizedBox(width: cardWidth, child: _capabilityCard(Icons.point_of_sale, 'POS Operations', 'Fast and reliable point-of-sale operations for your business.')),
                  SizedBox(width: cardWidth, child: _capabilityCard(Icons.auto_graph, 'Intelligent', 'AI-powered insights and intelligent business decisions.')),
                  SizedBox(width: cardWidth, child: _capabilityCard(Icons.settings, 'Advanced Technical', 'Powerful tools designed for modern retail businesses.')),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _capabilityCard(
    IconData icon,
    String title,
    String description,
  ) {
    return Container(
      width: double.infinity,
      margin: EdgeInsets.zero,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: darkGreen,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            color: Colors.white,
            size: 25,
          ),

          const SizedBox(width: 15),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),

                const SizedBox(height: 6),

                Text(
                  description,
                  style: TextStyle(
                    color: Colors.white.withOpacity(.75),
                    fontSize: 12,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // CTA
  // ============================================================

  Widget _buildCTA(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: 25,
        vertical: 45,
      ),
      color: darkGreen,
      child: Column(
        children: [
          const Text(
            'Ready to scale your retail operations?',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white,
              fontSize: 25,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 12),

          Text(
            'Deploy a smarter POS solution built for modern retail businesses.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white.withOpacity(.75),
              fontSize: 13,
            ),
          ),

          const SizedBox(height: 22),
        ],
      ),
    );
  }
}