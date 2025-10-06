import 'package:flutter/material.dart';
import 'pages/login_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const AbsensiApp());
}

class AbsensiApp extends StatelessWidget {
  const AbsensiApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Absensi Guru',
      theme: ThemeData(
        primarySwatch: Colors.green,
        scaffoldBackgroundColor: Colors.grey[50],
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.green[500]!),
      ),
      debugShowCheckedModeBanner: false,
      home: const LoginPage(),
    );
  }
}
