import 'dart:io';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:path_provider/path_provider.dart';
import 'db_helper.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Absensi Selfie Lokal',
      theme: ThemeData(useMaterial3: true, colorSchemeSeed: Colors.deepOrange),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  CameraController? _cameraController;
  List<CameraDescription>? _cameras;
  String _info = "Belum absen";
  File? _capturedImage;

  // Lokasi pusat absensi: SMK N 2 Yogyakarta
  final double centerLat = -7.797068;
  final double centerLng = 110.370529;

  final double maxDistance = 4000; // 1 km

  @override
  void initState() {
    super.initState();
    _initAll();
  }

  Future<void> _initAll() async {
    await Permission.camera.request();
    await Permission.locationWhenInUse.request();

    _cameras = await availableCameras();
    // Kamera depan
    final frontCamera = _cameras!.firstWhere(
      (c) => c.lensDirection == CameraLensDirection.front,
      orElse: () => _cameras![0],
    );

    _cameraController = CameraController(frontCamera, ResolutionPreset.medium);
    await _cameraController!.initialize();
    setState(() {});
  }

  Future<void> _ambilAbsensi() async {
    // 1. Cek lokasi
    final pos = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );
    final distance = Geolocator.distanceBetween(
      pos.latitude,
      pos.longitude,
      centerLat,
      centerLng,
    );

    if (distance > maxDistance) {
      setState(() {
        _info =
            "Anda di luar area absensi (>${(distance / 1000).toStringAsFixed(2)} km)";
      });
      return;
    }

    // 2. Ambil foto
    final image = await _cameraController!.takePicture();

    // 3. Simpan foto ke folder aplikasi
    final dir = await getApplicationDocumentsDirectory();
    final savePath =
        "${dir.path}/absen_${DateTime.now().millisecondsSinceEpoch}.jpg";
    await File(image.path).copy(savePath);

    // 4. Simpan data ke database
    await DBHelper.insertAbsensi({
      'photoPath': savePath,
      'latitude': pos.latitude,
      'longitude': pos.longitude,
      'timestamp': DateTime.now().toIso8601String(),
    });

    setState(() {
      _capturedImage = File(savePath);
      _info = "Absensi Berhasil ✅";
    });
  }

  Future<void> _lihatData() async {
    final list = await DBHelper.getAllAbsensi();
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Riwayat Absensi"),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: list.length,
            itemBuilder: (ctx, i) {
              final d = list[i];
              return ListTile(
                leading: Image.file(
                  File(d['photoPath']),
                  width: 50,
                  fit: BoxFit.cover,
                ),
                title: Text("Waktu: ${d['timestamp']}"),
                subtitle: Text("Lat:${d['latitude']}, Lng:${d['longitude']}"),
              );
            },
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Absensi Selfie Lokal")),
      body: Column(
        children: [
          Expanded(
            flex: 3,
            child:
                _cameraController == null ||
                    !_cameraController!.value.isInitialized
                ? const Center(child: CircularProgressIndicator())
                : CameraPreview(_cameraController!),
          ),
          Expanded(
            flex: 2,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(_info, style: const TextStyle(fontSize: 16)),
                  const SizedBox(height: 10),
                  ElevatedButton.icon(
                    onPressed: _ambilAbsensi,
                    icon: const Icon(Icons.camera_alt),
                    label: const Text("Ambil Absensi"),
                  ),
                  ElevatedButton.icon(
                    onPressed: _lihatData,
                    icon: const Icon(Icons.history),
                    label: const Text("Lihat Riwayat"),
                  ),
                  if (_capturedImage != null)
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Image.file(_capturedImage!, height: 120),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
