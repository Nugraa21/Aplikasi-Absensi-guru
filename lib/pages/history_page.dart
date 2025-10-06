// lib/pages/history_page.dart
// Page to view attendance history with filters and popups for details.

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/db_service.dart';

class HistoryPage extends StatefulWidget {
  final Map<String, dynamic> user;
  const HistoryPage({super.key, required this.user});

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  DateTime? selectedDate;
  String selectedType = 'semua';
  late Future<List<Map<String, dynamic>>> _future;

  @override
  void initState() {
    super.initState();
    selectedDate = DateTime.now();
    _future = DBService.getAttendance(widget.user['id']);
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: selectedDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null) setState(() => selectedDate = picked);
  }

  Future<void> _refresh() async {
    setState(() {
      _future = DBService.getAttendance(widget.user['id']);
    });
  }

  void _showPopup(Map<String, dynamic> a) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text("${a['date']} ${a['time']} - ${a['type'].toUpperCase()}"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (a['photo'] != null)
              Image.file(File(a['photo']), height: 200, fit: BoxFit.cover),
            Text("Lokasi: ${a['location']}"),
            Text(
              "Status: ${(a['approved'] ?? 0) == 1 ? 'Approved' : 'Pending'}",
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Tutup"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _future,
      builder: (context, snap) {
        if (snap.connectionState != ConnectionState.done)
          return const Center(
            child: CircularProgressIndicator(color: Colors.green),
          );
        var list = snap.data ?? [];
        if (selectedDate != null) {
          final dateStr = DateFormat('yyyy-MM-dd').format(selectedDate!);
          list = list.where((a) => a['date'] == dateStr).toList();
        }
        if (selectedType != 'semua') {
          list = list.where((a) => a['type'] == selectedType).toList();
        }
        return RefreshIndicator(
          onRefresh: _refresh,
          color: Colors.green,
          child: Column(
            children: [
              Card(
                margin: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    ListTile(
                      leading: const Icon(Icons.calendar_today),
                      title: Text(
                        selectedDate != null
                            ? DateFormat('yyyy-MM-dd').format(selectedDate!)
                            : 'Semua Tanggal',
                      ),
                      trailing: const Icon(Icons.arrow_drop_down),
                      onTap: _selectDate,
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: DropdownButton<String>(
                        value: selectedType,
                        isExpanded: true,
                        items: const [
                          DropdownMenuItem(
                            value: 'semua',
                            child: Text('Semua Type'),
                          ),
                          DropdownMenuItem(
                            value: 'masuk',
                            child: Text('Hanya Masuk'),
                          ),
                          DropdownMenuItem(
                            value: 'pulang',
                            child: Text('Hanya Pulang'),
                          ),
                        ],
                        onChanged: (v) => setState(() => selectedType = v!),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: list.isEmpty
                    ? Center(
                        child: Text(
                          "Belum ada absensi ${selectedType == 'semua' ? '' : 'type $selectedType'}.",
                          style: TextStyle(color: Colors.grey.shade700),
                        ),
                      )
                    : SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: DataTable(
                          columns: const [
                            DataColumn(label: Text('Tanggal')),
                            DataColumn(label: Text('Waktu')),
                            DataColumn(label: Text('Type')),
                            DataColumn(label: Text('Status')),
                          ],
                          rows: list.map((a) {
                            final approved = (a['approved'] ?? 0) == 1;
                            return DataRow(
                              onSelectChanged: (selected) => _showPopup(a),
                              cells: [
                                DataCell(Text(a['date'])),
                                DataCell(Text(a['time'])),
                                DataCell(Text(a['type'].toUpperCase())),
                                DataCell(
                                  Text(approved ? 'Approved' : 'Pending'),
                                ),
                              ],
                            );
                          }).toList(),
                        ),
                      ),
              ),
            ],
          ),
        );
      },
    );
  }
}
