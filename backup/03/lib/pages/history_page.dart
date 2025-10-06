import 'dart:io';
import 'package:flutter/material.dart';
import '../services/db_service.dart';

class HistoryPage extends StatelessWidget {
  final Map<String, dynamic> user;
  const HistoryPage({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Riwayat Absensi")),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: DBService.getAttendance(user['id']),
        builder: (context, snapshot) {
          if (!snapshot.hasData)
            return const Center(child: CircularProgressIndicator());
          final data = snapshot.data!;
          if (data.isEmpty)
            return const Center(child: Text("Belum ada absensi."));
          return ListView.builder(
            itemCount: data.length,
            itemBuilder: (context, i) {
              final item = data[i];
              return Card(
                child: ListTile(
                  leading: Image.file(
                    File(item['photo']),
                    width: 50,
                    height: 50,
                    fit: BoxFit.cover,
                  ),
                  title: Text("${item['date']} ${item['time']}"),
                  subtitle: Text("Lokasi: ${item['location']}"),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
