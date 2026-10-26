import 'package:flutter/material.dart';

import '../services/auth_service.dart';
import '../services/customer_app_service.dart';
import '../services/google_identity_service.dart';
import '../widgets/navbar.dart';
import 'login_page.dart';

class ProfilePage extends StatefulWidget {
  final bool showAppBar;
  final CustomerAppService? service;
  final HttpAuthRepository? authRepository;
  final Future<void> Function()? onLogout;

  const ProfilePage({
    super.key,
    this.showAppBar = true,
    this.service,
    this.authRepository,
    this.onLogout,
  });

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  static const Color darkGreen = Color(0xFF064E46);
  static const Color lightBackground = Color(0xFFF8F9FC);

  late Future<Map<String, dynamic>>? _profileFuture;
  late Future<List<UserSession>>? _sessionsFuture;
  bool _isLinkingGoogle = false;
  bool _googleLinked = false;

  @override
  void initState() {
    super.initState();
    _profileFuture = widget.service == null ? null : _loadProfile();
    _sessionsFuture = widget.authRepository?.getSessions();
  }

  Future<Map<String, dynamic>> _loadProfile() async {
    final response = await widget.service!.getProfile();
    final profile = _profileData(response);
    final user = await widget.authRepository?.getMe();
    if (user == null) return profile;
    return {
      ...profile,
      if ((profile['email'] ?? '').toString().isEmpty) 'email': user.email,
      if ((profile['phone'] ?? '').toString().isEmpty) 'phone': user.phone,
    };
  }

  Map<String, dynamic> _profileData(Map<String, dynamic> response) {
    final data = response['data'] is Map<String, dynamic>
        ? response['data'] as Map<String, dynamic>
        : response;
    final user = data['user'] is Map<String, dynamic>
        ? data['user'] as Map<String, dynamic>
        : data['customer'] is Map<String, dynamic>
            ? data['customer'] as Map<String, dynamic>
            : data;
    return {...data, ...user};
  }

  Future<void> _logout(BuildContext context) async {
    if (widget.onLogout != null) {
      await widget.onLogout!();
      return;
    }
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginPage()),
      (route) => false,
    );
  }

  Future<void> _revokeSession(UserSession session) async {
    final repository = widget.authRepository;
    if (repository == null || session.isCurrent != false) return;
    try {
      await repository.deleteSession(session.id);
      if (!mounted) return;
      setState(() => _sessionsFuture = repository.getSessions());
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Session signed out.')),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Unable to sign out session: $error')),
      );
    }
  }

  Future<void> _linkGoogleAccount() async {
    final repository = widget.authRepository;
    if (repository == null || _isLinkingGoogle) return;

    setState(() => _isLinkingGoogle = true);
    try {
      final idToken = await GoogleIdentityService().getIdToken();
      await repository.linkCustomerGoogleAccount(idToken: idToken);
      if (!mounted) return;
      setState(() => _googleLinked = true);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Google account linked successfully.')),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Unable to link Google account: $error')),
      );
    } finally {
      if (mounted) setState(() => _isLinkingGoogle = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: lightBackground,
      appBar: widget.showAppBar
          ? TechNovaNavbar(
              title: 'Profile',
              onProfileTap: () => Navigator.of(context).pop(),
            )
          : null,
      body: SafeArea(
        child: _profileFuture == null
            ? const Center(child: Text('Sign in to load your profile.'))
            : FutureBuilder<Map<String, dynamic>>(
                future: _profileFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    return Center(
                      child: Text('Unable to load profile: ${snapshot.error}'),
                    );
                  }
                  return _buildProfile(snapshot.data ?? const {});
                },
              ),
      ),
    );
  }

  Widget _buildProfile(Map<String, dynamic> profile) {
    final firstName = (profile['firstName'] ?? '').toString();
    final lastName = (profile['lastName'] ?? '').toString();
    final name = (profile['name'] ?? '$firstName $lastName').toString().trim();
    final initials = name
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .take(2)
        .map((part) => part[0].toUpperCase())
        .join();
    final address = profile['address'] is Map<String, dynamic>
        ? (profile['address'] as Map<String, dynamic>).values.join(', ')
        : profile['address']?.toString() ?? '—';
    final details = <String, String>{
      'Customer ID': (profile['customerNumber'] ?? profile['id'] ?? '—').toString(),
      'First Name': firstName.isEmpty ? '—' : firstName,
      'Last Name': lastName.isEmpty ? '—' : lastName,
      'Phone No': (profile['phone'] ?? '—').toString(),
      'Email': (profile['email'] ?? '—').toString(),
      'Address': address.isEmpty ? '—' : address,
    };

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(18, 20, 18, 28),
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: darkGreen,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                CircleAvatar(
                  radius: 34,
                  backgroundColor: Colors.white,
                  child: Text(
                    initials.isEmpty ? '?' : initials,
                    style: const TextStyle(
                      color: darkGreen,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  name.isEmpty ? 'Customer' : name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 19,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Customer Profile',
                  style: TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey.shade100),
            ),
            child: Column(
              children: details.entries
                  .map((entry) => _ProfileDetailRow(
                        label: entry.key,
                        value: entry.value,
                      ))
                  .toList(),
            ),
          ),
          if (widget.authRepository != null) ...[
            const SizedBox(height: 18),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade100),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Google sign-in',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    'Link the Google account that uses your registered customer email.',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: _isLinkingGoogle || _googleLinked
                          ? null
                          : _linkGoogleAccount,
                      icon: _isLinkingGoogle
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Icon(
                              _googleLinked ? Icons.check : Icons.link,
                              size: 18,
                            ),
                      label: Text(
                        _googleLinked
                            ? 'Google account linked'
                            : 'Link Google account',
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          if (_sessionsFuture != null) ...[
            const SizedBox(height: 22),
            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Active sessions',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
              ),
            ),
            const SizedBox(height: 10),
            FutureBuilder<List<UserSession>>(
              future: _sessionsFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Text('Unable to load sessions: ${snapshot.error}');
                }
                final sessions = snapshot.data ?? const [];
                if (sessions.isEmpty) {
                  return const Text('No active sessions found.');
                }
                return Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Column(
                    children: sessions.map((session) {
                      return ListTile(
                        leading: const Icon(Icons.devices_outlined),
                        title: Text(session.deviceName),
                        subtitle: Text(session.lastActive),
                        trailing: session.isCurrent == true
                            ? const Text('This device')
                            : session.isCurrent == false
                                ? IconButton(
                                tooltip: 'Sign out this device',
                                onPressed: () => _revokeSession(session),
                                icon: const Icon(Icons.logout),
                              )
                                : const Tooltip(
                                    message: 'The server does not identify the current device.',
                                    child: Icon(Icons.info_outline),
                                  ),
                      );
                    }).toList(),
                  ),
                );
              },
            ),
          ],
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: OutlinedButton.icon(
              onPressed: () => _logout(context),
              icon: const Icon(Icons.logout, color: Colors.red),
              label: const Text(
                'Logout',
                style: TextStyle(color: Colors.red, fontWeight: FontWeight.w600),
              ),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Colors.red),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileDetailRow extends StatelessWidget {
  final String label;
  final String value;

  const _ProfileDetailRow({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 11),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 105,
            child: Text(
              label,
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 12,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: const TextStyle(
                color: Color(0xFF0F172A),
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
