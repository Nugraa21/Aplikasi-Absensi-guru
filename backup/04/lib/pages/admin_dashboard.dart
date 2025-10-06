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
  List<Map<String, dynamic>> users = [];
  List<Map<String, dynamic>> attends = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    _loadAll();
  }

  Future<void> _loadAll() async {
    setState(() => loading = true);
    users = await DBService.getAllUsers();
    attends = await DBService.getAllAttendance();
    setState(() => loading = false);
  }

  Widget _glass({required Widget child}) {
    return ClipRRect(
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
  }

  Future<void> _approve(int id) async {
    await DBService.approveAttendance(id);
    await _loadAll();
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text("Absensi disetujui")));
  }

  Future<void> _delAttendance(int id) async {
    await DBService.deleteAttendance(id);
    await _loadAll();
  }

  Future<void> _delUser(int id) async {
    await DBService.deleteUser(id);
    await _loadAll();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Admin Dashboard"),
        backgroundColor: Colors.orange,
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadAll,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    _glass(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "Daftar Guru & Admin",
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          ListView.separated(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: users.length,
                            separatorBuilder: (_, __) => const Divider(),
                            itemBuilder: (ctx, i) {
                              final u = users[i];
                              return ListTile(
                                leading: CircleAvatar(
                                  backgroundImage: (u['photo'] ?? '').isNotEmpty
                                      ? FileImage(File(u['photo']))
                                            as ImageProvider
                                      : null,
                                  child: (u['photo'] ?? '').isEmpty
                                      ? const Icon(Icons.person)
                                      : null,
                                ),
                                title: Text(u['name'] ?? '-'),
                                subtitle: Text(
                                  "${u['email']}\nNIP: ${u['nip'] ?? '-'}",
                                ),
                                isThreeLine: true,
                                trailing: IconButton(
                                  icon: const Icon(
                                    Icons.delete,
                                    color: Colors.red,
                                  ),
                                  onPressed: () => _delUser(u['id']),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    _glass(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "Riwayat Absensi (Semua)",
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: attends.length,
                            itemBuilder: (ctx, i) {
                              final a = attends[i];
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
                                      final user = snap.data;
                                      return Text(
                                        "Guru: ${user != null ? user['name'] : '-'}\nLokasi: ${a['location']}\nStatus: ${(a['approved'] ?? 0) == 1 ? 'Approved' : 'Pending'}",
                                      );
                                    },
                                  ),
                                  isThreeLine: true,
                                  trailing: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      if ((a['approved'] ?? 0) == 0)
                                        IconButton(
                                          icon: const Icon(
                                            Icons.check,
                                            color: Colors.green,
                                          ),
                                          onPressed: () => _approve(a['id']),
                                        ),
                                      IconButton(
                                        icon: const Icon(
                                          Icons.delete,
                                          color: Colors.red,
                                        ),
                                        onPressed: () =>
                                            _delAttendance(a['id']),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
