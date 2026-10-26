import 'package:flutter/material.dart';

class SidebarWidget extends StatelessWidget {
  final String currentRoute;
  final ValueChanged<String>? onItemSelected;
  final bool customerMode;
  final Set<String>? staffPermissions;
  final Set<String>? staffRoles;

  const SidebarWidget({
    super.key,
    this.currentRoute = 'Dashboard',
    this.onItemSelected,
    this.customerMode = false,
    this.staffPermissions,
    this.staffRoles,
  });

  @override
  Widget build(BuildContext context) {
    // TechNova theme colors (Teal tone)
    final primaryColor = const Color(0xFF0D9488);
    final activeColor = const Color(0xFF115E59);

    // Oyage list eka
    final List<Map<String, dynamic>> staffMenuItems = [
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
    final visibleStaffMenuItems = staffMenuItems.where((item) {
      final title = item['title'];
      final requiredPermission = title == 'Dashboard' || title == 'Report'
          ? 'reports:view'
          : title == 'Products'
          ? 'products:view'
          : title == 'Promotion'
          ? 'sales:view'
          : title == 'Sales'
          ? 'sales:view'
          : title == 'Inventory'
          ? 'inventory:view'
          : title == 'Supplier'
          ? 'suppliers:view'
          : title == 'Customer'
          ? 'customers:view'
          : null;
      final isSupplierPortalUser =
          title == 'Supplier' && staffRoles?.contains('SUPPLIER') == true;
      return isSupplierPortalUser ||
          requiredPermission == null ||
          staffPermissions == null ||
          staffPermissions!.contains(requiredPermission);
    }).toList();
    final menuItems = customerMode
        ? [
            {'title': 'Customer', 'icon': Icons.people_outline},
            {'title': 'Products', 'icon': Icons.inventory_2_outlined},
            {'title': 'Promotion', 'icon': Icons.local_offer_outlined},
          ]
        : visibleStaffMenuItems;

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
              if (item['title'] == 'Customer') {
                final customerSectionSelected =
                    currentRoute == 'Customer' ||
                    currentRoute == 'Customer Dashboard';
                return Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12.0,
                    vertical: 4.0,
                  ),
                  child: ExpansionTile(
                    key: PageStorageKey(
                      'customer-menu-$customerSectionSelected',
                    ),
                    initiallyExpanded: customerSectionSelected,
                    leading: Icon(
                      Icons.people_outline,
                      color: customerSectionSelected
                          ? activeColor
                          : primaryColor,
                    ),
                    title: Text(
                      'Customer',
                      style: TextStyle(
                        color: customerSectionSelected
                            ? activeColor
                            : primaryColor,
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
                    tilePadding: const EdgeInsets.symmetric(horizontal: 12),
                    childrenPadding: const EdgeInsets.only(left: 14, bottom: 6),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    collapsedShape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    children: [
                      if (customerMode)
                        _customerMenuItem(
                          title: 'Customer Dashboard',
                          icon: Icons.loyalty_outlined,
                          selected: currentRoute == 'Customer Dashboard',
                          onTap: () {
                            Navigator.pop(context);
                            onItemSelected?.call('Customer Dashboard');
                          },
                        ),
                      if (!customerMode)
                        _customerMenuItem(
                          title: 'Customer List',
                          icon: Icons.people_alt_outlined,
                          selected: currentRoute == 'Customer',
                          onTap: () {
                            Navigator.pop(context);
                            onItemSelected?.call('Customer');
                          },
                        ),
                      if (customerMode)
                        _customerMenuItem(
                          title: 'Sign out',
                          icon: Icons.logout,
                          selected: false,
                          onTap: () {
                            Navigator.pop(context);
                            onItemSelected?.call('Customer Sign Out');
                          },
                        ),
                    ],
                  ),
                );
              }

              bool isSelected = currentRoute == item['title'];
              return Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12.0,
                  vertical: 4.0,
                ),
                child: Container(
                  decoration: BoxDecoration(
                    color: isSelected ? activeColor : Colors.white,
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(
                      color: isSelected
                          ? activeColor
                          : primaryColor.withValues(alpha: 0.3),
                      width: 1.5,
                    ),
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: activeColor.withValues(alpha: 0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
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
            }),
            if (!customerMode)
              ListTile(
                leading: const Icon(Icons.logout, color: Color(0xFF0D9488)),
                title: const Text('Sign out'),
                onTap: () {
                  Navigator.pop(context);
                  onItemSelected?.call('Staff Sign Out');
                },
              ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _customerMenuItem({
    required String title,
    required IconData icon,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return ListTile(
      dense: true,
      visualDensity: const VisualDensity(vertical: -1),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      selected: selected,
      selectedTileColor: const Color(0xFFE7F3EC),
      leading: Icon(
        icon,
        size: 19,
        color: selected ? const Color(0xFF115E59) : const Color(0xFF0D9488),
      ),
      title: Text(
        title,
        style: TextStyle(
          color: selected ? const Color(0xFF115E59) : const Color(0xFF0D9488),
          fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
          fontSize: 13,
        ),
      ),
      onTap: onTap,
    );
  }
}
