import 'dart:convert';

import 'package:http/http.dart' as http;

import 'auth_service.dart';

class CustomerAppService {
  final String baseUrl;
  String accessToken;
  final Future<void> Function()? refreshAccessToken;
  final http.Client _client;
  Future<void>? _refreshInProgress;

  CustomerAppService({
    required this.accessToken,
    String? baseUrl,
    http.Client? client,
    this.refreshAccessToken,
  }) : baseUrl = baseUrl ?? ApiConfig.baseUrl,
       _client = client ?? http.Client();

  Future<CustomerDashboardData> getDashboard() async {
    final responses = await Future.wait([
      _get('/customer-app/home'),
      _get('/customer-app/profile'),
      _get('/customer-app/loyalty', query: {'page': '1', 'pageSize': '5'}),
      _get('/customer-app/promotions', query: {'page': '1', 'pageSize': '5'}),
      _get(
        '/customer-app/credit-purchases',
        query: {'page': '1', 'pageSize': '5'},
      ),
    ]);

    return CustomerDashboardData.fromResponses(
      home: _asResponseMap(responses[0]),
      profile: _asResponseMap(responses[1]),
      loyalty: _asResponseMap(responses[2]),
      promotions: _asResponseMap(responses[3]),
      creditPurchases: _asResponseMap(responses[4]),
    );
  }

  Future<Map<String, dynamic>> getHome() async =>
      _asMap(await _get('/customer-app/home'));

  Future<Map<String, dynamic>> getProfile() async =>
      _asMap(await _get('/customer-app/profile'));

  Future<Map<String, dynamic>> getLoyalty({
    int page = 1,
    int pageSize = 20,
  }) async => _asMap(
    await _get(
      '/customer-app/loyalty',
      query: {'page': '$page', 'pageSize': '$pageSize'},
    ),
  );

  Future<Map<String, dynamic>> getProducts({
    int page = 1,
    int pageSize = 20,
    String? search,
    String? categoryId,
  }) async => _asMap(
    await _get(
      '/customer-app/products',
      query: {
        'page': '$page',
        'pageSize': '$pageSize',
        if (search != null && search.isNotEmpty) 'search': search,
        if (categoryId != null && categoryId.isNotEmpty)
          'categoryId': categoryId,
      },
    ),
  );

  Future<List<dynamic>> getCategories() async =>
      _asList(await _get('/customer-app/categories'));

  Future<Map<String, dynamic>> getCreditPurchases({
    int page = 1,
    int pageSize = 20,
  }) async => _asMap(
    await _get(
      '/customer-app/credit-purchases',
      query: {'page': '$page', 'pageSize': '$pageSize'},
    ),
  );

  Future<Map<String, dynamic>> getPromotions({
    int page = 1,
    int pageSize = 20,
  }) async => _asMap(
    await _get(
      '/customer-app/promotions',
      query: {'page': '$page', 'pageSize': '$pageSize'},
    ),
  );

  Future<Map<String, dynamic>> getNotifications({
    int page = 1,
    int pageSize = 20,
    bool unreadOnly = false,
  }) async => _asMap(
    await _get(
      '/customer-app/notifications',
      query: {
        'page': '$page',
        'pageSize': '$pageSize',
        if (unreadOnly) 'unread': 'true',
      },
    ),
  );

  Future<void> markNotificationRead(String id) async {
    await _patch('/customer-app/notifications/${Uri.encodeComponent(id)}/read');
  }

  Future<void> markAllNotificationsRead() async {
    await _patch('/customer-app/notifications/read-all');
  }

  Future<dynamic> _get(String path, {Map<String, String>? query}) async {
    final uri = Uri.parse('$baseUrl$path').replace(queryParameters: query);
    final tokenUsed = accessToken;
    var response = await _client.get(uri, headers: _headers);
    if (response.statusCode == 401 && refreshAccessToken != null) {
      if (tokenUsed == accessToken) await _refreshSession();
      response = await _client.get(uri, headers: _headers);
    }
    return _decode(response);
  }

  Future<void> _patch(String path) async {
    final uri = Uri.parse('$baseUrl$path');
    final tokenUsed = accessToken;
    var response = await _client.patch(
      uri,
      headers: _headers,
    );
    if (response.statusCode == 401 && refreshAccessToken != null) {
      if (tokenUsed == accessToken) await _refreshSession();
      response = await _client.patch(uri, headers: _headers);
    }
    _decode(response);
  }

  Future<void> _refreshSession() async {
    final inProgress = _refreshInProgress;
    if (inProgress != null) {
      await inProgress;
      return;
    }

    final refresh = refreshAccessToken!();
    _refreshInProgress = refresh;
    try {
      await refresh;
    } finally {
      if (identical(_refreshInProgress, refresh)) _refreshInProgress = null;
    }
  }

  Map<String, String> get _headers => {
    'Accept': 'application/json',
    'Authorization': 'Bearer $accessToken',
  };

  dynamic _decode(http.Response response) {
    dynamic payload;
    try {
      payload = response.body.isEmpty
          ? <String, dynamic>{}
          : jsonDecode(response.body);
    } catch (_) {
      payload = response.body;
    }

    if (response.statusCode < 200 || response.statusCode >= 300) {
      final message = payload is Map<String, dynamic>
          ? payload['message'] ?? payload['error']
          : null;
      throw Exception(
        message?.toString() ??
            'Customer request failed (${response.statusCode}).',
      );
    }

    return payload;
  }

  void close() => _client.close();
}

class CustomerDashboardData {
  final Map<String, dynamic> customer;
  final Map<String, dynamic> summary;
  final int points;
  final String tier;
  final List<Map<String, dynamic>> promotions;
  final List<Map<String, dynamic>> creditPurchases;
  final List<Map<String, dynamic>> loyaltyTransactions;

  const CustomerDashboardData({
    required this.customer,
    required this.summary,
    required this.points,
    required this.tier,
    required this.promotions,
    required this.creditPurchases,
    required this.loyaltyTransactions,
  });

  factory CustomerDashboardData.fromResponses({
    required Map<String, dynamic> home,
    required Map<String, dynamic> profile,
    required Map<String, dynamic> loyalty,
    required Map<String, dynamic> promotions,
    required Map<String, dynamic> creditPurchases,
  }) {
    final homeCustomer = _asMap(home['customer']);
    final profileUser = _asMap(profile['user']);
    final customer = <String, dynamic>{
      ...homeCustomer,
      ...profile,
      'user': profileUser,
      'email': profileUser['email'] ?? profile['email'] ?? '',
      'phone': profileUser['phone'] ?? profile['phone'] ?? '',
    };
    final summary = _asMap(home['summary']);
    final loyaltyAccount = _asMap(profile['loyaltyAccount']);

    return CustomerDashboardData(
      customer: customer,
      summary: summary,
      points: _asInt(
        summary['loyaltyPoints'] ??
            loyalty['points'] ??
            loyaltyAccount['points'],
      ),
      tier:
          (summary['loyaltyTier'] ??
                  loyalty['tier'] ??
                  loyaltyAccount['tier'] ??
                  'Member')
              .toString(),
      promotions: _asMapList(promotions['data']),
      creditPurchases: _asMapList(creditPurchases['data']),
      loyaltyTransactions: _asMapList(loyalty['data']),
    );
  }

  String get name {
    final firstName = customer['firstName']?.toString().trim() ?? '';
    final lastName = customer['lastName']?.toString().trim() ?? '';
    final fullName = '$firstName $lastName'.trim();
    if (fullName.isNotEmpty) return fullName;
    return customer['name']?.toString() ?? 'Customer';
  }

  String get email => customer['email']?.toString() ?? '';
  String get phone => customer['phone']?.toString() ?? '';
  String get customerNumber => customer['customerNumber']?.toString() ?? '';
  String get currencyCode =>
      _asMap(customer['organization'])['currencyCode']?.toString() ?? 'LKR';
  num get storeCreditBalance {
    final value = _asMap(profileStoreCredit)['balance'];
    return num.tryParse(value?.toString() ?? '') ?? 0;
  }

  int get activeCreditPurchases => _asInt(summary['activeCreditPurchases']);
  int get activePromotions => _asInt(summary['activePromotions']);
  int get unreadNotifications => _asInt(summary['unreadNotifications']);

  dynamic get profileStoreCredit => _asMap(customer['storeCreditAccount']);
}

Map<String, dynamic> _asResponseMap(dynamic value) {
  final result = _asMap(value);
  final nested = result['data'];
  return nested is Map<String, dynamic> ? nested : result;
}

Map<String, dynamic> _asMap(dynamic value) =>
    value is Map<String, dynamic> ? value : <String, dynamic>{};

List<Map<String, dynamic>> _asMapList(dynamic value) {
  if (value is! List) return const [];
  return value.whereType<Map<String, dynamic>>().toList();
}

List<dynamic> _asList(dynamic value) => value is List ? value : const [];

int _asInt(dynamic value) => int.tryParse(value?.toString() ?? '') ?? 0;
