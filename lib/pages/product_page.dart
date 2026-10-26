import 'package:flutter/material.dart';

import '../services/customer_app_service.dart';
import '../services/staff_api_service.dart';
import 'products/viewCategory.dart';
import 'products/view_product.dart';

class ProductsPage extends StatefulWidget {
  final CustomerAppService? service;
  final StaffApiService? staffService;

  const ProductsPage({super.key, this.service, this.staffService});

  @override
  State<ProductsPage> createState() => _ProductsPageState();
}

class _ProductsPageState extends State<ProductsPage> {
  Future<Map<String, int>>? _overviewFuture;

  @override
  void initState() {
    super.initState();
    if (widget.service != null || widget.staffService != null) {
      _overviewFuture = _loadOverview();
    }
  }

  Future<Map<String, int>> _loadOverview() async {
    final results = await Future.wait([
      widget.staffService != null
          ? widget.staffService!.getCatalogProducts(page: 1, pageSize: 1)
          : widget.service!.getProducts(page: 1, pageSize: 1),
      widget.staffService != null
          ? widget.staffService!.getCatalogCategories()
          : widget.service!.getCategories(),
    ]);
    final products = results[0] as Map<String, dynamic>;
    final categories = results[1] as List<dynamic>;
    final meta = products['meta'];
    final productTotal = meta is Map<String, dynamic>
        ? int.tryParse(meta['total']?.toString() ?? '') ?? 0
        : (products['data'] is List ? (products['data'] as List).length : 0);
    return {'products': productTotal, 'categories': categories.length};
  }

  Widget _buildOverview() {
    return FutureBuilder<Map<String, int>>(
      future: _overviewFuture,
      builder: (context, snapshot) {
        final counts = snapshot.data;
        return Row(
          children: [
            Expanded(
              child: _buildSummaryCard(
                title: 'Products',
                value: counts?['products']?.toString() ?? '—',
                icon: Icons.inventory_2_outlined,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildSummaryCard(
                title: 'Categories',
                value: counts?['categories']?.toString() ?? '—',
                icon: Icons.grid_view_rounded,
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final cardColor = const Color(0xFF115E59);

    return Container(
      color: Colors.white,
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: Column(
              children: [
                _buildProductCard(
                  context,
                  title: 'View Products',
                  icon: Icons.inventory_2_outlined,
                  bgColor: cardColor,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ViewProductsPage(
                          service: widget.service,
                          staffService: widget.staffService,
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 18),
                _buildProductCard(
                  context,
                  title: 'View Categories',
                  icon: Icons.grid_view_rounded,
                  bgColor: cardColor,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => CategoryManagementScreen(
                          service: widget.service,
                          staffService: widget.staffService,
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 18),
                const SizedBox(height: 28),
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Product overview',
                    style: TextStyle(
                      color: Color(0xFF0F172A),
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                _buildOverview(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProductCard(
    BuildContext context, {
    required String title,
    required IconData icon,
    required Color bgColor,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(12),
      child: Ink(
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: bgColor.withValues(alpha: 0.3),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          splashColor: Colors.white24,
          highlightColor: Colors.white12,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 22),
            child: Row(
              children: [
                Icon(icon, color: Colors.white, size: 32),
                const SizedBox(width: 20),
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryCard({
    required String title,
    required String value,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FC),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFF0D9488), size: 24),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(color: Color(0xFF64748B), fontSize: 12),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: const TextStyle(
                  color: Color(0xFF0F172A),
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
