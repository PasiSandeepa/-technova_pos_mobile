import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:technova_pos_mobile/services/staff_api_service.dart';

class _RecordedRequest {
  final String method;
  final Uri uri;
  final Map<String, String> headers;
  final String body;

  const _RecordedRequest(this.method, this.uri, this.headers, this.body);
}

class _FakeClient extends http.BaseClient {
  final List<_RecordedRequest> requests = [];

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    final body = request is http.Request ? request.body : '';
    requests.add(
      _RecordedRequest(request.method, request.url, request.headers, body),
    );
    final responseBody = switch (request.url.path) {
      '/api/v1/auth/login' => jsonEncode({
        'accessToken': 'staff-access-token',
        'expiresIn': 900,
        'user': {
          'id': 'staff-1',
          'email': 'staff@example.com',
          'name': 'Staff User',
          'roles': ['Manager'],
          'permissions': ['sales:view', 'reports:view'],
        },
      }),
      '/api/v1/auth/me' => jsonEncode({
        'id': 'staff-1',
        'email': 'staff@example.com',
        'name': 'Staff User',
        'roles': ['Manager'],
        'permissions': ['sales:view', 'reports:view'],
      }),
      '/api/v1/sales' => jsonEncode({
        'data': [
          {'id': 'sale-1', 'invoiceNumber': 'INV-001'},
        ],
        'meta': {'page': 2, 'pageSize': 10, 'total': 1, 'pageCount': 1},
      }),
      '/api/v1/sales/sale-1' => jsonEncode({
        'id': 'sale-1',
        'invoiceNumber': 'INV-001',
      }),
      '/api/v1/reports/sales' => jsonEncode([
        {'invoiceNumber': 'INV-001', 'total': 1250},
      ]),
      '/api/v1/reports/dashboard' => jsonEncode({
        'sales': {'total': 1250},
      }),
      '/api/v1/branches' => jsonEncode({
        'data': [
          {'id': 'branch-1', 'name': 'Main Branch'},
        ],
        'meta': {'page': 1, 'pageSize': 100, 'total': 1, 'pageCount': 1},
      }),
      '/api/v1/catalog/products' => jsonEncode({
        'data': [
          {'id': 'product-1', 'name': 'Phone'},
        ],
        'meta': {'page': 1, 'pageSize': 10, 'total': 1, 'pageCount': 1},
      }),
      '/api/v1/catalog/categories' => jsonEncode([
        {'id': 'category-1', 'name': 'Phones'},
      ]),
      '/api/v1/inventory/stock' => jsonEncode({
        'data': [
          {'id': 'stock-1', 'quantity': 12},
        ],
        'meta': {'page': 1, 'pageSize': 20, 'total': 1, 'pageCount': 1},
      }),
      '/api/v1/customers' => jsonEncode({
        'data': [
          {'id': 'customer-1', 'firstName': 'Alice'},
        ],
        'meta': {'page': 1, 'pageSize': 20, 'total': 1, 'pageCount': 1},
      }),
      '/api/v1/suppliers' => jsonEncode({
        'data': [
          {'id': 'supplier-1', 'name': 'Parts Co'},
        ],
        'meta': {'page': 1, 'pageSize': 20, 'total': 1, 'pageCount': 1},
      }),
      '/api/v1/supplier-portal/dashboard' => jsonEncode({
        'supplier': {'id': 'supplier-portal-1', 'name': 'Parts Co'},
        'stats': {
          'pending': 1,
          'inTransit': 0,
          'completedThisMonth': 1,
          'unread': 2,
        },
        'orders': {
          'data': [
            {
              'id': 'po-1',
              'orderNumber': 'PO-1001',
              'total': 782398.42,
              'createdAt': '2026-10-02T00:00:00.000Z',
              'status': 'APPROVED',
              'supplierResponses': [],
              'supplierShipments': [],
            },
          ],
          'meta': {'page': 1, 'pageSize': 10, 'total': 1, 'pageCount': 1},
        },
      }),
      '/api/v1/supplier-portal/orders/po-1' => jsonEncode({
        'id': 'po-1',
        'orderNumber': 'PO-1001',
        'status': 'APPROVED',
        'items': [],
      }),
      '/api/v1/discounts' => jsonEncode([
        {'id': 'discount-1', 'name': 'Weekend deal'},
      ]),
      '/api/v1/notifications/in-app' => jsonEncode({
        'data': [
          {'id': 'notification-1', 'title': 'Sale completed'},
        ],
        'meta': {'page': 1, 'pageSize': 50, 'total': 1, 'pageCount': 1},
        'unread': 1,
      }),
      _ => '{}',
    };
    return http.StreamedResponse(
      Stream.value(utf8.encode(responseBody)),
      200,
      headers: {'content-type': 'application/json'},
    );
  }
}

void main() {
  const baseUrl = 'https://pos.nxcodeworks.com/api/v1';

  test(
    'staff API uses listed auth, sales, report, and branch routes',
    () async {
      final client = _FakeClient();
      final service = StaffApiService(baseUrl: baseUrl, client: client);

      final login = await service.login(
        email: 'staff@example.com',
        password: 'staff-password',
      );
      final currentUser = await service.getMe();
      final sales = await service.getSales(
        page: 2,
        pageSize: 10,
        search: 'INV-001',
        branchId: 'branch-1',
        from: DateTime(2026, 10, 1),
        to: DateTime(2026, 10, 5),
      );
      final saleDetail = await service.getSaleDetail('sale-1');
      final salesReport = await service.getSalesReport(
        from: DateTime(2026, 10, 1),
        to: DateTime(2026, 10, 5),
      );
      final dashboard = await service.getReportDashboard(
        from: DateTime(2026, 10, 1),
        to: DateTime(2026, 10, 5),
      );
      final branches = await service.getBranches();
      final products = await service.getCatalogProducts(
        page: 1,
        pageSize: 10,
        search: 'Phone',
        categoryId: 'category-1',
      );
      final categories = await service.getCatalogCategories();
      final inventory = await service.getInventoryStock(search: 'Phone');
      final customers = await service.getCustomers(search: 'Alice');
      final suppliers = await service.getSuppliers(search: 'Parts');
      final supplierDashboard = await service.getSupplierPortalDashboard(
        page: 1,
        pageSize: 10,
        from: DateTime(2026, 10, 1),
        to: DateTime(2026, 10, 5),
      );
      final supplierOrder = await service.getSupplierPortalOrder('po-1');
      final discounts = await service.getDiscounts();
      final notifications = await service.getInAppNotifications(
        unreadOnly: true,
      );
      await service.markInAppNotificationRead('notification-1');
      await service.markAllInAppNotificationsRead();

      expect(login.accessToken, 'staff-access-token');
      expect(currentUser.permissions, contains('reports:view'));
      expect(sales['meta']['page'], 2);
      expect(saleDetail['invoiceNumber'], 'INV-001');
      expect(salesReport.single['invoiceNumber'], 'INV-001');
      expect(dashboard['sales']['total'], 1250);
      expect(branches.single['id'], 'branch-1');
      expect(products['data'].single['id'], 'product-1');
      expect(categories.single['name'], 'Phones');
      expect(inventory['data'].single['quantity'], 12);
      expect(customers['data'].single['id'], 'customer-1');
      expect(suppliers['data'].single['id'], 'supplier-1');
      expect(supplierDashboard['stats']['pending'], 1);
      expect(
        supplierDashboard['orders']['data'].single['orderNumber'],
        'PO-1001',
      );
      expect(supplierOrder['orderNumber'], 'PO-1001');
      expect(discounts.single['id'], 'discount-1');
      expect(notifications['data'].single['id'], 'notification-1');
      expect(client.requests.map((request) => request.uri.path), [
        '/api/v1/auth/login',
        '/api/v1/auth/me',
        '/api/v1/sales',
        '/api/v1/sales/sale-1',
        '/api/v1/reports/sales',
        '/api/v1/reports/dashboard',
        '/api/v1/branches',
        '/api/v1/catalog/products',
        '/api/v1/catalog/categories',
        '/api/v1/inventory/stock',
        '/api/v1/customers',
        '/api/v1/suppliers',
        '/api/v1/supplier-portal/dashboard',
        '/api/v1/supplier-portal/orders/po-1',
        '/api/v1/discounts',
        '/api/v1/notifications/in-app',
        '/api/v1/notifications/in-app/notification-1/read',
        '/api/v1/notifications/in-app/read-all',
      ]);
      expect(jsonDecode(client.requests.first.body), {
        'email': 'staff@example.com',
        'password': 'staff-password',
      });
      expect(
        client.requests
            .skip(1)
            .every(
              (request) =>
                  request.headers['Authorization'] ==
                  'Bearer staff-access-token',
            ),
        isTrue,
      );
      expect(client.requests[2].uri.queryParameters, {
        'page': '2',
        'pageSize': '10',
        'search': 'INV-001',
        'branchId': 'branch-1',
        'from': '2026-10-01',
        'to': '2026-10-05',
      });
      expect(client.requests[7].uri.queryParameters, {
        'page': '1',
        'pageSize': '10',
        'search': 'Phone',
        'categoryId': 'category-1',
      });
      expect(client.requests[15].uri.queryParameters['unread'], 'true');
      expect(client.requests[16].method, 'PATCH');
      expect(client.requests[17].method, 'PATCH');

      service.close();
    },
  );
}
