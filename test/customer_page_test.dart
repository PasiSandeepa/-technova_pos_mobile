import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:technova_pos_mobile/services/auth_service.dart';
import 'package:technova_pos_mobile/services/customer_app_service.dart';
import 'package:technova_pos_mobile/services/staff_api_service.dart';
import 'package:technova_pos_mobile/pages/customer_page.dart';
import 'package:technova_pos_mobile/pages/customer_dashboard_page.dart';
import 'package:technova_pos_mobile/widgets/Sidebar_Widget.dart';

void main() {
  testWidgets('customer search filters by name and customer ID', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1440, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final service = StaffApiService(
      baseUrl: 'https://api.example.test/api/v1',
      accessToken: 'staff-token',
      client: MockClient((request) async {
        expect(request.headers['Authorization'], 'Bearer staff-token');
        expect(request.url.path, '/api/v1/customers');
        return http.Response(
          jsonEncode({
            'data': [
              {
                'id': 'customer-1',
                'name': 'Alice TechNova',
                'customerNumber': 'CUST-0001',
                'status': 'ACTIVE',
              },
            ],
            'meta': {'page': 1, 'pageSize': 100, 'total': 1, 'pageCount': 1},
          }),
          200,
          headers: {'content-type': 'application/json'},
        );
      }),
    );
    addTearDown(service.close);

    await tester.pumpWidget(MaterialApp(home: CustomersPage(service: service)));
    await tester.pumpAndSettle();

    final searchField = find.byType(TextField);
    expect(find.text('Alice TechNova'), findsOneWidget);

    await tester.enterText(searchField, 'cust-0001');
    await tester.pump();
    expect(find.text('Alice TechNova'), findsOneWidget);

    await tester.enterText(searchField, 'unknown');
    await tester.pump();
    expect(find.text('Alice TechNova'), findsNothing);
    expect(find.text('No customers found'), findsOneWidget);
    expect(find.text('Showing 0–0 of 1'), findsOneWidget);
  });

  testWidgets('customer dashboard is available under the Customer menu', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final scaffoldKey = GlobalKey<ScaffoldState>();
    String? selectedRoute;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          key: scaffoldKey,
          drawer: SidebarWidget(
            onItemSelected: (route) => selectedRoute = route,
          ),
          body: const SizedBox(),
        ),
      ),
    );
    scaffoldKey.currentState!.openDrawer();
    await tester.pumpAndSettle();
    await tester.tap(find.text('Customer').last);
    await tester.pumpAndSettle();

    expect(find.text('Customer Dashboard'), findsOneWidget);
    expect(find.text('Customer List'), findsOneWidget);
    await tester.tap(find.text('Customer Dashboard'));
    await tester.pumpAndSettle();

    expect(selectedRoute, 'Customer Dashboard');
  });

  testWidgets('customer mode exposes customer screens without staff routes', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final scaffoldKey = GlobalKey<ScaffoldState>();
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          key: scaffoldKey,
          drawer: const SidebarWidget(customerMode: true),
          body: const SizedBox(),
        ),
      ),
    );
    scaffoldKey.currentState!.openDrawer();
    await tester.pumpAndSettle();

    await tester.tap(find.text('Customer').last);
    await tester.pumpAndSettle();
    expect(find.text('Customer Dashboard'), findsOneWidget);
    expect(find.text('Sign out'), findsOneWidget);
    expect(find.text('Products'), findsOneWidget);
    expect(find.text('Promotion'), findsOneWidget);
    expect(find.text('Customer List'), findsNothing);
    expect(find.text('Report'), findsNothing);
  });

  testWidgets('dashboard displays the signed-in customer API data', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final service = CustomerAppService(
      accessToken: 'customer-token',
      baseUrl: 'https://api.example.test/api/v1',
      client: _customerApiClient(),
    );
    addTearDown(service.close);

    await tester.pumpWidget(
      MaterialApp(
        home: CustomerDashboardPage(
          customerUser: CustomerUser(
            id: 'user-1',
            name: 'Nimal Perera',
            phone: '+94771234567',
            email: 'nimal@example.com',
          ),
          service: service,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Welcome, Nimal Perera'), findsOneWidget);
    expect(find.text('nimal@example.com'), findsOneWidget);
    expect(find.text('365'), findsOneWidget);
    expect(find.text('Member promotion'), findsOneWidget);
    expect(find.text('INV-2048'), findsOneWidget);
    expect(find.text('Saman Perera'), findsNothing);
    expect(tester.takeException(), isNull);
  });
}

http.Client _customerApiClient() {
  return MockClient((request) async {
    expect(request.headers['Authorization'], 'Bearer customer-token');
    final Object payload = switch (request.url.path) {
      '/api/v1/customer-app/home' => {
        'customer': {
          'customerNumber': 'CUS-2048',
          'firstName': 'Nimal',
          'lastName': 'Perera',
        },
        'summary': {
          'loyaltyPoints': 365,
          'loyaltyTier': 'SILVER',
          'storeCreditBalance': 1200,
          'activeCreditPurchases': 1,
          'activePromotions': 1,
        },
      },
      '/api/v1/customer-app/profile' => {
        'firstName': 'Nimal',
        'lastName': 'Perera',
        'user': {'email': 'nimal@example.com', 'phone': '+94771234567'},
        'loyaltyAccount': {'points': 365, 'tier': 'SILVER'},
        'storeCreditAccount': {'balance': 1200},
      },
      '/api/v1/customer-app/loyalty' => {
        'points': 365,
        'tier': 'SILVER',
        'data': [
          {'points': 35, 'description': 'Purchase reward'},
        ],
        'meta': {'page': 1, 'pageSize': 5, 'total': 1, 'pageCount': 1},
      },
      '/api/v1/customer-app/promotions' => {
        'data': [
          {
            'name': 'Member promotion',
            'description': 'Discount for active members',
            'code': 'MEMBER10',
            'type': 'PERCENTAGE',
            'value': 10,
            'endsAt': '2026-12-31T00:00:00.000Z',
          },
        ],
        'meta': {'page': 1, 'pageSize': 5, 'total': 1, 'pageCount': 1},
      },
      '/api/v1/customer-app/credit-purchases' => {
        'data': [
          {
            'id': 'credit-1',
            'principal': 2500,
            'outstandingBalance': 1200,
            'status': 'ACTIVE',
            'createdAt': '2026-10-01T10:00:00.000Z',
            'sale': {
              'invoiceNumber': 'INV-2048',
              'total': 2500,
              'branch': {'name': 'Main branch'},
            },
          },
        ],
        'meta': {'page': 1, 'pageSize': 5, 'total': 1, 'pageCount': 1},
      },
      _ => throw StateError(
        'Unexpected customer endpoint: ${request.url.path}',
      ),
    };

    return http.Response(
      jsonEncode(payload),
      200,
      headers: {'content-type': 'application/json'},
    );
  });
}
