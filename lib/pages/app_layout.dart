import 'package:flutter/material.dart';

import '../widgets/Sidebar_Widget.dart';
import '../widgets/navbar.dart';
import 'dashboard_page.dart';
import 'product_page.dart';
import 'profile_page.dart';

class AppLayout extends StatefulWidget {
  const AppLayout({super.key});

  @override
  State<AppLayout> createState() => _AppLayoutState();
}

class _AppLayoutState extends State<AppLayout> {
  String selectedRoute = 'Dashboard';
  String previousRoute = 'Dashboard';

  void _selectRoute(String route) {
    setState(() {
      if (route != 'Profile') {
        previousRoute = route;
      }
      selectedRoute = route;
    });
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

  Widget _buildPage() {
    switch (selectedRoute) {
      case 'Products':
        return const ProductsPage();
      case 'Dashboard':
        return const DashboardPage();
      case 'Profile':
        return const ProfilePage(showAppBar: false);
      default:
        return _ComingSoonPage(title: selectedRoute);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FC),
      appBar: TechNovaNavbar(
        title: selectedRoute,
        onProfileTap: _toggleProfile,
      ),
      drawer: SidebarWidget(
        currentRoute: selectedRoute,
        onItemSelected: _selectRoute,
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