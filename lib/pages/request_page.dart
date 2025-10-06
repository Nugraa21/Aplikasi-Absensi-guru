// lib/pages/request_page.dart
// Page for teachers to submit special requests like meetings or early leave.

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/db_service.dart';

class RequestPage extends StatefulWidget {
  final Map<String, dynamic> user;
  const RequestPage({super.key, required this.user});

  @override
  State<RequestPage> createState() => _RequestPageState();
}

class _RequestPageState extends State<RequestPage> {
  final reasonCtrl = TextEditingController();
  String selectedType = 'rapat';
  bool loading = false;
  late Future<List<Map<String, dynamic>>> _future;

  @override
  void initState() {
    super.initState();
    _future = DBService.getRequests(userId: widget.user['id']);
  }

  Future<void> _submitRequest() async {
    if (reasonCtrl.text.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Isi alasan")));
      return;
    }
    setState(() => loading = true);
    final date = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final time = DateFormat('HH:mm:ss').format(DateTime.now());
    await DBService.saveRequest(
      widget.user['id'],
      date,
      time,
      reasonCtrl.text.trim(),
      selectedType,
    );
    reasonCtrl.clear();
    setState(() {
      loading = false;
      _future = DBService.getRequests(userId: widget.user['id']);
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Permintaan dikirim, tunggu approve admin")),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          const Text(
            "Permintaan Khusus",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          DropdownButton<String>(
            value: selectedType,
            isExpanded: true,
            items: const [
              DropdownMenuItem(value: 'rapat', child: Text('Rapat')),
              DropdownMenuItem(
                value: 'pulang_cepat',
                child: Text('Pulang Cepat'),
              ),
              DropdownMenuItem(value: 'lainnya', child: Text('Lainnya')),
            ],
            onChanged: (v) => setState(() => selectedType = v!),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: reasonCtrl,
            decoration: const InputDecoration(
              labelText: "Alasan",
              border: OutlineInputBorder(),
            ),
            maxLines: 3,
          ),
          const SizedBox(height: 8),
          ElevatedButton(
            onPressed: loading ? null : _submitRequest,
            child: loading
                ? const CircularProgressIndicator()
                : const Text("Kirim Permintaan"),
          ),
          const SizedBox(height: 16),
          const Text(
            "Riwayat Permintaan",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          Expanded(
            child: FutureBuilder<List<Map<String, dynamic>>>(
              future: _future,
              builder: (ctx, snap) {
                if (!snap.hasData)
                  return const Center(child: CircularProgressIndicator());
                final list = snap.data!;
                return ListView.builder(
                  itemCount: list.length,
                  itemBuilder: (ctx, i) {
                    final r = list[i];
                    final approved = (r['approved'] ?? 0) == 1;
                    return Card(
                      child: ListTile(
                        title: Text(
                          "${r['date']} ${r['time']} - ${r['type'].toUpperCase()}",
                        ),
                        subtitle: Text(
                          "Alasan: ${r['reason']}\nStatus: ${approved ? 'Approved' : 'Pending'}",
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
