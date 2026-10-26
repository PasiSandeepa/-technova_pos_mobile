import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/customer_app_service.dart';

class CustomerDashboardPage extends StatefulWidget {
  final CustomerUser customerUser;
  final CustomerAppService service;

  const CustomerDashboardPage({
    super.key,
    required this.customerUser,
    required this.service,
  });

  @override
  State<CustomerDashboardPage> createState() => _CustomerDashboardPageState();
}

class _CustomerDashboardPageState extends State<CustomerDashboardPage> {
  static const Color forest = Color(0xFF145B46);
  static const Color mint = Color(0xFFE7F3EC);
  static const Color canvas = Color(0xFFF5F7F4);

  late Future<CustomerDashboardData> _dashboardFuture;

  String get _customerName => _data != null && _data!.name != 'Customer'
      ? _data!.name
      : widget.customerUser.name;

  String get _customerEmail => _data?.email.isNotEmpty == true
      ? _data!.email
      : widget.customerUser.email;

  @override
  void initState() {
    super.initState();
    _dashboardFuture = widget.service.getDashboard();
  }

  Future<void> _refresh() async {
    final future = widget.service.getDashboard();
    setState(() => _dashboardFuture = future);
    await future;
  }

  void _showReceipt(_Purchase purchase) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      backgroundColor: Colors.white,
      builder: (context) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Purchase details',
              style: TextStyle(fontSize: 19, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 18),
            _detailRow('Purchase', purchase.title),
            _detailRow('Date', purchase.date),
            _detailRow('Store', purchase.store),
            _detailRow('Purchase amount', _formatCurrency(purchase.amount)),
            _detailRow(
              'Outstanding balance',
              _formatCurrency(purchase.balance),
            ),
            _detailRow('Status', purchase.status),
          ],
        ),
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(color: Color(0xFF68736C)),
            ),
          ),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  void _showRewards() {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      backgroundColor: Colors.white,
      builder: (context) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 30),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Your rewards',
              style: TextStyle(fontSize: 19, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Text(
              '${_data!.points} points · ${_data!.tier}',
              style: const TextStyle(color: Color(0xFF68736C), height: 1.45),
            ),
            const SizedBox(height: 16),
            if (_data!.loyaltyTransactions.isEmpty)
              const Text(
                'No loyalty transactions yet.',
                style: TextStyle(color: Color(0xFF68736C)),
              )
            else
              ..._data!.loyaltyTransactions.take(5).map((transaction) {
                final points =
                    transaction['points'] ?? transaction['pointsDelta'] ?? 0;
                final description =
                    transaction['description'] ??
                    transaction['type'] ??
                    'Points activity';
                return _detailRow(description.toString(), '$points points');
              }),
          ],
        ),
      ),
    );
  }

  CustomerDashboardData? _data;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<CustomerDashboardData>(
      future: _dashboardFuture,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return _buildError(snapshot.error.toString());
        }
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        _data = snapshot.data!;
        return _buildDashboard(_data!);
      },
    );
  }

  Widget _buildError(String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_off_outlined, size: 36, color: forest),
            const SizedBox(height: 12),
            const Text(
              'Could not load your account',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 6),
            Text(
              error,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Color(0xFF68736C)),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: _refresh,
              icon: const Icon(Icons.refresh),
              label: const Text('Try again'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDashboard(CustomerDashboardData data) {
    return Scaffold(
      backgroundColor: canvas,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final wide = constraints.maxWidth >= 900;
            final purchases = data.creditPurchases
                .map(_Purchase.fromJson)
                .toList();
            final content = Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildGreeting(),
                const SizedBox(height: 20),
                if (wide)
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: _buildMembershipCard()),
                      const SizedBox(width: 16),
                      Expanded(child: _buildSpendCard()),
                    ],
                  )
                else ...[
                  _buildMembershipCard(),
                  const SizedBox(height: 12),
                  _buildSpendCard(),
                ],
                const SizedBox(height: 26),
                _buildSectionHeading(
                  'Offers for you',
                  '${data.activePromotions} active promotions from your store',
                ),
                const SizedBox(height: 12),
                _buildOffers(wide),
                const SizedBox(height: 26),
                _buildSectionHeading(
                  'Credit purchases',
                  'Credit purchases linked to your account',
                  action: TextButton.icon(
                    onPressed: _showRewards,
                    icon: const Icon(Icons.card_giftcard_outlined, size: 17),
                    label: const Text('Points history'),
                    style: TextButton.styleFrom(foregroundColor: forest),
                  ),
                ),
                const SizedBox(height: 12),
                purchases.isEmpty
                    ? _emptyState('No credit purchases found.')
                    : _buildPurchases(purchases),
                const SizedBox(height: 24),
              ],
            );

            return RefreshIndicator(
              onRefresh: _refresh,
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1120),
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: EdgeInsets.symmetric(
                      horizontal: wide ? 28 : 16,
                      vertical: 20,
                    ),
                    child: content,
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _emptyState(String message) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(10),
      border: Border.all(color: const Color(0xFFE4E9E4)),
    ),
    child: Text(message, style: const TextStyle(color: Color(0xFF79827B))),
  );

  String _formatCurrency(num value) {
    final currency = _data?.currencyCode ?? 'LKR';
    final symbol = currency == 'LKR' ? 'Rs.' : currency;
    return '$symbol ${value.toStringAsFixed(2)}';
  }

  Widget _buildGreeting() {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'YOUR REWARDS',
                style: TextStyle(
                  color: forest,
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                'Welcome, $_customerName',
                style: TextStyle(
                  color: const Color(0xFF202A23),
                  fontSize: MediaQuery.sizeOf(context).width >= 600 ? 27 : 23,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                _customerEmail.isNotEmpty
                    ? _customerEmail
                    : 'Email not provided',
                style: const TextStyle(color: Color(0xFF6C756E), fontSize: 12),
              ),
              const SizedBox(height: 3),
              Text(
                _data!.phone,
                style: const TextStyle(color: Color(0xFF6C756E), fontSize: 11),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: const Color(0xFFE8EEE8),
            borderRadius: BorderRadius.circular(14),
          ),
          alignment: Alignment.center,
          child: Text(
            _initials(_customerName),
            style: const TextStyle(color: forest, fontWeight: FontWeight.w800),
          ),
        ),
      ],
    );
  }

  String _initials(String name) => name
      .trim()
      .split(RegExp(r'\s+'))
      .where((part) => part.isNotEmpty)
      .take(2)
      .map((part) => part[0].toUpperCase())
      .join();

  Widget _buildMembershipCard() {
    return Container(
      constraints: const BoxConstraints(minHeight: 222),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: forest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.stars_rounded,
                color: Color(0xFFE5C77A),
                size: 21,
              ),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'TECHNOVA REWARDS',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFE5C77A).withOpacity(0.16),
                  borderRadius: BorderRadius.circular(5),
                  border: Border.all(color: const Color(0x66E5C77A)),
                ),
                child: Text(
                  _data!.tier.toUpperCase(),
                  style: TextStyle(
                    color: Color(0xFFF1D992),
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 22),
          const Text(
            'AVAILABLE POINTS',
            style: TextStyle(
              color: Color(0xFFBFD6C9),
              fontSize: 9,
              fontWeight: FontWeight.w700,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 3),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                _data!.points.toString(),
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 34,
                  fontWeight: FontWeight.w700,
                  height: 1.1,
                ),
              ),
              Padding(
                padding: EdgeInsets.only(left: 7, bottom: 5),
                child: Text(
                  'pts',
                  style: TextStyle(color: Color(0xFFD3E3D8), fontSize: 12),
                ),
              ),
              Spacer(),
              Icon(Icons.card_giftcard_outlined, color: Color(0xFFE5C77A)),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: Text(
                  _data!.customerNumber.isNotEmpty
                      ? 'Member ${_data!.customerNumber}'
                      : 'Rewards member',
                  style: const TextStyle(
                    color: Color(0xFFD3E3D8),
                    fontSize: 10,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              TextButton(
                onPressed: _showRewards,
                style: TextButton.styleFrom(
                  foregroundColor: forest,
                  backgroundColor: const Color(0xFFE5C77A),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 13,
                    vertical: 10,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(7),
                  ),
                ),
                child: const Text(
                  'View rewards',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSpendCard() {
    return Container(
      constraints: const BoxConstraints(minHeight: 222),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE4E9E4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Expanded(
                child: Text(
                  'Account overview',
                  style: TextStyle(
                    color: Color(0xFF28342C),
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Icon(
                Icons.account_balance_wallet_outlined,
                color: forest,
                size: 20,
              ),
            ],
          ),
          const SizedBox(height: 20),
          const Text(
            'STORE CREDIT BALANCE',
            style: TextStyle(
              color: Color(0xFF7A847C),
              fontSize: 9,
              fontWeight: FontWeight.w700,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            _formatCurrency(_data!.storeCreditBalance),
            style: TextStyle(
              color: Color(0xFF202A23),
              fontSize: 25,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 18),
          const Divider(height: 1, color: Color(0xFFE9EDE9)),
          const SizedBox(height: 15),
          Row(
            children: [
              Expanded(
                child: _MiniMetric(
                  icon: Icons.credit_score_outlined,
                  label: 'Active credit purchases',
                  value: _data!.activeCreditPurchases.toString(),
                ),
              ),
              Expanded(
                child: _MiniMetric(
                  icon: Icons.local_offer_outlined,
                  label: 'Unread notifications',
                  value: _data!.unreadNotifications.toString(),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeading(String title, String subtitle, {Widget? action}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: Color(0xFF26322A),
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                subtitle,
                style: const TextStyle(color: Color(0xFF79827B), fontSize: 11),
              ),
            ],
          ),
        ),
        if (action != null) action,
      ],
    );
  }

  Widget _buildOffers(bool wide) {
    final offers = _data!.promotions;
    if (offers.isEmpty) return _emptyState('No active promotions right now.');

    return LayoutBuilder(
      builder: (context, constraints) {
        final useGrid = wide || constraints.maxWidth >= 680;
        if (useGrid) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (var index = 0; index < offers.length; index++) ...[
                if (index > 0) const SizedBox(width: 12),
                Expanded(child: _offerCard(offers[index])),
              ],
            ],
          );
        }

        return SizedBox(
          height: 240,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: offers.length,
            separatorBuilder: (context, index) => const SizedBox(width: 12),
            itemBuilder: (context, index) => SizedBox(
              width: constraints.maxWidth * 0.86,
              child: _offerCard(offers[index]),
            ),
          ),
        );
      },
    );
  }

  Widget _offerCard(Map<String, dynamic> offer) {
    final name = offer['name']?.toString() ?? 'Promotion';
    final description = offer['description']?.toString() ?? '';
    final code = offer['code']?.toString() ?? '';
    final endsAt = DateTime.tryParse(offer['endsAt']?.toString() ?? '');
    final value = offer['value']?.toString();
    final type = offer['type']?.toString().toLowerCase() ?? '';
    final offerValue = value == null || value == 'null'
        ? ''
        : '$value${type.contains('percent') ? '%' : ''}';
    return Container(
      constraints: const BoxConstraints(minHeight: 200),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE4E9E4)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: mint,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.local_offer_outlined,
              color: forest,
              size: 22,
            ),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  offerValue.isEmpty ? 'ACTIVE PROMOTION' : 'SAVE $offerValue',
                  style: TextStyle(
                    color: forest,
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.8,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  name,
                  style: const TextStyle(
                    color: Color(0xFF27332A),
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description.isEmpty
                      ? 'Available in your store.'
                      : description,
                  style: const TextStyle(
                    color: Color(0xFF707A72),
                    fontSize: 11,
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        endsAt == null
                            ? 'Available now'
                            : 'Until ${_shortDate(endsAt)}',
                        style: const TextStyle(
                          color: Color(0xFF8A938B),
                          fontSize: 10,
                        ),
                      ),
                    ),
                    if (code.isNotEmpty)
                      Text(
                        code,
                        style: const TextStyle(
                          color: forest,
                          fontWeight: FontWeight.w700,
                          fontSize: 10,
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPurchases(List<_Purchase> purchases) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE4E9E4)),
      ),
      child: Column(
        children: [
          for (var index = 0; index < purchases.length; index++) ...[
            if (index > 0) const Divider(height: 1, indent: 16, endIndent: 16),
            _purchaseTile(purchases[index]),
          ],
        ],
      ),
    );
  }

  Widget _purchaseTile(_Purchase purchase) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _showReceipt(purchase),
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: mint,
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Icon(purchase.icon, size: 19, color: forest),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      purchase.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFF28342C),
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${purchase.store}  ·  ${purchase.date}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFF7A847C),
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    _formatCurrency(purchase.balance),
                    style: const TextStyle(
                      color: Color(0xFF28342C),
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    purchase.status,
                    style: const TextStyle(
                      color: forest,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 4),
              const Icon(
                Icons.chevron_right,
                color: Color(0xFF9AA39B),
                size: 19,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MiniMetric extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _MiniMetric({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: const Color(0xFF588369), size: 18),
        const SizedBox(width: 7),
        Flexible(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(color: Color(0xFF7A847C), fontSize: 9),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Color(0xFF28342C),
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _Purchase {
  final String title;
  final String date;
  final String store;
  final num amount;
  final num balance;
  final String status;
  final IconData icon;

  const _Purchase({
    required this.title,
    required this.date,
    required this.store,
    required this.amount,
    required this.balance,
    required this.status,
    required this.icon,
  });

  factory _Purchase.fromJson(Map<String, dynamic> json) {
    final sale = _asMap(json['sale']);
    final branch = _asMap(sale['branch']);
    final rawDate =
        json['createdAt'] ?? sale['completedAt'] ?? sale['createdAt'];
    return _Purchase(
      title:
          sale['invoiceNumber']?.toString() ??
          json['agreementNumber']?.toString() ??
          json['id']?.toString() ??
          'Credit purchase',
      date: _shortDate(rawDate),
      store: branch['name']?.toString() ?? 'Store',
      amount: _asNum(json['principal'] ?? sale['total']),
      balance: _asNum(json['outstandingBalance'] ?? sale['balanceDue']),
      status: json['status']?.toString() ?? 'Unknown',
      icon: Icons.credit_card_outlined,
    );
  }
}

Map<String, dynamic> _asMap(dynamic value) =>
    value is Map<String, dynamic> ? value : <String, dynamic>{};

num _asNum(dynamic value) => num.tryParse(value?.toString() ?? '') ?? 0;

String _shortDate(dynamic value) {
  final date = DateTime.tryParse(value?.toString() ?? '');
  if (date == null) return 'Date unavailable';
  return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
}
