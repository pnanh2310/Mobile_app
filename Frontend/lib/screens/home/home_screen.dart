import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../models/models.dart';
import '../../providers/providers.dart';
import '../../services/services.dart';
import '../admin/admin_dashboard_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<News> _news = [];
  List<Match> _upcomingMatches = [];
  bool _isLoading = true;

  final Color primaryBlue = const Color(0xFF0A73FF);
  final Color sunYellow = const Color(0xFFFFD54F);

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final newsResponse = await apiService.getNews();
      _news = newsResponse.map((e) => News.fromJson(e)).take(5).toList();

      final matchesResponse = await apiService.getUpcomingMatches();
      _upcomingMatches = matchesResponse
          .map((e) => Match.fromJson(e))
          .take(3)
          .toList();
    } catch (_) {}
    if (!mounted) return;
    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.user;

    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FB),
      body: RefreshIndicator(
        onRefresh: _loadData,
        child: CustomScrollView(
          slivers: [
            _buildAppBar(user),
            SliverPadding(
              padding: const EdgeInsets.all(16),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  _buildWelcomeCard(user),
                  const SizedBox(height: 20),
                  if (user != null &&
                      (user.roles.contains('Admin') ||
                          user.roles.contains('Treasurer')))
                    _buildAdminDashboardButton(),
                  const SizedBox(height: 24),
                  _buildStatsRow(user),
                  const SizedBox(height: 32),
                  _buildSectionTitle('Trận đấu sắp tới'),
                  const SizedBox(height: 12),
                  _buildUpcomingMatches(),
                  const SizedBox(height: 32),
                  _buildSectionTitle('Tin tức CLB'),
                  const SizedBox(height: 12),
                  _buildNewsList(),
                  const SizedBox(height: 80),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ================= APP BAR =================

  Widget _buildAppBar(UserInfo? user) {
    return SliverAppBar(
      expandedHeight: 140,
      pinned: true,
      backgroundColor: primaryBlue,
      flexibleSpace: FlexibleSpaceBar(
        title: const Text(
          'PCM CLUB',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        background: Stack(
          fit: StackFit.expand,
          children: [
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    primaryBlue,
                    primaryBlue.withOpacity(0.85),
                    sunYellow.withOpacity(0.6),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
            ),
            BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
              child: Container(color: Colors.transparent),
            ),
          ],
        ),
      ),
      actions: [
        Consumer<NotificationProvider>(
          builder: (_, notif, __) => Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.notifications_none),
                onPressed: () {},
              ),
              if (notif.unreadCount > 0)
                Positioned(
                  right: 10,
                  top: 10,
                  child: CircleAvatar(
                    radius: 8,
                    backgroundColor: Colors.red,
                    child: Text(
                      '${notif.unreadCount}',
                      style: const TextStyle(fontSize: 10, color: Colors.white),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  // ================= WELCOME =================

  Widget _buildWelcomeCard(UserInfo? user) {
    if (user == null) return const SizedBox();

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: LinearGradient(
          colors: [primaryBlue, primaryBlue.withOpacity(0.8)],
        ),
        boxShadow: [
          BoxShadow(
            color: primaryBlue.withOpacity(0.3),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 34,
            backgroundColor: sunYellow,
            backgroundImage: user.avatarUrl != null
                ? NetworkImage(user.avatarUrl!)
                : null,
            child: user.avatarUrl == null
                ? Text(
                    user.fullName[0].toUpperCase(),
                    style: const TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  )
                : null,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Xin chào 👋',
                  style: TextStyle(color: Colors.white70),
                ),
                Text(
                  user.fullName,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '${user.tier.icon} ${user.tier.displayName} • DUPR ${user.rankLevel.toStringAsFixed(1)}',
                  style: const TextStyle(color: Colors.white70),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ================= ADMIN =================

  Widget _buildAdminDashboardButton() {
    return _glassCard(
      child: ListTile(
        leading: Icon(Icons.admin_panel_settings, color: primaryBlue),
        title: const Text(
          'Admin Dashboard',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: const Text('Quản lý & thống kê hệ thống'),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AdminDashboardScreen()),
          );
        },
      ),
    );
  }

  // ================= STATS =================

  Widget _buildStatsRow(UserInfo? user) {
    final formatter = NumberFormat.currency(locale: 'vi_VN', symbol: '₫');
    return Row(
      children: [
        Expanded(
          child: _statCard(
            'Số dư ví',
            formatter.format(user?.walletBalance ?? 0),
            Icons.account_balance_wallet,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _statCard(
            'DUPR',
            user?.rankLevel.toStringAsFixed(1) ?? '0.0',
            Icons.trending_up,
          ),
        ),
      ],
    );
  }

  Widget _statCard(String title, String value, IconData icon) {
    return _glassCard(
      child: Column(
        children: [
          Icon(icon, size: 32, color: primaryBlue),
          const SizedBox(height: 10),
          Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: primaryBlue,
            ),
          ),
        ],
      ),
    );
  }

  // ================= SECTION =================

  Widget _buildSectionTitle(String title) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        TextButton(onPressed: () {}, child: const Text('Xem tất cả')),
      ],
    );
  }

  // ================= MATCHES =================

  Widget _buildUpcomingMatches() {
    if (_isLoading) {
      return const Padding(
        padding: EdgeInsets.all(20),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    if (_upcomingMatches.isEmpty) {
      return _glassCard(child: const Text('Không có trận đấu sắp tới'));
    }
    return Column(children: _upcomingMatches.map(_buildMatchCard).toList());
  }

  Widget _buildMatchCard(Match match) {
    return _glassCard(
      margin: const EdgeInsets.only(bottom: 12),
      child: Column(
        children: [
          Text(
            '${match.team1Display}  VS  ${match.team2Display}',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 6),
          Text(
            DateFormat('dd/MM/yyyy HH:mm').format(match.startTime),
            style: const TextStyle(color: Colors.black54, fontSize: 12),
          ),
        ],
      ),
    );
  }

  // ================= NEWS =================

  Widget _buildNewsList() {
    if (_isLoading) {
      return const Padding(
        padding: EdgeInsets.all(20),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    if (_news.isEmpty) {
      return _glassCard(child: const Text('Không có tin tức'));
    }
    return Column(children: _news.map(_buildNewsCard).toList());
  }

  Widget _buildNewsCard(News news) {
    return _glassCard(
      margin: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            news.title,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 6),
          Text(news.content, maxLines: 3, overflow: TextOverflow.ellipsis),
          const SizedBox(height: 8),
          Text(
            DateFormat('dd/MM/yyyy').format(news.createdDate),
            style: const TextStyle(fontSize: 12, color: Colors.black54),
          ),
        ],
      ),
    );
  }

  // ================= GLASS CARD =================

  Widget _glassCard({required Widget child, EdgeInsets? margin}) {
    return Container(
      margin: margin,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 18,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: child,
    );
  }
}
