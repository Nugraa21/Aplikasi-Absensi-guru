import 'dart:io';
import 'package:flutter/material.dart';
import '../services/db_service.dart';

class HistoryPage extends StatefulWidget {
  final Map<String, dynamic> user;
  const HistoryPage({super.key, required this.user});

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  late Future<List<Map<String, dynamic>>> _future;

  @override
  void initState() {
    super.initState();
    _future = DBService.getAttendance(widget.user['id']);
  }

  Future<void> _refresh() async {
    setState(() {
      _future = DBService.getAttendance(widget.user['id']);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done)
            return const Center(child: CircularProgressIndicator());
          final list = snap.data ?? [];
          if (list.isEmpty)
            return Center(
              child: Text(
                "Belum ada absensi.",
                style: TextStyle(color: Colors.grey.shade700),
              ),
            );
          return RefreshIndicator(
            onRefresh: _refresh,
            child: ListView.builder(
              itemCount: list.length,
              itemBuilder: (ctx, i) {
                final a = list[i];
                final approved = (a['approved'] ?? 0) == 1;
                return Card(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  child: ListTile(
                    leading: a['photo'] != null
                        ? Image.file(
                            File(a['photo']),
                            width: 56,
                            height: 56,
                            fit: BoxFit.cover,
                          )
                        : null,
                    title: Text("${a['date']} ${a['time']}"),
                    subtitle: Text(
                      "Lokasi: ${a['location']}\nStatus: ${approved ? 'Approved' : 'Pending'}",
                    ),
                    isThreeLine: true,
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
