import 'dart:convert';
import 'dart:typed_data';

import 'package:file_saver/file_saver.dart';
import 'package:flutter/material.dart';
import 'package:pdf/widgets.dart' as pw;
import '../services/staff_api_service.dart';

class ReportPage extends StatefulWidget {
  final StaffApiService? service;
  final bool showReportCatalogue;

  const ReportPage({super.key, this.service, this.showReportCatalogue = true});

  @override
  State<ReportPage> createState() => _ReportPageState();
}

class _ReportPageState extends State<ReportPage> {
  static const Color _green = Color(0xFF0D9488);
  static const Color _darkGreen = Color(0xFF115E59);
  static const Color _background = Color(0xFFF8F9FC);
  static const Color _border = Color(0xFFE5E7EB);

  late DateTime _fromDate;
  late DateTime _toDate;
  DateTime? _appliedFromDate;
  DateTime? _appliedToDate;
  String? _selectedReport;
  bool _isExporting = false;
  bool _isLoading = false;
  String? _loadError;
  Map<String, dynamic> _dashboardData = {};

  final List<_SalesRecord> _salesData = [];

  final List<_ReportEntry> _reports = const [
    _ReportEntry(
      'Sales',
      'Invoices, cashiers, customers and payments',
      Icons.point_of_sale_outlined,
    ),
    _ReportEntry(
      'Purchase orders',
      'Suppliers, values, receipts and statuses',
      Icons.shopping_cart_outlined,
    ),
    _ReportEntry(
      'Inventory valuation',
      'On-hand, reserved, cost and retail values',
      Icons.inventory_2_outlined,
    ),
    _ReportEntry(
      'Low stock',
      'Products at or below reorder level',
      Icons.warning_amber_rounded,
    ),
    _ReportEntry(
      'Stock movements',
      'Receipts, sales, returns and adjustments',
      Icons.swap_horiz_rounded,
    ),
    _ReportEntry(
      'Stock transfers',
      'Outgoing, incoming and received quantities',
      Icons.local_shipping_outlined,
    ),
    _ReportEntry(
      'Returns & refunds',
      'Reasons, resolutions and refund values',
      Icons.assignment_return_outlined,
    ),
    _ReportEntry(
      'Customers',
      'Sales, credit and loyalty overview',
      Icons.people_outline,
    ),
    _ReportEntry(
      'Credit aging',
      'Outstanding balances and overdue buckets',
      Icons.account_balance_wallet_outlined,
    ),
    _ReportEntry(
      'Warranties',
      'Policies, serials, status and expiry',
      Icons.verified_outlined,
    ),
    _ReportEntry(
      'Employees & access',
      'Roles, branches, states and last login',
      Icons.badge_outlined,
    ),
  ];

  @override
  void initState() {
    super.initState();
    final today = DateUtils.dateOnly(DateTime.now());
    _toDate = today;
    _fromDate = today.subtract(const Duration(days: 30));
    _appliedFromDate = _fromDate;
    _appliedToDate = _toDate;
    _selectedReport = 'Sales';
    if (widget.service != null) {
      _salesData.clear();
      _loadReports();
    }
  }

  Future<void> _loadReports() async {
    final service = widget.service;
    if (service == null) return;
    setState(() {
      _isLoading = true;
      _loadError = null;
    });
    try {
      final dashboard = await service.getReportDashboard(
        from: _appliedFromDate!,
        to: _appliedToDate!,
      );
      final sales = widget.showReportCatalogue
          ? await service.getSalesReport(
              from: _appliedFromDate!,
              to: _appliedToDate!,
            )
          : <Map<String, dynamic>>[];
      final records = sales.map((sale) {
        final dateValue = sale['date'] ?? sale['createdAt'];
        final date =
            DateTime.tryParse(dateValue?.toString() ?? '') ?? DateTime.now();
        return _SalesRecord(
          invoice: sale['invoiceNumber']?.toString() ?? '',
          customer: sale['customer']?.toString() ?? 'Walk-in',
          cashier: sale['cashier']?.toString() ?? '',
          items: int.tryParse(sale['items']?.toString() ?? '') ?? 0,
          originalAmount: _asDouble(sale['subtotal']),
          discount: _asDouble(sale['discount']),
          tax: _asDouble(sale['tax']),
          finalAmount: _asDouble(sale['total']),
          paid: _asDouble(sale['paid']),
          balance: _asDouble(sale['balanceDue']),
          status: sale['status']?.toString() ?? '',
          date: date,
        );
      }).toList();
      if (!mounted) return;
      setState(() {
        _dashboardData = dashboard;
        _salesData
          ..clear()
          ..addAll(records);
      });
    } catch (error) {
      if (mounted) setState(() => _loadError = error.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  double _asDouble(dynamic value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '') ?? 0;
  }

  String get _activeReport => _selectedReport ?? 'Organization performance';

  List<_SalesRecord> get _filteredSales {
    if (_appliedFromDate == null || _appliedToDate == null) {
      return _salesData;
    }

    return _salesData.where((sale) {
      final saleDate = DateUtils.dateOnly(sale.date);
      final from = DateUtils.dateOnly(_appliedFromDate!);
      final to = DateUtils.dateOnly(_appliedToDate!);
      return !saleDate.isBefore(from) && !saleDate.isAfter(to);
    }).toList();
  }

  String _formatCurrency(num value) => 'LKR ${value.toStringAsFixed(2)}';

  String _formatDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    return '$day/$month/${date.year}';
  }

  String _fileDate(DateTime date) =>
      '${date.year}${date.month.toString().padLeft(2, '0')}${date.day.toString().padLeft(2, '0')}';

  Future<void> _chooseDate({required bool isFromDate}) async {
    final currentDate = isFromDate ? _fromDate : _toDate;
    final chosenDate = await showDatePicker(
      context: context,
      initialDate: currentDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (chosenDate == null || !mounted) return;

    setState(() {
      if (isFromDate) {
        _fromDate = DateUtils.dateOnly(chosenDate);
      } else {
        _toDate = DateUtils.dateOnly(chosenDate);
      }
    });
  }

  List<List<String>> get _reportRows {
    final filteredSales = _filteredSales;
    final salesSummary = _dashboardData['sales'] is Map<String, dynamic>
        ? _dashboardData['sales'] as Map<String, dynamic>
        : <String, dynamic>{};
    final creditSummary = _dashboardData['credit'] is Map<String, dynamic>
        ? _dashboardData['credit'] as Map<String, dynamic>
        : <String, dynamic>{};
    final returnsSummary = _dashboardData['returns'] is Map<String, dynamic>
        ? _dashboardData['returns'] as Map<String, dynamic>
        : <String, dynamic>{};
    final salesTotal = _asDouble(salesSummary['total']) != 0
        ? _asDouble(salesSummary['total'])
        : filteredSales.fold<double>(0, (sum, sale) => sum + sale.finalAmount);
    final outstanding = _asDouble(creditSummary['outstanding']) != 0
        ? _asDouble(creditSummary['outstanding'])
        : filteredSales.fold<double>(0, (sum, sale) => sum + sale.balance);
    final returnTotal = _asDouble(returnsSummary['total']);
    final customerCount =
        int.tryParse(_dashboardData['customers']?.toString() ?? '') ??
        filteredSales.map((sale) => sale.customer).toSet().length;

    return [
      ['Report', _activeReport],
      [
        'Date range',
        '${_formatDate(_appliedFromDate!)} - ${_formatDate(_appliedToDate!)}',
      ],
      ['Sales', _formatCurrency(salesTotal)],
      ['Outstanding credit', _formatCurrency(outstanding)],
      ['Returns', _formatCurrency(returnTotal)],
      ['Customers', '$customerCount'],
      ['Transactions', '${filteredSales.length}'],
      ['Records', '${filteredSales.length} sales records available'],
    ];
  }

  Future<void> _exportCsv() async {
    await _exportFile('CSV', () async {
      final rows = [
        ['Metric', 'Value'],
        ..._reportRows,
      ];
      final csv = rows.map((row) => row.map(_escapeCsv).join(',')).join('\r\n');
      return FileSaver.instance.saveAs(
        name: _fileName,
        bytes: Uint8List.fromList([0xEF, 0xBB, 0xBF, ...utf8.encode(csv)]),
        fileExtension: 'csv',
        mimeType: MimeType.csv,
      );
    });
  }

  String get _fileName =>
      'Technova_${_activeReport.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '_')}_${_fileDate(_appliedFromDate!)}_${_fileDate(_appliedToDate!)}';

  String _escapeCsv(String value) => '"${value.replaceAll('"', '""')}"';

  Future<void> _exportPdf() async {
    await _exportFile('PDF', () async {
      final document = pw.Document();
      document.addPage(
        pw.MultiPage(
          build: (context) => [
            pw.Text(
              'TechNova POS | Reports',
              style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 6),
            pw.Text(_activeReport),
            pw.Text(
              'Period: ${_formatDate(_appliedFromDate!)} - ${_formatDate(_appliedToDate!)}',
            ),
            pw.SizedBox(height: 18),
            pw.TableHelper.fromTextArray(
              headers: const ['Metric', 'Value'],
              data: _reportRows,
              headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
              cellPadding: const pw.EdgeInsets.all(8),
            ),
          ],
        ),
      );

      return FileSaver.instance.saveAs(
        name: _fileName,
        bytes: await document.save(),
        fileExtension: 'pdf',
        mimeType: MimeType.pdf,
      );
    });
  }

  Future<void> _exportFile(
    String format,
    Future<String?> Function() save,
  ) async {
    if (_isExporting) return;
    setState(() => _isExporting = true);
    try {
      final path = await save();
      if (mounted && path != null) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            SnackBar(content: Text('$format report saved successfully.')),
          );
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            SnackBar(content: Text('Could not export $format report: $error')),
          );
      }
    } finally {
      if (mounted) setState(() => _isExporting = false);
    }
  }

  void _applyDates() {
    if (_fromDate.isAfter(_toDate)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('The start date must be before the end date.'),
        ),
      );
      return;
    }
    setState(() {
      _appliedFromDate = _fromDate;
      _appliedToDate = _toDate;
    });
    _loadReports();
  }

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: _background,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth >= 760;
          final contentWidth = constraints.maxWidth > 1280
              ? 1280.0
              : constraints.maxWidth;

          return SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(
              isWide ? 20 : 16,
              16,
              isWide ? 20 : 16,
              24,
            ),
            child: Align(
              alignment: Alignment.topCenter,
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: contentWidth),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeader(isWide),
                    const SizedBox(height: 16),
                    _buildDateFilter(isWide),
                    const SizedBox(height: 16),
                    if (_isLoading) const LinearProgressIndicator(),
                    if (_loadError != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Text(
                          _loadError!,
                          style: const TextStyle(color: Color(0xFFB42318)),
                        ),
                      ),
                    _buildSummaryCards(isWide),
                    if (widget.showReportCatalogue) ...[
                      const SizedBox(height: 20),
                      const Text(
                        'Report catalogue',
                        style: TextStyle(
                          color: Color(0xFF17212B),
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _selectedReport == null
                            ? 'Choose a report to export its current summary.'
                            : 'Selected: $_selectedReport',
                        style: const TextStyle(
                          color: Color(0xFF718096),
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 12),
                      _buildReportCatalogue(isWide),
                    ],
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeader(bool isWide) {
    final title = widget.showReportCatalogue ? 'Reports' : 'Dashboard';
    final heading = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'BUSINESS INTELLIGENCE',
          style: TextStyle(
            color: _green,
            fontSize: 10,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.6,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          title,
          style: TextStyle(
            color: Color(0xFF17212B),
            fontSize: 23,
            fontWeight: FontWeight.w700,
          ),
        ),
        Text(
          '${widget.showReportCatalogue ? 'Sales reporting' : 'Business overview'} from ${_formatDate(_appliedFromDate!)} to ${_formatDate(_appliedToDate!)}.',
          style: const TextStyle(color: Color(0xFF718096), fontSize: 11),
        ),
      ],
    );

    final exportButtons = Wrap(
      spacing: 7,
      runSpacing: 7,
      children: [
        _ExportButton(
          label: 'PDF',
          icon: Icons.picture_as_pdf_outlined,
          color: const Color(0xFFDC4C4C),
          onPressed: _isExporting ? null : _exportPdf,
        ),
        _ExportButton(
          label: 'CSV',
          icon: Icons.table_chart_outlined,
          color: _green,
          onPressed: _isExporting ? null : _exportCsv,
        ),
      ],
    );

    if (isWide) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(child: heading),
          exportButtons,
        ],
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [heading, const SizedBox(height: 10), exportButtons],
    );
  }

  Widget _buildDateFilter(bool isWide) {
    final from = _dateSelector('From', _fromDate, isFromDate: true);
    final to = _dateSelector('To', _toDate, isFromDate: false);
    final applyButton = FilledButton(
      onPressed: _applyDates,
      style: FilledButton.styleFrom(
        backgroundColor: _green,
        foregroundColor: Colors.white,
        minimumSize: const Size(0, 44),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(9)),
      ),
      child: const Text(
        'Apply dates',
        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
      ),
    );

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: _border),
        borderRadius: BorderRadius.circular(12),
      ),
      child: isWide
          ? Row(
              children: [
                SizedBox(width: 150, child: from),
                const SizedBox(width: 10),
                SizedBox(width: 150, child: to),
                const SizedBox(width: 10),
                applyButton,
              ],
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Expanded(child: from),
                    const SizedBox(width: 8),
                    Expanded(child: to),
                  ],
                ),
                const SizedBox(height: 10),
                applyButton,
              ],
            ),
    );
  }

  Widget _dateSelector(
    String label,
    DateTime date, {
    required bool isFromDate,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Color(0xFF4B5563),
            fontSize: 10,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 4),
        OutlinedButton(
          onPressed: () => _chooseDate(isFromDate: isFromDate),
          style: OutlinedButton.styleFrom(
            foregroundColor: const Color(0xFF374151),
            backgroundColor: Colors.white,
            side: const BorderSide(color: _border),
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 11),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(9),
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  _formatDate(date),
                  style: const TextStyle(fontSize: 11),
                ),
              ),
              const Icon(Icons.calendar_month_outlined, size: 15),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryCards(bool isWide) {
    final filteredSales = _filteredSales;
    final sales = _dashboardData['sales'] is Map<String, dynamic>
        ? _dashboardData['sales'] as Map<String, dynamic>
        : <String, dynamic>{};
    final credit = _dashboardData['credit'] is Map<String, dynamic>
        ? _dashboardData['credit'] as Map<String, dynamic>
        : <String, dynamic>{};
    final returns = _dashboardData['returns'] is Map<String, dynamic>
        ? _dashboardData['returns'] as Map<String, dynamic>
        : <String, dynamic>{};
    final salesTotal = widget.service != null
        ? _asDouble(sales['total'])
        : filteredSales.fold<double>(0, (sum, sale) => sum + sale.finalAmount);
    final outstanding = widget.service != null
        ? _asDouble(credit['outstanding'])
        : filteredSales.fold<double>(0, (sum, sale) => sum + sale.balance);
    final returnTotal = widget.service != null
        ? _asDouble(returns['total'])
        : filteredSales.fold<double>(
            0,
            (sum, sale) =>
                sum +
                (sale.status == 'Cancelled' ? sale.finalAmount * 0.08 : 0),
          );
    final customerCount = widget.service != null
        ? int.tryParse(_dashboardData['customers']?.toString() ?? '') ?? 0
        : filteredSales.map((sale) => sale.customer).toSet().length;

    final metrics = [
      _ReportMetric(
        'SALES',
        _formatCurrency(salesTotal),
        '${sales['count'] ?? filteredSales.length} transactions',
      ),
      _ReportMetric(
        'OUTSTANDING CREDIT',
        _formatCurrency(outstanding),
        '${credit['accounts'] ?? filteredSales.where((sale) => sale.balance > 0).length} agreements',
      ),
      _ReportMetric(
        'RETURNS',
        _formatCurrency(returnTotal),
        '${returns['count'] ?? filteredSales.where((sale) => sale.status == 'Cancelled').length} returns',
      ),
      _ReportMetric(
        'CUSTOMERS',
        '$customerCount',
        '${filteredSales.length} active sales',
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = isWide ? 4 : 2;
        final gap = 10.0;
        final width = (constraints.maxWidth - gap * (columns - 1)) / columns;
        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: metrics
              .map(
                (metric) => SizedBox(
                  width: width,
                  height: 112,
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(color: _border),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x080F172A),
                          blurRadius: 5,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          metric.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Color(0xFF718096),
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          metric.value,
                          style: const TextStyle(
                            color: Color(0xFF17212B),
                            fontSize: 19,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          metric.note,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Color(0xFF718096),
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              )
              .toList(),
        );
      },
    );
  }

  Widget _buildReportCatalogue(bool isWide) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = isWide ? 4 : 2;
        final gap = 10.0;
        final width = (constraints.maxWidth - gap * (columns - 1)) / columns;

        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: _reports.map((report) {
            final isSelected = _selectedReport == report.title;
            return SizedBox(
              width: width,
              height: 84,
              child: Material(
                color: Colors.white,
                borderRadius: BorderRadius.circular(11),
                child: InkWell(
                  onTap: () => setState(() => _selectedReport = report.title),
                  borderRadius: BorderRadius.circular(11),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: isSelected ? _green : _border,
                        width: isSelected ? 1.3 : 1,
                      ),
                      borderRadius: BorderRadius.circular(11),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                '${report.title}  →',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: _darkGreen,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            Icon(report.icon, color: _green, size: 15),
                          ],
                        ),
                        const Spacer(),
                        Text(
                          report.description,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Color(0xFF718096),
                            fontSize: 10,
                            height: 1.25,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        );
      },
    );
  }
}

class _SalesRecord {
  final String invoice;
  final String customer;
  final String cashier;
  final int items;
  final double originalAmount;
  final double discount;
  final double tax;
  final double finalAmount;
  final double paid;
  final double balance;
  final String status;
  final DateTime date;

  const _SalesRecord({
    required this.invoice,
    required this.customer,
    required this.cashier,
    required this.items,
    required this.originalAmount,
    required this.discount,
    required this.tax,
    required this.finalAmount,
    required this.paid,
    required this.balance,
    required this.status,
    required this.date,
  });
}

class _ReportEntry {
  final String title;
  final String description;
  final IconData icon;

  const _ReportEntry(this.title, this.description, this.icon);
}

class _ReportMetric {
  final String title;
  final String value;
  final String note;

  const _ReportMetric(this.title, this.value, this.note);
}

class _ExportButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback? onPressed;

  const _ExportButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 15),
      label: Text(label),
      style: OutlinedButton.styleFrom(
        foregroundColor: color,
        backgroundColor: Colors.white,
        side: BorderSide(color: color.withValues(alpha: 0.3)),
        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 9),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(9)),
        textStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
      ),
    );
  }
}
