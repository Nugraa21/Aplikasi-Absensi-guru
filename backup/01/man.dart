// ====================================================================== test code dari flutter create .

import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Test Kamera & GPS',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepOrange),
        useMaterial3: true,
      ),
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
  String _locationText = "Lokasi belum didapat";

  @override
  void initState() {
    super.initState();
    _initPermissions();
  }

  /// Meminta izin Kamera dan Lokasi
  Future<void> _initPermissions() async {
    await Permission.camera.request();
    await Permission.locationWhenInUse.request();

    _initCamera();
  }

  /// Inisialisasi Kamera
  Future<void> _initCamera() async {
    _cameras = await availableCameras();
    if (_cameras != null && _cameras!.isNotEmpty) {
      _cameraController = CameraController(
        _cameras![0],
        ResolutionPreset.medium,
      );
      await _cameraController!.initialize();
      setState(() {});
    }
  }

  /// Mendapatkan Lokasi saat ini
  Future<void> _getLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      setState(() {
        _locationText = "GPS tidak aktif!";
      });
      return;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        setState(() {
          _locationText = "Izin GPS ditolak!";
        });
        return;
      }
    }

    final pos = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );

    setState(() {
      _locationText = "Lat: ${pos.latitude}, Lng: ${pos.longitude}";
    });
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Test Kamera & GPS')),
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
            flex: 1,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(_locationText),
                  const SizedBox(height: 10),
                  ElevatedButton.icon(
                    onPressed: _getLocation,
                    icon: const Icon(Icons.location_on),
                    label: const Text("Dapatkan Lokasi"),
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


// ====================================================================== test code dari flutter create .


// // Mengimpor package Flutter untuk membuat UI
// import 'package:flutter/material.dart';

// // Fungsi utama (entry point) aplikasi Flutter
// void main() {
//   // Menjalankan widget MyApp sebagai aplikasi utama
//   runApp(const MyApp());
// }

// // Kelas MyApp adalah root widget dari aplikasi
// class MyApp extends StatelessWidget {
//   // Konstruktor MyApp, menggunakan "const" untuk membuat widget ini immutable
//   const MyApp({super.key});

//   // Override metode build untuk mendefinisikan UI dari widget ini
//   @override
//   Widget build(BuildContext context) {
//     // Menggunakan MaterialApp untuk mengatur tema, title, dan halaman utama aplikasi
//     return MaterialApp(
//       // Judul aplikasi yang muncul di task switcher
//       title: 'Flutter Demo',

//       // Tema aplikasi menggunakan ColorScheme dengan seedColor untuk menghasilkan warna turunan
//       theme: ThemeData(
//         colorScheme: ColorScheme.fromSeed(
//           seedColor: Colors.deepPurple,
//         ), // Tema warna utama aplikasi
//       ),

//       // Halaman utama aplikasi ditentukan ke MyHomePage
//       home: const MyHomePage(title: 'Flutter Demo Home Page'),
//     );
//   }
// }

// // Kelas MyHomePage adalah StatefulWidget yang menampilkan halaman utama aplikasi
// class MyHomePage extends StatefulWidget {
//   // Konstruktor untuk menerima parameter title
//   const MyHomePage({super.key, required this.title});

//   // Variabel untuk menyimpan judul halaman
//   final String title;

//   // Metode untuk membuat state dari widget ini
//   @override
//   State<MyHomePage> createState() => _MyHomePageState();
// }

// // Kelas _MyHomePageState menyimpan state (keadaan) dari MyHomePage
// class _MyHomePageState extends State<MyHomePage> {
//   // Variabel counter untuk menyimpan jumlah klik tombol
//   int _counter = 0;

//   // Fungsi untuk menambah nilai counter setiap kali tombol ditekan
//   void _incrementCounter() {
//     setState(() {
//       // setState digunakan untuk memberitahu Flutter agar UI diperbarui
//       _counter++; // Menambah nilai counter sebesar 1
//     });
//   }

//   // Metode build untuk mendefinisikan UI halaman ini
//   @override
//   Widget build(BuildContext context) {
//     // Scaffold menyediakan struktur dasar halaman seperti AppBar, body, dan FloatingActionButton
//     return Scaffold(
//       // AppBar (bagian atas aplikasi) menampilkan judul halaman
//       appBar: AppBar(
//         // Warna background AppBar menggunakan warna inverse dari tema
//         backgroundColor: Theme.of(context).colorScheme.inversePrimary,
//         // Menampilkan teks judul dari widget.title
//         title: Text(widget.title),
//       ),

//       // Body menampilkan konten utama halaman
//       body: Center(
//         // Center digunakan agar konten di tengah layar
//         child: Column(
//           // Mengatur susunan widget secara vertikal (atas ke bawah)
//           mainAxisAlignment:
//               MainAxisAlignment.center, // Konten berada di tengah vertikal
//           children: <Widget>[
//             // Teks statis yang memberi tahu pengguna
//             const Text('You have pushed the button this many times:'),

//             // Teks untuk menampilkan jumlah klik tombol (_counter)
//             Text(
//               '$_counter', // Menampilkan nilai counter
//               style: Theme.of(
//                 context,
//               ).textTheme.headlineMedium, // Menggunakan gaya teks dari tema
//             ),
//           ],
//         ),
//       ),

//       // FloatingActionButton (tombol bulat mengambang di pojok kanan bawah)
//       floatingActionButton: FloatingActionButton(
//         // Aksi yang dijalankan saat tombol ditekan
//         onPressed: _incrementCounter,
//         // Tooltip yang muncul saat pengguna menahan tombol
//         tooltip: 'Increment',
//         // Ikon yang ditampilkan di dalam tombol
//         child: const Icon(Icons.add),
//       ),
//     );
//   }
// }

// ======================================================================

// import 'package:flutter/material.dart';

// void main() {
//   runApp(const MyApp());
// }

// class MyApp extends StatelessWidget {
//   const MyApp({super.key});

//   // This widget is the root of your application.
//   @override
//   Widget build(BuildContext context) {
//     return MaterialApp(
//       title: 'Flutter Demo',
//       theme: ThemeData(
//         colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
//       ),
//       home: const MyHomePage(title: 'Flutter Demo Home Page'),
//     );
//   }
// }

// class MyHomePage extends StatefulWidget {
//   const MyHomePage({super.key, required this.title});

//   final String title;

//   @override
//   State<MyHomePage> createState() => _MyHomePageState();
// }

// class _MyHomePageState extends State<MyHomePage> {
//   int _counter = 0;

//   void _incrementCounter() {
//     setState(() {
//       _counter++;
//     });
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         backgroundColor: Theme.of(context).colorScheme.inversePrimary,
//         title: Text(widget.title),
//       ),
//       body: Center(
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: <Widget>[
//             const Text('You have pushed the button this many times:'),
//             Text(
//               '$_counter',
//               style: Theme.of(context).textTheme.headlineMedium,
//             ),
//           ],
//         ),
//       ),
//       floatingActionButton: FloatingActionButton(
//         onPressed: _incrementCounter,
//         tooltip: 'Increment',
//         child: const Icon(Icons.add),
//       ),
//     );
//   }
// }
