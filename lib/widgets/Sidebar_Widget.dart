import 'package:flutter/material.dart';

class SidebarWidget extends StatelessWidget {
  final String currentRoute;
  final ValueChanged<String>? onItemSelected;

  const SidebarWidget({
    Key? key,
    this.currentRoute = 'Dashboard',
    this.onItemSelected,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // TechNova theme colors (Teal tone)
    final primaryColor = const Color(0xFF0D9488);
    final activeColor = const Color(0xFF115E59);

    // Oyage list eka
    final List<Map<String, dynamic>> menuItems = [
      {'title': 'Dashboard', 'icon': Icons.dashboard_outlined},
      {'title': 'Products', 'icon': Icons.inventory_2_outlined},
      {'title': 'Promotion', 'icon': Icons.local_offer_outlined},
      {'title': 'Notification', 'icon': Icons.notifications_outlined},
      {'title': 'Inventory', 'icon': Icons.warehouse_outlined},
      {'title': 'Report', 'icon': Icons.bar_chart_outlined},
      {'title': 'Sales', 'icon': Icons.point_of_sale_outlined},
      {'title': 'Customer', 'icon': Icons.people_outline},
      {'title': 'Supplier', 'icon': Icons.local_shipping_outlined},
    ];

    return Drawer(
      child: Container(
        color: Colors.white,
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            // Logo saha Header eka
            DrawerHeader(
              margin: EdgeInsets.zero,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border(
                  bottom: BorderSide(color: Colors.grey.shade200, width: 1),
                ),
              ),
              child: Center(
                child: Image.asset(
                  'assets/images/technova-logo-transparent.png',
                  width: 280,
                  height: 199,
                ),
              ),
            ),
            const SizedBox(height: 10),
            // Menu Items loop karanawa
            ...menuItems.map((item) {
              bool isSelected = currentRoute == item['title'];
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 4.0),
                child: Container(
                  decoration: BoxDecoration(
                    color: isSelected ? activeColor : Colors.white,
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(
                      color: isSelected ? activeColor : primaryColor.withOpacity(0.3),
                      width: 1.5,
                    ),
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: activeColor.withOpacity(0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            )
                          ]
                        : [],
                  ),
                  child: ListTile(
                    leading: Icon(
                      item['icon'],
                      color: isSelected ? Colors.white : primaryColor,
                    ),
                    title: Text(
                      item['title'],
                      style: TextStyle(
                        color: isSelected ? Colors.white : primaryColor,
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
                    onTap: () {
                      Navigator.pop(context);
                      onItemSelected?.call(item['title'] as String);
                    },
                  ),
                ),
              );
            }).toList(),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}