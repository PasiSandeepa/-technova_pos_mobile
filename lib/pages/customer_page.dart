import 'package:flutter/material.dart';
import '../services/staff_api_service.dart';

class CustomersPage extends StatefulWidget {
  final StaffApiService? service;

  const CustomersPage({super.key, this.service});

  @override
  State<CustomersPage> createState() => _CustomersPageState();
}

class _CustomersPageState extends State<CustomersPage> {
  String _searchQuery = '';
  String _status = 'All statuses';
  List<Map<String, dynamic>> _customers = [];
  bool _isLoading = false;
  String? _error;
  int _total = 0;

  List<Map<String, dynamic>> get _visibleCustomers {
    final query = _searchQuery.toLowerCase();
    if (query.isEmpty) return _customers;
    return _customers.where((customer) {
      final name =
          customer['name']?.toString() ??
          '${customer['firstName'] ?? ''} ${customer['lastName'] ?? ''}';
      return [
        name,
        customer['customerNumber'],
        customer['phone'],
      ].join(' ').toLowerCase().contains(query);
    }).toList();
  }

  @override
  void initState() {
    super.initState();
    _loadCustomers();
  }

  Future<void> _loadCustomers() async {
    final service = widget.service;
    if (service == null) {
      setState(() => _error = 'Staff sign-in is required to load customers.');
      return;
    }
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final response = await service.getCustomers(
        page: 1,
        pageSize: 100,
        search: _searchQuery,
        status: _status == 'All statuses' ? null : _status,
      );
      final rows = response['data'] is List
          ? (response['data'] as List)
                .whereType<Map<String, dynamic>>()
                .toList()
          : <Map<String, dynamic>>[];
      final meta = response['meta'] is Map<String, dynamic>
          ? response['meta'] as Map<String, dynamic>
          : <String, dynamic>{};
      if (!mounted) return;
      setState(() {
        _customers = rows;
        _total = int.tryParse(meta['total']?.toString() ?? '') ?? rows.length;
      });
    } catch (error) {
      if (mounted) setState(() => _error = error.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F7FC),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              const Text(
                'CRM',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF159A8C),
                ),
              ),

              const SizedBox(height: 2),

              const Text(
                'Customers',
                style: TextStyle(
                  fontSize: 21,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF202124),
                ),
              ),

              const SizedBox(height: 2),

              const Text(
                'Customer profiles, loyalty and credit exposure.',
                style: TextStyle(fontSize: 11, color: Color(0xFF8A8A8A)),
              ),

              const SizedBox(height: 18),

              // Main Card
              Expanded(
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFE8E8E8)),
                  ),
                  child: Column(
                    children: [
                      // Search + Status
                      Row(
                        children: [
                          Expanded(
                            child: SizedBox(
                              height: 34,
                              child: TextField(
                                onChanged: (value) =>
                                    setState(() => _searchQuery = value.trim()),
                                onSubmitted: (_) => _loadCustomers(),
                                decoration: InputDecoration(
                                  hintText: 'Search number, name or phone',
                                  hintStyle: const TextStyle(
                                    fontSize: 11,
                                    color: Color(0xFFAAAAAA),
                                  ),
                                  prefixIcon: const Icon(
                                    Icons.search,
                                    size: 17,
                                    color: Color(0xFFB0B8C0),
                                  ),
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                  ),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: const BorderSide(
                                      color: Color(0xFFE5E5E5),
                                    ),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: const BorderSide(
                                      color: Color(0xFFE5E5E5),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(width: 10),

                          SizedBox(
                            width: 140,
                            height: 34,
                            child: DropdownButtonFormField<String>(
                              isExpanded: true,
                              initialValue: _status,
                              items: const [
                                DropdownMenuItem(
                                  value: 'All statuses',
                                  child: Text('All statuses'),
                                ),
                                DropdownMenuItem(
                                  value: 'ACTIVE',
                                  child: Text('ACTIVE'),
                                ),
                                DropdownMenuItem(
                                  value: 'INACTIVE',
                                  child: Text('INACTIVE'),
                                ),
                              ],
                              onChanged: (value) {
                                if (value == null) return;
                                setState(() => _status = value);
                                _loadCustomers();
                              },
                              style: const TextStyle(
                                fontSize: 11,
                                color: Color(0xFF444444),
                              ),
                              decoration: InputDecoration(
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: const BorderSide(
                                    color: Color(0xFFE5E5E5),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 12),

                      // Table
                      Expanded(
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: SizedBox(
                            width: 1200,
                            child: Column(
                              children: [
                                // Table Header
                                Container(
                                  height: 36,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                  ),
                                  color: const Color(0xFFF8F9FA),
                                  child: const Row(
                                    children: [
                                      Expanded(
                                        flex: 2,
                                        child: Text(
                                          'Customer',
                                          style: _headerStyle,
                                        ),
                                      ),
                                      Expanded(
                                        flex: 2,
                                        child: Text(
                                          'Contact',
                                          style: _headerStyle,
                                        ),
                                      ),
                                      Expanded(
                                        flex: 2,
                                        child: Text(
                                          'Credit',
                                          style: _headerStyle,
                                        ),
                                      ),
                                      Expanded(
                                        flex: 1,
                                        child: Text(
                                          'Loyalty',
                                          style: _headerStyle,
                                        ),
                                      ),
                                      Expanded(
                                        flex: 2,
                                        child: Text(
                                          'Status',
                                          style: _headerStyle,
                                        ),
                                      ),
                                      Expanded(
                                        flex: 2,
                                        child: Text(
                                          'Actions',
                                          textAlign: TextAlign.right,
                                          style: _headerStyle,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                                if (_isLoading)
                                  const SizedBox(
                                    height: 58,
                                    child: Center(
                                      child: CircularProgressIndicator(),
                                    ),
                                  )
                                else if (_error != null)
                                  SizedBox(
                                    height: 58,
                                    child: Center(child: Text(_error!)),
                                  )
                                else if (_visibleCustomers.isEmpty)
                                  const SizedBox(
                                    height: 58,
                                    child: Center(
                                      child: Text('No customers found'),
                                    ),
                                  )
                                else
                                  ..._visibleCustomers.map(_customerRow),
                              ],
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 8),

                      // Footer
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              'Showing ${_visibleCustomers.isEmpty ? 0 : 1}–${_visibleCustomers.length} of $_total',
                              style: TextStyle(
                                fontSize: 10,
                                color: Color(0xFF777777),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static const TextStyle _headerStyle = TextStyle(
    fontSize: 10,
    fontWeight: FontWeight.w600,
    color: Color(0xFF444444),
  );

  Widget _customerRow(Map<String, dynamic> customer) {
    final name =
        customer['name']?.toString() ??
        '${customer['firstName'] ?? ''} ${customer['lastName'] ?? ''}'.trim();
    final loyalty = customer['loyaltyAccount'] is Map<String, dynamic>
        ? customer['loyaltyAccount'] as Map<String, dynamic>
        : <String, dynamic>{};
    final credit = customer['storeCreditAccount'] is Map<String, dynamic>
        ? customer['storeCreditAccount'] as Map<String, dynamic>
        : <String, dynamic>{};
    final points = customer['loyaltyPoints'] ?? loyalty['points'] ?? 0;
    final balance = customer['creditBalance'] ?? credit['balance'] ?? 0;
    final limit = customer['creditLimit'] ?? 0;

    return Container(
      height: 58,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xFFF0F0F0))),
      ),
      child: Row(
        children: [
          Expanded(flex: 2, child: _customerInfo(customer, name)),
          Expanded(
            flex: 2,
            child: Text(
              '${customer['phone'] ?? '—'}\n${customer['email'] ?? '—'}',
              style: const TextStyle(fontSize: 11, color: Color(0xFF777777)),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              'Balance $balance\nLimit $limit',
              style: const TextStyle(fontSize: 11, color: Color(0xFF777777)),
            ),
          ),
          Expanded(
            flex: 1,
            child: Text('$points pts', style: const TextStyle(fontSize: 11)),
          ),
          Expanded(
            flex: 2,
            child: Text(
              customer['status']?.toString() ?? '—',
              style: const TextStyle(fontSize: 10, color: Color(0xFF555555)),
            ),
          ),
          Expanded(
            flex: 2,
            child: Align(
              alignment: Alignment.centerRight,
              child: IconButton(
                tooltip: 'View customer',
                onPressed: () => _showCustomer(customer),
                icon: const Icon(Icons.open_in_new, size: 17),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showCustomer(Map<String, dynamic> customer) {
    final name =
        customer['name']?.toString() ??
        '${customer['firstName'] ?? ''} ${customer['lastName'] ?? ''}'.trim();
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(name.isEmpty ? 'Customer' : name),
        content: SelectableText(
          [
            'Customer number: ${customer['customerNumber'] ?? '—'}',
            'Phone: ${customer['phone'] ?? '—'}',
            'Email: ${customer['email'] ?? '—'}',
            'Status: ${customer['status'] ?? '—'}',
          ].join('\n'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _customerInfo(Map<String, dynamic> customer, String name) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          name.isEmpty ? 'Customer' : name,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: Color(0xFF333333),
          ),
        ),
        SizedBox(height: 2),
        Text(
          customer['customerNumber']?.toString() ?? '—',
          style: TextStyle(fontSize: 9, color: Color(0xFF999999)),
        ),
      ],
    );
  }
}
