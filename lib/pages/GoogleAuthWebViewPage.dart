import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

class GoogleAuthTokens {
  final String accessToken;
  final String refreshToken;

  const GoogleAuthTokens({
    required this.accessToken,
    required this.refreshToken,
  });
}

class GoogleAuthWebViewPage extends StatefulWidget {
  const GoogleAuthWebViewPage({super.key});

  @override
  State<GoogleAuthWebViewPage> createState() => _GoogleAuthWebViewPageState();
}

class _GoogleAuthWebViewPageState extends State<GoogleAuthWebViewPage> {
  late final WebViewController _controller;
  bool _isLoading = true;
  bool _hasReturnedTokens = false;

  GoogleAuthTokens? _tokensFromUrl(String url) {
    final uri = Uri.tryParse(url);
    if (uri == null) return null;

    final parameters = <String, String>{...uri.queryParameters};
    final fragment = uri.fragment;
    if (fragment.isNotEmpty) {
      final queryStart = fragment.lastIndexOf('?');
      final fragmentParameters = queryStart >= 0
          ? fragment.substring(queryStart + 1)
          : fragment;
      if (fragmentParameters.contains('=')) {
        parameters.addAll(Uri.splitQueryString(fragmentParameters));
      }
    }

    final accessToken =
        parameters['accessToken'] ??
        parameters['access_token'] ??
        parameters['token'];
    if (accessToken == null || accessToken.isEmpty) return null;

    return GoogleAuthTokens(
      accessToken: accessToken,
      refreshToken:
          parameters['refreshToken'] ?? parameters['refresh_token'] ?? '',
    );
  }

  void _returnTokens(GoogleAuthTokens tokens) {
    if (_hasReturnedTokens || !mounted) return;
    _hasReturnedTokens = true;
    Navigator.of(context).pop(tokens);
  }

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onNavigationRequest: (request) {
            final tokens = _tokensFromUrl(request.url);
            if (tokens != null) {
              _returnTokens(tokens);
              return NavigationDecision.prevent;
            }
            return NavigationDecision.navigate;
          },
          onPageStarted: (url) {
            if (mounted) setState(() => _isLoading = true);
          },
          onPageFinished: (url) {
            if (mounted) setState(() => _isLoading = false);
          },
        ),
      )
      ..loadRequest(Uri.parse('https://pos.nxcodeworks.com/api/v1/auth/google'));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sign in with Google', style: TextStyle(fontSize: 14)),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF202124),
        elevation: 0.5,
      ),
      body: Stack(
        children: [
          WebViewWidget(controller: _controller),
          if (_isLoading)
            const Center(
              child: CircularProgressIndicator(color: Color(0xFF0D9488)),
            ),
        ],
      ),
    );
  }
}
