import 'package:flutter/material.dart';

import '../widgets/Sidebar_Widget.dart';
import '../widgets/navbar.dart';
import 'notifications_page.dart';
import 'promotion_page.dart';
import 'product_page.dart';
import 'report_page.dart';
import 'profile_page.dart';
import 'sales_page.dart';
import 'customer_page.dart';
import 'customer_dashboard_page.dart';
import 'inventory_page.dart';
import 'supplier_page.dart';
import '../services/auth_service.dart';
import '../services/customer_app_service.dart';
import '../services/staff_api_service.dart';
import 'home_page.dart';

class AppLayout extends StatefulWidget {
  final String initialRoute;
  final bool customerMode;
  final CustomerUser? customerUser;
  final String? customerAccessToken;
  final String? customerRefreshToken;
  final bool persistCustomerSession;
  final String? staffAccessToken;
  final StaffUser? staffUser;

  const AppLayout({
    super.key,
    this.initialRoute = 'Dashboard',
    this.customerMode = false,
    this.customerUser,
    this.customerAccessToken,
    this.customerRefreshToken,
    this.persistCustomerSession = false,
    this.staffAccessToken,
    this.staffUser,
  });

  @override
  State<AppLayout> createState() => _AppLayoutState();
}

class _AppLayoutState extends State<AppLayout> {
  late String selectedRoute;
  late String previousRoute;
  late String _routeBeforeNotifications;
  CustomerAppService? _customerAppService;
  StaffApiService? _staffApiService;
  String? _customerAccessToken;
  String? _customerRefreshToken;

  @override
  void initState() {
    super.initState();
    selectedRoute = widget.initialRoute;
    previousRoute = widget.initialRoute;
    _routeBeforeNotifications = widget.initialRoute;
    final accessToken = widget.customerAccessToken;
    _customerAccessToken = accessToken;
    _customerRefreshToken = widget.customerRefreshToken;
    if (widget.customerMode && accessToken != null && accessToken.isNotEmpty) {
      _customerAppService = CustomerAppService(
        accessToken: accessToken,
        refreshAccessToken: _refreshCustomerSession,
      );
    }
    final staffToken = widget.staffAccessToken;
    if (!widget.customerMode && staffToken != null && staffToken.isNotEmpty) {
      _staffApiService = StaffApiService(accessToken: staffToken);
    }
  }

  @override
  void dispose() {
    _customerAppService?.close();
    _staffApiService?.close();
    super.dispose();
  }

  void _selectRoute(String route) {
    if (route == 'Customer Sign Out') {
      _signOutCustomer();
      return;
    }
    if (route == 'Staff Sign Out') {
      _signOutStaff();
      return;
    }
    setState(() {
      if (route != 'Profile') {
        previousRoute = route;
      }
      selectedRoute = route;
    });
  }

  Future<void> _signOutCustomer() async {
    try {
      final refreshToken = _customerRefreshToken;
      if (refreshToken != null && refreshToken.isNotEmpty) {
        await HttpAuthRepository(
          accessToken: _customerAccessToken,
        ).logout(refreshToken: refreshToken);
      }
    } catch (_) {
      // A network failure should not keep the customer in a signed-in screen.
    }
    await CustomerSessionStore().clear();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const HomePage()),
      (route) => false,
    );
  }

  void _signOutStaff() {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const HomePage()),
      (route) => false,
    );
  }

  Future<void> _refreshCustomerSession() async {
    final refreshToken = _customerRefreshToken;
    if (refreshToken == null || refreshToken.isEmpty) {
      await _signOutCustomer();
      throw Exception('Customer session has expired. Please sign in again.');
    }

    try {
      final response = await HttpAuthRepository(
        accessToken: _customerAccessToken,
      ).refreshToken(refreshToken: refreshToken);
      _customerAccessToken = response.tokens.accessToken;
      _customerRefreshToken = response.tokens.refreshToken;
      _customerAppService?.accessToken = response.tokens.accessToken;
      if (widget.persistCustomerSession) {
        await CustomerSessionStore().save(response);
      }
    } catch (_) {
      await _signOutCustomer();
      throw Exception('Customer session has expired. Please sign in again.');
    }
  }

  void _toggleProfile() {
    setState(() {
      if (selectedRoute == 'Profile') {
        selectedRoute = previousRoute;
      } else {
        previousRoute = selectedRoute;
        selectedRoute = 'Profile';
      }
    });
  }

  void _toggleNotifications() {
    setState(() {
      if (selectedRoute == 'Notification') {
        selectedRoute = _routeBeforeNotifications;
      } else {
        _routeBeforeNotifications = selectedRoute;
        selectedRoute = 'Notification';
      }
    });
  }

  Widget _buildPage() {
    switch (selectedRoute) {
      case 'Products':
        if (!widget.customerMode &&
            widget.staffUser?.permissions.contains('products:view') != true) {
          return const _ComingSoonPage(
            title: 'products:view permission required',
          );
        }
        return ProductsPage(
          service: _customerAppService,
          staffService: _staffApiService,
        );
      case 'Promotion':
        if (!widget.customerMode &&
            widget.staffUser?.permissions.contains('sales:view') != true) {
          return const _ComingSoonPage(title: 'sales:view permission required');
        }
        return PromotionPage(
          onBack: () => _selectRoute(
            widget.customerMode ? 'Customer Dashboard' : 'Dashboard',
          ),
          service: _customerAppService,
          staffService: _staffApiService,
        );
      case 'Notification':
        return NotificationsPage(
          service: _customerAppService,
          staffService: _staffApiService,
        );
      case 'Report':
        if (widget.staffUser?.permissions.contains('reports:view') == true) {
          return ReportPage(service: _staffApiService);
        }
        return const _ComingSoonPage(title: 'reports:view permission required');
      case 'Sales':
        if (widget.staffUser?.permissions.contains('sales:view') == true) {
          return SalesPage(service: _staffApiService);
        }
        return const _ComingSoonPage(title: 'sales:view permission required');
      case 'Customer':
        if (widget.staffUser?.permissions.contains('customers:view') == true) {
          return CustomersPage(service: _staffApiService);
        }
        return const _ComingSoonPage(
          title: 'customers:view permission required',
        );
      case 'Inventory':
        if (widget.staffUser?.permissions.contains('inventory:view') == true &&
            _staffApiService != null) {
          return InventoryPage(service: _staffApiService!);
        }
        return const _ComingSoonPage(
          title: 'inventory:view permission required',
        );
      case 'Supplier':
        if (widget.staffUser?.roles.contains('SUPPLIER') == true &&
            widget.staffUser?.permissions.contains('supplier-portal:access') ==
                true &&
            _staffApiService != null) {
          return SupplierDashboardPage(service: _staffApiService!);
        }
        if (widget.staffUser?.permissions.contains('suppliers:view') == true &&
            _staffApiService != null) {
          return SuppliersPage(service: _staffApiService!);
        }
        return const _ComingSoonPage(
          title: 'suppliers:view permission required',
        );
      case 'Customer Dashboard':
        if (widget.customerUser != null && _customerAppService != null) {
          return CustomerDashboardPage(
            customerUser: widget.customerUser!,
            service: _customerAppService!,
          );
        }
        return const _ComingSoonPage(title: 'Customer sign-in required');
      case 'Dashboard':
        if (widget.staffUser?.permissions.contains('reports:view') == true) {
          return ReportPage(
            service: _staffApiService,
            showReportCatalogue: false,
          );
        }
        return const _ComingSoonPage(title: 'reports:view permission required');
      case 'Profile':
        return ProfilePage(
          showAppBar: false,
          service: _customerAppService,
          authRepository: widget.customerMode
              ? HttpAuthRepository(accessToken: _customerAccessToken)
              : null,
          onLogout: widget.customerMode ? _signOutCustomer : null,
        );
      default:
        return _ComingSoonPage(title: selectedRoute);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FC),
      appBar: TechNovaNavbar(
        title: selectedRoute == 'Notification'
            ? 'Notifications'
            : selectedRoute,
        onNotificationTap: _toggleNotifications,
        onProfileTap: _toggleProfile,
        showAccountActions: true,
      ),
      drawer: SidebarWidget(
        currentRoute: selectedRoute,
        onItemSelected: _selectRoute,
        customerMode: widget.customerMode,
        staffPermissions: widget.staffUser?.permissions.toSet(),
        staffRoles: widget.staffUser?.roles.toSet(),
      ),
      body: _buildPage(),
    );
  }
}

class _ComingSoonPage extends StatelessWidget {
  final String title;

  const _ComingSoonPage({required this.title});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        '$title page',
        style: const TextStyle(
          color: Color(0xFF0F172A),
          fontSize: 22,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
