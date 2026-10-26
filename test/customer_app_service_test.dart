import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:technova_pos_mobile/services/auth_service.dart';
import 'package:technova_pos_mobile/services/customer_app_service.dart';

class _RecordedRequest {
  final String method;
  final Uri uri;
  final Map<String, String> headers;
  final String body;

  const _RecordedRequest(this.method, this.uri, this.headers, this.body);
}

class _FakeClient extends http.BaseClient {
  final List<_RecordedRequest> requests = [];
  final int Function(int requestIndex)? statusForRequest;
  final http.Response Function(http.BaseRequest request, int requestIndex)?
  responseForRequest;

  _FakeClient({this.statusForRequest, this.responseForRequest});

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    final requestBody = request is http.Request ? request.body : '';
    final requestIndex = requests.length;
    requests.add(
      _RecordedRequest(request.method, request.url, request.headers, requestBody),
    );
    final response =
        responseForRequest?.call(request, requestIndex) ??
        http.Response(
          '{}',
          statusForRequest?.call(requestIndex) ?? 200,
          headers: {'content-type': 'application/json'},
        );
    return http.StreamedResponse(
      Stream.value(response.bodyBytes),
      response.statusCode,
      headers: response.headers,
    );
  }
}

void main() {
  const baseUrl = 'https://pos.nxcodeworks.com/api/v1';

  test('customer auth uses login, refresh, and logout API endpoints', () async {
    final client = _FakeClient(
      responseForRequest: (request, _) {
        switch (request.url.path) {
          case '/api/v1/auth/customer/login':
            return http.Response(
              jsonEncode({
                'accessToken': 'customer-access-1',
                'refreshToken': 'customer-refresh-1',
                'user': {'id': 'customer-1', 'phone': '+94771234567'},
                'customer': {'id': 'profile-1', 'customerNumber': 'C-1'},
              }),
              200,
              headers: {'content-type': 'application/json'},
            );
          case '/api/v1/auth/customer/refresh':
            return http.Response(
              jsonEncode({
                'accessToken': 'customer-access-2',
                'refreshToken': 'customer-refresh-2',
                'user': {'id': 'customer-1', 'phone': '+94771234567'},
                'customer': {'id': 'profile-1', 'customerNumber': 'C-1'},
              }),
              200,
              headers: {'content-type': 'application/json'},
            );
          case '/api/v1/auth/customer/logout':
            return http.Response('', 204);
          default:
            throw StateError('Unexpected auth route: ${request.url.path}');
        }
      },
    );
    final repository = HttpAuthRepository(baseUrl: baseUrl);

    final login = await repository.login(
      phone: '+94771234567',
      password: 'customer-password',
    );
    final refreshed = await repository.refreshToken(
      refreshToken: login.tokens.refreshToken,
    );
    await repository.logout(refreshToken: refreshed.tokens.refreshToken);

    expect(login.tokens.accessToken, 'customer-access-1');
    expect(refreshed.tokens.accessToken, 'customer-access-2');
    expect(refreshed.tokens.refreshToken, 'customer-refresh-2');
    expect(client.requests.map((request) => request.uri.path), [
      '/api/v1/auth/customer/login',
      '/api/v1/auth/customer/refresh',
      '/api/v1/auth/customer/logout',
    ]);
    expect(jsonDecode(client.requests[0].body), {
      'phone': '+94771234567',
      'password': 'customer-password',
    });
    expect(jsonDecode(client.requests[1].body), {
      'refreshToken': 'customer-refresh-1',
    });
    expect(jsonDecode(client.requests[2].body), {
      'refreshToken': 'customer-refresh-2',
    });
    expect(
      client.requests[2].headers['Authorization'],
      'Bearer customer-access-2',
    );
  });

  test('customer service calls the listed customer-app routes', () async {
    final client = _FakeClient();
    final service = CustomerAppService(
      accessToken: 'access-token',
      baseUrl: baseUrl,
      client: client,
    );

    await service.getHome();
    await service.getProfile();
    await service.getLoyalty(page: 2, pageSize: 10);
    await service.getProducts(
      page: 3,
      pageSize: 25,
      search: 'phone',
      categoryId: 'category-4',
    );
    await service.getCategories();
    await service.getCreditPurchases(page: 2, pageSize: 10);
    await service.getPromotions(page: 1, pageSize: 50);
    await service.getNotifications(page: 1, pageSize: 100, unreadOnly: true);
    await service.markNotificationRead('notice-7');
    await service.markAllNotificationsRead();

    expect(
      client.requests.map((request) => '${request.method} ${request.uri.path}'),
      [
        'GET /api/v1/customer-app/home',
        'GET /api/v1/customer-app/profile',
        'GET /api/v1/customer-app/loyalty',
        'GET /api/v1/customer-app/products',
        'GET /api/v1/customer-app/categories',
        'GET /api/v1/customer-app/credit-purchases',
        'GET /api/v1/customer-app/promotions',
        'GET /api/v1/customer-app/notifications',
        'PATCH /api/v1/customer-app/notifications/notice-7/read',
        'PATCH /api/v1/customer-app/notifications/read-all',
      ],
    );
    expect(client.requests.every(
      (request) => request.headers['Authorization'] == 'Bearer access-token',
    ), isTrue);
    expect(client.requests[2].uri.queryParameters, {
      'page': '2',
      'pageSize': '10',
    });
    expect(client.requests[3].uri.queryParameters, {
      'page': '3',
      'pageSize': '25',
      'search': 'phone',
      'categoryId': 'category-4',
    });
    expect(client.requests[7].uri.queryParameters['unread'], 'true');
  });

  test('customer dashboard loads its five backend resources', () async {
    final client = _FakeClient();
    final service = CustomerAppService(
      accessToken: 'access-token',
      baseUrl: baseUrl,
      client: client,
    );

    await service.getDashboard();

    expect(
      client.requests.map((request) => request.uri.path).toSet(),
      {
        '/api/v1/customer-app/home',
        '/api/v1/customer-app/profile',
        '/api/v1/customer-app/loyalty',
        '/api/v1/customer-app/promotions',
        '/api/v1/customer-app/credit-purchases',
      },
    );
  });

  test('a 401 refreshes the token and retries the request once', () async {
    final client = _FakeClient(
      statusForRequest: (index) => index == 0 ? 401 : 200,
    );
    late CustomerAppService service;
    var refreshCount = 0;
    service = CustomerAppService(
      accessToken: 'expired-token',
      baseUrl: baseUrl,
      client: client,
      refreshAccessToken: () async {
        refreshCount++;
        service.accessToken = 'rotated-token';
      },
    );

    await service.getHome();

    expect(refreshCount, 1);
    expect(client.requests, hasLength(2));
    expect(client.requests[0].headers['Authorization'], 'Bearer expired-token');
    expect(client.requests[1].headers['Authorization'], 'Bearer rotated-token');
    expect(client.requests[0].uri, client.requests[1].uri);
  });
}