import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // Import fix untuk DateFormat
import 'attendance_page.dart';
import 'history_page.dart';
import 'profile_page.dart';
import 'admin_dashboard.dart';
import 'login_page.dart';
import '../services/db_service.dart';

class HomePage extends StatefulWidget {
  final Map<String, dynamic> user;
  const HomePage({super.key, required this.user});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int currentIndex = 0;
  late final List<Widget> pages;
  bool hasCheckInToday = false;
  bool hasCheckOutToday = false;

  @override
  void initState() {
    super.initState();
    pages = [
      AttendancePage(user: widget.user),
      HistoryPage(user: widget.user),
      ProfilePage(user: widget.user),
    ];
    _loadTodayStatus();
  }

  Future<void> _loadTodayStatus() async {
    final todayAttendance = await DBService.getAttendance(widget.user['id']);
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    hasCheckInToday = todayAttendance.any(
      (a) =>
          a['date'] == today &&
          a['type'] == 'masuk' &&
          (a['approved'] ?? 0) == 1,
    );
    hasCheckOutToday = todayAttendance.any(
      (a) =>
          a['date'] == today &&
          a['type'] == 'pulang' &&
          (a['approved'] ?? 0) == 1,
    );
    if (mounted) setState(() {});
  }

  void _logout() {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginPage()),
      (r) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isAdmin = (widget.user['isAdmin'] ?? 0) == 1;
    return Scaffold(
      appBar: AppBar(
        title: Text("Halo, ${widget.user['name'] ?? 'User'}"),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _logout,
            tooltip: 'Logout',
          ),
          if (isAdmin)
            IconButton(
              icon: const Icon(Icons.admin_panel_settings),
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AdminDashboard()),
              ),
              tooltip: 'Admin Dashboard',
            ),
        ],
      ),
      body: Column(
        children: [
          if (!isAdmin && currentIndex == 0)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              color: hasCheckInToday && hasCheckOutToday
                  ? Colors.green[100]!
                  : hasCheckInToday
                  ? Colors.orange[100]!
                  : Colors.red[100]!,
              child: Column(
                children: [
                  Text(
                    "Status Hari Ini (${DateFormat('yyyy-MM-dd').format(DateTime.now())})",
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text(
                    hasCheckInToday
                        ? "✓ Sudah absen masuk"
                        : "• Belum absen masuk (jam 6:00 pagi)",
                  ),
                  Text(
                    hasCheckOutToday
                        ? "✓ Sudah absen pulang"
                        : "• Belum absen pulang (jam 4:00 sore)",
                  ),
                ],
              ),
            ),
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 250),
              child: pages[currentIndex],
            ),
          ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: currentIndex,
        selectedItemColor: Colors.green,
        onTap: (i) {
          setState(() => currentIndex = i);
          if (i == 1) _loadTodayStatus();
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.camera_alt),
            label: 'Absensi',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.history), label: 'Riwayat'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profil'),
        ],
      ),
    );
  }
}
