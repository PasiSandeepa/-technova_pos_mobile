import 'package:flutter/material.dart';

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  // =========================
  // COLORS
  // =========================

  static const Color darkGreen = Color(0xFF064E46);
  static const Color green = Color(0xFF0D9488);
  static const Color lightGreen = Color(0xFFE7F7F5);
  static const Color lightBg = Color(0xFFF8F9FC);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: lightBg,

      // =========================
      // BODY
      // =========================

      body: SafeArea(
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(
              child: _buildWelcome(),
            ),

            SliverToBoxAdapter(
              child: _buildSummaryCards(),
            ),

            SliverToBoxAdapter(
              child: _buildSalesChart(),
            ),

            SliverToBoxAdapter(
              child: _buildOverallInformation(),
            ),

            SliverToBoxAdapter(
              child: _buildCustomerOverview(),
            ),

            SliverToBoxAdapter(
              child: _buildTopSellingProducts(),
            ),

            SliverToBoxAdapter(
              child: _buildLowStockProducts(),
            ),

            SliverToBoxAdapter(
              child: _buildRecentSales(),
            ),

            SliverToBoxAdapter(
              child: _buildTopCustomers(),
            ),

            SliverToBoxAdapter(
              child: _buildTopCategories(),
            ),

            SliverToBoxAdapter(
              child: _buildOrderStatistics(),
            ),

            const SliverToBoxAdapter(
              child: SizedBox(height: 20),
            ),
          ],
        ),
      ),
    );
  }

  // =========================================================
  // WELCOME
  // =========================================================

  Widget _buildWelcome() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 20, 18, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Dashboard',
            style: TextStyle(
              fontSize: 25,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),

          const SizedBox(height: 5),

          Text(
            'Here is your business overview today.',
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  // =========================================================
  // SUMMARY CARDS
  // =========================================================

  Widget _buildSummaryCards() {
    final cards = [
      _SummaryData(
        title: 'Total Sales',
        value: 'Rs. 8,458,798',
        percentage: '+25%',
        icon: Icons.trending_up,
        positive: true,
      ),
      _SummaryData(
        title: 'Total Sales Return',
        value: 'Rs. 488,798',
        percentage: '-18%',
        icon: Icons.keyboard_return,
        positive: false,
      ),
      _SummaryData(
        title: 'Total Purchase',
        value: 'Rs. 8,980,097',
        percentage: '+10%',
        icon: Icons.shopping_cart_outlined,
        positive: true,
      ),
      _SummaryData(
        title: 'Purchase Return',
        value: 'Rs. 78,458,798',
        percentage: '-20%',
        icon: Icons.assignment_return_outlined,
        positive: false,
      ),
    ];

    return SizedBox(
      height: 142,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 18),
        scrollDirection: Axis.horizontal,
        itemCount: cards.length,
        itemBuilder: (context, index) {
          final item = cards[index];

          return Container(
            width: 190,
            margin: const EdgeInsets.only(right: 12),
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Colors.grey.shade100,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.035),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: lightGreen,
                        borderRadius: BorderRadius.circular(9),
                      ),
                      child: Icon(
                        item.icon,
                        color: green,
                        size: 17,
                      ),
                    ),

                    const Spacer(),

                    Icon(
                      item.positive
                          ? Icons.arrow_upward
                          : Icons.arrow_downward,
                      size: 14,
                      color: item.positive
                          ? Colors.green
                          : Colors.red,
                    ),
                  ],
                ),

                const SizedBox(height: 10),

                Text(
                  item.title,
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey.shade600,
                  ),
                ),

                const SizedBox(height: 4),

                Text(
                  item.value,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 3),

                Text(
                  '${item.percentage} vs last month',
                  style: TextStyle(
                    fontSize: 9,
                    color: item.positive
                        ? Colors.green
                        : Colors.red,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // =========================================================
  // SALES CHART
  // =========================================================

  Widget _buildSalesChart() {
    return _sectionCard(
      title: 'Sales & Purchase',
      icon: Icons.bar_chart_rounded,
      child: Column(
        children: [
          Row(
            children: [
              _smallStatistic(
                'Total Purchase',
                '49K',
              ),
              const SizedBox(width: 25),
              _smallStatistic(
                'Total Sales',
                '38K',
              ),
            ],
          ),

          const SizedBox(height: 22),

          SizedBox(
            height: 190,
            child: CustomPaint(
              painter: SalesChartPainter(),
              child: Container(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _smallStatistic(
    String title,
    String value,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 11,
            color: Colors.grey.shade600,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          value,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 17,
          ),
        ),
      ],
    );
  }

  // =========================================================
  // OVERALL INFORMATION
  // =========================================================

  Widget _buildOverallInformation() {
    return _sectionCard(
      title: 'Overall Information',
      icon: Icons.insights_outlined,
      child: Row(
        children: [
          Expanded(
            child: _infoBox(
              Icons.people_outline,
              'Suppliers',
              '6,987',
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _infoBox(
              Icons.person_outline,
              'Customers',
              '4,895',
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _infoBox(
              Icons.shopping_cart_outlined,
              'Orders',
              '487',
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoBox(
    IconData icon,
    String title,
    String value,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(
        vertical: 15,
        horizontal: 5,
      ),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            size: 21,
            color: green,
          ),

          const SizedBox(height: 8),

          Text(
            value,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 3),

          Text(
            title,
            style: TextStyle(
              fontSize: 9,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  // =========================================================
  // CUSTOMER OVERVIEW
  // =========================================================

  Widget _buildCustomerOverview() {
    return _sectionCard(
      title: 'Customers Overview',
      icon: Icons.people_alt_outlined,
      child: Row(
        children: [
          SizedBox(
            width: 130,
            height: 130,
            child: CustomPaint(
              painter: DonutChartPainter(),
            ),
          ),

          const SizedBox(width: 18),

          Expanded(
            child: Column(
              children: [
                _customerLegend(
                  'First Time',
                  '5.5K',
                  green,
                ),
                const SizedBox(height: 18),
                _customerLegend(
                  'Returning',
                  '3.5K',
                  Colors.teal.shade200,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _customerLegend(
    String title,
    String value,
    Color color,
  ) {
    return Row(
      children: [
        Container(
          width: 9,
          height: 9,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),

        const SizedBox(width: 8),

        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 11,
            ),
          ),
        ),

        Text(
          value,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  // =========================================================
  // TOP SELLING PRODUCTS
  // =========================================================

  Widget _buildTopSellingProducts() {
    final products = [
      ['Charger Cable - Lightning', 'Rs. 247', '25%'],
      ['Yeast Full Type Earphone', 'Rs. 525', '20%'],
      ['Apple Airpods 2', 'Rs. 4,500', '18%'],
      ['Vacuum Cleaner', 'Rs. 12,500', '-12%'],
      ['Samsung Galaxy S21 FE 5G', 'Rs. 89,500', '15%'],
    ];

    return _sectionCard(
      title: 'Top Selling Products',
      icon: Icons.star_outline,
      child: Column(
        children: products.map((product) {
          return _productRow(
            product[0],
            product[1],
            product[2],
            false,
          );
        }).toList(),
      ),
    );
  }

  // =========================================================
  // LOW STOCK
  // =========================================================

  Widget _buildLowStockProducts() {
    final products = [
      ['Vacuum Cleaner Robot', '2 pcs'],
      ['HDMI Cable', '08 pcs'],
      ['KitchenAid Stand Mixer', '08 pcs'],
      ['Levi’s Trucker Jacket', '12 pcs'],
      ['Lay’s Classic', '10 pcs'],
    ];

    return _sectionCard(
      title: 'Low Stock Products',
      icon: Icons.warning_amber_rounded,
      child: Column(
        children: products.map((product) {
          return _productRow(
            product[0],
            'Stock',
            product[1],
            true,
          );
        }).toList(),
      ),
    );
  }

  Widget _productRow(
    String name,
    String price,
    String percentage,
    bool lowStock,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(
        vertical: 11,
      ),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: Colors.grey.shade100,
          ),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(9),
            ),
            child: Icon(
              lowStock
                  ? Icons.inventory_2_outlined
                  : Icons.shopping_bag_outlined,
              color: lowStock
                  ? Colors.orange
                  : green,
              size: 20,
            ),
          ),

          const SizedBox(width: 10),

          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),

                const SizedBox(height: 4),

                Text(
                  price,
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),

          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 8,
              vertical: 5,
            ),
            decoration: BoxDecoration(
              color: lowStock
                  ? Colors.red.shade50
                  : Colors.green.shade50,
              borderRadius: BorderRadius.circular(7),
            ),
            child: Text(
              percentage,
              style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.bold,
                color: lowStock
                    ? Colors.red
                    : Colors.green,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // =========================================================
  // RECENT SALES
  // =========================================================

  Widget _buildRecentSales() {
    final sales = [
      ['Apple Watch Series 9', 'Rs. 65,000', 'Today'],
      ['Gold Bracelet', 'Rs. 15,250', 'Today'],
      ['PEYTI Rambler Tumbler', 'Rs. 12,500', '12 Sep'],
      ['Omo Genius Starter Kit', 'Rs. 4,850', '11 Sep'],
    ];

    return _sectionCard(
      title: 'Recent Sales',
      icon: Icons.receipt_long_outlined,
      child: Column(
        children: sales.map((sale) {
          return _saleRow(
            sale[0],
            sale[1],
            sale[2],
          );
        }).toList(),
      ),
    );
  }

  Widget _saleRow(
    String name,
    String price,
    String date,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(
        vertical: 11,
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: lightGreen,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.shopping_bag,
              color: green,
              size: 20,
            ),
          ),

          const SizedBox(width: 10),

          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),

                const SizedBox(height: 4),

                Text(
                  date,
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),

          Text(
            price,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  // =========================================================
  // TOP CUSTOMERS
  // =========================================================

  Widget _buildTopCustomers() {
    final customers = [
      ['Carlos Curran', '24 Orders', 'Rs. 8,965'],
      ['Stan Gaunter', '22 Orders', 'Rs. 6,985'],
      ['Richard Wilson', '14 Orders', 'Rs. 5,366'],
      ['Mary Britton', '09 Orders', 'Rs. 4,569'],
      ['Annie Tremblay', '14 Orders', 'Rs. 5,698'],
    ];

    return _sectionCard(
      title: 'Top Customers',
      icon: Icons.person_outline,
      child: Column(
        children: customers.map((customer) {
          return Container(
            padding: const EdgeInsets.symmetric(
              vertical: 10,
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 19,
                  backgroundColor: lightGreen,
                  child: Text(
                    customer[0][0],
                    style: const TextStyle(
                      color: darkGreen,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),

                const SizedBox(width: 10),

                Expanded(
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      Text(
                        customer[0],
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        customer[1],
                        style: TextStyle(
                          fontSize: 9,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),

                Text(
                  customer[2],
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  // =========================================================
  // TOP CATEGORIES
  // =========================================================

  Widget _buildTopCategories() {
    return _sectionCard(
      title: 'Top Categories',
      icon: Icons.category_outlined,
      child: Row(
        children: [
          SizedBox(
            width: 145,
            height: 145,
            child: CustomPaint(
              painter: CategoryDonutPainter(),
            ),
          ),

          const SizedBox(width: 15),

          Expanded(
            child: Column(
              children: [
                _categoryItem(
                  'Electronics',
                  '698 Sales',
                  Colors.teal,
                ),
                _categoryItem(
                  'Sports',
                  '545 Sales',
                  Colors.orange,
                ),
                _categoryItem(
                  'Fashion',
                  '456 Sales',
                  Colors.pink,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _categoryItem(
    String title,
    String sales,
    Color color,
  ) {
    return Padding(
      padding: const EdgeInsets.only(
        bottom: 14,
      ),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),

          const SizedBox(width: 7),

          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 11,
              ),
            ),
          ),

          Text(
            sales,
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  // =========================================================
  // ORDER STATISTICS
  // =========================================================

  Widget _buildOrderStatistics() {
    return _sectionCard(
      title: 'Order Statistics',
      icon: Icons.calendar_month_outlined,
      child: Column(
        children: [
          SizedBox(
            height: 190,
            child: CustomPaint(
              painter: OrderStatisticsPainter(),
              child: Container(),
            ),
          ),

          const SizedBox(height: 10),

          Row(
            mainAxisAlignment:
                MainAxisAlignment.spaceAround,
            children: [
              _orderLegend(
                'Orders',
                green,
              ),
              _orderLegend(
                'Completed',
                Colors.teal.shade200,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _orderLegend(
    String title,
    Color color,
  ) {
    return Row(
      children: [
        Container(
          width: 9,
          height: 9,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          title,
          style: const TextStyle(
            fontSize: 10,
          ),
        ),
      ],
    );
  }

  // =========================================================
  // COMMON SECTION CARD
  // =========================================================

  Widget _sectionCard({
    required String title,
    required IconData icon,
    required Widget child,
  }) {
    return Container(
      margin: const EdgeInsets.fromLTRB(
        18,
        12,
        18,
        4,
      ),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(17),
        border: Border.all(
          color: Colors.grey.shade100,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.025),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: lightGreen,
                  borderRadius:
                      BorderRadius.circular(8),
                ),
                child: Icon(
                  icon,
                  color: green,
                  size: 17,
                ),
              ),

              const SizedBox(width: 9),

              Text(
                title,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const Spacer(),

              Text(
                'View All',
                style: TextStyle(
                  fontSize: 10,
                  color: green,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          child,
        ],
      ),
    );
  }
}

// =========================================================
// DATA CLASS
// =========================================================

class _SummaryData {
  final String title;
  final String value;
  final String percentage;
  final IconData icon;
  final bool positive;

  const _SummaryData({
    required this.title,
    required this.value,
    required this.percentage,
    required this.icon,
    required this.positive,
  });
}

// =========================================================
// SALES CHART PAINTER
// =========================================================

class SalesChartPainter extends CustomPainter {
  @override
  void paint(
    Canvas canvas,
    Size size,
  ) {
    final paint = Paint()
      ..style = PaintingStyle.fill;

    final months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];

    final sales = [
      65,
      32,
      25,
      65,
      38,
      63,
      25,
      45,
      64,
      48,
      42,
      30,
    ];

    final purchase = [
      45,
      25,
      18,
      46,
      26,
      48,
      18,
      35,
      46,
      32,
      30,
      25,
    ];

    final chartHeight = size.height - 28;
    final barWidth = size.width / 16;

    for (int i = 0; i < months.length; i++) {
      final x = i * (size.width / 12) + 5;

      // Purchase
      paint.color = const Color(0xFF9AE6DF);

      final purchaseHeight =
          chartHeight * purchase[i] / 70;

      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(
            x,
            chartHeight - purchaseHeight,
            barWidth,
            purchaseHeight,
          ),
          const Radius.circular(5),
        ),
        paint,
      );

      // Sales
      paint.color = const Color(0xFF0D9488);

      final salesHeight =
          chartHeight * sales[i] / 70;

      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(
            x + barWidth * .45,
            chartHeight - salesHeight,
            barWidth,
            salesHeight,
          ),
          const Radius.circular(5),
        ),
        paint,
      );

      final textPainter = TextPainter(
        text: TextSpan(
          text: months[i],
          style: const TextStyle(
            fontSize: 8,
            color: Colors.grey,
          ),
        ),
        textDirection: TextDirection.ltr,
      );

      textPainter.layout();

      textPainter.paint(
        canvas,
        Offset(
          x,
          chartHeight + 7,
        ),
      );
    }
  }

  @override
  bool shouldRepaint(
    covariant CustomPainter oldDelegate,
  ) {
    return false;
  }
}

// =========================================================
// CUSTOMER DONUT
// =========================================================

class DonutChartPainter extends CustomPainter {
  @override
  void paint(
    Canvas canvas,
    Size size,
  ) {
    final center = Offset(
      size.width / 2,
      size.height / 2,
    );

    final radius = size.width / 2 - 12;

    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 17
      ..strokeCap = StrokeCap.round;

    paint.color = const Color(0xFF0D9488);

    canvas.drawArc(
      Rect.fromCircle(
        center: center,
        radius: radius,
      ),
      -1.57,
      4.05,
      false,
      paint,
    );

    paint.color = const Color(0xFF9AE6DF);

    canvas.drawArc(
      Rect.fromCircle(
        center: center,
        radius: radius,
      ),
      2.48,
      1.95,
      false,
      paint,
    );

    final textPainter = TextPainter(
      text: const TextSpan(
        text: '9K',
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Colors.black87,
        ),
      ),
      textDirection: TextDirection.ltr,
    );

    textPainter.layout();

    textPainter.paint(
      canvas,
      Offset(
        center.dx - textPainter.width / 2,
        center.dy - textPainter.height / 2,
      ),
    );
  }

  @override
  bool shouldRepaint(
    covariant CustomPainter oldDelegate,
  ) {
    return false;
  }
}

// =========================================================
// CATEGORY DONUT
// =========================================================

class CategoryDonutPainter extends CustomPainter {
  @override
  void paint(
    Canvas canvas,
    Size size,
  ) {
    final center = Offset(
      size.width / 2,
      size.height / 2,
    );

    final radius = size.width / 2 - 10;

    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 22;

    paint.color = Colors.teal;

    canvas.drawArc(
      Rect.fromCircle(
        center: center,
        radius: radius,
      ),
      -1.57,
      2.2,
      false,
      paint,
    );

    paint.color = Colors.orange;

    canvas.drawArc(
      Rect.fromCircle(
        center: center,
        radius: radius,
      ),
      0.63,
      1.6,
      false,
      paint,
    );

    paint.color = Colors.pink;

    canvas.drawArc(
      Rect.fromCircle(
        center: center,
        radius: radius,
      ),
      2.23,
      1.7,
      false,
      paint,
    );

    final textPainter = TextPainter(
      text: const TextSpan(
        text: '698',
        style: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
    );

    textPainter.layout();

    textPainter.paint(
      canvas,
      Offset(
        center.dx - textPainter.width / 2,
        center.dy - textPainter.height / 2,
      ),
    );
  }

  @override
  bool shouldRepaint(
    covariant CustomPainter oldDelegate,
  ) {
    return false;
  }
}

// =========================================================
// ORDER STATISTICS CHART
// =========================================================

class OrderStatisticsPainter extends CustomPainter {
  @override
  void paint(
    Canvas canvas,
    Size size,
  ) {
    final paint = Paint()
      ..style = PaintingStyle.fill;

    const rows = 7;
    const columns = 7;

    final cellWidth = size.width / columns;
    final cellHeight = size.height / rows;

    for (int row = 0; row < rows; row++) {
      for (int col = 0; col < columns; col++) {
        final value =
            (row * 3 + col * 2) % 4;

        if (value == 0) {
          paint.color =
              const Color(0xFFCCF3EF);
        } else if (value == 1) {
          paint.color =
              const Color(0xFF9AE6DF);
        } else if (value == 2) {
          paint.color =
              const Color(0xFF5DD3C9);
        } else {
          paint.color =
              const Color(0xFF0D9488);
        }

        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(
              col * cellWidth + 2,
              row * cellHeight + 2,
              cellWidth - 4,
              cellHeight - 4,
            ),
            const Radius.circular(5),
          ),
          paint,
        );
      }
    }

    final textPainter = TextPainter(
      text: const TextSpan(
        text: '287 Orders',
        style: TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
    );

    textPainter.layout();

    final center = Offset(
      size.width / 2,
      size.height / 2,
    );

    textPainter.paint(
      canvas,
      Offset(
        center.dx - textPainter.width / 2,
        center.dy - textPainter.height / 2,
      ),
    );
  }

  @override
  bool shouldRepaint(
    covariant CustomPainter oldDelegate,
  ) {
    return false;
  }
}