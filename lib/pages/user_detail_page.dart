// lib/pages/user_detail_page.dart
// Page for admin to view and edit user details, attendance history with popups for photos and editing times.

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/db_service.dart';

class UserDetailPage extends StatefulWidget {
  final Map<String, dynamic> user;
  const UserDetailPage({super.key, required this.user});

  @override
  State<UserDetailPage> createState() => _UserDetailPageState();
}

class _UserDetailPageState extends State<UserDetailPage> {
  late Future<List<Map<String, dynamic>>> _future;
  late TextEditingController nameCtrl;
  late TextEditingController nipCtrl;
  late TextEditingController jabatanCtrl;
  late TextEditingController kelasCtrl;
  String photoPath = '';
  bool editingUser = false;

  @override
  void initState() {
    super.initState();
    _future = DBService.getAttendance(widget.user['id']);
    nameCtrl = TextEditingController(text: widget.user['name']);
    nipCtrl = TextEditingController(text: widget.user['nip']);
    jabatanCtrl = TextEditingController(text: widget.user['jabatan']);
    kelasCtrl = TextEditingController(text: widget.user['kelas']);
    photoPath = widget.user['photo'] ?? '';
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

  Future<void> _editAttendance(Map<String, dynamic> att) async {
    final timeCtrl = TextEditingController(text: att['time']);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Edit Waktu Absensi"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (att['photo'] != null)
              Image.file(File(att['photo']), height: 200),
            TextField(
              controller: timeCtrl,
              decoration: const InputDecoration(labelText: "Waktu (HH:mm:ss)"),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Batal"),
          ),
          ElevatedButton(
            onPressed: () async {
              await DBService.updateAttendanceTime(att['id'], timeCtrl.text);
              Navigator.pop(ctx);
              _refresh();
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(const SnackBar(content: Text("Waktu diupdate")));
            },
            child: const Text("Simpan"),
          ),
        ],
      ),
    );
  }

  Future<void> _showAttendancePopup(Map<String, dynamic> att) async {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          "${att['date']} ${att['time']} - ${att['type'].toUpperCase()}",
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (att['photo'] != null)
              Image.file(File(att['photo']), height: 200),
            Text("Lokasi: ${att['location']}"),
            Text(
              "Status: ${(att['approved'] ?? 0) == 1 ? 'Approved' : 'Pending'}",
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Tutup"),
          ),
          if ((att['approved'] ?? 0) == 0)
            ElevatedButton(
              onPressed: () {
                Navigator.pop(ctx);
                _approveAttendance(att['id']);
              },
              child: const Text("Setujui"),
            ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              _editAttendance(att);
            },
            child: const Text("Edit Waktu"),
          ),
        ],
      ),
    );
  }

  Future<void> _saveUserEdit() async {
    await DBService.updateProfile(
      widget.user['id'],
      nameCtrl.text,
      nipCtrl.text,
      jabatanCtrl.text,
      kelasCtrl.text,
      photoPath,
    );
    setState(() => editingUser = false);
    _refresh();
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text("Profil diupdate")));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.user['name'] ?? 'User'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: Icon(editingUser ? Icons.save : Icons.edit),
            onPressed: editingUser
                ? _saveUserEdit
                : () => setState(() => editingUser = true),
          ),
        ],
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done)
            return const Center(
              child: CircularProgressIndicator(color: Colors.green),
            );
          final list = snap.data ?? [];
          final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
          final todayAttendance = list
              .where((a) => a['date'] == today)
              .toList();
          final hasCheckIn = todayAttendance.any(
            (a) => a['type'] == 'masuk' && (a['approved'] ?? 0) == 1,
          );
          final hasCheckOut = todayAttendance.any(
            (a) => a['type'] == 'pulang' && (a['approved'] ?? 0) == 1,
          );
          return RefreshIndicator(
            onRefresh: _refresh,
            color: Colors.green,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          CircleAvatar(
                            radius: 40,
                            backgroundImage: photoPath.isNotEmpty
                                ? FileImage(File(photoPath))
                                : null,
                            child: photoPath.isEmpty
                                ? const Icon(
                                    Icons.person,
                                    size: 40,
                                    color: Colors.green,
                                  )
                                : null,
                          ),
                          const SizedBox(height: 12),
                          if (editingUser)
                            TextField(
                              controller: nameCtrl,
                              decoration: const InputDecoration(
                                labelText: "Nama",
                              ),
                            ),
                          if (!editingUser)
                            Text(
                              widget.user['name'] ?? '-',
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          if (editingUser)
                            TextField(
                              controller: jabatanCtrl,
                              decoration: const InputDecoration(
                                labelText: "Jabatan",
                              ),
                            ),
                          if (editingUser)
                            TextField(
                              controller: kelasCtrl,
                              decoration: const InputDecoration(
                                labelText: "Kelas",
                              ),
                            ),
                          if (!editingUser)
                            Text(
                              "${widget.user['jabatan']} • ${widget.user['kelas']}",
                              style: const TextStyle(color: Colors.grey),
                            ),
                          if (editingUser)
                            TextField(
                              controller: nipCtrl,
                              decoration: const InputDecoration(
                                labelText: "NIP",
                              ),
                            ),
                          if (!editingUser)
                            Text(
                              "NIP: ${widget.user['nip'] ?? '-'} | Email: ${widget.user['email'] ?? '-'}",
                            ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Card(
                    color: hasCheckIn && hasCheckOut
                        ? Colors.green[50]
                        : Colors.orange[50],
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          const Text(
                            "Status Hari Ini",
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(today),
                          Text(
                            hasCheckIn
                                ? "✓ Masuk: Approved"
                                : "• Masuk: Belum/Tidak Approved",
                          ),
                          Text(
                            hasCheckOut
                                ? "✓ Pulang: Approved"
                                : "• Pulang: Belum/Tidak Approved",
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
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
                    ),
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
                          onTap: () => _showAttendancePopup(a),
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
                            "${a['date']} ${a['time']} - ${a['type'].toUpperCase()}",
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
            ),
          );
        },
      ),
    );
  }
}
