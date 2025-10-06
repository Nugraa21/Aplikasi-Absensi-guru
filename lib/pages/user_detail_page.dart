import 'dart:io';
import 'package:flutter/material.dart';
import '../services/db_service.dart';

class UserDetailPage extends StatefulWidget {
  final Map<String, dynamic> user;
  const UserDetailPage({super.key, required this.user});

  @override
  State<UserDetailPage> createState() => _UserDetailPageState();
}

class _UserDetailPageState extends State<UserDetailPage> {
  late Future<List<Map<String, dynamic>>> _future;

  @override
  void initState() {
    super.initState();
    _future = DBService.getAttendance(widget.user['id']);
  }

  Future<void> _refresh() async {
    setState(() => _future = DBService.getAttendance(widget.user['id']));
  }

  Future<void> _approveAttendance(int id) async {
    await DBService.approveAttendance(id);
    await _refresh();
    if (mounted)
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Absensi disetujui")));
  }

  Future<void> _denyAttendance(int id) async {
    await DBService.denyAttendance(id);
    await _refresh();
    if (mounted)
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Absensi dihapus")));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.user['name'] ?? 'User'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done)
            return const Center(
              child: CircularProgressIndicator(color: Colors.green),
            );
          final list = snap.data ?? [];
          return RefreshIndicator(
            onRefresh: _refresh,
            color: Colors.green,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Info user
                  Card(
                    elevation: 4,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          CircleAvatar(
                            radius: 40,
                            backgroundImage:
                                (widget.user['photo'] ?? '').isNotEmpty
                                ? FileImage(File(widget.user['photo']))
                                : null,
                            child: (widget.user['photo'] ?? '').isEmpty
                                ? const Icon(
                                    Icons.person,
                                    size: 40,
                                    color: Colors.green,
                                  )
                                : null,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            widget.user['name'] ?? '-',
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            "${widget.user['jabatan']} • ${widget.user['kelas']}",
                            style: const TextStyle(color: Colors.grey),
                          ),
                          Text(
                            "NIP: ${widget.user['nip'] ?? '-'} | Email: ${widget.user['email'] ?? '-'}",
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Riwayat absensi
                  Text(
                    "Riwayat Absensi (${list.length})",
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (list.isEmpty)
                    const Center(
                      child: Text(
                        "Belum ada absensi.",
                        style: TextStyle(color: Colors.grey),
                      ),
                    )
                  else
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: list.length,
                      itemBuilder: (ctx, i) {
                        final a = list[i];
                        final approved = (a['approved'] ?? 0) == 1;
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
                              style: const TextStyle(
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            subtitle: Text(
                              "Lokasi: ${a['location']}\nStatus: ${approved ? 'Approved' : 'Pending'}",
                            ),
                            trailing: approved
                                ? const Icon(
                                    Icons.check_circle,
                                    color: Colors.green,
                                  )
                                : Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      IconButton(
                                        icon: const Icon(
                                          Icons.check,
                                          color: Colors.green,
                                        ),
                                        onPressed: () =>
                                            _approveAttendance(a['id']),
                                      ),
                                      IconButton(
                                        icon: const Icon(
                                          Icons.delete,
                                          color: Colors.red,
                                        ),
                                        onPressed: () =>
                                            _denyAttendance(a['id']),
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
          );
        },
      ),
    );
  }
}
