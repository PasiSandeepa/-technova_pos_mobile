import 'dart:convert';

import 'package:flutter/material.dart';
import '../services/staff_api_service.dart';

class SalesPage extends StatefulWidget {
  final StaffApiService? service;

  const SalesPage({super.key, this.service});

  @override
  State<SalesPage> createState() => _SalesPageState();
}

class _SalesPageState extends State<SalesPage> {
  final TextEditingController searchController = TextEditingController();
  final List<Map<String, dynamic>> _sales = [];
  List<Map<String, dynamic>> _branches = [];
  Map<String, String> _cashierNames = {};
  bool _isLoading = false;
  String? _loadError;
  int _page = 1;
  int _pageSize = 20;
  int _pageCount = 1;
  int _total = 0;

  String status = 'All statuses';
  String branch = 'All branches';
  String cashier = 'All cashiers';
  DateTime? fromDate;
  DateTime? toDate;

  final Color primaryColor = const Color(0xFF079B8C);
  final Color backgroundColor = const Color(0xFFF7F8FB);
  final Color borderColor = const Color(0xFFE5E8EC);

  @override
  void initState() {
    super.initState();
    if (widget.service != null) {
      _loadBranches();
      _loadSales();
    }
  }

  Future<void> _loadBranches() async {
    try {
      final branches = await widget.service!.getBranches();
      if (mounted) setState(() => _branches = branches);
    } catch (_) {
      // Sales remain usable with the all-branches filter if this fails.
    }
  }

  Future<void> _loadSales() async {
    final service = widget.service;
    if (service == null) return;
    setState(() {
      _isLoading = true;
      _loadError = null;
    });
    try {
      final result = await service.getSales(
        page: _page,
        pageSize: _pageSize,
        search: searchController.text.trim(),
        branchId: branch == 'All branches' ? null : branch,
        cashierId: cashier == 'All cashiers' ? null : cashier,
        status: status == 'All statuses' ? null : status,
        from: fromDate,
        to: toDate,
      );
      final meta = result['meta'] is Map<String, dynamic>
          ? result['meta'] as Map<String, dynamic>
          : <String, dynamic>{};
      final rows = result['data'] is List
          ? (result['data'] as List).whereType<Map<String, dynamic>>().toList()
          : <Map<String, dynamic>>[];
      final cashiers = <String, String>{};
      for (final sale in rows) {
        final createdBy = sale['createdBy'] is Map<String, dynamic>
            ? sale['createdBy'] as Map<String, dynamic>
            : <String, dynamic>{};
        final id =
            sale['createdById']?.toString() ?? createdBy['id']?.toString();
        final name =
            createdBy['email']?.toString() ??
            createdBy['name']?.toString() ??
            id;
        if (id != null && name != null) cashiers[id] = name;
      }
      if (!mounted) return;
      setState(() {
        _sales
          ..clear()
          ..addAll(rows);
        _cashierNames = {..._cashierNames, ...cashiers};
        _total = int.tryParse(meta['total']?.toString() ?? '') ?? rows.length;
        _pageCount = int.tryParse(meta['pageCount']?.toString() ?? '') ?? 1;
      });
    } catch (error) {
      if (mounted) setState(() => _loadError = error.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _clearFilters() {
    searchController.clear();
    setState(() {
      status = 'All statuses';
      branch = 'All branches';
      cashier = 'All cashiers';
      fromDate = null;
      toDate = null;
      _page = 1;
    });
    _loadSales();
  }

  String _saleText(Map<String, dynamic> sale, String key) =>
      sale[key]?.toString() ?? '';

  num _saleNumber(Map<String, dynamic> sale, List<String> keys) {
    for (final key in keys) {
      final value = sale[key];
      if (value is num) return value;
      final parsed = num.tryParse(value?.toString() ?? '');
      if (parsed != null) return parsed;
    }
    return 0;
  }

  String _currency(num value) => 'LKR ${value.toStringAsFixed(2)}';

  Future<void> _showSaleDetails(Map<String, dynamic> sale) async {
    final service = widget.service;
    final id = sale['id']?.toString();
    if (service == null || id == null || id.isEmpty) return;
    try {
      final details = await service.getSaleDetail(id);
      if (!mounted) return;
      await showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(sale['invoiceNumber']?.toString() ?? 'Sale details'),
          content: SingleChildScrollView(
            child: SelectableText(
              const JsonEncoder.withIndent('  ').convert(details),
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
        SnackBar(content: Text('Unable to load sale details: $error')),
      );
    }
  }

  Future<void> selectDate(bool isFrom) async {
    final picked = await showDatePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      initialDate: DateTime.now(),
    );

    if (picked != null) {
      setState(() {
        if (isFrom) {
          fromDate = picked;
        } else {
          toDate = picked;
        }
      });
    }
  }

  String formatDate(DateTime? date) {
    if (date == null) return "dd/mm/yyyy";

    return "${date.day.toString().padLeft(2, '0')}/"
        "${date.month.toString().padLeft(2, '0')}/"
        "${date.year}";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final bool isMobile = constraints.maxWidth < 700;

            return SingleChildScrollView(
              padding: EdgeInsets.all(isMobile ? 16 : 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(isMobile),
                  const SizedBox(height: 18),

                  _buildFilters(isMobile),
                  const SizedBox(height: 18),

                  _buildSalesReport(isMobile),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  // ============================================================
  // HEADER
  // ============================================================

  Widget _buildHeader(bool isMobile) {
    if (isMobile) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "TRANSACTIONS",
            style: TextStyle(
              color: primaryColor,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.7,
            ),
          ),
          const SizedBox(height: 3),

          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Sales",
                style: TextStyle(
                  fontSize: 25,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF263238),
                ),
              ),
              SizedBox(height: 4),
              Text(
                "Completed sales, payment balances and receipt details.",
                style: TextStyle(
                  fontSize: 12,
                  color: Color(0xFF757575),
                  height: 1.4,
                ),
              ),
            ],
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "TRANSACTIONS",
          style: TextStyle(
            color: primaryColor,
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.7,
          ),
        ),
        const SizedBox(height: 3),
        const Text(
          "Sales",
          style: TextStyle(
            fontSize: 25,
            fontWeight: FontWeight.w700,
            color: Color(0xFF263238),
          ),
        ),
        const SizedBox(height: 3),
        Text(
          "Completed sales, payment balances and receipt details.",
          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
        ),
      ],
    );
  }

  // ============================================================
  // FILTERS
  // ============================================================

  Widget _buildFilters(bool isMobile) {
    return Container(
      padding: EdgeInsets.all(isMobile ? 12 : 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.025),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: isMobile
          ? Column(
              children: [
                _searchField(),
                const SizedBox(height: 10),

                Row(
                  children: [
                    Expanded(child: _statusDropdown()),
                    const SizedBox(width: 10),
                    Expanded(child: _branchDropdown()),
                  ],
                ),

                const SizedBox(height: 10),

                Row(
                  children: [
                    Expanded(child: _cashierDropdown()),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _dateField(
                        label: "From",
                        date: fromDate,
                        onTap: () => selectDate(true),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 10),

                Row(
                  children: [
                    Expanded(
                      child: _dateField(
                        label: "To",
                        date: toDate,
                        onTap: () => selectDate(false),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: SizedBox(
                        height: 44,
                        child: ElevatedButton.icon(
                          onPressed: _isLoading ? null : _loadSales,
                          icon: const Icon(Icons.refresh, size: 16),
                          label: const Text(
                            "Generate report",
                            style: TextStyle(fontSize: 11),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primaryColor,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 10),

                SizedBox(
                  width: double.infinity,
                  height: 42,
                  child: OutlinedButton(
                    onPressed: () {
                      _clearFilters();
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.grey.shade700,
                      side: BorderSide(color: borderColor),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text(
                      "Clear filters",
                      style: TextStyle(fontSize: 12),
                    ),
                  ),
                ),
              ],
            )
          : Row(
              children: [
                Expanded(flex: 2, child: _searchField()),
                const SizedBox(width: 10),

                Expanded(child: _statusDropdown()),
                const SizedBox(width: 10),

                Expanded(child: _branchDropdown()),
                const SizedBox(width: 10),

                Expanded(child: _cashierDropdown()),
                const SizedBox(width: 10),

                Expanded(
                  child: _dateField(
                    label: "From",
                    date: fromDate,
                    onTap: () => selectDate(true),
                  ),
                ),

                const SizedBox(width: 10),

                Expanded(
                  child: _dateField(
                    label: "To",
                    date: toDate,
                    onTap: () => selectDate(false),
                  ),
                ),

                const SizedBox(width: 10),

                Expanded(
                  child: SizedBox(
                    height: 44,
                    child: ElevatedButton.icon(
                      onPressed: _isLoading ? null : _loadSales,
                      icon: const Icon(Icons.refresh, size: 15),
                      label: const Text(
                        "Generate report",
                        style: TextStyle(fontSize: 11),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryColor,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                ),

                const SizedBox(width: 10),

                Expanded(
                  child: SizedBox(
                    height: 44,
                    child: OutlinedButton(
                      onPressed: _clearFilters,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.grey.shade700,
                        side: BorderSide(color: borderColor),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text(
                        "Clear filters",
                        style: TextStyle(fontSize: 11),
                      ),
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  // ============================================================
  // SEARCH
  // ============================================================

  Widget _searchField() {
    return _fieldContainer(
      child: TextField(
        controller: searchController,
        onSubmitted: (_) => _loadSales(),
        style: const TextStyle(fontSize: 12),
        decoration: InputDecoration(
          hintText: "Invoice or customer",
          hintStyle: TextStyle(color: Colors.grey.shade500, fontSize: 12),
          prefixIcon: Icon(Icons.search, size: 17, color: Colors.grey.shade500),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 10,
            vertical: 13,
          ),
        ),
      ),
    );
  }

  // ============================================================
  // DROPDOWNS
  // ============================================================

  Widget _statusDropdown() {
    return _dropdown(
      value: status,
      items: const [
        "All statuses",
        "COMPLETED",
        "PARTIALLY_REFUNDED",
        "REFUNDED",
        "VOIDED",
      ],
      onChanged: (value) {
        setState(() {
          status = value!;
        });
      },
    );
  }

  Widget _branchDropdown() {
    final items = <DropdownMenuItem<String>>[
      const DropdownMenuItem(
        value: 'All branches',
        child: Text('All branches'),
      ),
      ..._branches
          .map((item) {
            final id = item['id']?.toString() ?? '';
            final name = item['name']?.toString() ?? id;
            return DropdownMenuItem(value: id, child: Text(name));
          })
          .where((item) => item.value?.isNotEmpty == true),
    ];
    final selected = items.any((item) => item.value == branch)
        ? branch
        : 'All branches';
    return _fieldContainer(
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: selected,
          isExpanded: true,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          items: items,
          onChanged: (value) {
            if (value != null) setState(() => branch = value);
          },
        ),
      ),
    );
  }

  Widget _cashierDropdown() {
    final items = <DropdownMenuItem<String>>[
      const DropdownMenuItem(
        value: 'All cashiers',
        child: Text('All cashiers'),
      ),
      ..._cashierNames.entries.map(
        (entry) => DropdownMenuItem(value: entry.key, child: Text(entry.value)),
      ),
    ];
    final selected = items.any((item) => item.value == cashier)
        ? cashier
        : 'All cashiers';
    return _fieldContainer(
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: selected,
          isExpanded: true,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          items: items,
          onChanged: (value) {
            if (value != null) setState(() => cashier = value);
          },
        ),
      ),
    );
  }

  Widget _dropdown({
    required String value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    return _fieldContainer(
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isExpanded: true,
          icon: Icon(
            Icons.keyboard_arrow_down,
            size: 18,
            color: Colors.grey.shade600,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 10),
          style: const TextStyle(fontSize: 12, color: Color(0xFF37474F)),
          items: items.map((item) {
            return DropdownMenuItem(
              value: item,
              child: Text(item, overflow: TextOverflow.ellipsis),
            );
          }).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }

  // ============================================================
  // DATE FIELD
  // ============================================================

  Widget _dateField({
    required String label,
    required DateTime? date,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        height: 44,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: borderColor),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(fontSize: 9, color: Colors.grey.shade500),
                  ),
                  const SizedBox(height: 1),
                  Text(
                    formatDate(date),
                    style: TextStyle(
                      fontSize: 11,
                      color: date == null
                          ? Colors.grey.shade500
                          : Colors.grey.shade800,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.calendar_today_outlined,
              size: 15,
              color: Colors.grey.shade600,
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // FIELD CONTAINER
  // ============================================================

  Widget _fieldContainer({required Widget child}) {
    return Container(
      height: 44,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: borderColor),
        borderRadius: BorderRadius.circular(8),
      ),
      child: child,
    );
  }

  // ============================================================
  // SALES REPORT
  // ============================================================

  Widget _buildSalesReport(bool isMobile) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          _reportHeader(isMobile),

          const Divider(height: 1, color: Color(0xFFE8EBEE)),

          _emptyTable(isMobile),

          const Divider(height: 1, color: Color(0xFFE8EBEE)),

          _pagination(isMobile),
        ],
      ),
    );
  }

  // ============================================================
  // REPORT HEADER
  // ============================================================

  Widget _reportHeader(bool isMobile) {
    return Padding(
      padding: EdgeInsets.all(isMobile ? 12 : 14),
      child: isMobile
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Sales Report",
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF37474F),
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  "$_total matching transactions",
                  style: TextStyle(fontSize: 10, color: Colors.grey.shade500),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    _exportButton(
                      icon: Icons.picture_as_pdf_outlined,
                      label: "PDF",
                      color: Colors.red.shade300,
                    ),
                    const SizedBox(width: 7),
                    _exportButton(
                      icon: Icons.table_chart_outlined,
                      label: "CSV",
                      color: primaryColor,
                    ),
                    const SizedBox(width: 7),
                    _iconButton(Icons.print_outlined),
                  ],
                ),
              ],
            )
          : Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Sales Report",
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF37474F),
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        "$_total matching transactions",
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.grey.shade500,
                        ),
                      ),
                    ],
                  ),
                ),

                _exportButton(
                  icon: Icons.picture_as_pdf_outlined,
                  label: "PDF",
                  color: Colors.red.shade300,
                ),
                const SizedBox(width: 7),

                _exportButton(
                  icon: Icons.table_chart_outlined,
                  label: "CSV",
                  color: primaryColor,
                ),
                const SizedBox(width: 7),

                _iconButton(Icons.print_outlined),
              ],
            ),
    );
  }

  Widget _exportButton({
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: color.withOpacity(0.06),
        borderRadius: BorderRadius.circular(7),
        border: Border.all(color: color.withOpacity(0.15)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _iconButton(IconData icon) {
    return Container(
      width: 34,
      height: 34,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(7),
        border: Border.all(color: borderColor),
      ),
      child: Icon(icon, size: 16, color: Colors.grey.shade600),
    );
  }

  // ============================================================
  // TABLE
  // ============================================================

  Widget _emptyTable(bool isMobile) {
    final columns = [
      "Invoice",
      "Customer",
      "Cashier",
      "Items",
      "Original amount",
      "Discount given",
      "Tax",
      "Final amount",
      "Paid",
      "Balance",
      "Status",
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: SizedBox(
        width: isMobile ? 1100 : double.infinity,
        child: Column(
          children: [
            Container(
              height: 34,
              color: const Color(0xFFF8F9FA),
              child: Row(
                children: columns.map((column) {
                  return SizedBox(
                    width: _columnWidth(column),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          column,
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),

            if (_isLoading)
              const SizedBox(
                height: 82,
                child: Center(child: CircularProgressIndicator()),
              )
            else if (_loadError != null)
              SizedBox(height: 82, child: Center(child: Text(_loadError!)))
            else if (_sales.isEmpty)
              SizedBox(
                height: 82,
                child: Center(
                  child: Text(
                    "No sales match these filters.",
                    style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                  ),
                ),
              )
            else
              ..._sales.map(_saleRow),
          ],
        ),
      ),
    );
  }

  Widget _saleRow(Map<String, dynamic> sale) {
    final customer = sale['customer'] is Map<String, dynamic>
        ? sale['customer'] as Map<String, dynamic>
        : <String, dynamic>{};
    final createdBy = sale['createdBy'] is Map<String, dynamic>
        ? sale['createdBy'] as Map<String, dynamic>
        : <String, dynamic>{};
    final customerName =
        customer['name']?.toString() ??
        '${customer['firstName'] ?? ''} ${customer['lastName'] ?? ''}'.trim();
    final items = sale['items'] is List ? (sale['items'] as List).length : 0;
    final values = [
      _saleText(sale, 'invoiceNumber'),
      customerName.isEmpty ? 'Walk-in' : customerName,
      createdBy['email']?.toString() ?? sale['cashier']?.toString() ?? '—',
      '$items',
      _currency(_saleNumber(sale, ['subtotal'])),
      _currency(_saleNumber(sale, ['discountTotal', 'discount'])),
      _currency(_saleNumber(sale, ['taxTotal', 'tax'])),
      _currency(_saleNumber(sale, ['total'])),
      _currency(_saleNumber(sale, ['paidTotal', 'paid'])),
      _currency(_saleNumber(sale, ['balanceDue', 'balance'])),
      _saleText(sale, 'status'),
    ];
    return InkWell(
      onTap: () => _showSaleDetails(sale),
      child: SizedBox(
        height: 48,
        child: Row(
          children: [
            for (var index = 0; index < values.length; index++)
              SizedBox(
                width: _columnWidth(
                  [
                    'Invoice',
                    'Customer',
                    'Cashier',
                    'Items',
                    'Original amount',
                    'Discount given',
                    'Tax',
                    'Final amount',
                    'Paid',
                    'Balance',
                    'Status',
                  ][index],
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      values[index],
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 10),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  double _columnWidth(String column) {
    switch (column) {
      case "Invoice":
        return 100;
      case "Customer":
        return 130;
      case "Cashier":
        return 110;
      case "Items":
        return 70;
      case "Original amount":
        return 130;
      case "Discount given":
        return 130;
      case "Tax":
        return 90;
      case "Final amount":
        return 120;
      case "Paid":
        return 100;
      case "Balance":
        return 100;
      case "Status":
        return 100;
      default:
        return 100;
    }
  }

  // ============================================================
  // PAGINATION
  // ============================================================

  Widget _pagination(bool isMobile) {
    return Padding(
      padding: EdgeInsets.all(isMobile ? 12 : 12),
      child: isMobile
          ? Column(
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    "Showing ${_total == 0 ? 0 : (_page - 1) * _pageSize + 1}–${(_page - 1) * _pageSize + _sales.length} of $_total",
                    style: TextStyle(fontSize: 10, color: Colors.grey.shade600),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    _rowsDropdown(),
                    const SizedBox(width: 8),
                    _pageButton('Previous', enabled: _page > 1),
                    const SizedBox(width: 5),
                    Text(
                      "Page $_page of ${_pageCount < 1 ? 1 : _pageCount}",
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(width: 5),
                    _pageButton('Next', enabled: _page < _pageCount),
                  ],
                ),
              ],
            )
          : Row(
              children: [
                Expanded(
                  child: Text(
                    "Showing ${_total == 0 ? 0 : (_page - 1) * _pageSize + 1}–${(_page - 1) * _pageSize + _sales.length} of $_total",
                    style: TextStyle(fontSize: 10, color: Colors.grey.shade600),
                  ),
                ),

                _rowsDropdown(),

                const SizedBox(width: 8),

                _pageButton('Previous', enabled: _page > 1),

                const SizedBox(width: 8),

                Text(
                  "Page $_page of ${_pageCount < 1 ? 1 : _pageCount}",
                  style: TextStyle(fontSize: 10, color: Colors.grey.shade600),
                ),

                const SizedBox(width: 8),

                _pageButton('Next', enabled: _page < _pageCount),
              ],
            ),
    );
  }

  Widget _rowsDropdown() {
    return Container(
      height: 34,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: borderColor),
        borderRadius: BorderRadius.circular(7),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<int>(
          value: _pageSize,
          icon: const Icon(Icons.keyboard_arrow_down, size: 15),
          style: TextStyle(fontSize: 10, color: Colors.grey.shade700),
          items: const [
            DropdownMenuItem(value: 10, child: Text("10 rows")),
            DropdownMenuItem(value: 20, child: Text("20 rows")),
            DropdownMenuItem(value: 50, child: Text("50 rows")),
          ],
          onChanged: (value) {
            if (value == null) return;
            setState(() {
              _pageSize = value;
              _page = 1;
            });
            _loadSales();
          },
        ),
      ),
    );
  }

  Widget _pageButton(String text, {required bool enabled}) {
    return SizedBox(
      height: 34,
      child: OutlinedButton(
        onPressed: enabled && !_isLoading
            ? () {
                setState(() => _page += text == 'Next' ? 1 : -1);
                _loadSales();
              }
            : null,
        child: Text(text),
      ),
    );
  }
}
