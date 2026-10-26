import 'package:flutter/material.dart';

import '../services/staff_api_service.dart';
import 'report_page.dart';

class DashboardPage extends StatelessWidget {
  final StaffApiService? service;

  const DashboardPage({super.key, this.service});

  @override
  Widget build(BuildContext context) {
    if (service == null) {
      return const Center(
        child: Text('Sign in to load dashboard data.'),
      );
    }
    return ReportPage(service: service, showReportCatalogue: false);
  }
}
