import 'dart:io';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:geolocator/geolocator.dart';
import '../services/location_service.dart';
import '../services/db_service.dart';

class AttendancePage extends StatefulWidget {
  final Map<String, dynamic> user;
  const AttendancePage({super.key, required this.user});

  @override
  State<AttendancePage> createState() => _AttendancePageState();
}

class _AttendancePageState extends State<AttendancePage> {
  CameraController? _controller;
  bool loading = false;
  double radiusMeters = 1000;
  String selectedType = 'masuk';
  final double centerLat = -7.797068;
  final double centerLng = 110.370529;

  @override
  void initState() {
    super.initState();
    _initCamera();
    _loadRadius();
  }

  Future<void> _loadRadius() async {
    final v = await DBService.getSetting('attendance_radius');
    setState(() => radiusMeters = double.tryParse(v) ?? 1000);
  }

  Future<void> _initCamera() async {
    final cams = await availableCameras();
    final front = cams.firstWhere(
      (c) => c.lensDirection == CameraLensDirection.front,
      orElse: () => cams.first,
    );
    _controller = CameraController(front, ResolutionPreset.medium);
    await _controller!.initialize();
    if (mounted) setState(() {});
  }

  bool _isValidTime(String type) {
    final now = DateTime.now();
    final hour = now.hour;
    if (type == 'masuk') {
      return hour >= 6 && hour < 9;
    } else {
      return hour >= 15 && hour <= 18;
    }
  }

  Future<void> _takeAndSave(String type) async {
    if (_controller == null || !_controller!.value.isInitialized) return;
    if (!_isValidTime(type)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            type == 'masuk'
                ? "Absen masuk hanya jam 6:00-9:00 pagi!"
                : "Absen pulang hanya jam 15:00-18:00 sore!",
          ),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }
    setState(() => loading = true);

    final pos = await LocationService.getCurrentPosition();
    if (pos == null) {
      setState(() => loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Gagal dapat lokasi / izin belum diberikan"),
        ),
      );
      return;
    }

    final dist = LocationService.distanceInMeters(
      pos.latitude,
      pos.longitude,
      centerLat,
      centerLng,
    );
    if (dist > radiusMeters) {
      setState(() => loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "Di luar area absensi (${(dist / 1000).toStringAsFixed(2)} km)",
          ),
        ),
      );
      return;
    }

    final xfile = await _controller!.takePicture();
    final dir = await getApplicationDocumentsDirectory();
    final savePath =
        '${dir.path}/absen_${widget.user['id']}_${type}_${DateTime.now().millisecondsSinceEpoch}.jpg';
    await File(xfile.path).copy(savePath);

    final date = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final time = DateFormat('HH:mm:ss').format(DateTime.now());
    await DBService.saveAttendance(
      widget.user['id'],
      date,
      time,
      '${pos.latitude},${pos.longitude}',
      savePath,
      type,
    );

    setState(() => loading = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("Absen $type berhasil! (pending admin)"),
        backgroundColor: Colors.green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_controller == null || !_controller!.value.isInitialized) {
      return const Center(
        child: CircularProgressIndicator(color: Colors.green),
      );
    }
    return Column(
      children: [
        Expanded(child: CameraPreview(_controller!)),
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Text(
                "Radius absensi: ${radiusMeters.toInt()} m",
                style: const TextStyle(color: Colors.black54),
              ),
              const SizedBox(height: 8),
              DropdownButton<String>(
                value: selectedType,
                isExpanded: true,
                items: const [
                  DropdownMenuItem(
                    value: 'masuk',
                    child: Text('Absen Masuk (6:00 pagi)'),
                  ),
                  DropdownMenuItem(
                    value: 'pulang',
                    child: Text('Absen Pulang (4:00 sore)'),
                  ),
                ],
                onChanged: (v) => setState(() => selectedType = v!),
              ),
              const SizedBox(height: 8),
              FutureBuilder<Position?>(
                future: LocationService.getCurrentPosition(),
                builder: (ctx, snap) {
                  if (snap.hasData) {
                    final dist = LocationService.distanceInMeters(
                      snap.data!.latitude,
                      snap.data!.longitude,
                      centerLat,
                      centerLng,
                    );
                    final inRadius = dist <= radiusMeters;
                    return Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: inRadius ? Colors.green[100]! : Colors.red[100]!,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.location_on,
                            color: inRadius ? Colors.green : Colors.red,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              inRadius
                                  ? "Di dalam radius SMK"
                                  : "Di luar radius (${(dist / 1000).toStringAsFixed(2)} km)",
                            ),
                          ),
                        ],
                      ),
                    );
                  }
                  return const SizedBox();
                },
              ),
              const SizedBox(height: 8),
              ElevatedButton.icon(
                onPressed: loading ? null : () => _takeAndSave(selectedType),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  minimumSize: const Size.fromHeight(48),
                ),
                icon: const Icon(Icons.camera_alt),
                label: loading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : Text("Absen ${selectedType.toUpperCase()}"),
              ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }
}
