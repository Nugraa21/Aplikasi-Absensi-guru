import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // Untuk DateFormat di DBService
import '../services/db_service.dart';
import 'user_detail_page.dart'; // Halaman baru

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  int _currentIndex = 0;

  List<Map<String, dynamic>> pendingUsers = [];
  List<Map<String, dynamic>> allUsers = [];
  List<Map<String, dynamic>> allAttendance = [];
  int todayAttendanceCount = 0;
  final radiusCtrl = TextEditingController();
  bool loading = true;

  @override
  void initState() {
    super.initState();
    _loadAll();
  }

  Future<void> _loadAll() async {
    setState(() => loading = true);
    pendingUsers = await DBService.getPendingUsers();
    allUsers = await DBService.getAllUsers();
    allAttendance = await DBService.getAllAttendance();
    todayAttendanceCount =
        await DBService.getTodayAttendanceCount(); // Summary baru
    final r = await DBService.getSetting('attendance_radius');
    radiusCtrl.text = r.isNotEmpty ? r : '1000';

    // Debug print: Cek data di console
    print(
      'Loaded: Pending=${pendingUsers.length}, AllUsers=${allUsers.length}, Attendance=${allAttendance.length}, Today=${todayAttendanceCount}',
    );

    setState(() => loading = false);
  }

  Widget _glass({required Widget child}) => ClipRRect(
    borderRadius: BorderRadius.circular(16), // Lebih bulat
    child: BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10), // Blur lebih halus
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Colors.green.withOpacity(0.2),
          ), // Border hijau
          boxShadow: [
            BoxShadow(color: Colors.green.withOpacity(0.1), blurRadius: 10),
          ], // Shadow lembut
        ),
        child: child,
      ),
    ),
  );

  Future<void> _approveUser(int id) async {
    await DBService.approveUser(id);
    await _loadAll();
    if (mounted)
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Akun disetujui")));
  }

  Future<void> _denyUser(int id) async {
    await DBService.denyUser(id);
    await _loadAll();
    if (mounted)
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Akun ditolak & dihapus")));
  }

  Future<void> _approveAttendance(int id) async {
    await DBService.approveAttendance(id);
    await _loadAll();
    if (mounted)
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Absensi disetujui")));
  }

  Future<void> _denyAttendance(int id) async {
    await DBService.denyAttendance(id);
    await _loadAll();
    if (mounted)
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Absensi dihapus")));
  }

  Future<void> _saveRadius() async {
    final val = radiusCtrl.text.trim();
    if (double.tryParse(val) == null) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Masukkan angka radius valid (meter)")),
        );
      return;
    }
    await DBService.setSetting('attendance_radius', val);
    await _loadAll();
    if (mounted)
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Radius disimpan")));
  }

  // Summary Cards (fitur baru)
  Widget _buildSummary() => Padding(
    padding: const EdgeInsets.all(16),
    child: Row(
      children: [
        Expanded(
          child: _summaryCard(
            Icons.people,
            "Total User",
            allUsers.length.toString(),
            Colors.green[300]!,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _summaryCard(
            Icons.pending,
            "Pending",
            pendingUsers.length.toString(),
            Colors.orange,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _summaryCard(
            Icons.check_circle,
            "Absen Hari Ini",
            todayAttendanceCount.toString(),
            Colors.green[600]!,
          ),
        ),
      ],
    ),
  );

  Widget _summaryCard(IconData icon, String title, String value, Color color) =>
      Card(
        elevation: 4,
        color: Colors.white,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
              Icon(icon, color: color, size: 32),
              const SizedBox(height: 4),
              Text(
                value,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(title, style: const TextStyle(color: Colors.grey)),
            ],
          ),
        ),
      );

  Widget _pendingUsersTab() => Container(
    // Wrap di Container biar height aman
    height: double.infinity,
    child: _glass(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "Konfirmasi User Baru",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              Text(
                "${pendingUsers.length}",
                style: TextStyle(color: Colors.green[600], fontSize: 16),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (pendingUsers.isEmpty)
            const Expanded(
              // Expanded di sini biar center fill space
              child: Center(
                child: Text(
                  "Tidak ada pendaftaran baru.",
                  style: TextStyle(color: Colors.grey),
                ),
              ),
            )
          else
            Expanded(
              child: ListView.separated(
                itemCount: pendingUsers.length,
                separatorBuilder: (_, __) => const Divider(),
                itemBuilder: (ctx, i) {
                  final u = pendingUsers[i];
                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Colors.green[100],
                      child: Text(
                        u['name']?.substring(0, 1) ?? '?',
                        style: const TextStyle(color: Colors.green),
                      ),
                    ),
                    title: Text(
                      u['name'] ?? '-',
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    ),
                    subtitle: Text(
                      "${u['jabatan'] ?? '-'} • ${u['kelas'] ?? '-'}\n${u['email']}",
                    ),
                    isThreeLine: true,
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.check, color: Colors.green),
                          onPressed: () => _approveUser(u['id']),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, color: Colors.red),
                          onPressed: () => _denyUser(u['id']),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    ),
  );

  Widget _allUsersTab() => Container(
    // Wrap di Container
    height: double.infinity,
    child: _glass(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Semua User",
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: LayoutBuilder(
              builder: (ctx, constraints) {
                if (constraints.maxWidth > 600) {
                  // Grid untuk layar lebar
                  return GridView.builder(
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          childAspectRatio: 1.2,
                        ),
                    itemCount: allUsers.length,
                    itemBuilder: (ctx, i) => _userCard(allUsers[i]),
                  );
                } else {
                  // List untuk mobile
                  return allUsers.isEmpty
                      ? const Center(
                          child: Text(
                            "Belum ada user.",
                            style: TextStyle(color: Colors.grey),
                          ),
                        )
                      : ListView.separated(
                          itemCount: allUsers.length,
                          separatorBuilder: (_, __) => const Divider(),
                          itemBuilder: (ctx, i) =>
                              _userCard(allUsers[i], isList: true),
                        );
                }
              },
            ),
          ),
        ],
      ),
    ),
  );

  Widget _userCard(Map<String, dynamic> u, {bool isList = false}) => Card(
    margin: EdgeInsets.symmetric(horizontal: isList ? 0 : 8, vertical: 4),
    child: InkWell(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => UserDetailPage(user: u)),
      ),
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            CircleAvatar(
              radius: 30,
              backgroundImage: (u['photo'] ?? '').isNotEmpty
                  ? FileImage(File(u['photo']))
                  : null,
              child: (u['photo'] ?? '').isEmpty
                  ? const Icon(Icons.person, color: Colors.green)
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    u['name'] ?? '-',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  Text(
                    "${u['jabatan']} • ${u['kelas']}",
                    style: const TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            ),
            FutureBuilder<bool>(
              future: DBService.hasTodayAttendance(u['id']),
              builder: (ctx, snap) {
                if (!snap.hasData) return const SizedBox();
                return snap.data!
                    ? Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: Colors.green,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.check,
                          color: Colors.white,
                          size: 16,
                        ),
                      )
                    : const Icon(Icons.schedule, color: Colors.grey);
              },
            ),
          ],
        ),
      ),
    ),
  );

  Widget _attendanceTab() => Container(
    // Wrap di Container
    height: double.infinity,
    child: _glass(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Konfirmasi Absensi",
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: allAttendance.isEmpty
                ? const Center(
                    child: Text(
                      "Belum ada absensi.",
                      style: TextStyle(color: Colors.grey),
                    ),
                  )
                : ListView.builder(
                    itemCount: allAttendance.length,
                    itemBuilder: (ctx, i) {
                      final a = allAttendance[i];
                      return Card(
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        child: ListTile(
                          leading: a['photo'] != null
                              ? ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Image.file(
                                    File(a['photo']),
                                    width: 64,
                                    height: 64,
                                    fit: BoxFit.cover,
                                  ),
                                )
                              : null,
                          title: Text(
                            "${a['date']} ${a['time']}",
                            style: const TextStyle(fontWeight: FontWeight.w500),
                          ),
                          subtitle: FutureBuilder<Map<String, dynamic>?>(
                            future: DBService.getUserById(a['userId']),
                            builder: (context, snap) {
                              final u = snap.data;
                              return Text(
                                "${u != null ? u['name'] : '-'} • ${a['location']}\nStatus: ${(a['approved'] ?? 0) == 1 ? 'Approved' : 'Pending'}",
                              );
                            },
                          ),
                          trailing: ((a['approved'] ?? 0) == 0)
                              ? IconButton(
                                  icon: const Icon(
                                    Icons.check,
                                    color: Colors.green,
                                  ),
                                  onPressed: () => _approveAttendance(a['id']),
                                )
                              : null,
                          onLongPress: () =>
                              _denyAttendance(a['id']), // Long press untuk deny
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    ),
  );

  Widget _radiusTab() => Container(
    // Wrap di Container
    height: double.infinity,
    child: _glass(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Pengaturan Radius Absensi",
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: radiusCtrl,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: 'Radius (meter)',
              prefixIcon: const Icon(Icons.location_on),
              border: const OutlineInputBorder(
                borderRadius: BorderRadius.all(Radius.circular(12)),
              ),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _saveRadius,
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
              child: const Text("Simpan"),
            ),
          ),
          const Spacer(), // Biar content di atas, space di bawah
        ],
      ),
    ),
  );

  @override
  Widget build(BuildContext context) {
    // Hapus Expanded dari list tabs – sekarang list biasa
    final tabs = [
      _pendingUsersTab(),
      _allUsersTab(),
      _attendanceTab(),
      _radiusTab(),
    ];
    return Scaffold(
      appBar: AppBar(
        title: const Text("Dashboard Admin"),
        backgroundColor: Colors.green, // Hijau
        foregroundColor: Colors.white,
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadAll),
        ],
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator(color: Colors.green))
          : RefreshIndicator(
              onRefresh: _loadAll,
              color: Colors.green,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  children: [
                    _buildSummary(), // Summary cards
                    const SizedBox(height: 16),
                    // Gunakan Container biar fill space, tanpa fixed height
                    Container(
                      height:
                          MediaQuery.of(context).size.height *
                          0.6, // Adjust ~60% screen, biar scrollable
                      width: double.infinity,
                      child: tabs[_currentIndex],
                    ),
                  ],
                ),
              ),
            ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        selectedItemColor: Colors.green,
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
        onTap: (i) => setState(() => _currentIndex = i),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.person_add),
            label: "User Baru",
          ),
          BottomNavigationBarItem(icon: Icon(Icons.group), label: "User"),
          BottomNavigationBarItem(
            icon: Icon(Icons.assignment),
            label: "Absensi",
          ),
          BottomNavigationBarItem(icon: Icon(Icons.settings), label: "Radius"),
        ],
      ),
    );
  }
}
