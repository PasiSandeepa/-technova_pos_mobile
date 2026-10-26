import 'package:flutter/material.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:excel/excel.dart' as ex;
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';
import 'dart:io';

import '../../services/auth_service.dart';
import '../../services/customer_app_service.dart';
import '../../services/staff_api_service.dart';
import '../../widgets/navbar.dart';
import '../profile_page.dart';

class ViewProductsPage extends StatefulWidget {
  final CustomerAppService? service;
  final StaffApiService? staffService;

  const ViewProductsPage({super.key, this.service, this.staffService});

  @override
  State<ViewProductsPage> createState() => _ViewProductsPageState();
}

class _ViewProductsPageState extends State<ViewProductsPage> {
  final Color primaryColor = const Color(0xFF0D9488);
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> _products = const [];
  int _page = 1;
  int _pageCount = 1;
  int _totalProducts = 0;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _refreshProducts();
  }

  Future<void> _refreshProducts() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final Map<String, dynamic> response;
      if (widget.staffService != null) {
        response = await widget.staffService!.getCatalogProducts(
          page: _page,
          pageSize: 100,
          search: _searchController.text.trim(),
        );
      } else {
        var service = widget.service;
        if (service == null) {
          final accessToken = await CustomerSessionStore().readAccessToken();
          if (accessToken == null || accessToken.isEmpty) {
            setState(() {
              _products = const [];
              _totalProducts = 0;
              _pageCount = 1;
              _isLoading = false;
            });
            return;
          }
          service = CustomerAppService(accessToken: accessToken);
        }
        try {
          response = await service.getProducts(
            page: _page,
            pageSize: 100,
            search: _searchController.text.trim(),
          );
        } finally {
          if (widget.service == null) service.close();
        }
      }

      final raw = response['data'];
      final normalized = raw is List
          ? raw.whereType<Map<String, dynamic>>().map((item) {
              final map = Map<String, dynamic>.from(item);
              final category = map['category'];
              final brand = map['brand'];
              return {
                'sku': map['sku'] ?? map['productCode'] ?? map['id'] ?? 'N/A',
                'name': map['name'] ?? map['productName'] ?? 'Unnamed product',
                'category': category is Map<String, dynamic>
                    ? category['name'] ?? 'General'
                    : map['categoryName'] ?? 'General',
                'brand': brand is Map<String, dynamic>
                    ? brand['name'] ?? 'N/A'
                    : map['brandName'] ?? 'N/A',
                'price': map['sellingPrice'] ?? map['price'] ?? '—',
                'qty':
                    map['availableQuantity'] ??
                    map['qty'] ??
                    map['stockQuantity'] ??
                    0,
              };
            }).toList()
          : <Map<String, dynamic>>[];

      if (mounted) {
        final meta = response['meta'];
        final total = meta is Map<String, dynamic>
            ? int.tryParse(meta['total']?.toString() ?? '') ?? normalized.length
            : normalized.length;
        final pageCount = meta is Map<String, dynamic>
            ? int.tryParse(meta['pageCount']?.toString() ?? '') ?? 1
            : 1;
        setState(() {
          _products = normalized;
          _totalProducts = total;
          _pageCount = pageCount < 1 ? 1 : pageCount;
          _isLoading = false;
        });
      }
    } catch (error) {
      if (mounted) {
        setState(() {
          _error = error.toString();
          _isLoading = false;
        });
      }
    }
  }

  void _submitSearch() {
    setState(() => _page = 1);
    _refreshProducts();
  }

  void _changePage(int page) {
    setState(() => _page = page);
    _refreshProducts();
  }

  List<Map<String, dynamic>> get filteredProducts {
    final query = _searchController.text.trim().toLowerCase();

    if (query.isEmpty) {
      return _products;
    }

    return _products.where((product) {
      final sku = (product['sku'] ?? '').toString().toLowerCase();
      final name = (product['name'] ?? '').toString().toLowerCase();
      final category = (product['category'] ?? '').toString().toLowerCase();
      final brand = (product['brand'] ?? '').toString().toLowerCase();

      return sku.contains(query) ||
          name.contains(query) ||
          category.contains(query) ||
          brand.contains(query);
    }).toList();
  }

  Future<void> _exportToPDF() async {
    final pdf = pw.Document();
    final data = _products;

    pdf.addPage(
      pw.Page(
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                'TechNova - Products Report',
                style: pw.TextStyle(
                  fontSize: 22,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 20),
              pw.TableHelper.fromTextArray(
                headers: [
                  'SKU',
                  'Product Name',
                  'Category',
                  'Brand',
                  'Price',
                  'Available quantity',
                ],
                data: data
                    .map(
                      (p) => [
                        p['sku'],
                        p['name'],
                        p['category'],
                        p['brand'],
                        p['price'],
                        p['qty'],
                      ],
                    )
                    .toList(),
              ),
            ],
          );
        },
      ),
    );

    Directory directory =
        await getDownloadsDirectory() ??
        await getApplicationDocumentsDirectory();
    final filePath = '${directory.path}/Products_Report.pdf';
    final file = File(filePath);
    final pdfBytes = await pdf.save();
    await file.writeAsBytes(pdfBytes);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('PDF saved successfully to: $filePath')),
      );
    }

    await OpenFile.open(filePath);
  }

  Future<void> _exportToExcel() async {
    var excel = ex.Excel.createExcel();
    String sheetName = excel.getDefaultSheet() ?? 'Sheet1';
    var sheet = excel[sheetName];

    sheet.appendRow([
      ex.TextCellValue('SKU'),
      ex.TextCellValue('Product Name'),
      ex.TextCellValue('Category'),
      ex.TextCellValue('Brand'),
      ex.TextCellValue('Price'),
      ex.TextCellValue('Available quantity'),
    ]);

    for (var p in _products) {
      sheet.appendRow([
        ex.TextCellValue(p['sku']),
        ex.TextCellValue(p['name']),
        ex.TextCellValue(p['category']),
        ex.TextCellValue(p['brand']),
        ex.TextCellValue(p['price']),
        ex.TextCellValue(p['qty']),
      ]);
    }

    Directory directory =
        await getDownloadsDirectory() ??
        await getApplicationDocumentsDirectory();
    final path = '${directory.path}/Products_Report.xlsx';

    final file = File(path);
    await file.create(recursive: true);
    await file.writeAsBytes(excel.encode()!);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Excel saved successfully to: $path')),
      );
    }

    await OpenFile.open(path);
  }

  @override
  Widget build(BuildContext context) {
    final items = filteredProducts;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: TechNovaNavbar(
        title: 'View Products',
        onProfileTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const ProfilePage()),
          );
        },
        actions: [
          PopupMenuButton<String>(
            tooltip: 'Product actions',
            icon: Icon(Icons.more_vert, color: primaryColor),
            onSelected: (value) {
              switch (value) {
                case 'pdf':
                  _exportToPDF();
                  return;
                case 'excel':
                  _exportToExcel();
                  return;
                case 'refresh':
                  _refreshProducts();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Refreshing products...')),
                  );
                  return;
              }
            },
            itemBuilder: (context) => const [
              PopupMenuItem(
                value: 'pdf',
                child: ListTile(
                  leading: Icon(Icons.picture_as_pdf, color: Colors.red),
                  title: Text('Export PDF'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              PopupMenuItem(
                value: 'excel',
                child: ListTile(
                  leading: Icon(Icons.table_chart, color: Colors.green),
                  title: Text('Export Excel'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              PopupMenuItem(
                value: 'refresh',
                child: ListTile(
                  leading: Icon(Icons.refresh),
                  title: Text('Refresh'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ],
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Text('Unable to load products: $_error'),
              ),
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16.0,
                    vertical: 10.0,
                  ),
                  child: Row(
                    children: [
                      Text(
                        'Dashboard',
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 12,
                        ),
                      ),
                      Text(
                        ' > ',
                        style: TextStyle(
                          color: Colors.grey.shade400,
                          fontSize: 12,
                        ),
                      ),
                      Text(
                        'Products',
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 12,
                        ),
                      ),
                      Text(
                        ' > ',
                        style: TextStyle(
                          color: Colors.grey.shade400,
                          fontSize: 12,
                        ),
                      ),
                      const Text(
                        'View Products',
                        style: TextStyle(
                          color: Color(0xFF0F172A),
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16.0,
                    vertical: 4.0,
                  ),
                  child: TextField(
                    controller: _searchController,
                    onChanged: (_) => setState(() {}),
                    onSubmitted: (_) => _submitSearch(),
                    decoration: InputDecoration(
                      hintText: 'Search products...',
                      hintStyle: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade400,
                      ),
                      prefixIcon: const Icon(
                        Icons.search,
                        size: 20,
                        color: Colors.grey,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        vertical: 0,
                        horizontal: 12,
                      ),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: primaryColor),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Expanded(
                  child: items.isEmpty
                      ? const Center(
                          child: Text(
                            'No products found',
                            style: TextStyle(
                              color: Color(0xFF64748B),
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16.0),
                          itemCount: items.length,
                          itemBuilder: (context, index) {
                            final product = items[index];
                            return Container(
                              margin: const EdgeInsets.only(bottom: 12.0),
                              padding: const EdgeInsets.all(12.0),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(10),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.grey.withValues(alpha: 0.1),
                                    blurRadius: 6,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 3,
                                        ),
                                        decoration: BoxDecoration(
                                          color: primaryColor.withValues(
                                            alpha: 0.1,
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            4,
                                          ),
                                        ),
                                        child: Text(
                                          product['sku'].toString(),
                                          style: TextStyle(
                                            color: primaryColor,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 11,
                                          ),
                                        ),
                                      ),
                                      Text(
                                        product['price'].toString(),
                                        style: const TextStyle(
                                          color: Color(0xFF0F172A),
                                          fontWeight: FontWeight.bold,
                                          fontSize: 15,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    product['name'].toString(),
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF1E293B),
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        'Category: ${product['category']} (${product['brand']})',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey.shade600,
                                        ),
                                      ),
                                      Text(
                                        'Available: ${product['qty']}',
                                        style: const TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.green,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          '$_totalProducts products · Page $_page of $_pageCount',
                          style: const TextStyle(
                            color: Color(0xFF64748B),
                            fontSize: 12,
                          ),
                        ),
                      ),
                      IconButton(
                        tooltip: 'Previous page',
                        onPressed: _page > 1 && !_isLoading
                            ? () => _changePage(_page - 1)
                            : null,
                        icon: const Icon(Icons.chevron_left),
                      ),
                      IconButton(
                        tooltip: 'Next page',
                        onPressed: _page < _pageCount && !_isLoading
                            ? () => _changePage(_page + 1)
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

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}
