import 'dart:io';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:intl/intl.dart';
import '../services/location_service.dart';
import '../services/db_service.dart';
import 'package:path_provider/path_provider.dart';

class AttendancePage extends StatefulWidget {
  final Map<String, dynamic> user;
  const AttendancePage({super.key, required this.user});

  @override
  State<AttendancePage> createState() => _AttendancePageState();
}

class _AttendancePageState extends State<AttendancePage> {
  CameraController? controller;
  XFile? capturedImage;
  bool isLoading = false;

  final double officeLat = -7.793389;
  final double officeLon = 110.384160;
  final double maxDistance = 3000; // 1 km

  @override
  void initState() {
    super.initState();
    _initCamera();
  }

  Future<void> _initCamera() async {
    final cameras = await availableCameras();
    final front = cameras.firstWhere(
      (c) => c.lensDirection == CameraLensDirection.front,
    );
    controller = CameraController(front, ResolutionPreset.medium);
    await controller!.initialize();
    setState(() {});
  }

  Future<void> takeAttendance() async {
    setState(() => isLoading = true);
    final position = await LocationService.getCurrentPosition();
    if (position == null) {
      setState(() => isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Gagal mendapatkan lokasi!")),
      );
      return;
    }

    final distance = LocationService.distanceInMeters(
      position.latitude,
      position.longitude,
      officeLat,
      officeLon,
    );
    if (distance > maxDistance) {
      setState(() => isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Anda di luar area absensi!")),
      );
      return;
    }

    capturedImage = await controller!.takePicture();
    final dir = await getApplicationDocumentsDirectory();
    final path =
        '${dir.path}/absen_${DateTime.now().millisecondsSinceEpoch}.jpg';
    await File(capturedImage!.path).copy(path);

    final date = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final time = DateFormat('HH:mm:ss').format(DateTime.now());

    await DBService.saveAttendance(
      widget.user['id'],
      date,
      time,
      "${position.latitude},${position.longitude}",
      path,
    );

    setState(() => isLoading = false);
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text("Absensi berhasil!")));
  }

  @override
  Widget build(BuildContext context) {
    if (controller == null || !controller!.value.isInitialized) {
      return const Center(child: CircularProgressIndicator());
    }

    return Scaffold(
      appBar: AppBar(title: const Text("Absensi")),
      body: Column(
        children: [
          Expanded(child: CameraPreview(controller!)),
          Padding(
            padding: const EdgeInsets.all(16),
            child: ElevatedButton(
              onPressed: isLoading ? null : takeAttendance,
              style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
              child: isLoading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text(
                      "Ambil Selfie & Absen",
                      style: TextStyle(fontSize: 18),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
