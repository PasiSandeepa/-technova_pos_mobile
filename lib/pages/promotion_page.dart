import 'package:flutter/material.dart';

import '../services/customer_app_service.dart';
import '../services/staff_api_service.dart';

class PromotionPage extends StatefulWidget {
  final VoidCallback onBack;
  final CustomerAppService? service;
  final StaffApiService? staffService;

  const PromotionPage({
    super.key,
    required this.onBack,
    this.service,
    this.staffService,
  });

  @override
  State<PromotionPage> createState() => _PromotionPageState();
}

class _PromotionPageState extends State<PromotionPage> {
  static const Color _green = Color(0xFF0D9488);
  static const Color _darkGreen = Color(0xFF115E59);
  static const Color _background = Color(0xFFF8F9FC);
  static const Color _border = Color(0xFFE5E7EB);

  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> _promotions = const [];
  int _totalPromotions = 0;
  int _page = 1;
  int _pageCount = 1;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadPromotions();
  }

  Future<void> _loadPromotions() async {
    final service = widget.service;
    final staffService = widget.staffService;
    if (service == null && staffService == null) {
      setState(() {
        _isLoading = false;
        _error = 'Sign in to view promotions.';
      });
      return;
    }
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final response = staffService != null
          ? {
              'data': await staffService.getDiscounts(),
              'meta': <String, dynamic>{},
            }
          : await service!.getPromotions(page: _page, pageSize: 50);
      final raw = response['data'];
      final promotions = raw is List
          ? raw.whereType<Map<String, dynamic>>().toList()
          : <Map<String, dynamic>>[];
      final meta = response['meta'];
      if (!mounted) return;
      setState(() {
        _promotions = promotions;
        _totalPromotions = meta is Map<String, dynamic>
            ? int.tryParse(meta['total']?.toString() ?? '') ?? promotions.length
            : promotions.length;
        _pageCount = meta is Map<String, dynamic>
            ? int.tryParse(meta['pageCount']?.toString() ?? '') ?? 1
            : 1;
        _isLoading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error.toString();
        _isLoading = false;
      });
    }
  }

  List<Map<String, dynamic>> get _filteredPromotions {
    final query = _searchController.text.trim().toLowerCase();
    return _promotions.where((promotion) {
      final product = promotion['product'];
      final productName = product is Map<String, dynamic>
          ? (product['name'] ?? '').toString()
          : '';
      final searchable = [
        promotion['name'],
        promotion['code'],
        promotion['description'],
        productName,
      ].join(' ').toLowerCase();
      return query.isEmpty || searchable.contains(query);
    }).toList();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _refreshFilters() {
    setState(() {
      _searchController.clear();
      _page = 1;
    });
    _loadPromotions();
  }

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: _background,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth >= 760;
          final contentWidth = constraints.maxWidth > 1200
              ? 1200.0
              : constraints.maxWidth;

          return SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(
              isWide ? 24 : 16,
              18,
              isWide ? 24 : 16,
              24,
            ),
            child: Align(
              alignment: Alignment.topCenter,
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: contentWidth),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Expanded(
                          child: Text(
                            'Promotions',
                            style: TextStyle(
                              color: Color(0xFF17212B),
                              fontSize: 22,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        ElevatedButton.icon(
                          onPressed: widget.onBack,
                          icon: const Icon(Icons.arrow_back, size: 17),
                          label: const Text('Back'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _darkGreen,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 11,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Dashboard  ›  Promotions',
                      style: TextStyle(color: Color(0xFF718096), fontSize: 12),
                    ),
                    const SizedBox(height: 18),
                    _buildPromotionCount(),
                    const SizedBox(height: 16),
                    _buildFilters(isWide),
                    const SizedBox(height: 16),
                    _buildCampaigns(),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildPromotionCount() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: _border),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        '$_totalPromotions active promotions',
        style: const TextStyle(
          color: Color(0xFF17212B),
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildFilters(bool isWide) {
    final searchField = TextField(
      controller: _searchController,
      decoration: InputDecoration(
        hintText: 'Search promotion, code, or product',
        hintStyle: const TextStyle(color: Color(0xFF9AA5B1), fontSize: 13),
        prefixIcon: const Icon(
          Icons.search,
          color: Color(0xFF9AA5B1),
          size: 20,
        ),
        contentPadding: const EdgeInsets.symmetric(vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: _border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: _border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: _green),
        ),
      ),
    );

    final refreshButton = SizedBox(
      height: 48,
      width: isWide ? 48 : 52,
      child: OutlinedButton(
        onPressed: _refreshFilters,
        style: OutlinedButton.styleFrom(
          foregroundColor: const Color(0xFF3D4852),
          side: const BorderSide(color: _border),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          padding: EdgeInsets.zero,
        ),
        child: const Icon(Icons.refresh, size: 19),
      ),
    );

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: _border),
        borderRadius: BorderRadius.circular(12),
      ),
      child: isWide
          ? Row(
              children: [
                Expanded(child: SizedBox(height: 48, child: searchField)),
                const SizedBox(width: 8),
                refreshButton,
              ],
            )
          : Column(
              children: [
                Row(
                  children: [
                    Expanded(child: SizedBox(height: 48, child: searchField)),
                    const SizedBox(width: 8),
                    refreshButton,
                  ],
                ),
              ],
            ),
    );
  }

  Widget _buildCampaigns() {
    final visible = _filteredPromotions;
    final Widget content;
    if (_isLoading) {
      content = const Padding(
        padding: EdgeInsets.all(28),
        child: Center(child: CircularProgressIndicator()),
      );
    } else if (_error != null) {
      content = Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Text('Unable to load promotions: $_error'),
            TextButton.icon(
              onPressed: _loadPromotions,
              icon: const Icon(Icons.refresh),
              label: const Text('Try again'),
            ),
          ],
        ),
      );
    } else if (visible.isEmpty) {
      content = const Padding(
        padding: EdgeInsets.all(28),
        child: Center(
          child: Text(
            'No active promotions found.',
            style: TextStyle(color: Color(0xFF718096), fontSize: 12),
          ),
        ),
      );
    } else {
      content = Column(children: visible.map(_buildPromotion).toList());
    }

    return _Panel(
      title: 'Promotion campaigns',
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            color: const Color(0xFFF8FAFC),
            child: const Text(
              'PROMOTIONS',
              style: TextStyle(
                color: Color(0xFF718096),
                fontSize: 10,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.4,
              ),
            ),
          ),
          content,
          const Divider(height: 1, color: _border),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'Showing ${visible.length} of $_totalPromotions promotions',
                    style: const TextStyle(
                      color: Color(0xFF718096),
                      fontSize: 11,
                    ),
                  ),
                ),
                IconButton(
                  tooltip: 'Previous page',
                  onPressed: _page > 1 && !_isLoading
                      ? () => setState(() {
                          _page--;
                          _loadPromotions();
                        })
                      : null,
                  icon: const Icon(Icons.chevron_left),
                ),
                Text(
                  '$_page of $_pageCount',
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 11),
                ),
                IconButton(
                  tooltip: 'Next page',
                  onPressed: _page < _pageCount && !_isLoading
                      ? () => setState(() {
                          _page++;
                          _loadPromotions();
                        })
                      : null,
                  icon: const Icon(Icons.chevron_right),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPromotion(Map<String, dynamic> promotion) {
    final product = promotion['product'];
    final productName = product is Map<String, dynamic>
        ? product['name']?.toString()
        : null;
    final name = (promotion['name'] ?? promotion['code'] ?? 'Promotion')
        .toString();
    final code = promotion['code']?.toString() ?? '';
    final description = promotion['description']?.toString() ?? '';
    final type = promotion['type']?.toString() ?? '';
    final value = promotion['value']?.toString() ?? '';
    final endsAt = promotion['endsAt']?.toString() ?? '';
    return ListTile(
      leading: const Icon(Icons.local_offer_outlined, color: _green),
      title: Text(name, style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (description.isNotEmpty) Text(description),
          if (productName != null) Text('Product: $productName'),
          if (code.isNotEmpty) Text('Code: $code'),
          if (value.isNotEmpty) Text('$type: $value'),
          if (endsAt.isNotEmpty) Text('Ends: $endsAt'),
        ],
      ),
      isThreeLine: true,
    );
  }
}

class _Panel extends StatelessWidget {
  final String title;
  final Widget child;

  const _Panel({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFFE5E7EB)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 15, 14, 13),
            child: Text(
              title,
              style: const TextStyle(
                color: Color(0xFF263442),
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const Divider(height: 1, color: Color(0xFFE5E7EB)),
          child,
        ],
      ),
    );
  }
}
