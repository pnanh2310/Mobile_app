import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';

import '../../models/models.dart';
import '../../providers/providers.dart';
import '../../widgets/widgets.dart';

class BookingScreen extends StatefulWidget {
  const BookingScreen({super.key});

  @override
  State<BookingScreen> createState() => _BookingScreenState();
}

class _BookingScreenState extends State<BookingScreen> {
  DateTime _focusedDay = DateTime.now();
  DateTime _selectedDay = DateTime.now();
  CalendarFormat _calendarFormat = CalendarFormat.week;

  Court? _selectedCourt;
  TimeOfDay _startTime = const TimeOfDay(hour: 8, minute: 0);
  TimeOfDay _endTime = const TimeOfDay(hour: 9, minute: 0);

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final bookingProvider = context.read<BookingProvider>();
    await bookingProvider.loadCourts();
    await _loadCalendar();

    if (bookingProvider.courts.isNotEmpty) {
      _selectedCourt = bookingProvider.courts.first;
      setState(() {});
    }
  }

  Future<void> _loadCalendar() async {
    final from = _focusedDay.subtract(const Duration(days: 7));
    final to = _focusedDay.add(const Duration(days: 14));
    await context.read<BookingProvider>().loadCalendar(from, to);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FB),
      appBar: AppBar(
        title: const Text(
          'Đặt sân',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.list_alt_rounded),
            onPressed: _showMyBookings,
          ),
        ],
      ),
      body: Consumer<BookingProvider>(
        builder: (context, booking, _) {
          return LoadingOverlay(
            isLoading: booking.isLoading,
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _sectionTitle('Chọn ngày'),
                  _buildCalendar(),

                  const SizedBox(height: 24),
                  _sectionTitle('Chọn sân'),
                  _buildCourtSelector(booking.courts),

                  const SizedBox(height: 24),
                  _sectionTitle('Chọn thời gian'),
                  _buildTimeSelector(),

                  const SizedBox(height: 24),
                  _sectionTitle('Tóm tắt'),
                  _buildBookingSummary(),

                  const SizedBox(height: 24),
                  _buildBookingSlots(booking.calendarSlots),

                  const SizedBox(height: 32),
                  PrimaryButton(
                    text: 'Đặt sân',
                    icon: Icons.check_circle_outline,
                    onPressed: _createBooking,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // ================= SECTION =================

  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Container(
            width: 5,
            height: 22,
            decoration: BoxDecoration(
              color: ThemeProvider.primaryColor,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(width: 10),
          Text(
            title,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  // ================= CALENDAR =================

  Widget _buildCalendar() {
    return GlassCard(
      child: TableCalendar(
        firstDay: DateTime.now().subtract(const Duration(days: 30)),
        lastDay: DateTime.now().add(const Duration(days: 90)),
        focusedDay: _focusedDay,
        calendarFormat: _calendarFormat,
        selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
        onDaySelected: (selectedDay, focusedDay) {
          _selectedDay = selectedDay;
          _focusedDay = focusedDay;
          setState(() {});
          _loadCalendar();
        },
        onFormatChanged: (format) {
          _calendarFormat = format;
          setState(() {});
        },
        onPageChanged: (focusedDay) {
          _focusedDay = focusedDay;
          _loadCalendar();
        },
        calendarStyle: CalendarStyle(
          todayDecoration: BoxDecoration(
            color: ThemeProvider.primaryColor.withOpacity(0.25),
            shape: BoxShape.circle,
          ),
          selectedDecoration: BoxDecoration(
            color: ThemeProvider.primaryColor,
            shape: BoxShape.circle,
          ),
        ),
        headerStyle: const HeaderStyle(
          titleCentered: true,
          formatButtonVisible: true,
        ),
      ),
    );
  }

  // ================= COURT =================

  Widget _buildCourtSelector(List<Court> courts) {
    return GlassCard(
      child: courts.isEmpty
          ? const Text('Không có sân nào')
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: courts.map((court) {
                    final isSelected = _selectedCourt?.id == court.id;
                    return ChoiceChip(
                      label: Text(court.name),
                      selected: isSelected,
                      selectedColor: ThemeProvider.primaryColor,
                      labelStyle: TextStyle(
                        color: isSelected ? Colors.white : Colors.black87,
                        fontWeight: FontWeight.w600,
                      ),
                      onSelected: (_) {
                        _selectedCourt = court;
                        setState(() {});
                      },
                    );
                  }).toList(),
                ),
                if (_selectedCourt != null) ...[
                  const SizedBox(height: 14),
                  Text(
                    'Giá: ${NumberFormat.currency(locale: 'vi_VN', symbol: '₫').format(_selectedCourt!.pricePerHour)}/giờ',
                    style: TextStyle(
                      color: ThemeProvider.accentColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ],
            ),
    );
  }

  // ================= TIME =================

  Widget _buildTimeSelector() {
    return GlassCard(
      child: Row(
        children: [
          Expanded(
            child: _timeBox(
              'Từ',
              _startTime,
              (t) => setState(() => _startTime = t),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: _timeBox(
              'Đến',
              _endTime,
              (t) => setState(() => _endTime = t),
            ),
          ),
        ],
      ),
    );
  }

  Widget _timeBox(
    String label,
    TimeOfDay time,
    ValueChanged<TimeOfDay> onChanged,
  ) {
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: () async {
        final picked = await showTimePicker(
          context: context,
          initialTime: time,
        );
        if (picked != null) onChanged(picked);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.withOpacity(0.25)),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          children: [
            Text(label, style: const TextStyle(color: Colors.grey)),
            const SizedBox(height: 6),
            Text(
              time.format(context),
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }

  // ================= SUMMARY =================

  Widget _buildBookingSummary() {
    if (_selectedCourt == null) return const SizedBox();

    final start = DateTime(
      _selectedDay.year,
      _selectedDay.month,
      _selectedDay.day,
      _startTime.hour,
      _startTime.minute,
    );
    final end = DateTime(
      _selectedDay.year,
      _selectedDay.month,
      _selectedDay.day,
      _endTime.hour,
      _endTime.minute,
    );

    final hours = end.difference(start).inMinutes / 60;
    final total = hours * _selectedCourt!.pricePerHour;

    return GlassCard(
      child: Column(
        children: [
          _summaryRow('Ngày', DateFormat('dd/MM/yyyy').format(_selectedDay)),
          _summaryRow('Sân', _selectedCourt!.name),
          _summaryRow('Thời gian', '${hours.toStringAsFixed(1)} giờ'),
          const Divider(height: 26),
          _summaryRow(
            'Tổng tiền',
            NumberFormat.currency(locale: 'vi_VN', symbol: '₫').format(total),
            highlight: true,
          ),
        ],
      ),
    );
  }

  Widget _summaryRow(String label, String value, {bool highlight = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: highlight ? 18 : null,
              color: highlight ? ThemeProvider.primaryColor : null,
            ),
          ),
        ],
      ),
    );
  }

  // ================= BOOKED SLOTS =================

  Widget _buildBookingSlots(List<CalendarSlot> slots) {
    final daySlots = slots.where((s) {
      return s.startTime.year == _selectedDay.year &&
          s.startTime.month == _selectedDay.month &&
          s.startTime.day == _selectedDay.day &&
          (_selectedCourt == null || s.courtId == _selectedCourt!.id);
    }).toList();

    if (daySlots.isEmpty) return const SizedBox();

    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Lịch đã đặt trong ngày',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          ...daySlots.map((slot) {
            final color = slot.isMyBooking
                ? ThemeProvider.primaryColor
                : Colors.red;
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Text(
                    '${DateFormat.Hm().format(slot.startTime)} - ${DateFormat.Hm().format(slot.endTime)}',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const Spacer(),
                  Text(
                    slot.isMyBooking ? 'Của bạn' : 'Đã đặt',
                    style: TextStyle(color: color),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  // ================= ACTIONS =================

  Future<void> _createBooking() async {
    if (_selectedCourt == null) return;

    final start = DateTime(
      _selectedDay.year,
      _selectedDay.month,
      _selectedDay.day,
      _startTime.hour,
      _startTime.minute,
    );
    final end = DateTime(
      _selectedDay.year,
      _selectedDay.month,
      _selectedDay.day,
      _endTime.hour,
      _endTime.minute,
    );

    if (!end.isAfter(start)) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Giờ không hợp lệ')));
      return;
    }

    final success = await context.read<BookingProvider>().createBooking(
      _selectedCourt!.id,
      start,
      end,
    );

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(success ? 'Đặt sân thành công' : 'Đặt sân thất bại'),
        backgroundColor: success ? Colors.green : Colors.red,
      ),
    );

    if (success) {
      await _loadCalendar();
      context.read<WalletProvider>().loadBalance();
      context.read<AuthProvider>().refreshUser();
    }
  }

  void _showMyBookings() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) {
        context.read<BookingProvider>().loadMyBookings();
        return const Center(child: Text('My bookings'));
      },
    );
  }
}
