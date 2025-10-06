import 'dart:io';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
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

  // Center: SMK N 2 Yogyakarta (approx). Radius 1 km.
  final double centerLat = -7.797068;
  final double centerLng = 110.370529;
  final double maxDistance = 3000;

  @override
  void initState() {
    super.initState();
    _initCamera();
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

  Future<void> _takeAndSaveAttendance() async {
    if (_controller == null || !_controller!.value.isInitialized) return;
    setState(() => loading = true);

    final pos = await LocationService.getCurrentPosition();
    if (pos == null) {
      setState(() => loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Gagal mendapatkan lokasi / izin belum diberikan"),
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
    if (dist > maxDistance) {
      setState(() => loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "Anda di luar area absensi (${(dist / 1000).toStringAsFixed(2)} km)",
          ),
        ),
      );
      return;
    }

    final xfile = await _controller!.takePicture();
    final dir = await getApplicationDocumentsDirectory();
    final savePath =
        '${dir.path}/absen_${widget.user['id']}_${DateTime.now().millisecondsSinceEpoch}.jpg';
    await File(xfile.path).copy(savePath);

    final date = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final time = DateFormat('HH:mm:ss').format(DateTime.now());
    await DBService.saveAttendance(
      widget.user['id'],
      date,
      time,
      '${pos.latitude},${pos.longitude}',
      savePath,
    );

    setState(() => loading = false);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Absensi tersimpan. Menunggu konfirmasi admin."),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_controller == null || !_controller!.value.isInitialized) {
      return const Center(child: CircularProgressIndicator());
    }

    return Column(
      children: [
        Expanded(child: CameraPreview(_controller!)),
        Padding(
          padding: const EdgeInsets.all(14.0),
          child: Column(
            children: [
              const Text(
                "Selfie akan dikirim dan disimpan sebagai pending. Admin harus mengonfirmasi.",
              ),
              const SizedBox(height: 8),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepOrange,
                  minimumSize: const Size.fromHeight(48),
                ),
                onPressed: loading ? null : _takeAndSaveAttendance,
                icon: const Icon(Icons.camera_alt),
                label: loading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text("Kirim Absensi Selfie"),
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
