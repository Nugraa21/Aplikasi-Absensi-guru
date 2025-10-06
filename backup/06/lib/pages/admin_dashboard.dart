import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import '../services/db_service.dart';

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
    final r = await DBService.getSetting('attendance_radius');
    radiusCtrl.text = r.isNotEmpty ? r : '1000';
    setState(() => loading = false);
  }

  Widget _glass({required Widget child}) => ClipRRect(
    borderRadius: BorderRadius.circular(12),
    child: BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withOpacity(0.06)),
        ),
        child: child,
      ),
    ),
  );

  Future<void> _approveUser(int id) async {
    await DBService.approveUser(id);
    await _loadAll();
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text("Akun disetujui")));
  }

  Future<void> _denyUser(int id) async {
    await DBService.denyUser(id);
    await _loadAll();
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text("Akun ditolak & dihapus")));
  }

  Future<void> _approveAttendance(int id) async {
    await DBService.approveAttendance(id);
    await _loadAll();
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text("Absensi disetujui")));
  }

  Future<void> _denyAttendance(int id) async {
    await DBService.denyAttendance(id);
    await _loadAll();
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text("Absensi dihapus")));
  }

  Future<void> _saveRadius() async {
    final val = radiusCtrl.text.trim();
    if (double.tryParse(val) == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Masukkan angka radius valid (meter)")),
      );
      return;
    }
    await DBService.setSetting('attendance_radius', val);
    await _loadAll();
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text("Radius disimpan")));
  }

  Widget _pendingUsersTab() => _glass(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Konfirmasi User Baru",
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        if (pendingUsers.isEmpty) const Text("Tidak ada pendaftaran baru."),
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: pendingUsers.length,
          separatorBuilder: (_, __) => const Divider(),
          itemBuilder: (ctx, i) {
            final u = pendingUsers[i];
            return ListTile(
              leading: CircleAvatar(
                child: Text(u['name']?.substring(0, 1) ?? '?'),
              ),
              title: Text(u['name'] ?? '-'),
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
      ],
    ),
  );

  Widget _allUsersTab() => _glass(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Semua User",
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: allUsers.length,
          separatorBuilder: (_, __) => const Divider(),
          itemBuilder: (ctx, i) {
            final u = allUsers[i];
            return ListTile(
              leading: CircleAvatar(
                backgroundImage: (u['photo'] ?? '').isNotEmpty
                    ? FileImage(File(u['photo']))
                    : null,
                child: (u['photo'] ?? '').isEmpty
                    ? const Icon(Icons.person)
                    : null,
              ),
              title: Text(u['name'] ?? '-'),
              subtitle: Text("${u['jabatan']} • ${u['kelas']}\n${u['email']}"),
              isThreeLine: true,
            );
          },
        ),
      ],
    ),
  );

  Widget _attendanceTab() => _glass(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Konfirmasi Absensi",
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: allAttendance.length,
          itemBuilder: (ctx, i) {
            final a = allAttendance[i];
            return Card(
              child: ListTile(
                leading: a['photo'] != null
                    ? Image.file(
                        File(a['photo']),
                        width: 64,
                        height: 64,
                        fit: BoxFit.cover,
                      )
                    : null,
                title: Text("${a['date']} ${a['time']}"),
                subtitle: FutureBuilder<Map<String, dynamic>?>(
                  future: DBService.getUserById(a['userId']),
                  builder: (context, snap) {
                    final u = snap.data;
                    return Text(
                      "Guru: ${u != null ? u['name'] : '-'}\nLokasi: ${a['location']}\nStatus: ${(a['approved'] ?? 0) == 1 ? 'Approved' : 'Pending'}",
                    );
                  },
                ),
                isThreeLine: true,
                trailing: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if ((a['approved'] ?? 0) == 0)
                      IconButton(
                        icon: const Icon(Icons.check, color: Colors.green),
                        onPressed: () => _approveAttendance(a['id']),
                      ),
                    IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () => _denyAttendance(a['id']),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    ),
  );

  Widget _radiusTab() => _glass(
    child: Row(
      children: [
        Expanded(
          child: TextField(
            controller: radiusCtrl,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Radius absensi (meter)',
            ),
          ),
        ),
        const SizedBox(width: 8),
        ElevatedButton(
          onPressed: _saveRadius,
          style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
          child: const Text("Simpan"),
        ),
      ],
    ),
  );

  @override
  Widget build(BuildContext context) {
    final tabs = [
      _pendingUsersTab(),
      _allUsersTab(),
      _attendanceTab(),
      _radiusTab(),
    ];
    return Scaffold(
      appBar: AppBar(
        title: const Text("Dashboard Admin"),
        backgroundColor: Colors.deepOrange,
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadAll,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                physics: const AlwaysScrollableScrollPhysics(),
                child: tabs[_currentIndex],
              ),
            ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        selectedItemColor: Colors.deepOrange,
        unselectedItemColor: Colors.grey,
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
