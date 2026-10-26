import 'package:flutter/material.dart';

import '../services/customer_app_service.dart';
import '../services/staff_api_service.dart';

class NotificationsPage extends StatefulWidget {
  final CustomerAppService? service;
  final StaffApiService? staffService;

  const NotificationsPage({super.key, this.service, this.staffService});

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  late Future<List<Map<String, dynamic>>> _notificationsFuture;

  @override
  void initState() {
    super.initState();
    _notificationsFuture = _loadNotifications();
  }

  Future<List<Map<String, dynamic>>> _loadNotifications() async {
    final service = widget.service;
    final staffService = widget.staffService;
    if (service == null && staffService == null) return const [];
    final response = staffService != null
        ? await staffService.getInAppNotifications(pageSize: 100)
        : await service!.getNotifications(page: 1, pageSize: 100);
    final data = response['data'];
    final items = data is List
        ? data
        : data is Map<String, dynamic>
        ? data['notifications'] ?? data['items'] ?? data['data']
        : response['notifications'];
    return items is List
        ? items.whereType<Map<String, dynamic>>().toList()
        : const [];
  }

  bool _isRead(Map<String, dynamic> notification) =>
      notification['isRead'] == true ||
      notification['read'] == true ||
      notification['readAt'] != null;

  Future<void> _markRead(Map<String, dynamic> notification) async {
    final id = (notification['id'] ?? notification['_id'] ?? '').toString();
    if (id.isEmpty ||
        (widget.service == null && widget.staffService == null) ||
        _isRead(notification)) {
      return;
    }
    try {
      if (widget.staffService != null) {
        await widget.staffService!.markInAppNotificationRead(id);
      } else {
        await widget.service!.markNotificationRead(id);
      }
      if (mounted) {
        setState(() => _notificationsFuture = _loadNotifications());
      }
    } catch (error) {
      _showError(error);
    }
  }

  Future<void> _markAllRead() async {
    if (widget.service == null && widget.staffService == null) return;
    try {
      if (widget.staffService != null) {
        await widget.staffService!.markAllInAppNotificationsRead();
      } else {
        await widget.service!.markAllNotificationsRead();
      }
      if (mounted) {
        setState(() => _notificationsFuture = _loadNotifications());
      }
    } catch (error) {
      _showError(error);
    }
  }

  void _showError(Object error) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Notification update failed: $error')),
    );
  }

  static const Color _background = Color(0xFFF8F9FC);
  static const Color _border = Color(0xFFE7E9EF);

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: _background,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth >= 700;

          return SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(
              isWide ? 20 : 16,
              18,
              isWide ? 20 : 16,
              24,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Notifications',
                        style: TextStyle(
                          color: Color(0xFF17212B),
                          fontSize: 21,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    OutlinedButton.icon(
                      onPressed:
                          widget.service == null && widget.staffService == null
                          ? null
                          : _markAllRead,
                      icon: const Icon(Icons.done_all_rounded, size: 16),
                      label: const Text('Mark all read'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF374151),
                        backgroundColor: Colors.white,
                        side: const BorderSide(color: _border),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 11,
                          vertical: 10,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(9),
                        ),
                        textStyle: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 17),
                FutureBuilder<List<Map<String, dynamic>>>(
                  future: _notificationsFuture,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (snapshot.hasError) {
                      return Center(
                        child: Column(
                          children: [
                            Text(
                              'Unable to load notifications: ${snapshot.error}',
                            ),
                            TextButton(
                              onPressed: () => setState(
                                () =>
                                    _notificationsFuture = _loadNotifications(),
                              ),
                              child: const Text('Retry'),
                            ),
                          ],
                        ),
                      );
                    }
                    final notifications = snapshot.data ?? const [];
                    if (notifications.isEmpty) {
                      return Container(
                        width: double.infinity,
                        constraints: const BoxConstraints(minHeight: 90),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 18,
                          vertical: 24,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          border: Border.all(color: _border),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        alignment: Alignment.center,
                        child: const Text(
                          'No notifications yet.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Color(0xFF718096),
                            fontSize: 12,
                          ),
                        ),
                      );
                    }
                    return Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border: Border.all(color: _border),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Column(
                        children: notifications
                            .map(_buildNotification)
                            .toList(),
                      ),
                    );
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildNotification(Map<String, dynamic> notification) {
    final isRead = _isRead(notification);
    final title = (notification['title'] ?? 'Notification').toString();
    final message =
        (notification['message'] ??
                notification['body'] ??
                notification['description'] ??
                '')
            .toString();
    final createdAt =
        (notification['createdAt'] ?? notification['sentAt'] ?? '').toString();
    return InkWell(
      onTap: () => _markRead(notification),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isRead ? Colors.white : const Color(0xFFF3FAF8),
          border: const Border(bottom: BorderSide(color: _border)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              isRead ? Icons.notifications_none : Icons.notifications_active,
              size: 19,
              color: isRead ? const Color(0xFF718096) : const Color(0xFF0D9488),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  if (message.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(message, style: const TextStyle(fontSize: 12)),
                  ],
                  if (createdAt.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(
                      createdAt,
                      style: const TextStyle(
                        fontSize: 10,
                        color: Color(0xFF718096),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (!isRead)
              const Padding(
                padding: EdgeInsets.only(left: 8, top: 5),
                child: Icon(Icons.circle, size: 8, color: Color(0xFF0D9488)),
              ),
          ],
        ),
      ),
    );
  }
}
