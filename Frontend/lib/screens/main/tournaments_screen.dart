import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../models/models.dart';
import '../../providers/providers.dart';
import '../../widgets/widgets.dart';

class TournamentsScreen extends StatefulWidget {
  const TournamentsScreen({super.key});

  @override
  State<TournamentsScreen> createState() => _TournamentsScreenState();
}

class _TournamentsScreenState extends State<TournamentsScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);

    Future.microtask(() {
      context.read<TournamentProvider>().loadTournaments();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Giải đấu',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: ThemeProvider.primaryColor,
          labelColor: ThemeProvider.primaryColor,
          unselectedLabelColor: theme.colorScheme.onSurface.withOpacity(0.6),
          tabs: const [
            Tab(text: 'Mở đăng ký'),
            Tab(text: 'Đang diễn ra'),
            Tab(text: 'Đã kết thúc'),
          ],
        ),
      ),
      body: Consumer<TournamentProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading && provider.tournaments.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          return TabBarView(
            controller: _tabController,
            children: [
              _buildTournamentList(
                provider.tournaments
                    .where(
                      (t) =>
                          t.status == TournamentStatus.open ||
                          t.status == TournamentStatus.registering,
                    )
                    .toList(),
              ),
              _buildTournamentList(
                provider.tournaments
                    .where(
                      (t) =>
                          t.status == TournamentStatus.ongoing ||
                          t.status == TournamentStatus.drawCompleted,
                    )
                    .toList(),
              ),
              _buildTournamentList(
                provider.tournaments
                    .where((t) => t.status == TournamentStatus.finished)
                    .toList(),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildTournamentList(List<Tournament> tournaments) {
    if (tournaments.isEmpty) {
      return const EmptyState(
        message: 'Không có giải đấu nào',
        icon: Icons.emoji_events_outlined,
      );
    }

    return RefreshIndicator(
      onRefresh: () => context.read<TournamentProvider>().loadTournaments(),
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: tournaments.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, index) =>
            _buildTournamentCard(tournaments[index]),
      ),
    );
  }

  Widget _buildTournamentCard(Tournament tournament) {
    final formatter = NumberFormat.currency(locale: 'vi_VN', symbol: '₫');
    final statusColor = _getStatusColor(tournament.status);

    return GlassCard(
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () => _showTournamentDetail(tournament),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              /// Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [statusColor, statusColor.withOpacity(0.7)],
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.emoji_events, color: Colors.white),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          tournament.name,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Chip(
                          visualDensity: VisualDensity.compact,
                          backgroundColor: statusColor.withOpacity(0.15),
                          label: Text(
                            tournament.status.displayName,
                            style: TextStyle(
                              fontSize: 12,
                              color: statusColor,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              _buildInfoRow(
                Icons.calendar_today,
                '${DateFormat('dd/MM').format(tournament.startDate)}'
                ' - ${DateFormat('dd/MM/yyyy').format(tournament.endDate)}',
              ),
              _buildInfoRow(
                Icons.sports_tennis,
                _getFormatName(tournament.format),
              ),
              _buildInfoRow(Icons.people, tournament.participantDisplay),

              const Divider(height: 24),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _priceBlock(
                    'Phí tham gia',
                    formatter.format(tournament.entryFee),
                  ),
                  _priceBlock(
                    'Giải thưởng',
                    formatter.format(tournament.prizePool),
                    highlight: true,
                  ),
                ],
              ),

              if (tournament.canRegister && !tournament.isFull) ...[
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: PrimaryButton(
                    text: 'Đăng ký tham gia',
                    icon: Icons.add,
                    onPressed: () => _joinTournament(tournament),
                  ),
                ),
              ],

              if (tournament.isFull && tournament.canRegister) ...[
                const SizedBox(height: 16),
                _warningBox('Đã đủ số lượng người tham gia'),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _priceBlock(String title, String value, {bool highlight = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 12,
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: highlight ? ThemeProvider.accentColor : null,
          ),
        ),
      ],
    );
  }

  Widget _warningBox(String text) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.red.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: const TextStyle(color: Colors.red, fontWeight: FontWeight.w600),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Icon(
            icon,
            size: 16,
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(TournamentStatus status) {
    switch (status) {
      case TournamentStatus.open:
      case TournamentStatus.registering:
        return Colors.green;
      case TournamentStatus.drawCompleted:
        return Colors.blue;
      case TournamentStatus.ongoing:
        return ThemeProvider.accentColor;
      case TournamentStatus.finished:
        return Colors.grey;
    }
  }

  String _getFormatName(TournamentFormat format) {
    switch (format) {
      case TournamentFormat.knockout:
        return 'Loại trực tiếp';
      case TournamentFormat.roundRobin:
        return 'Vòng tròn';
      case TournamentFormat.hybrid:
        return 'Kết hợp';
    }
  }

  Future<void> _showTournamentDetail(Tournament tournament) async {
    await context.read<TournamentProvider>().loadTournamentDetail(
      tournament.id,
    );

    if (!mounted) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _TournamentDetailSheet(tournament: tournament),
    );
  }

  Future<void> _joinTournament(Tournament tournament) async {
    final controller = TextEditingController();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Đăng ký giải đấu'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(labelText: 'Tên đội (tuỳ chọn)'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Xác nhận'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final success = await context.read<TournamentProvider>().joinTournament(
        tournament.id,
        teamName: controller.text.isNotEmpty ? controller.text : null,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            success
                ? 'Đăng ký thành công!'
                : context.read<TournamentProvider>().errorMessage ??
                      'Đăng ký thất bại',
          ),
          backgroundColor: success ? Colors.green : Colors.red,
        ),
      );

      if (success) {
        context.read<WalletProvider>().loadBalance();
        context.read<AuthProvider>().refreshUser();
      }
    }
  }
}

class _TournamentDetailSheet extends StatelessWidget {
  final Tournament tournament;

  const _TournamentDetailSheet({required this.tournament});

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      builder: (_, controller) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Consumer<TournamentProvider>(
          builder: (_, provider, __) {
            final detail = provider.selectedTournament;
            if (provider.isLoading || detail == null) {
              return const Center(child: CircularProgressIndicator());
            }

            return ListView(
              controller: controller,
              padding: const EdgeInsets.all(16),
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  detail.name,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (detail.description != null) ...[
                  const SizedBox(height: 8),
                  Text(detail.description!),
                ],
                const SizedBox(height: 24),
                const Text(
                  'Người tham gia',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                ...detail.participants.map(
                  (p) => ListTile(
                    leading: CircleAvatar(
                      backgroundColor: ThemeProvider.primaryColor,
                      child: Text(
                        p.displayName[0].toUpperCase(),
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                    title: Text(p.displayName),
                    subtitle: p.partnerName != null
                        ? Text('cùng ${p.partnerName}')
                        : null,
                  ),
                ),
                const SizedBox(height: 40),
              ],
            );
          },
        ),
      ),
    );
  }
}
