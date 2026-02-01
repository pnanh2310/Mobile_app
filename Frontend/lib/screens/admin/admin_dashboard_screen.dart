import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../../services/api_service.dart';

/* =======================
   🎨 COLOR PALETTE
======================= */
const Color kPrimaryBlue = Color(0xFF1E88E5);
const Color kSecondaryBlue = Color(0xFF90CAF9);
const Color kSunYellow = Color(0xFFFFC107);
const Color kSuccessGreen = Color(0xFF43A047);
const Color kDangerRed = Color(0xFFE53935);
const Color kBackground = Color(0xFFF4F7FB);
const Color kTextDark = Color(0xFF1F2937);

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  bool _isLoading = true;
  Map<String, dynamic>? _clubBalance;
  Map<String, dynamic>? _stats;
  List<dynamic>? _revenueData;
  List<dynamic>? _pendingDeposits;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final results = await Future.wait([
        apiService.getClubBalance(),
        apiService.getDashboardStats(),
        apiService.getRevenueChart(),
        apiService.getPendingDeposits(),
      ]);

      setState(() {
        _clubBalance = results[0] as Map<String, dynamic>;
        _stats = results[1] as Map<String, dynamic>;
        _revenueData = results[2] as List<dynamic>;
        _pendingDeposits = results[3] as List<dynamic>;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Lỗi: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFE3F2FD), kBackground],
          ),
        ),
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : RefreshIndicator(
                onRefresh: _loadData,
                child: CustomScrollView(
                  slivers: [
                    _buildAppBar(),
                    SliverPadding(
                      padding: const EdgeInsets.all(16),
                      sliver: SliverList(
                        delegate: SliverChildListDelegate([
                          if (_clubBalance != null) _buildClubBalanceCard(),
                          const SizedBox(height: 20),
                          if (_stats != null) _buildStatsCards(),
                          const SizedBox(height: 24),
                          if (_revenueData != null && _revenueData!.isNotEmpty)
                            _buildRevenueChart(),
                          const SizedBox(height: 24),
                          if (_pendingDeposits != null) _buildPendingDeposits(),
                        ]),
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }

  /* =======================
        APP BAR
======================= */
  SliverAppBar _buildAppBar() {
    return SliverAppBar(
      pinned: true,
      expandedHeight: 90,
      backgroundColor: kPrimaryBlue,
      elevation: 0,
      title: const Text(
        'Admin Dashboard',
        style: TextStyle(fontWeight: FontWeight.bold),
      ),
      actions: [
        IconButton(icon: const Icon(Icons.refresh), onPressed: _loadData),
      ],
    );
  }

  /* =======================
      💰 CLUB BALANCE
======================= */
  Widget _buildClubBalanceCard() {
    final balance = _clubBalance!['totalBalance'] as num;
    final isNegative = _clubBalance!['isNegative'] as bool;
    final memberCount = _clubBalance!['memberCount'] as int;

    return _glassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isNegative ? kDangerRed : kSuccessGreen,
                ),
                child: Icon(
                  isNegative
                      ? Icons.warning_amber
                      : Icons.account_balance_wallet,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Tổng quỹ CLB',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: kTextDark,
                    ),
                  ),
                  Text(
                    '$memberCount thành viên',
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 18),
          Text(
            NumberFormat.currency(
              locale: 'vi_VN',
              symbol: 'VND',
            ).format(balance),
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.bold,
              color: isNegative ? kDangerRed : kSuccessGreen,
            ),
          ),
          if (isNegative) ...[
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: kDangerRed.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Row(
                children: [
                  Icon(Icons.error_outline, color: kDangerRed),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Quỹ CLB đang âm, cần xử lý sớm!',
                      style: TextStyle(
                        color: kDangerRed,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  /* =======================
        📊 STATS
======================= */
  Widget _buildStatsCards() {
    final members = _stats!['members'];
    final bookings = _stats!['bookings'];
    final tournaments = _stats!['tournaments'];
    final finance = _stats!['finance'];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Thống kê tổng quan',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: kTextDark,
          ),
        ),
        const SizedBox(height: 12),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 14,
          mainAxisSpacing: 14,
          childAspectRatio: 1.3,
          children: [
            _statTile(
              'Thành viên',
              '${members['total']}',
              Icons.people,
              kPrimaryBlue,
            ),
            _statTile(
              'Booking tháng',
              '${bookings['thisMonth']}',
              Icons.calendar_month,
              kSunYellow,
            ),
            _statTile(
              'Giải đấu mở',
              '${tournaments['open']}',
              Icons.emoji_events,
              Colors.deepPurple,
            ),
            _statTile(
              'Doanh thu',
              NumberFormat.compact(
                locale: 'vi',
              ).format(finance['thisMonthRevenue']),
              Icons.attach_money,
              kSuccessGreen,
            ),
          ],
        ),
      ],
    );
  }

  Widget _statTile(String title, String value, IconData icon, Color color) {
    return _glassCard(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 36),
          const SizedBox(height: 10),
          Text(
            value,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(title, style: const TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }

  /* =======================
        📈 CHART
======================= */
  Widget _buildRevenueChart() {
    return _glassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Doanh thu 12 tháng',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: kTextDark,
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 240,
            child: LineChart(
              LineChartData(
                gridData: FlGridData(show: true, drawVerticalLine: false),
                borderData: FlBorderData(show: false),
                titlesData: FlTitlesData(
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 42,
                      getTitlesWidget: (v, _) => Text(
                        NumberFormat.compact(locale: 'vi').format(v),
                        style: const TextStyle(fontSize: 10),
                      ),
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      interval: 1,
                      getTitlesWidget: (v, _) {
                        if (v.toInt() >= _revenueData!.length) {
                          return const Text('');
                        }
                        return Text(
                          _revenueData![v.toInt()]['month'].split('-')[1],
                          style: const TextStyle(fontSize: 10),
                        );
                      },
                    ),
                  ),
                ),
                lineBarsData: [
                  _line(_revenueData!, 'income', kSuccessGreen),
                  _line(_revenueData!, 'expense', kDangerRed),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  LineChartBarData _line(List data, String key, Color color) {
    return LineChartBarData(
      isCurved: true,
      color: color,
      barWidth: 3,
      dotData: const FlDotData(show: false),
      spots: data
          .asMap()
          .entries
          .map(
            (e) => FlSpot(e.key.toDouble(), (e.value[key] as num).toDouble()),
          )
          .toList(),
    );
  }

  /* =======================
        💸 PENDING
======================= */
  Widget _buildPendingDeposits() {
    if (_pendingDeposits!.isEmpty) {
      return _glassCard(
        child: Column(
          children: const [
            Icon(Icons.check_circle_outline, size: 48, color: kSuccessGreen),
            SizedBox(height: 8),
            Text('Không có yêu cầu chờ duyệt'),
          ],
        ),
      );
    }

    return _glassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Yêu cầu nạp tiền (${_pendingDeposits!.length})',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: kTextDark,
            ),
          ),
          const SizedBox(height: 12),
          ..._pendingDeposits!.map(
            (e) => _buildDepositItem(e as Map<String, dynamic>),
          ),
        ],
      ),
    );
  }

  Widget _buildDepositItem(Map<String, dynamic> deposit) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  deposit['description'],
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  NumberFormat.currency(
                    locale: 'vi_VN',
                    symbol: 'VND',
                  ).format(deposit['amount']),
                  style: const TextStyle(
                    color: kSuccessGreen,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.check_circle, color: kSuccessGreen),
            onPressed: () => _approveDeposit(deposit['id']),
          ),
          IconButton(
            icon: const Icon(Icons.cancel, color: kDangerRed),
            onPressed: () => _rejectDeposit(deposit['id']),
          ),
        ],
      ),
    );
  }

  /* =======================
        🧩 UTILS
======================= */
  Widget _glassCard({required Widget child}) {
    return Card(
      elevation: 10,
      shadowColor: kPrimaryBlue.withOpacity(0.12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(padding: const EdgeInsets.all(18), child: child),
    );
  }

  Future<void> _approveDeposit(int id) async {
    await apiService.approveDeposit(id);
    _loadData();
  }

  Future<void> _rejectDeposit(int id) async {
    await apiService.rejectDeposit(id);
    _loadData();
  }
}
