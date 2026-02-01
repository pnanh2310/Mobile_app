import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/providers.dart';
import '../home/home_screen.dart';
import 'booking_screen.dart';
import 'tournaments_screen.dart';
import 'wallet_screen.dart';
import 'profile_screen.dart';

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = const [
    HomeScreen(),
    BookingScreen(),
    TournamentsScreen(),
    WalletScreen(),
    ProfileScreen(),
  ];

  @override
  void initState() {
    super.initState();

    Future.microtask(() {
      context.read<NotificationProvider>()
        ..init()
        ..loadUnreadCount();

      context.read<WalletProvider>().loadBalance();
      context.read<BookingProvider>().loadCourts();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FB),
      body: IndexedStack(index: _currentIndex, children: _screens),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  // ================= BOTTOM NAV =================

  Widget _buildBottomNav() {
    return SafeArea(
      top: false,
      child: Container(
        margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
        padding: const EdgeInsets.symmetric(vertical: 6),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 24,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _navItem(Icons.home, 'Trang chủ', 0),
            _navItem(Icons.calendar_today, 'Đặt sân', 1),
            _navItem(Icons.emoji_events, 'Giải đấu', 2),
            _navItem(Icons.account_balance_wallet, 'Ví', 3),
            _navItem(Icons.person, 'Cá nhân', 4),
          ],
        ),
      ),
    );
  }

  Widget _navItem(IconData icon, String label, int index) {
    final isActive = _currentIndex == index;

    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _currentIndex = index),
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isActive
                ? Colors.green.withOpacity(0.12)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 24,
                color: isActive ? Colors.green.shade600 : Colors.grey.shade500,
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                  color: isActive
                      ? Colors.green.shade600
                      : Colors.grey.shade500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
