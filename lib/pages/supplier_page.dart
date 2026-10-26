import 'package:flutter/material.dart';

import '../services/staff_api_service.dart';

class SupplierDashboardPage extends StatefulWidget {
  final StaffApiService service;

  const SupplierDashboardPage({super.key, required this.service});

  @override
  State<SupplierDashboardPage> createState() => _SupplierDashboardPageState();
}

class _SupplierDashboardPageState extends State<SupplierDashboardPage> {
  static const Color _green = Color(0xFF0D9488);
  static const Color _border = Color(0xFFE4E9EF);

  final TextEditingController _searchController = TextEditingController();
  late DateTimeRange _dateRange;
  Map<String, dynamic> _dashboard = {};
  List<Map<String, dynamic>> _orders = [];
  int _page = 1;
  int _pageCount = 1;
  int _total = 0;
  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    final today = DateUtils.dateOnly(DateTime.now());
    _dateRange = DateTimeRange(
      start: today.subtract(const Duration(days: 30)),
      end: today,
    );
    _loadDashboard();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadDashboard() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final response = await widget.service.getSupplierPortalDashboard(
        page: _page,
        pageSize: 10,
        search: _searchController.text.trim(),
        from: _dateRange.start,
        to: _dateRange.end,
      );
      final ordersResponse = response['orders'] is Map<String, dynamic>
          ? response['orders'] as Map<String, dynamic>
          : <String, dynamic>{};
      final orders = ordersResponse['data'] is List
          ? (ordersResponse['data'] as List)
                .whereType<Map<String, dynamic>>()
                .toList()
          : <Map<String, dynamic>>[];
      final meta = ordersResponse['meta'] is Map<String, dynamic>
          ? ordersResponse['meta'] as Map<String, dynamic>
          : <String, dynamic>{};
      if (!mounted) return;
      setState(() {
        _dashboard = response;
        _orders = orders;
        _total = _int(meta['total'], fallback: orders.length);
        _pageCount = _int(meta['pageCount'], fallback: 1).clamp(1, 1 << 30);
      });
    } catch (error) {
      if (mounted) setState(() => _error = error.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  int _int(dynamic value, {int fallback = 0}) =>
      int.tryParse(value?.toString() ?? '') ?? fallback;

  num _number(dynamic value) {
    if (value is num) return value;
    return num.tryParse(value?.toString() ?? '') ?? 0;
  }

  String _currency(dynamic value) => 'LKR ${_number(value).toStringAsFixed(2)}';

  String _formatDate(dynamic value) {
    final date = DateTime.tryParse(value?.toString() ?? '');
    if (date == null) return '—';
    return '${date.day}/${date.month}/${date.year}';
  }

  Future<void> _chooseDateRange() async {
    final range = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2000),
      lastDate: DateTime.now().add(const Duration(days: 1)),
      initialDateRange: _dateRange,
    );
    if (range == null || !mounted) return;
    setState(() {
      _dateRange = DateTimeRange(
        start: DateUtils.dateOnly(range.start),
        end: DateUtils.dateOnly(range.end),
      );
      _page = 1;
    });
    _loadDashboard();
  }

  Map<String, dynamic> _map(dynamic value) =>
      value is Map<String, dynamic> ? value : <String, dynamic>{};

  String _deliveryStatus(Map<String, dynamic> order) {
    if (order['status']?.toString() == 'RECEIVED') return 'Received';
    final shipments = order['supplierShipments'];
    if (shipments is List && shipments.isNotEmpty) {
      final shipment = _map(shipments.first);
      return (shipment['status'] ?? 'In transit').toString();
    }
    final responses = order['supplierResponses'];
    if (responses is! List || responses.isEmpty) return 'Pending response';
    final response = _map(responses.first);
    if (response['reviewStatus']?.toString() == 'PENDING') {
      return 'Pending response';
    }
    return (response['status'] ?? order['status'] ?? 'Pending').toString();
  }

  Future<void> _showOrder(Map<String, dynamic> order) async {
    final id = order['id']?.toString();
    if (id == null || id.isEmpty) return;
    try {
      final detail = await widget.service.getSupplierPortalOrder(id);
      if (!mounted) return;
      final branch = _map(detail['branch']);
      final items = detail['items'] is List
          ? (detail['items'] as List).whereType<Map<String, dynamic>>()
          : const <Map<String, dynamic>>[];
      await showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(detail['orderNumber']?.toString() ?? 'Purchase order'),
          content: SizedBox(
            width: 440,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  _detail('Status', detail['status']),
                  _detail('Branch', branch['name']),
                  _detail('Expected date', _formatDate(detail['expectedAt'])),
                  _detail('Total', _currency(detail['total'])),
                  const Divider(height: 24),
                  const Text(
                    'Items',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 8),
                  if (items.isEmpty) const Text('No item details available.'),
                  ...items.map((item) {
                    final product = _map(item['product']);
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(
                        (product['name'] ?? item['description'] ?? 'Item')
                            .toString(),
                      ),
                      subtitle: Text('Quantity: ${item['quantity'] ?? '—'}'),
                      trailing: Text(
                        _currency(item['lineTotal'] ?? item['total']),
                      ),
                    );
                  }),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
          ],
        ),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Unable to load purchase order: $error')),
      );
    }
  }

  Widget _detail(String label, dynamic value) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Row(
      children: [
        Expanded(child: Text(label)),
        Text(value?.toString() ?? '—'),
      ],
    ),
  );

  @override
  Widget build(BuildContext context) {
    final stats = _map(_dashboard['stats']);
    final supplier = _map(_dashboard['supplier']);
    return ColoredBox(
      color: const Color(0xFFF7F9FC),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final wide = constraints.maxWidth >= 760;
          return SingleChildScrollView(
            padding: EdgeInsets.all(wide ? 22 : 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            supplier['name']?.toString() ??
                                'Supplier Dashboard',
                            style: const TextStyle(
                              fontSize: 21,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF17212B),
                            ),
                          ),
                          const SizedBox(height: 3),
                          const Text(
                            'Dashboard  ›  Supplier Dashboard',
                            style: TextStyle(
                              fontSize: 11,
                              color: Color(0xFF718096),
                            ),
                          ),
                        ],
                      ),
                    ),
                    OutlinedButton.icon(
                      onPressed: _chooseDateRange,
                      icon: const Icon(Icons.calendar_month_outlined, size: 16),
                      label: Text(
                        '${_formatDate(_dateRange.start)} - ${_formatDate(_dateRange.end)}',
                      ),
                    ),
                    IconButton(
                      tooltip: 'Refresh',
                      onPressed: _isLoading ? null : _loadDashboard,
                      icon: const Icon(Icons.refresh),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                LayoutBuilder(
                  builder: (context, cardConstraints) {
                    final columns = cardConstraints.maxWidth >= 600 ? 3 : 1;
                    final gap = 10.0;
                    final width =
                        (cardConstraints.maxWidth - gap * (columns - 1)) /
                        columns;
                    return Wrap(
                      spacing: gap,
                      runSpacing: gap,
                      children: [
                        _summaryCard(
                          width,
                          'PENDING ORDERS',
                          _int(stats['pending']).toString(),
                          '${_int(stats['unread'])} unread notifications',
                          Icons.inventory_2_outlined,
                          const Color(0xFFB91C1C),
                        ),
                        _summaryCard(
                          width,
                          'IN TRANSIT',
                          _int(stats['inTransit']).toString(),
                          'Active shipments',
                          Icons.local_shipping_outlined,
                          const Color(0xFF12345A),
                        ),
                        _summaryCard(
                          width,
                          'COMPLETED (MTD)',
                          _int(stats['completedThisMonth']).toString(),
                          'Received this month',
                          Icons.task_alt_outlined,
                          _green,
                        ),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 18),
                _buildOrdersPanel(wide),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _summaryCard(
    double width,
    String title,
    String value,
    String subtitle,
    IconData icon,
    Color color,
  ) => Container(
    width: width,
    constraints: const BoxConstraints(minHeight: 82),
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: Colors.white,
      border: Border.all(color: _border),
      borderRadius: BorderRadius.circular(12),
    ),
    child: Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF718096),
                ),
              ),
              const SizedBox(height: 7),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF17212B),
                ),
              ),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 10,
                  color: title == 'PENDING ORDERS' && subtitle.startsWith('0')
                      ? const Color(0xFF718096)
                      : color,
                ),
              ),
            ],
          ),
        ),
        CircleAvatar(
          backgroundColor: color,
          foregroundColor: Colors.white,
          child: Icon(icon, size: 18),
        ),
      ],
    ),
  );

  Widget _buildOrdersPanel(bool wide) => Container(
    width: double.infinity,
    decoration: BoxDecoration(
      color: Colors.white,
      border: Border.all(color: _border),
      borderRadius: BorderRadius.circular(12),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              const Expanded(
                child: Text(
                  'Active Purchase Orders',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                ),
              ),
              SizedBox(
                width: wide ? 220 : 150,
                height: 38,
                child: TextField(
                  controller: _searchController,
                  onSubmitted: (_) {
                    setState(() => _page = 1);
                    _loadDashboard();
                  },
                  decoration: const InputDecoration(
                    hintText: 'Filter transfers...',
                    prefixIcon: Icon(Icons.search, size: 16),
                    contentPadding: EdgeInsets.symmetric(vertical: 8),
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
              IconButton(
                tooltip: 'Apply filters',
                onPressed: _isLoading ? null : _loadDashboard,
                icon: const Icon(Icons.filter_alt_outlined, size: 18),
              ),
            ],
          ),
        ),
        const Divider(height: 1),
        if (_isLoading)
          const SizedBox(
            height: 140,
            child: Center(child: CircularProgressIndicator()),
          )
        else if (_error != null)
          SizedBox(
            height: 140,
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Unable to load supplier orders: $_error'),
                  TextButton(
                    onPressed: _loadDashboard,
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ),
          )
        else if (_orders.isEmpty)
          const SizedBox(
            height: 110,
            child: Center(child: Text('No purchase orders found.')),
          )
        else
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              headingRowColor: WidgetStateProperty.all(const Color(0xFFF8FAFC)),
              columns: const [
                DataColumn(label: Text('PO Number')),
                DataColumn(label: Text('Date')),
                DataColumn(label: Text('Total Amount')),
                DataColumn(label: Text('Delivery Status')),
                DataColumn(label: Text('Actions')),
              ],
              rows: _orders.map((order) {
                return DataRow(
                  cells: [
                    DataCell(
                      Text(
                        order['orderNumber']?.toString() ?? '—',
                        style: const TextStyle(
                          color: _green,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      onTap: () => _showOrder(order),
                    ),
                    DataCell(Text(_formatDate(order['createdAt']))),
                    DataCell(Text(_currency(order['total']))),
                    DataCell(_statusChip(_deliveryStatus(order))),
                    DataCell(
                      IconButton(
                        tooltip: 'View order',
                        onPressed: () => _showOrder(order),
                        icon: const Icon(Icons.visibility_outlined, size: 17),
                      ),
                    ),
                  ],
                );
              }).toList(),
            ),
          ),
        const Divider(height: 1),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Row(
            children: [
              Text(
                'Rows per page: 10  ·  $_total entries',
                style: const TextStyle(fontSize: 10, color: Color(0xFF718096)),
              ),
              const Spacer(),
              IconButton(
                tooltip: 'Previous page',
                onPressed: _page > 1 && !_isLoading
                    ? () {
                        setState(() => _page--);
                        _loadDashboard();
                      }
                    : null,
                icon: const Icon(Icons.chevron_left),
              ),
              Text('$_page / $_pageCount'),
              IconButton(
                tooltip: 'Next page',
                onPressed: _page < _pageCount && !_isLoading
                    ? () {
                        setState(() => _page++);
                        _loadDashboard();
                      }
                    : null,
                icon: const Icon(Icons.chevron_right),
              ),
            ],
          ),
        ),
      ],
    ),
  );

  Widget _statusChip(String status) {
    final lower = status.toLowerCase();
    final color = lower.contains('received') || lower.contains('completed')
        ? const Color(0xFF047857)
        : lower.contains('transit') || lower.contains('dispatched')
        ? const Color(0xFF1D4ED8)
        : const Color(0xFF9A6700);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(status, style: TextStyle(color: color, fontSize: 10)),
    );
  }
}

class SuppliersPage extends StatefulWidget {
  final StaffApiService service;

  const SuppliersPage({super.key, required this.service});

  @override
  State<SuppliersPage> createState() => _SuppliersPageState();
}

class _SuppliersPageState extends State<SuppliersPage> {
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> _suppliers = [];
  int _total = 0;
  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadSuppliers();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadSuppliers() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final response = await widget.service.getSuppliers(
        page: 1,
        pageSize: 100,
        search: _searchController.text.trim(),
      );
      final suppliers = response['data'] is List
          ? (response['data'] as List)
                .whereType<Map<String, dynamic>>()
                .toList()
          : <Map<String, dynamic>>[];
      final meta = response['meta'] is Map<String, dynamic>
          ? response['meta'] as Map<String, dynamic>
          : <String, dynamic>{};
      if (!mounted) return;
      setState(() {
        _suppliers = suppliers;
        _total =
            int.tryParse(meta['total']?.toString() ?? '') ?? suppliers.length;
      });
    } catch (error) {
      if (mounted) setState(() => _error = error.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: const Color(0xFFF8F9FC),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'Suppliers',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
                  ),
                ),
                Text('$_total suppliers'),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _searchController,
              onSubmitted: (_) => _loadSuppliers(),
              decoration: const InputDecoration(
                hintText: 'Search suppliers',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _error != null
                  ? Center(child: Text('Unable to load suppliers: $_error'))
                  : _suppliers.isEmpty
                  ? const Center(child: Text('No suppliers found.'))
                  : ListView.separated(
                      itemCount: _suppliers.length,
                      separatorBuilder: (_, _) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final supplier = _suppliers[index];
                        final contact =
                            supplier['contactName'] ??
                            supplier['contactPerson'] ??
                            supplier['email'] ??
                            'No contact details';
                        return ListTile(
                          leading: const Icon(Icons.local_shipping_outlined),
                          title: Text(
                            supplier['name']?.toString() ?? 'Supplier',
                          ),
                          subtitle: Text(
                            '${supplier['code'] ?? ''} · $contact',
                          ),
                          trailing: Text(supplier['status']?.toString() ?? ''),
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
