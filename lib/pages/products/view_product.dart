import 'package:flutter/material.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:excel/excel.dart' as ex;
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';
import 'dart:io';

import '../../widgets/navbar.dart';
import '../profile_page.dart';

class ViewProductsPage extends StatefulWidget {
  const ViewProductsPage({Key? key}) : super(key: key);

  @override
  State<ViewProductsPage> createState() => _ViewProductsPageState();
}

class _ViewProductsPageState extends State<ViewProductsPage> {
  final Color primaryColor = const Color(0xFF0D9488);
  final TextEditingController _searchController = TextEditingController();

  // Dummy Products Data
  final List<Map<String, dynamic>> dummyProducts = [
    {'sku': 'PT001', 'name': 'Lenovo IdeaPad 3', 'category': 'Computers', 'brand': 'Lenovo', 'price': '\$600', 'unit': 'Pc', 'qty': '100', 'createdBy': 'Admin'},
    {'sku': 'PT002', 'name': 'Beats Pro', 'category': 'Electronics', 'brand': 'Beats', 'price': '\$160', 'unit': 'Pc', 'qty': '140', 'createdBy': 'Nimal'},
    {'sku': 'PT003', 'name': 'Nike Jordan', 'category': 'Shoe', 'brand': 'Nike', 'price': '\$110', 'unit': 'Pc', 'qty': '300', 'createdBy': 'Kasun'},
    {'sku': 'PT004', 'name': 'Apple Series 5 Watch', 'category': 'Electronics', 'brand': 'Apple', 'price': '\$120', 'unit': 'Pc', 'qty': '450', 'createdBy': 'Admin'},
    {'sku': 'PT005', 'name': 'Amazon Echo Dot', 'category': 'Electronics', 'brand': 'Amazon', 'price': '\$80', 'unit': 'Pc', 'qty': '320', 'createdBy': 'Saman'},
  ];

  List<Map<String, dynamic>> get filteredProducts {
    final query = _searchController.text.trim().toLowerCase();

    if (query.isEmpty) {
      return dummyProducts;
    }

    return dummyProducts.where((product) {
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

  // ==========================================
  // 1. PDF EXPORT FUNCTION
  // ==========================================
  Future<void> _exportToPDF() async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text('TechNova - Products Report', style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 20),
              pw.Table.fromTextArray(
                headers: ['SKU', 'Product Name', 'Category', 'Brand', 'Price', 'Qty', 'Created By'],
                data: dummyProducts.map((p) => [p['sku'], p['name'], p['category'], p['brand'], p['price'], '${p['qty']} ${p['unit']}', p['createdBy']]).toList(),
              ),
            ],
          );
        },
      ),
    );

    Directory directory = await getDownloadsDirectory() ?? await getApplicationDocumentsDirectory();
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

  // ==========================================
  // 2. EXCEL EXPORT FUNCTION
  // ==========================================
  Future<void> _exportToExcel() async {
    var excel = ex.Excel.createExcel();
    String sheetName = excel.getDefaultSheet() ?? 'Sheet1';
    var sheet = excel[sheetName];

    // Table Headers
    sheet.appendRow([
      ex.TextCellValue('SKU'),
      ex.TextCellValue('Product Name'),
      ex.TextCellValue('Category'),
      ex.TextCellValue('Brand'),
      ex.TextCellValue('Price'),
      ex.TextCellValue('Qty'),
      ex.TextCellValue('Created By'),
    ]);

    // Adding Data Rows
    for (var p in dummyProducts) {
      sheet.appendRow([
        ex.TextCellValue(p['sku']),
        ex.TextCellValue(p['name']),
        ex.TextCellValue(p['category']),
        ex.TextCellValue(p['brand']),
        ex.TextCellValue(p['price']),
        ex.TextCellValue(p['qty']),
        ex.TextCellValue(p['createdBy']),
      ]);
    }

    Directory directory = await getDownloadsDirectory() ?? await getApplicationDocumentsDirectory();
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
                  setState(() {});
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Products Refreshed!')),
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
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Breadcrumb
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
            child: Row(
              children: [
                Text('Dashboard', style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                Text(' > ', style: TextStyle(color: Colors.grey.shade400, fontSize: 12)),
                Text('Products', style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                Text(' > ', style: TextStyle(color: Colors.grey.shade400, fontSize: 12)),
                const Text('View Products', style: TextStyle(color: Color(0xFF0F172A), fontWeight: FontWeight.w600, fontSize: 12)),
              ],
            ),
          ),

          // Search Bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
            child: TextField(
              controller: _searchController,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                hintText: 'Search products...',
                hintStyle: TextStyle(fontSize: 13, color: Colors.grey.shade400),
                prefixIcon: const Icon(Icons.search, size: 20, color: Colors.grey),
                contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 12),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey.shade300)),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey.shade300)),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: primaryColor)),
              ),
            ),
          ),
          const SizedBox(height: 10),

          // Products List
          Expanded(
            child: filteredProducts.isEmpty
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
                    itemCount: filteredProducts.length,
                    itemBuilder: (context, index) {
                      final product = filteredProducts[index];

                      return Container(
                        margin: const EdgeInsets.only(bottom: 12.0),
                        padding: const EdgeInsets.all(12.0),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(10),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.grey.withOpacity(0.1),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 3,
                                  ),
                                  decoration: BoxDecoration(
                                    color: primaryColor.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    product['sku'],
                                    style: TextStyle(
                                      color: primaryColor,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 11,
                                    ),
                                  ),
                                ),
                                Text(
                                  product['price'],
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
                              product['name'],
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF1E293B),
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Created by: ${product['createdBy'] ?? 'Unknown'}',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade600,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Category: ${product['category']} (${product['brand']})',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                                Text(
                                  'Qty: ${product['qty']} ${product['unit']}',
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