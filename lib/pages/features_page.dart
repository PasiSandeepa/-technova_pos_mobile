import 'package:flutter/material.dart';
import 'home_page.dart';
import 'login_page.dart';

class FeaturesPage extends StatelessWidget {
  const FeaturesPage({super.key});

  static const Color darkGreen = Color(0xFF064E46);
  static const Color green = Color(0xFF0D9488);
  static const Color lightBg = Color(0xFFF8F9FC);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: lightBg,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              _buildFeaturesHeader(context),
              _buildCoreRetailOperations(),
              _buildStockControl(),
              _buildSalesBilling(),
              _buildIntelligentDecision(),
              _buildInfrastructure(),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // FEATURES HEADER
  // ============================================================

  Widget _buildFeaturesHeader(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 55, horizontal: 20),
      color: darkGreen,
      child: Column(
        children: [
          const Text(
            'Comprehensive',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),

          const Text(
            'Features & Capabilities',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 12),

          Text(
            'Everything you need to build, operate and scale '
            'your retail business efficiently.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white.withOpacity(.75),
              fontSize: 11,
              height: 1.5,
            ),
          ),

          const SizedBox(height: 22),

          Align(
            alignment: Alignment.center,
            child: ElevatedButton.icon(
              onPressed: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const LoginPage(),
                  ),
                );
              },
              icon: const Icon(Icons.arrow_forward, size: 18),
              label: const Text('Get Started'),
              style: ElevatedButton.styleFrom(
                backgroundColor: green,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 13,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // CORE RETAIL OPERATIONS
  // ============================================================

  Widget _buildCoreRetailOperations() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Core Retail Operations',
            style: TextStyle(
              color: green,
              fontSize: 23,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 8),

          Text(
            'Complete tools to manage every aspect of your retail operation.',
            style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
          ),

          const SizedBox(height: 20),

          _featureCard(
            Icons.store,
            'Branch Management',
            'Manage multiple branches and monitor your operations from one place.',
          ),

          _featureCard(
            Icons.people,
            'User Management (RBAC)',
            'Control users, roles and permissions securely.',
          ),

          _featureCard(
            Icons.sync,
            'Multi-Location Sync',
            'Keep all your locations synchronized with real-time data.',
          ),
        ],
      ),
    );
  }

  Widget _featureCard(IconData icon, String title, String description) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: darkGreen,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Colors.white, size: 25),

          const SizedBox(height: 12),

          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),

          const SizedBox(height: 7),

          Text(
            description,
            style: TextStyle(
              color: Colors.white.withOpacity(.75),
              fontSize: 12,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // STOCK CONTROL
  // ============================================================

  Widget _buildStockControl() {
    return Container(
      color: lightBg,
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          // STOCK IMAGE
          Container(
            height: 210,
            width: double.infinity,
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(14)),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: Image.asset(
                'assets/images/Monitoring.webp',
                fit: BoxFit.cover,
              ),
            ),
          ),

          const SizedBox(height: 25),

          Align(
            alignment: Alignment.centerLeft,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: green.withOpacity(.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Text(
                'SMART INVENTORY',
                style: TextStyle(
                  color: green,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),

          const SizedBox(height: 12),

          const Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'End-to-End Stock Control',
              style: TextStyle(
                color: green,
                fontSize: 23,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),

          const SizedBox(height: 10),

          Text(
            'Track inventory, suppliers and purchases with complete visibility.',
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 13,
              height: 1.5,
            ),
          ),

          const SizedBox(height: 20),

          _smallInfo(
            'Supplier Management',
            'Manage supplier information and relationships.',
          ),

          _smallInfo(
            'Purchase Order Tracking',
            'Track purchase orders from creation to completion.',
          ),

          _smallInfo(
            'Inventory Management',
            'Monitor stock levels and inventory movements.',
          ),

          _smallInfo(
            'Real-Time Stock Tracking',
            'Get real-time visibility into your inventory.',
          ),
        ],
      ),
    );
  }

  Widget _smallInfo(String title, String description) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.check_circle_outline, color: green, size: 20),

          const SizedBox(width: 10),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),

                const SizedBox(height: 3),

                Text(
                  description,
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // SALES & BILLING
  // ============================================================

  Widget _buildSalesBilling() {
    return Container(
      width: double.infinity,
      color: darkGreen,
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          const Text(
            'Sales & Billing',
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 8),

          Text(
            'POWERFUL SALES MANAGEMENT FOR YOUR BUSINESS',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white.withOpacity(.7), fontSize: 10),
          ),

          const SizedBox(height: 25),

          _salesCard(
            Icons.shopping_cart,
            'Sales Processing',
            'Process sales quickly and accurately.',
          ),

          _salesCard(
            Icons.payment,
            'Multiple Payment Methods',
            'Support cash, card and digital payments.',
          ),

          _salesCard(
            Icons.receipt_long,
            'Returns & Refunds',
            'Handle returns and refunds easily.',
          ),

          _salesCard(
            Icons.local_offer,
            'Loyalty Programs',
            'Reward customers and increase retention.',
          ),
        ],
      ),
    );
  }

  Widget _salesCard(IconData icon, String title, String description) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: green),

          const SizedBox(height: 10),

          Text(
            title,
            style: const TextStyle(
              color: darkGreen,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 5),

          Text(
            description,
            style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // INTELLIGENT DECISION SUPPORT
  // ============================================================

  Widget _buildIntelligentDecision() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Intelligent Decision Support',
            style: TextStyle(
              color: green,
              fontSize: 23,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 12),

          Text(
            'Turn your business data into actionable insights.',
            style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
          ),

          const SizedBox(height: 20),

          _decisionItem(
            Icons.auto_awesome,
            'AI-Powered Analytics',
            'Use intelligent analytics to understand your business.',
          ),

          _decisionItem(
            Icons.trending_up,
            'Sales Forecasting',
            'Predict future sales using historical business data.',
          ),

          _decisionItem(
            Icons.analytics,
            'Demand Forecasting',
            'Predict demand and improve inventory planning.',
          ),

          _decisionItem(
            Icons.lightbulb_outline,
            'Inventory Optimization',
            'Optimize stock levels and reduce unnecessary inventory.',
          ),

          const SizedBox(height: 25),

          // AI IMAGE
          Container(
            height: 230,
            width: double.infinity,
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(14)),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: Image.asset('assets/images/robot.jpg', fit: BoxFit.cover),
            ),
          ),
        ],
      ),
    );
  }

  Widget _decisionItem(IconData icon, String title, String description) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 17),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: green, size: 22),

          const SizedBox(width: 12),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),

                const SizedBox(height: 4),

                Text(
                  description,
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // INFRASTRUCTURE
  // ============================================================

  Widget _buildInfrastructure() {
    return Container(
      width: double.infinity,
      color: darkGreen,
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          const Text(
            'Infrastructure & Resilience',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 8),

          Text(
            'Engineered for modern retail, reliability and scale.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white.withOpacity(.7), fontSize: 10),
          ),

          const SizedBox(height: 25),

          _infraCard(
            Icons.cloud_done,
            'Offline-First Mode',
            'Continue working even when your internet connection is unavailable.',
          ),

          _infraCard(
            Icons.sync,
            'Automatic Synchronization',
            'Automatically synchronize data when connectivity returns.',
          ),

          _infraCard(
            Icons.security,
            'Secure and Scalable',
            'Enterprise-grade security and scalable infrastructure.',
          ),
        ],
      ),
    );
  }

  Widget _infraCard(IconData icon, String title, String description) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: [
          Icon(icon, color: green, size: 28),

          const SizedBox(height: 10),

          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: darkGreen,
              fontWeight: FontWeight.bold,
              fontSize: 15,
            ),
          ),

          const SizedBox(height: 7),

          Text(
            description,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 12,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}
