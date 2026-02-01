import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../models/models.dart';
import '../../providers/providers.dart';
import '../../widgets/widgets.dart';

class WalletScreen extends StatefulWidget {
  const WalletScreen({super.key});

  @override
  State<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends State<WalletScreen> {
  @override
  void initState() {
    super.initState();
    final provider = context.read<WalletProvider>();
    provider.loadBalance();
    provider.loadTransactions();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Ví của tôi'), centerTitle: true),
      body: Consumer<WalletProvider>(
        builder: (context, wallet, _) {
          return RefreshIndicator(
            onRefresh: () async {
              await wallet.loadBalance();
              await wallet.loadTransactions();
            },
            child: CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        _buildBalanceCard(wallet.balance),
                        const SizedBox(height: 16),
                        _buildActionButtons(),
                        const SizedBox(height: 24),
                        _buildTransactionHeader(),
                      ],
                    ),
                  ),
                ),
                if (wallet.isLoading)
                  const SliverFillRemaining(
                    child: Center(child: CircularProgressIndicator()),
                  )
                else if (wallet.transactions.isEmpty)
                  SliverFillRemaining(
                    child: EmptyState(
                      message: 'Chưa có giao dịch nào',
                      icon: Icons.receipt_long_outlined,
                    ),
                  )
                else
                  SliverList(
                    delegate: SliverChildBuilderDelegate((context, index) {
                      final transaction = wallet.transactions[index];
                      return _buildTransactionItem(transaction);
                    }, childCount: wallet.transactions.length),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  // ================= BALANCE CARD =================

  Widget _buildBalanceCard(double balance) {
    final formatter = NumberFormat.currency(locale: 'vi_VN', symbol: '₫');

    return Stack(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                ThemeProvider.primaryColor,
                ThemeProvider.secondaryColor,
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: ThemeProvider.primaryColor.withOpacity(0.4),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.account_balance_wallet,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      'Số dư khả dụng',
                      style: TextStyle(color: Colors.white, fontSize: 12),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              const Text(
                'Tổng số dư',
                style: TextStyle(color: Colors.white70, fontSize: 14),
              ),
              const SizedBox(height: 4),
              Text(
                formatter.format(balance),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),

        // icon mờ trang trí
        Positioned(
          right: -20,
          bottom: -20,
          child: Icon(
            Icons.account_balance_wallet,
            size: 140,
            color: Colors.white.withOpacity(0.08),
          ),
        ),
      ],
    );
  }

  // ================= ACTION BUTTONS =================

  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: _buildActionButton(
            icon: Icons.add,
            label: 'Nạp tiền',
            color: ThemeProvider.primaryColor,
            onTap: _showDepositDialog,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildActionButton(
            icon: Icons.history,
            label: 'Lịch sử',
            color: ThemeProvider.secondaryColor,
            onTap: () => context.read<WalletProvider>().loadTransactions(),
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GlassCard(
      child: InkWell(
        onTap: onTap,
        splashColor: color.withOpacity(0.15),
        highlightColor: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 14),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color),
              ),
              const SizedBox(height: 8),
              Text(
                label,
                style: TextStyle(fontWeight: FontWeight.w600, color: color),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ================= HEADER =================

  Widget _buildTransactionHeader() {
    return Row(
      children: [
        Container(
          width: 4,
          height: 20,
          decoration: BoxDecoration(
            color: ThemeProvider.primaryColor,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(width: 8),
        const Text(
          'Lịch sử giao dịch',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const Spacer(),
        TextButton.icon(
          onPressed: () {},
          icon: const Icon(Icons.filter_list, size: 18),
          label: const Text('Lọc'),
        ),
      ],
    );
  }

  // ================= TRANSACTION ITEM =================

  Widget _buildTransactionItem(WalletTransaction transaction) {
    final formatter = NumberFormat.currency(locale: 'vi_VN', symbol: '₫');
    final isPositive = transaction.isPositive;

    return GlassCard(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: (isPositive ? Colors.green : Colors.red).withOpacity(
                  0.2,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                _getTransactionIcon(transaction.type),
                color: isPositive ? Colors.green : Colors.red,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    transaction.type.displayName,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  if (transaction.description != null)
                    Text(
                      transaction.description!,
                      style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withOpacity(0.6),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  Text(
                    DateFormat(
                      'dd/MM/yyyy HH:mm',
                    ).format(transaction.createdDate),
                    style: TextStyle(
                      fontSize: 11,
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withOpacity(0.5),
                    ),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${isPositive ? '+' : '-'}${formatter.format(transaction.amount.abs())}',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: isPositive ? Colors.green : Colors.red,
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: _getStatusColor(
                      transaction.status,
                    ).withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    _getStatusText(transaction.status),
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: _getStatusColor(transaction.status),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ================= HELPERS =================

  IconData _getTransactionIcon(TransactionType type) {
    switch (type) {
      case TransactionType.deposit:
        return Icons.arrow_downward;
      case TransactionType.withdraw:
        return Icons.arrow_upward;
      case TransactionType.payment:
        return Icons.shopping_cart;
      case TransactionType.refund:
        return Icons.replay;
      case TransactionType.reward:
        return Icons.emoji_events;
    }
  }

  Color _getStatusColor(TransactionStatus status) {
    switch (status) {
      case TransactionStatus.completed:
        return Colors.green;
      case TransactionStatus.pending:
        return Colors.orange;
      case TransactionStatus.rejected:
      case TransactionStatus.failed:
        return Colors.red;
    }
  }

  String _getStatusText(TransactionStatus status) {
    switch (status) {
      case TransactionStatus.completed:
        return 'Thành công';
      case TransactionStatus.pending:
        return 'Chờ duyệt';
      case TransactionStatus.rejected:
        return 'Từ chối';
      case TransactionStatus.failed:
        return 'Thất bại';
    }
  }

  // ================= DEPOSIT DIALOG =================

  void _showDepositDialog() {
    final amountController = TextEditingController();
    final descriptionController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Nạp tiền'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildInput(
              controller: amountController,
              label: 'Số tiền',
              hint: 'Nhập số tiền cần nạp',
              prefix: '₫ ',
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 12),
            _buildInput(
              controller: descriptionController,
              label: 'Ghi chú (tùy chọn)',
              hint: 'VD: Nạp qua chuyển khoản',
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: ThemeProvider.accentColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: ThemeProvider.accentColor),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'Yêu cầu nạp tiền sẽ được Admin duyệt trong vòng 24h',
                      style: TextStyle(fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          ElevatedButton(onPressed: () {}, child: const Text('Gửi yêu cầu')),
        ],
      ),
    );
  }

  Widget _buildInput({
    required TextEditingController controller,
    required String label,
    required String hint,
    String? prefix,
    TextInputType? keyboardType,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixText: prefix,
        filled: true,
        fillColor: Colors.grey.shade100,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}
