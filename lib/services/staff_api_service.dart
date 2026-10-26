import 'dart:convert';

import 'package:http/http.dart' as http;

import 'auth_service.dart';

class StaffUser {
  final String id;
  final String email;
  final String name;
  final List<String> roles;
  final List<String> permissions;

  const StaffUser({
    required this.id,
    required this.email,
    required this.name,
    required this.roles,
    required this.permissions,
  });

  factory StaffUser.fromJson(Map<String, dynamic> json) => StaffUser(
    id: json['id']?.toString() ?? '',
    email: json['email']?.toString() ?? '',
    name: json['name']?.toString() ?? '',
    roles: _stringList(json['roles']),
    permissions: _stringList(json['permissions']),
  );
}

class StaffLoginResponse {
  final String accessToken;
  final int expiresIn;
  final StaffUser user;

  const StaffLoginResponse({
    required this.accessToken,
    required this.expiresIn,
    required this.user,
  });
}

class StaffApiService {
  final String baseUrl;
  final http.Client _client;
  String? accessToken;

  StaffApiService({String? baseUrl, this.accessToken, http.Client? client})
    : baseUrl = baseUrl ?? ApiConfig.baseUrl,
      _client = client ?? http.Client();

  Future<StaffLoginResponse> login({
    required String email,
    required String password,
  }) async {
    final payload = await _request(
      'POST',
      '/auth/login',
      body: {'email': email, 'password': password},
    );
    final data = _unwrap(payload);
    final token = data['accessToken']?.toString() ?? '';
    if (token.isEmpty) {
      throw Exception('Access token was not returned by the server.');
    }

    accessToken = token;
    return StaffLoginResponse(
      accessToken: token,
      expiresIn: int.tryParse(data['expiresIn']?.toString() ?? '') ?? 0,
      user: StaffUser.fromJson(_asMap(data['user'])),
    );
  }

  Future<StaffUser> getMe() async {
    final data = _unwrap(await _request('GET', '/auth/me'));
    return StaffUser.fromJson(_asMap(data['user'] ?? data));
  }

  Future<Map<String, dynamic>> getSales({
    int page = 1,
    int pageSize = 20,
    String? search,
    String? branchId,
    String? cashierId,
    String? status,
    DateTime? from,
    DateTime? to,
  }) async {
    final payload = await _request(
      'GET',
      '/sales',
      query: {
        'page': '$page',
        'pageSize': '$pageSize',
        if (search != null && search.isNotEmpty) 'search': search,
        if (branchId != null && branchId.isNotEmpty) 'branchId': branchId,
        if (cashierId != null && cashierId.isNotEmpty) 'cashierId': cashierId,
        if (status != null && status.isNotEmpty) 'status': status,
        if (from != null) 'from': _dateParameter(from),
        if (to != null) 'to': _dateParameter(to),
      },
    );
    return _page(payload);
  }

  Future<Map<String, dynamic>> getSaleDetail(String id) async => _asMap(
    _unwrap(await _request('GET', '/sales/${Uri.encodeComponent(id)}')),
  );

  Future<List<Map<String, dynamic>>> getSalesReport({
    required DateTime from,
    required DateTime to,
  }) async {
    final payload = await _request(
      'GET',
      '/reports/sales',
      query: {'from': _dateParameter(from), 'to': _dateParameter(to)},
    );
    final data = payload is List
        ? payload
        : _unwrap(payload)['data'] ?? payload;
    return _mapList(data);
  }

  Future<Map<String, dynamic>> getReportDashboard({
    required DateTime from,
    required DateTime to,
  }) async {
    final payload = await _request(
      'GET',
      '/reports/dashboard',
      query: {'from': _dateParameter(from), 'to': _dateParameter(to)},
    );
    return _asMap(_unwrap(payload));
  }

  Future<List<Map<String, dynamic>>> getBranches({
    int page = 1,
    int pageSize = 100,
  }) async {
    final payload = await _request(
      'GET',
      '/branches',
      query: {'page': '$page', 'pageSize': '$pageSize'},
    );
    final data = payload is List ? payload : _unwrap(payload);
    return _mapList(
      data is Map<String, dynamic> ? data['data'] ?? data['branches'] : data,
    );
  }

  Future<Map<String, dynamic>> getSupplierPortalDashboard({
    int page = 1,
    int pageSize = 10,
    String? search,
    String? status,
    DateTime? from,
    DateTime? to,
  }) async => _asMap(
    _unwrap(
      await _request(
        'GET',
        '/supplier-portal/dashboard',
        query: {
          'page': '$page',
          'pageSize': '$pageSize',
          if (search != null && search.isNotEmpty) 'search': search,
          if (status != null && status.isNotEmpty) 'status': status,
          if (from != null) 'from': _dateParameter(from),
          if (to != null) 'to': _dateParameter(to),
        },
      ),
    ),
  );

  Future<Map<String, dynamic>> getSupplierPortalOrder(String id) async =>
      _asMap(
        _unwrap(
          await _request(
            'GET',
            '/supplier-portal/orders/${Uri.encodeComponent(id)}',
          ),
        ),
      );

  Future<Map<String, dynamic>> getCatalogProducts({
    int page = 1,
    int pageSize = 20,
    String? search,
    String? categoryId,
    String? branchId,
    String? status,
  }) async => _page(
    await _request(
      'GET',
      '/catalog/products',
      query: {
        'page': '$page',
        'pageSize': '$pageSize',
        if (search != null && search.isNotEmpty) 'search': search,
        if (categoryId != null && categoryId.isNotEmpty)
          'categoryId': categoryId,
        if (branchId != null && branchId.isNotEmpty) 'branchId': branchId,
        if (status != null && status.isNotEmpty) 'status': status,
      },
    ),
  );

  Future<Map<String, dynamic>> getInventoryStock({
    int page = 1,
    int pageSize = 20,
    String? search,
    String? branchId,
    String? productId,
  }) async => _page(
    await _request(
      'GET',
      '/inventory/stock',
      query: {
        'page': '$page',
        'pageSize': '$pageSize',
        if (search != null && search.isNotEmpty) 'search': search,
        if (branchId != null && branchId.isNotEmpty) 'branchId': branchId,
        if (productId != null && productId.isNotEmpty) 'productId': productId,
      },
    ),
  );

  Future<Map<String, dynamic>> getCustomers({
    int page = 1,
    int pageSize = 20,
    String? search,
    String? status,
  }) async => _page(
    await _request(
      'GET',
      '/customers',
      query: {
        'page': '$page',
        'pageSize': '$pageSize',
        if (search != null && search.isNotEmpty) 'search': search,
        if (status != null && status.isNotEmpty) 'status': status,
      },
    ),
  );

  Future<Map<String, dynamic>> getSuppliers({
    int page = 1,
    int pageSize = 20,
    String? search,
    String? status,
  }) async => _page(
    await _request(
      'GET',
      '/suppliers',
      query: {
        'page': '$page',
        'pageSize': '$pageSize',
        if (search != null && search.isNotEmpty) 'search': search,
        if (status != null && status.isNotEmpty) 'status': status,
      },
    ),
  );

  Future<List<Map<String, dynamic>>> getCatalogCategories() async =>
      _collection(await _request('GET', '/catalog/categories'));

  Future<List<Map<String, dynamic>>> getDiscounts() async =>
      _collection(await _request('GET', '/discounts'));

  Future<Map<String, dynamic>> getInAppNotifications({
    int page = 1,
    int pageSize = 50,
    bool unreadOnly = false,
  }) async => _page(
    await _request(
      'GET',
      '/notifications/in-app',
      query: {
        'page': '$page',
        'pageSize': '$pageSize',
        if (unreadOnly) 'unread': 'true',
      },
    ),
  );

  Future<void> markInAppNotificationRead(String id) async {
    await _request(
      'PATCH',
      '/notifications/in-app/${Uri.encodeComponent(id)}/read',
    );
  }

  Future<void> markAllInAppNotificationsRead() async {
    await _request('PATCH', '/notifications/in-app/read-all');
  }

  Future<dynamic> _request(
    String method,
    String path, {
    Map<String, String>? query,
    Map<String, dynamic>? body,
  }) async {
    final uri = Uri.parse('$baseUrl$path').replace(queryParameters: query);
    final headers = <String, String>{
      'Accept': 'application/json',
      if (body != null) 'Content-Type': 'application/json',
      if (accessToken case final token? when token.isNotEmpty)
        'Authorization': 'Bearer $token',
    };
    final response = switch (method) {
      'POST' => await _client.post(
        uri,
        headers: headers,
        body: jsonEncode(body),
      ),
      'PATCH' => await _client.patch(
        uri,
        headers: headers,
        body: body == null ? null : jsonEncode(body),
      ),
      _ => await _client.get(uri, headers: headers),
    };
    final payload = _decode(response.body);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      final data = _asMap(payload);
      throw Exception(
        data['message']?.toString() ??
            data['error']?.toString() ??
            'Request failed (${response.statusCode}).',
      );
    }
    return payload;
  }

  dynamic _decode(String body) {
    if (body.isEmpty) return <String, dynamic>{};
    try {
      return jsonDecode(body);
    } catch (_) {
      return body;
    }
  }

  void close() => _client.close();
}

Map<String, dynamic> _unwrap(dynamic value) {
  final map = _asMap(value);
  return map['data'] is Map<String, dynamic>
      ? map['data'] as Map<String, dynamic>
      : map;
}

Map<String, dynamic> _page(dynamic value) {
  final data = _unwrap(value);
  if (data['data'] is List) return data;
  if (value is List) return {'data': value, 'meta': <String, dynamic>{}};
  return {'data': <dynamic>[], 'meta': <String, dynamic>{}};
}

List<Map<String, dynamic>> _collection(dynamic value) {
  if (value is List) return _mapList(value);
  final data = _unwrap(value);
  return _mapList(data['data'] ?? data['items'] ?? data['notifications']);
}

Map<String, dynamic> _asMap(dynamic value) =>
    value is Map<String, dynamic> ? value : <String, dynamic>{};

List<Map<String, dynamic>> _mapList(dynamic value) => value is List
    ? value.whereType<Map<String, dynamic>>().toList()
    : <Map<String, dynamic>>[];

List<String> _stringList(dynamic value) =>
    value is List ? value.map((item) => item.toString()).toList() : <String>[];

String _dateParameter(DateTime value) =>
    '${value.year.toString().padLeft(4, '0')}-'
    '${value.month.toString().padLeft(2, '0')}-'
    '${value.day.toString().padLeft(2, '0')}';
