import 'package:google_sign_in/google_sign_in.dart';

class GoogleIdentityService {
  static const String _serverClientId = String.fromEnvironment(
    'GOOGLE_SERVER_CLIENT_ID',
    defaultValue:
        '696943989952-spg8sjqf0acp9ef86otupd21ql5qrv1h.apps.googleusercontent.com',
  );

  static final GoogleSignIn _googleSignIn = GoogleSignIn.instance;
  static Future<void>? _initialization;

  Future<String> getIdToken() async {
    if (_serverClientId.isEmpty) {
      throw StateError(
        'Google sign-in is not configured. Set GOOGLE_SERVER_CLIENT_ID.',
      );
    }

    _initialization ??= _googleSignIn.initialize(
      serverClientId: _serverClientId,
    );
    await _initialization;

    final account = await _googleSignIn.authenticate();
    final idToken = account.authentication.idToken;
    if (idToken == null || idToken.isEmpty) {
      throw Exception('Google did not return an ID token.');
    }
    return idToken;
  }
}
