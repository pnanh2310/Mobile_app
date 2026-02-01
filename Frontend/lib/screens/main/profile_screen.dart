import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../models/models.dart';
import '../../providers/providers.dart';
import '../../services/services.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  MemberProfile? _profile;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final auth = context.read<AuthProvider>();
    if (auth.user == null) return;

    setState(() => _isLoading = true);

    try {
      final response = await apiService.getMemberProfile(auth.user!.memberId);

      if (!mounted) return;
      setState(() {
        _profile = MemberProfile.fromJson(response);
      });
    } catch (_) {
      // ignore
    }

    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final theme = context.watch<ThemeProvider>();
    final user = auth.user;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Hồ sơ cá nhân',
          style: TextStyle(
            fontFamily: 'Montserrat',
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.green,
        actions: [
          IconButton(
            icon: Icon(theme.isDark ? Icons.light_mode : Icons.dark_mode),
            onPressed: theme.toggleTheme,
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _showLogoutDialog,
          ),
        ],
      ),
      body: Stack(
        children: [
          RefreshIndicator(
            onRefresh: _loadProfile,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _buildProfileHeader(user),
                  const SizedBox(height: 20),
                  _buildStatsGrid(),
                  const SizedBox(height: 20),
                  _buildTierCard(user),
                  const SizedBox(height: 20),
                  _buildMenuItems(),
                  const SizedBox(height: 80),
                ],
              ),
            ),
          ),

          /// Loading overlay
          if (_isLoading)
            Container(
              color: Colors.black.withOpacity(0.05),
              child: const Center(child: CircularProgressIndicator()),
            ),
        ],
      ),
    );
  }

  // ================= UI PART =================

  Widget _buildProfileHeader(UserInfo? user) {
    if (user == null) return const SizedBox();

    final theme = Theme.of(context);

    return Card(
      elevation: 6,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            CircleAvatar(
              radius: 48,
              backgroundColor: Colors.green,
              backgroundImage: user.avatarUrl != null
                  ? NetworkImage(user.avatarUrl!)
                  : null,
              child: user.avatarUrl == null
                  ? Text(
                      user.fullName[0].toUpperCase(),
                      style: const TextStyle(
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        fontFamily: 'Montserrat',
                      ),
                    )
                  : null,
            ),
            const SizedBox(height: 12),
            Text(
              user.fullName,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                fontFamily: 'Montserrat',
              ),
            ),
            const SizedBox(height: 4),
            Text(user.email, style: theme.textTheme.bodySmall),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              children: [
                Chip(
                  label: Text("${user.tier.icon} ${user.tier.displayName}"),
                  backgroundColor: Colors.green.withOpacity(0.15),
                ),
                Chip(
                  label: Text("DUPR ${user.rankLevel.toStringAsFixed(1)}"),
                  backgroundColor: Colors.lightGreen.withOpacity(0.2),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsGrid() {
    final profile = _profile;

    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            'Trận đấu',
            profile?.totalMatches.toString() ?? '0',
            Icons.sports_tennis,
            Colors.green,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            'Chiến thắng',
            profile?.totalWins.toString() ?? '0',
            Icons.emoji_events,
            Colors.lightGreen,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 8),
            Text(
              title,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontFamily: 'Montserrat',
              ),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTierCard(UserInfo? user) {
    if (user == null) return const SizedBox();

    final spent = _profile?.totalSpent ?? 0;

    return Card(
      elevation: 6,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Hạng thành viên',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                fontFamily: 'Montserrat',
              ),
            ),
            const SizedBox(height: 8),
            Text(
              user.tier.displayName,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.green,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Tổng chi tiêu: ${NumberFormat.currency(locale: 'vi_VN', symbol: '₫').format(spent)}',
              style: const TextStyle(color: Colors.black54),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuItems() {
    return Card(
      elevation: 6,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Column(
        children: [
          _buildMenuItem(Icons.person_outline, 'Chỉnh sửa hồ sơ'),
          _buildMenuItem(Icons.history, 'Lịch sử thi đấu'),
          _buildMenuItem(Icons.notifications_outlined, 'Cài đặt thông báo'),
          _buildMenuItem(Icons.help_outline, 'Trợ giúp & Phản hồi'),
          _buildMenuItem(Icons.info_outline, 'Về ứng dụng'),
        ],
      ),
    );
  }

  Widget _buildMenuItem(IconData icon, String title) {
    return ListTile(
      leading: Icon(icon, color: Colors.green),
      title: Text(title),
      trailing: const Icon(Icons.chevron_right),
      onTap: () {},
    );
  }

  // ================= ACTION =================

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Đăng xuất'),
        content: const Text('Bạn có chắc muốn đăng xuất?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              context.read<AuthProvider>().logout();
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Đăng xuất'),
          ),
        ],
      ),
    );
  }
}
