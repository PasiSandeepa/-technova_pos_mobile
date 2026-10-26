import 'package:flutter/material.dart';

import '../services/staff_api_service.dart';

class InventoryPage extends StatefulWidget {
  final StaffApiService service;

  const InventoryPage({super.key, required this.service});

  @override
  State<InventoryPage> createState() => _InventoryPageState();
}

class _InventoryPageState extends State<InventoryPage> {
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> _stock = [];
  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadStock();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadStock() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final response = await widget.service.getInventoryStock(
        page: 1,
        pageSize: 100,
        search: _searchController.text.trim(),
      );
      final stock = response['data'] is List
          ? (response['data'] as List)
                .whereType<Map<String, dynamic>>()
                .toList()
          : <Map<String, dynamic>>[];
      if (!mounted) return;
      setState(() => _stock = stock);
    } catch (error) {
      if (mounted) setState(() => _error = error.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String _text(dynamic value) => value?.toString() ?? '—';

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: const Color(0xFFF8F9FC),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Inventory',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    onSubmitted: (_) => _loadStock(),
                    decoration: const InputDecoration(
                      hintText: 'Search product or SKU',
                      prefixIcon: Icon(Icons.search),
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  tooltip: 'Refresh inventory',
                  onPressed: _isLoading ? null : _loadStock,
                  icon: const Icon(Icons.refresh),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _error != null
                  ? Center(child: Text('Unable to load inventory: $_error'))
                  : _stock.isEmpty
                  ? const Center(child: Text('No inventory records found.'))
                  : ListView.separated(
                      itemCount: _stock.length,
                      separatorBuilder: (_, _) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final item = _stock[index];
                        final product = item['product'] is Map<String, dynamic>
                            ? item['product'] as Map<String, dynamic>
                            : <String, dynamic>{};
                        final branch = item['branch'] is Map<String, dynamic>
                            ? item['branch'] as Map<String, dynamic>
                            : <String, dynamic>{};
                        final name =
                            item['productName'] ??
                            product['name'] ??
                            item['name'] ??
                            'Product';
                        final sku = item['sku'] ?? product['sku'] ?? '';
                        final quantity =
                            item['quantity'] ??
                            item['availableQuantity'] ??
                            item['onHand'] ??
                            item['stockQuantity'] ??
                            0;
                        final branchName =
                            item['branchName'] ??
                            branch['name'] ??
                            'All branches';
                        return ListTile(
                          leading: const Icon(Icons.inventory_2_outlined),
                          title: Text(_text(name)),
                          subtitle: Text(
                            'SKU ${_text(sku)} · ${_text(branchName)}',
                          ),
                          trailing: Text(
                            _text(quantity),
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
