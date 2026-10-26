import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

class ApiConfig {
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://pos.nxcodeworks.com/api/v1',
  );
}

class AuthEndpoints {
  static const String customerLogin = '/auth/customer/login';
  static const String customerGoogleLogin = '/auth/google/mobile';
  static const String customerGoogleLink = '/auth/customer/google/link';
  static const String forgotPassword = '/auth/forgot-password';
  static const String verifyResetOtp = '/auth/verify-reset-otp';
  static const String resetPassword = '/auth/reset-password';
  static const String customerRefresh = '/auth/customer/refresh';
  static const String customerLogout = '/auth/customer/logout';
  static const String me = '/auth/me';
  static const String sessions = '/auth/sessions';
  static const String changePassword = '/auth/change-password';
  static const String sessionDelete = '/auth/sessions/:id';

  static String sessionById(String id) => '$sessions/${Uri.encodeComponent(id)}';

  static const Map<String, String> descriptions = {
    customerLogin: 'Customer login using phone and password',
    customerGoogleLogin: 'Mobile Google login using a verified Google ID token',
    customerRefresh: 'Generate a new access token',
    customerLogout: 'Log out and invalidate refresh token',
    me: 'Get currently logged-in user',
    sessions: 'List logged-in devices/sessions',
    sessionDelete: 'Log out another device',
    changePassword: 'Change customer password',
  };
}

class CustomerUser {
  final String id;
  final String name;
  final String phone;
  final String email;
  final String customerNumber;
  final bool mustChangePassword;

  CustomerUser({
    required this.id,
    required this.name,
    required this.phone,
    required this.email,
    this.customerNumber = '',
    this.mustChangePassword = false,
  });

  factory CustomerUser.fromJson(Map<String, dynamic> json) {
    final firstName = json['firstName']?.toString().trim() ?? '';
    final lastName = json['lastName']?.toString().trim() ?? '';
    final fullName = '$firstName $lastName'.trim();
    return CustomerUser(
      id: json['id']?.toString() ?? '',
      name: fullName.isNotEmpty ? fullName : json['name']?.toString() ?? '',
      phone: json['phone']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      customerNumber: json['customerNumber']?.toString() ?? '',
      mustChangePassword: json['mustChangePassword'] == true,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'phone': phone,
    'email': email,
    'customerNumber': customerNumber,
    'mustChangePassword': mustChangePassword,
  };
}

class CustomerSessionStore {
  static const FlutterSecureStorage _storage = FlutterSecureStorage();
  static const String _accessTokenKey = 'customer_access_token';
  static const String _refreshTokenKey = 'customer_refresh_token';
  static const String _customerKey = 'customer_user';

  Future<void> save(AuthResponse response) async {
    await _storage.write(
      key: _accessTokenKey,
      value: response.tokens.accessToken,
    );
    await _storage.write(
      key: _refreshTokenKey,
      value: response.tokens.refreshToken,
    );
    await _storage.write(
      key: _customerKey,
      value: jsonEncode(response.user.toJson()),
    );
  }

  Future<String?> readAccessToken() => _storage.read(key: _accessTokenKey);

  Future<String?> readRefreshToken() => _storage.read(key: _refreshTokenKey);

  Future<CustomerUser?> readCustomer() async {
    final encoded = await _storage.read(key: _customerKey);
    if (encoded == null) return null;
    try {
      final value = jsonDecode(encoded);
      return value is Map<String, dynamic>
          ? CustomerUser.fromJson(value)
          : null;
    } catch (_) {
      return null;
    }
  }

  Future<void> clear() async {
    await _storage.delete(key: _accessTokenKey);
    await _storage.delete(key: _refreshTokenKey);
    await _storage.delete(key: _customerKey);
  }
}

class AuthTokens {
  final String accessToken;
  final String refreshToken;

  AuthTokens({required this.accessToken, required this.refreshToken});

  Map<String, dynamic> toJson() => {
    'accessToken': accessToken,
    'refreshToken': refreshToken,
  };
}

class AuthResponse {
  final CustomerUser user;
  final AuthTokens tokens;

  AuthResponse({required this.user, required this.tokens});
}

class UserSession {
  final String id;
  final String deviceName;
  final String lastActive;
  final bool? isCurrent;

  UserSession({
    required this.id,
    required this.deviceName,
    required this.lastActive,
    this.isCurrent,
  });
}

abstract class AuthRepository {
  Future<AuthResponse> login({required String phone, required String password});

  Future<AuthResponse> refreshToken({required String refreshToken});

  Future<void> logout({required String refreshToken});

  Future<CustomerUser> getMe();

  Future<List<UserSession>> getSessions();

  Future<void> deleteSession(String sessionId);

  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  });
}

class HttpAuthRepository implements AuthRepository {
  final String baseUrl;
  final http.Client _client;
  String? accessToken;

  HttpAuthRepository({
    this.baseUrl = ApiConfig.baseUrl,
    this.accessToken,
    http.Client? client,
  }) : _client = client ?? http.Client();

  Map<String, String> _headers({String? token}) => {
    'Content-Type': 'application/json',
    if ((token ?? accessToken) != null && (token ?? accessToken)!.isNotEmpty)
      'Authorization': 'Bearer ${(token ?? accessToken)!}',
  };

  Map<String, String> get _publicHeaders => {'Content-Type': 'application/json'};

  dynamic _decodeResponse(http.Response response) {
    if (response.body.isEmpty) {
      return {};
    }

    try {
      return jsonDecode(response.body);
    } catch (_) {
      return response.body;
    }
  }

  String _errorMessage(dynamic payload, String fallback) {
    if (payload is Map<String, dynamic>) {
      for (final key in ['message', 'error', 'msg', 'detail']) {
        final value = payload[key];
        if (value is String && value.trim().isNotEmpty) return value.trim();
      }

      final nested = payload['data'];
      if (nested is Map<String, dynamic>) {
        final message = _errorMessage(nested, '');
        if (message.isNotEmpty) return message;
      }

      final errors = payload['errors'];
      if (errors is List && errors.isNotEmpty) {
        return errors.map((error) => error.toString()).join(', ');
      }
      if (errors is Map<String, dynamic> && errors.isNotEmpty) {
        return errors.values.expand((value) {
          if (value is List) return value.map((item) => item.toString());
          return [value.toString()];
        }).join(', ');
      }
    }
    return fallback;
  }

  @override
  Future<AuthResponse> login({
    required String phone,
    required String password,
  }) async {
    final uri = Uri.parse('$baseUrl${AuthEndpoints.customerLogin}');
    final response = await _client.post(
      uri,
      headers: _headers(),
      body: jsonEncode({'phone': phone, 'password': password}),
    );

    return _parseAuthResponse(response, fallbackMessage: 'Login failed');
  }

  Future<AuthResponse> loginWithGoogleIdToken({required String idToken}) async {
    final uri = Uri.parse('$baseUrl${AuthEndpoints.customerGoogleLogin}');
    final response = await _client.post(
      uri,
      headers: _headers(),
      body: jsonEncode({'idToken': idToken}),
    );

    return _parseAuthResponse(
      response,
      fallbackMessage: 'Google sign-in failed',
    );
  }

  Future<void> linkCustomerGoogleAccount({required String idToken}) async {
    final uri = Uri.parse('$baseUrl${AuthEndpoints.customerGoogleLink}');
    final response = await _client.post(
      uri,
      headers: _headers(),
      body: jsonEncode({'idToken': idToken}),
    );
    final payload = _decodeResponse(response);

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(_errorMessage(payload, 'Unable to link Google account'));
    }
  }

  Future<String> requestCustomerPasswordReset({required String email}) async {
    final uri = Uri.parse('$baseUrl${AuthEndpoints.forgotPassword}');
    final response = await _client.post(
      uri,
      headers: _publicHeaders,
      body: jsonEncode({'email': email}),
    );
    final payload = _decodeResponse(response);

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(_errorMessage(payload, 'Unable to send reset code'));
    }

    final data = payload is Map<String, dynamic> &&
            payload['data'] is Map<String, dynamic>
        ? payload['data'] as Map<String, dynamic>
        : payload is Map<String, dynamic>
        ? payload
        : <String, dynamic>{};
    final challengeToken = data['challengeToken']?.toString() ?? '';
    if (challengeToken.isEmpty) {
      throw Exception('Reset challenge token was not returned by the server.');
    }
    return challengeToken;
  }

  Future<String> verifyCustomerPasswordResetOtp({
    required String challengeToken,
    required String otp,
  }) async {
    final uri = Uri.parse('$baseUrl${AuthEndpoints.verifyResetOtp}');
    final response = await _client.post(
      uri,
      headers: _publicHeaders,
      body: jsonEncode({'challengeToken': challengeToken, 'otp': otp}),
    );
    final payload = _decodeResponse(response);

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(_errorMessage(payload, 'Reset code verification failed'));
    }

    final data = payload is Map<String, dynamic> &&
            payload['data'] is Map<String, dynamic>
        ? payload['data'] as Map<String, dynamic>
        : payload is Map<String, dynamic>
        ? payload
        : <String, dynamic>{};
    final resetToken = data['resetToken']?.toString() ?? '';
    if (resetToken.isEmpty) {
      throw Exception('Password reset token was not returned by the server.');
    }
    return resetToken;
  }

  Future<void> resetCustomerPassword({
    required String resetToken,
    required String password,
  }) async {
    final uri = Uri.parse('$baseUrl${AuthEndpoints.resetPassword}');
    final response = await _client.post(
      uri,
      headers: _publicHeaders,
      body: jsonEncode({'resetToken': resetToken, 'password': password}),
    );
    final payload = _decodeResponse(response);

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(_errorMessage(payload, 'Password reset failed'));
    }
  }

  Future<String> requestStaffPasswordReset({required String email}) =>
      requestCustomerPasswordReset(email: email);

  Future<String> verifyStaffPasswordResetOtp({
    required String challengeToken,
    required String otp,
  }) => verifyCustomerPasswordResetOtp(
    challengeToken: challengeToken,
    otp: otp,
  );

  Future<void> resetStaffPassword({
    required String resetToken,
    required String password,
  }) => resetCustomerPassword(resetToken: resetToken, password: password);

  AuthResponse _parseAuthResponse(
    http.Response response, {
    required String fallbackMessage,
  }) {
    final payload = _decodeResponse(response);

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(
        '${_errorMessage(payload, fallbackMessage)} (HTTP ${response.statusCode})',
      );
    }

    final data = payload is Map<String, dynamic>
        ? (payload['data'] ?? payload)
        : <String, dynamic>{};

    final tokensData = data['tokens'] ?? data;
    final userData = data['user'] is Map<String, dynamic>
        ? data['user'] as Map<String, dynamic>
        : <String, dynamic>{};
    final customerData = data['customer'] is Map<String, dynamic>
        ? data['customer'] as Map<String, dynamic>
        : <String, dynamic>{};

    final accessToken =
        (tokensData['accessToken'] ??
                tokensData['token'] ??
                data['accessToken'] ??
                data['token'] ??
                '')
            .toString();
    final refreshToken =
        (tokensData['refreshToken'] ?? data['refreshToken'] ?? '').toString();

    if (accessToken.isEmpty) {
      throw Exception('Access token was not returned by the server.');
    }

    this.accessToken = accessToken;
    final customerUser = CustomerUser.fromJson({
      ...userData,
      ...customerData,
      'email': userData['email'] ?? customerData['email'],
      'phone': userData['phone'] ?? customerData['phone'],
      'mustChangePassword': userData['mustChangePassword'],
    });

    return AuthResponse(
      user: customerUser,
      tokens: AuthTokens(accessToken: accessToken, refreshToken: refreshToken),
    );
  }

  @override
  Future<AuthResponse> refreshToken({required String refreshToken}) async {
    final uri = Uri.parse('$baseUrl${AuthEndpoints.customerRefresh}');
    final response = await _client.post(
      uri,
      headers: _headers(),
      body: jsonEncode({'refreshToken': refreshToken}),
    );

    final payload = _decodeResponse(response);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(_errorMessage(payload, 'Token refresh failed'));
    }

    final data = payload is Map<String, dynamic>
        ? (payload['data'] ?? payload)
        : <String, dynamic>{};

    final tokensData = data['tokens'] ?? data;
    final accessToken =
        (tokensData['accessToken'] ??
                tokensData['token'] ??
                data['accessToken'] ??
                '')
            .toString();
    final newRefreshToken =
        (tokensData['refreshToken'] ?? data['refreshToken'] ?? refreshToken)
            .toString();
    this.accessToken = accessToken;

    return AuthResponse(
      user: CustomerUser.fromJson({
        ...((data['user'] as Map<String, dynamic>?) ?? <String, dynamic>{}),
        ...((data['customer'] as Map<String, dynamic>?) ?? <String, dynamic>{}),
      }),
      tokens: AuthTokens(
        accessToken: accessToken,
        refreshToken: newRefreshToken,
      ),
    );
  }

  @override
  Future<void> logout({required String refreshToken}) async {
    final uri = Uri.parse('$baseUrl${AuthEndpoints.customerLogout}');
    final response = await _client.post(
      uri,
      headers: _headers(token: accessToken),
      body: jsonEncode({'refreshToken': refreshToken}),
    );

    final payload = _decodeResponse(response);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(_errorMessage(payload, 'Logout failed'));
    }
  }

  @override
  Future<CustomerUser> getMe() async {
    final uri = Uri.parse('$baseUrl${AuthEndpoints.me}');
    final response = await _client.get(
      uri,
      headers: _headers(token: accessToken),
    );
    final payload = _decodeResponse(response);

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(_errorMessage(payload, 'Unable to load user profile'));
    }

    final data = payload is Map<String, dynamic>
        ? (payload['data'] ?? payload)
        : <String, dynamic>{};

    return CustomerUser.fromJson(
      data is Map<String, dynamic> ? data : <String, dynamic>{},
    );
  }

  @override
  Future<List<UserSession>> getSessions() async {
    final uri = Uri.parse('$baseUrl${AuthEndpoints.sessions}');
    final response = await _client.get(
      uri,
      headers: _headers(token: accessToken),
    );
    final payload = _decodeResponse(response);

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(_errorMessage(payload, 'Unable to load sessions'));
    }

    final items = payload is Map<String, dynamic>
        ? (payload['data'] ?? payload['sessions'] ?? [])
        : payload;

    if (items is! List) {
      return const [];
    }

    return items.map<UserSession>((item) {
      final map = item is Map<String, dynamic> ? item : <String, dynamic>{};
      return UserSession(
        id: map['id']?.toString() ?? '',
        deviceName:
            map['deviceName']?.toString() ??
            map['device']?.toString() ??
          map['userAgent']?.toString() ??
          'Unknown device',
        lastActive:
          map['lastActive']?.toString() ??
          map['lastUsedAt']?.toString() ??
          map['createdAt']?.toString() ??
          '',
        isCurrent: map['isCurrent'] is bool ? map['isCurrent'] as bool : null,
      );
    }).toList();
  }

  @override
  Future<void> deleteSession(String sessionId) async {
    final uri = Uri.parse('$baseUrl${AuthEndpoints.sessionById(sessionId)}');
    final response = await _client.delete(
      uri,
      headers: _headers(token: accessToken),
    );
    final payload = _decodeResponse(response);

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(_errorMessage(payload, 'Unable to delete session'));
    }
  }

  @override
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    final uri = Uri.parse('$baseUrl${AuthEndpoints.changePassword}');
    final response = await _client.post(
      uri,
      headers: _headers(token: accessToken),
      body: jsonEncode({
        'currentPassword': currentPassword,
        'newPassword': newPassword,
      }),
    );

    final payload = _decodeResponse(response);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(
        '${_errorMessage(payload, 'Password update failed')} '
        '(HTTP ${response.statusCode})',
      );
    }
  }

  void close() => _client.close();
}
